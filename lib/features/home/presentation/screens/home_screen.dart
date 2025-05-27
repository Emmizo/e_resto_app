import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/action_queue_provider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/action_queue_helper.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/dio_service.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../restaurant/data/models/restaurant_model.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';

class CuisineCategory {
  final int? id; // null for 'All'
  final String name;
  CuisineCategory({this.id, required this.name});
}

class PromoBanner {
  final int id;
  final int restaurantId;
  final String title;
  final String description;
  final String imagePath;
  final String startDate;
  final String endDate;
  final bool isActive;
  final String restaurantName;

  PromoBanner({
    required this.id,
    required this.restaurantId,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.restaurantName,
  });

  factory PromoBanner.fromJson(Map<String, dynamic> json) {
    return PromoBanner(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      title: json['title'],
      description: json['description'],
      imagePath: json['image_path'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isActive: json['is_active'] == 1,
      restaurantName: json['restaurant']['name'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<RestaurantModel> restaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  bool _isRestaurantLoading = true;
  String? _restaurantError;
  List<CuisineCategory> _categories = [CuisineCategory(name: 'All')];
  final Set<int> _favoriteLoading = {};
  double? _userLat;
  double? _userLng;
  Timer? _locationRefreshTimer;
  StreamSubscription<Position>? _positionStreamSubscription;
  List<PromoBanner> _promoBanners = [];
  bool _isPromoLoading = true;
  Timer? _debounce;

  List<CuisineCategory> get categories => _categories;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
    _checkAndStartLocationUpdates();
    _fetchPromoBanners();
  }

  Future<void> _checkAndStartLocationUpdates() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showLocationDeniedDialog();
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showLocationDeniedDialog(permanently: true);
      return;
    }
    // Permission granted, start location updates
    _getUserLocationAndSort();
    _startLocationAutoRefresh();
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters before update
      ),
    ).listen((Position position) {
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      _sortRestaurantsByDistance();
    }, onError: (e) {
      // Optionally handle stream errors gracefully
    });
  }

  void _startLocationAutoRefresh() {
    _locationRefreshTimer?.cancel();
    _locationRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _getUserLocationAndSort();
    });
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await DioService.getDio().get(ApiEndpoints.cuisines);
      final data = response.data['data'] as List;
      final cuisineCategories = data
          .map((c) =>
              CuisineCategory(id: c['id'] as int, name: c['name'] as String))
          .toList();

      // Cache to SQLite
      final db = await DatabaseHelper().db;
      final batch = db.batch();
      batch.delete('categories');
      for (final c in cuisineCategories) {
        batch.insert('categories', {'id': c.id, 'name': c.name},
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      setState(() {
        _categories = [CuisineCategory(name: 'All'), ...cuisineCategories];
        _tabController?.dispose();
        _tabController = TabController(length: _categories.length, vsync: this);
        _tabController?.addListener(() {
          if (_tabController?.indexIsChanging ?? false) {
            setState(() {
              _selectedCategoryIndex = _tabController?.index ?? 0;
            });
          }
        });
      });
    } catch (e) {
      // Try to load from SQLite
      try {
        final db = await DatabaseHelper().db;
        final maps = await db.query('categories');
        final cached = maps
            .map((m) =>
                CuisineCategory(id: m['id'] as int?, name: m['name'] as String))
            .toList();
        if (!mounted) return;
        setState(() {
          _categories = [CuisineCategory(name: 'All'), ...cached];
        });
        _tabController?.dispose();
        _tabController = TabController(length: _categories.length, vsync: this);
        _tabController?.addListener(() {
          if (_tabController?.indexIsChanging ?? false) {
            setState(() {
              _selectedCategoryIndex = _tabController?.index ?? 0;
            });
          }
        });
      } catch (e2) {
        setState(() {
          _isPromoLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _positionStreamSubscription?.cancel();
    _locationRefreshTimer?.cancel();
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isRestaurantLoading = true;
      _restaurantError = null;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await DioService.getDio().get(
        ApiEndpoints.restaurants,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      if (!mounted) return;
      final List<dynamic> data = response.data['data'];

      final restaurants = data
          .map((json) {
            try {
              return RestaurantModel.fromJson(json);
            } catch (e) {
              return null;
            }
          })
          .where((r) => r != null)
          .cast<RestaurantModel>()
          .toList();

      if (restaurants.isEmpty) {
      } else {}
      if (!mounted) return;
      setState(() {
        this.restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isRestaurantLoading = false;
      });
      _applyFiltersAndSearch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isRestaurantLoading = false;
        _restaurantError = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    _applyFiltersAndSearch();
  }

  void _applyFiltersAndSearch() {
    setState(() {
      _filteredRestaurants = _searchQuery.isEmpty
          ? List.from(restaurants)
          : restaurants.where((restaurant) {
              final cuisineName = _categories
                  .firstWhere(
                    (cat) => cat.id == restaurant.cuisineId,
                    orElse: () => CuisineCategory(name: ''),
                  )
                  .name;
              return restaurant.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  (cuisineName.isNotEmpty &&
                      cuisineName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()));
            }).toList();
      // Always sort filtered list by distance
      _filteredRestaurants.sort((a, b) {
        final double aDist = _distanceTo(a) ?? double.infinity;
        final double bDist = _distanceTo(b) ?? double.infinity;
        return aDist.compareTo(bDist);
      });

      // Apply category filter if not "All"
      if (_selectedCategoryIndex > 0) {
        final selectedCategory = _categories[_selectedCategoryIndex];
        _filteredRestaurants = _filteredRestaurants
            .where((r) => r.cuisineId == selectedCategory.id)
            .toList();
        // Sort again after category filter
        _filteredRestaurants.sort((a, b) {
          final double aDist = _distanceTo(a) ?? double.infinity;
          final double bDist = _distanceTo(b) ?? double.infinity;
          return aDist.compareTo(bDist);
        });
      }
    });
  }

  Future<void> _getUserLocationAndSort() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      _sortRestaurantsByDistance();
    } catch (e) {
      // If location fails, just use the original order
    }
  }

  void _sortRestaurantsByDistance() {
    if (_userLat == null || _userLng == null) return;
    restaurants.sort((a, b) {
      final double aDist = Geolocator.distanceBetween(
          _userLat!,
          _userLng!,
          double.tryParse(a.latitude) ?? 0.0,
          double.tryParse(a.longitude) ?? 0.0);
      final double bDist = Geolocator.distanceBetween(
          _userLat!,
          _userLng!,
          double.tryParse(b.latitude) ?? 0.0,
          double.tryParse(b.longitude) ?? 0.0);
      return aDist.compareTo(bDist);
    });
    setState(() {});
  }

  List<RestaurantModel> get nearestRestaurantsForMap {
    if (_userLat == null || _userLng == null) {
      return restaurants.take(5).toList();
    }
    return restaurants.take(5).toList(); // Already sorted by distance
  }

  double? _distanceTo(RestaurantModel restaurant) {
    if (_userLat == null || _userLng == null) return null;
    final lat = double.tryParse(restaurant.latitude);
    final lng = double.tryParse(restaurant.longitude);
    if (lat == null || lng == null) return null;
    // Ignore (0,0) coordinates
    if (lat == 0.0 && lng == 0.0) return null;
    return Geolocator.distanceBetween(
      _userLat!,
      _userLng!,
      lat,
      lng,
    );
  }

  Future<void> _toggleFavorite(RestaurantModel restaurant) async {
    final isOnline =
        Provider.of<ConnectivityProvider>(context, listen: false).isOnline;
    final isCurrentlyFavorite = restaurant.isFavorite;
    setState(() {
      _favoriteLoading.add(restaurant.id);
    });
    if (!isOnline) {
      // Queue the action using the helper
      await ActionQueueHelper.queueAction(
        actionType: isCurrentlyFavorite ? 'unfavorite' : 'favorite',
        payload: {'restaurant_id': restaurant.id},
      );
      // Refresh the badge
      if (mounted) {
        context.read<ActionQueueProvider>().refresh();
      }
      // Optimistically update the UI
      setState(() {
        restaurants = restaurants.map((r) {
          if (r.id == restaurant.id) {
            return r.copyWith(isFavorite: !isCurrentlyFavorite);
          }
          return r;
        }).toList();
        _filteredRestaurants = _filteredRestaurants.map((r) {
          if (r.id == restaurant.id) {
            return r.copyWith(isFavorite: !isCurrentlyFavorite);
          }
          return r;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyFavorite
              ? 'Will remove from favorites when online'
              : 'Will add to favorites when online'),
        ),
      );
      setState(() {
        _favoriteLoading.remove(restaurant.id);
      });
      return;
    }
    final dio = DioService.getDio();
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    try {
      final endpoint = isCurrentlyFavorite
          ? ApiEndpoints.restaurantUnfavorite
          : ApiEndpoints.restaurantFavorite;
      await dio.post(
        endpoint,
        data: {'restaurant_id': restaurant.id},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      if (!mounted) return;
      setState(() {
        // Update the favorite status in both lists
        restaurants = restaurants.map((r) {
          if (r.id == restaurant.id) {
            return r.copyWith(isFavorite: !isCurrentlyFavorite);
          }
          return r;
        }).toList();
        _filteredRestaurants = _filteredRestaurants.map((r) {
          if (r.id == restaurant.id) {
            return r.copyWith(isFavorite: !isCurrentlyFavorite);
          }
          return r;
        }).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isCurrentlyFavorite
              ? 'Removed from favorites'
              : 'Added to favorites'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchPromoBanners() async {
    setState(() => _isPromoLoading = true);
    try {
      final response = await DioService.getDio().get(ApiEndpoints.promoBanners);
      final data = response.data['data'] as List;
      final banners = data.map((e) => PromoBanner.fromJson(e)).toList();

      // Cache to SQLite
      final db = await DatabaseHelper().db;
      final batch = db.batch();
      batch.delete('banners');
      for (final b in banners) {
        batch.insert(
            'banners',
            {
              'id': b.id,
              'restaurantId': b.restaurantId,
              'title': b.title,
              'description': b.description,
              'imagePath': b.imagePath,
              'startDate': b.startDate,
              'endDate': b.endDate,
              'isActive': b.isActive ? 1 : 0,
              'restaurantName': b.restaurantName,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
      if (!mounted) return;
      setState(() {
        _promoBanners = banners;
        _isPromoLoading = false;
      });
    } catch (e) {
      // Try to load from SQLite
      try {
        final db = await DatabaseHelper().db;
        final maps = await db.query('banners');
        if (!mounted) return;
        final cached = maps
            .map((m) => PromoBanner(
                  id: m['id'] as int,
                  restaurantId: m['restaurantId'] as int,
                  title: m['title'] as String,
                  description: m['description'] as String,
                  imagePath: m['imagePath'] as String,
                  startDate: m['startDate'] as String,
                  endDate: m['endDate'] as String,
                  isActive: (m['isActive'] as int) == 1,
                  restaurantName: m['restaurantName'] as String,
                ))
            .toList();
        if (!mounted) return;
        setState(() {
          _promoBanners = cached;
          _isPromoLoading = false;
        });
      } catch (e2) {
        if (!mounted) return;
        setState(() => _isPromoLoading = false);
      }
    }
  }

  void _showLocationDeniedDialog({bool permanently = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission'),
        content: Text(permanently
            ? 'Location permission is permanently denied. Please enable it in Settings to use location features.'
            : 'Location permission is required to show nearby restaurants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          if (permanently)
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                style: Theme.of(context).textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Search restaurant or cuisine...',
                  hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                  prefixIcon: Icon(Icons.search,
                      color: Theme.of(context).colorScheme.primary),
                  filled: true,
                  fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
                      Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFiltersAndSearch();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Promo Banner
            if (_isPromoLoading)
              const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              (() {
                // If there are no banners at all, remove the section
                if (_promoBanners.isEmpty) {
                  return const SizedBox.shrink();
                }
                // If location is not available, remove the section
                if (_userLat == null || _userLng == null) {
                  return const SizedBox.shrink();
                }
                // If location is available, filter by distance (5 km)
                final List<PromoBanner> nearBanners =
                    _promoBanners.where((banner) {
                  final restaurant = restaurants.firstWhere(
                    (r) => r.id == banner.restaurantId,
                    orElse: () => RestaurantModel(
                      id: -1,
                      name: '',
                      description: '',
                      address: '',
                      longitude: '',
                      latitude: '',
                      phoneNumber: '',
                      email: '',
                      openingHours: '',
                      cuisineId: null,
                      priceRange: '',
                      image: null,
                      ownerId: -1,
                      isApproved: false,
                      status: false,
                      menus: [],
                      averageRating: 0.0,
                      isFavorite: false,
                      acceptsReservations: 0,
                      acceptsDelivery: 0,
                    ),
                  );
                  if (restaurant.id == -1) return false;
                  final lat = double.tryParse(restaurant.latitude);
                  final lng = double.tryParse(restaurant.longitude);
                  if (lat == null || lng == null) return false;
                  final dist = Geolocator.distanceBetween(
                    _userLat!,
                    _userLng!,
                    lat,
                    lng,
                  );

                  return dist < 5000;
                }).toList();
                if (nearBanners.isEmpty) {
                  return const SizedBox.shrink();
                }
                return CarouselSlider(
                  options: CarouselOptions(
                    height: 180,
                    autoPlay: true,
                    enlargeCenterPage: true,
                    viewportFraction: 1.0,
                  ),
                  items: nearBanners.map((banner) {
                    final promoRestaurant = restaurants.firstWhere(
                      (r) => r.id == banner.restaurantId,
                      orElse: () => RestaurantModel(
                        id: -1,
                        name: '',
                        description: '',
                        address: '',
                        longitude: '',
                        latitude: '',
                        phoneNumber: '',
                        email: '',
                        openingHours: '',
                        cuisineId: null,
                        priceRange: '',
                        image: null,
                        ownerId: -1,
                        isApproved: false,
                        status: false,
                        menus: [],
                        averageRating: 0.0,
                        isFavorite: false,
                        acceptsReservations: 0,
                        acceptsDelivery: 0,
                      ),
                    );
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          banner.imagePath.isNotEmpty
                              ? Image.network(
                                  fixImageUrl(banner.imagePath),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 180,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: double.infinity,
                                    height: 180,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.local_offer,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 180,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.local_offer,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                ),
                          // Stronger gradient overlay at bottom
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: 90,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withValues(alpha: 0.85),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                            ),
                          ),
                          // Text and button
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  banner.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 6, offset: Offset(0, 2))
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Flexible(
                                  child: Text(
                                    banner.description,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.92),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      shadows: [
                                        const Shadow(
                                            blurRadius: 6, offset: Offset(0, 2))
                                      ],
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner.restaurantName,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    shadows: [
                                      Shadow(
                                          blurRadius: 6, offset: Offset(0, 2))
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.black45,
                                    ),
                                    onPressed: promoRestaurant.id != -1
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RestaurantDetailsScreen(
                                                  restaurant: promoRestaurant,
                                                  cuisines: _categories,
                                                ),
                                              ),
                                            );
                                          }
                                        : null,
                                    child: const Text('Visit Us',
                                        style: TextStyle(color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              })(),
            const SizedBox(height: 24),
            // Category Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Select by Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 20),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategoryIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryIndex = index;
                        _applyFiltersAndSearch();
                      });
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : [],
                          ),
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.fastfood,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Fastest Near You
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Fastest Near You',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: context.watch<ConnectivityProvider>().isOnline
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllRestaurantsScreen(
                                  restaurants: _filteredRestaurants,
                                  categories: _categories,
                                  userLat: _userLat,
                                  userLng: _userLng,
                                ),
                              ),
                            );
                          }
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'No internet connection. Please try again later.')),
                            );
                          },
                    child: const Text('See more'),
                  ),
                ],
              ),
            ),
            // Remove Expanded and use shrinkWrap for GridView
            _isRestaurantLoading
                ? const Center(child: CircularProgressIndicator())
                : _restaurantError != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                size: 54, color: Colors.red[300]),
                            const SizedBox(height: 10),
                            Text(
                              'Something went wrong',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We couldn\'t load restaurants. Please try again.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.grey[600]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : _filteredRestaurants.isEmpty
                        ? Center(
                            child: Card(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.restaurant_outlined,
                                        size: 54, color: Colors.grey[400]),
                                    const SizedBox(height: 10),
                                    Text(
                                      'No restaurants found',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Try a different search or category',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.grey[600]),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : (() {
                            // Chunk the restaurants into groups of 3 for horizontally scrollable rows
                            final List<List<RestaurantModel>> chunked = [];
                            for (var i = 0;
                                i < _filteredRestaurants.length;
                                i += 3) {
                              chunked.add(_filteredRestaurants
                                  .skip(i)
                                  .take(3)
                                  .toList());
                            }
                            return Column(
                              children: [
                                for (int i = 0; i < chunked.length; i++) ...[
                                  SizedBox(
                                    height: 240, // Card height
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: chunked[i].length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 16),
                                      itemBuilder: (context, index) {
                                        final restaurant = chunked[i][index];
                                        return SizedBox(
                                          width: 180,
                                          child: _ApiRestaurantCard(
                                            restaurant: restaurant,
                                            categories: _categories,
                                            onFavoriteToggle: () =>
                                                _toggleFavorite(restaurant),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (i < chunked.length - 1)
                                    const SizedBox(height: 16),
                                ],
                              ],
                            );
                          })(),
          ],
        ),
      ),
    );
  }
}

class _ApiRestaurantCard extends StatefulWidget {
  final RestaurantModel restaurant;
  final List<CuisineCategory> categories;
  final VoidCallback? onFavoriteToggle;
  const _ApiRestaurantCard({
    required this.restaurant,
    required this.categories,
    this.onFavoriteToggle,
  });

  @override
  State<_ApiRestaurantCard> createState() => _ApiRestaurantCardState();
}

class _ApiRestaurantCardState extends State<_ApiRestaurantCard> {
  double _tilt = 0;

  void _onTapDown(TapDownDetails details) {
    setState(() => _tilt = 0.05);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _tilt = 0);
  }

  void _onTapCancel() {
    setState(() => _tilt = 0);
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    final categories = widget.categories;
    final onFavoriteToggle = widget.onFavoriteToggle;
    final distance = _distanceToUser(context, restaurant);
    // Debug print for distance

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(
              restaurant: restaurant,
              cuisines: categories,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateX(_tilt),
        child: Card(
          elevation: 12, // Higher elevation for more depth
          shadowColor: Colors.black.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: restaurant.image != null &&
                              restaurant.image!.isNotEmpty
                          ? Image.network(
                              fixImageUrl(restaurant.image!),
                              width: double.infinity,
                              height: 90,
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value:
                                          loadingProgress.expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  (loadingProgress
                                                          .expectedTotalBytes ??
                                                      1)
                                              : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[200],
                                width: double.infinity,
                                height: 90,
                                child: const Icon(Icons.restaurant,
                                    color: Colors.grey, size: 40),
                              ),
                            )
                          : Container(
                              color: Colors.grey[200],
                              width: double.infinity,
                              height: 90,
                              child: const Icon(Icons.restaurant,
                                  color: Colors.grey, size: 40),
                            ),
                    ),
                    // Distance chip
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: distance != null ? Colors.green : Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          distance != null
                              ? (distance < 1000
                                  ? '${distance.toStringAsFixed(0)} m'
                                  : '${(distance / 1000).toStringAsFixed(2)} km')
                              : 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                    // Rating badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber[700],
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            const BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.averageRating.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Divider(height: 1, color: Theme.of(context).dividerColor),
                const SizedBox(height: 4),
                Text(
                  restaurant.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                // Cuisine chip (always visible)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: Colors
                        .red, // TEMP: make chip background red for visibility
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    restaurant.cuisineName ??
                        (categories
                            .firstWhere(
                              (cat) => cat.id == restaurant.cuisineId,
                              orElse: () => CuisineCategory(name: 'Unknown'),
                            )
                            .name),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white, // TEMP: white text for contrast
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  restaurant.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        restaurant.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: onFavoriteToggle,
                      tooltip:
                          restaurant.isFavorite ? 'Unfavorite' : 'Favorite',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double? _distanceToUser(BuildContext context, RestaurantModel restaurant) {
    final homeState = context.findAncestorStateOfType<HomeScreenState>();
    if (homeState == null ||
        homeState._userLat == null ||
        homeState._userLng == null) {
      return null;
    }
    final lat = double.tryParse(restaurant.latitude);
    final lng = double.tryParse(restaurant.longitude);
    if (lat == null || lng == null) return null;
    if (lat == 0.0 && lng == 0.0) return null;
    return Geolocator.distanceBetween(
      homeState._userLat!,
      homeState._userLng!,
      lat,
      lng,
    );
  }
}

// Placeholder for the 'See more' screen
class AllRestaurantsScreen extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  final List<CuisineCategory> categories;
  final double? userLat;
  final double? userLng;
  const AllRestaurantsScreen(
      {super.key,
      required this.restaurants,
      required this.categories,
      this.userLat,
      this.userLng});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Restaurants')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final restaurant = restaurants[index];
          final cuisine = categories.firstWhere(
            (cat) => cat.id == restaurant.cuisineId,
            orElse: () => CuisineCategory(name: 'Unknown'),
          );
          return Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailsScreen(
                      restaurant: restaurant,
                      cuisines: categories,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      backgroundImage: (restaurant.image != null &&
                              restaurant.image!.isNotEmpty)
                          ? NetworkImage(restaurant.image!)
                          : null,
                      child: (restaurant.image == null ||
                              restaurant.image!.isEmpty)
                          ? Icon(Icons.restaurant,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              size: 32)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant.cuisineName ?? cuisine.name,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            restaurant.address,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (userLat != null && userLng != null)
                            Builder(
                              builder: (context) {
                                final dist = Geolocator.distanceBetween(
                                  userLat!,
                                  userLng!,
                                  double.tryParse(restaurant.latitude) ?? 0.0,
                                  double.tryParse(restaurant.longitude) ?? 0.0,
                                );
                                return Text(
                                  dist < 1000
                                      ? '${dist.toStringAsFixed(0)} m away'
                                      : '${(dist / 1000).toStringAsFixed(2)} km away',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary,
                                        fontSize: 12,
                                      ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

String fixImageUrl(String url) {
  if (Platform.isAndroid) {
    return url.replaceFirst('localhost', '10.0.2.2');
  }
  return url;
}
