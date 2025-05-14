import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import '../../../restaurant/data/restaurant_remote_datasource.dart';
import '../../../restaurant/data/models/restaurant_model.dart';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:e_resta_app/core/services/action_queue_helper.dart';
import 'package:e_resta_app/core/providers/action_queue_provider.dart';
import 'package:e_resta_app/core/services/dio_service.dart';

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
  final Set<Marker> _markers = {};

  GoogleMapController? _mapController;
  bool _isMapReady = false;
  LatLng _initialPosition = const LatLng(0, 0);
  bool _isLoading = true;
  bool _hasLocationPermission = false;
  TabController? _tabController;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<RestaurantModel> restaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  bool _isRestaurantLoading = true;
  String? _restaurantError;
  List<CuisineCategory> _categories = [CuisineCategory(id: null, name: 'All')];
  bool _isCategoriesLoading = true;
  String? _categoriesError;
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
      debugPrint('Location stream error: \\${e.toString()}');
    });
  }

  void _startLocationAutoRefresh() {
    _locationRefreshTimer?.cancel();
    _locationRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _getUserLocationAndSort();
    });
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isCategoriesLoading = true;
      _categoriesError = null;
    });
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
        _categories = [
          CuisineCategory(id: null, name: 'All'),
          ...cuisineCategories
        ];
        _isCategoriesLoading = false;
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
        setState(() {
          _categories = [CuisineCategory(id: null, name: 'All'), ...cached];
          _isCategoriesLoading = false;
          _categoriesError = 'Showing offline data.';
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
          _isCategoriesLoading = false;
          _categoriesError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _positionStreamSubscription?.cancel();
    _locationRefreshTimer?.cancel();
    _mapController?.dispose();
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
      final datasource = RestaurantRemoteDatasource(Dio());
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final restaurants = await datasource.fetchRestaurants(token: token);

      // Cache to SQLite
      final db = await DatabaseHelper().db;
      final batch = db.batch();
      batch.delete('restaurants');
      for (final r in restaurants) {
        batch.insert('restaurants', r.toJson(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);

      setState(() {
        this.restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isRestaurantLoading = false;
      });
      _applyFiltersAndSearch();
    } catch (e) {
      debugPrint('Error fetching restaurants: \\${e.toString()}');
      // Try to load from SQLite
      try {
        final db = await DatabaseHelper().db;
        final maps = await db.query('restaurants');
        final cached = maps.map((m) => RestaurantModel.fromJson(m)).toList();
        setState(() {
          restaurants = cached;
          _filteredRestaurants = cached;
          _isRestaurantLoading = false;
          _restaurantError = 'Showing offline data.';
        });
        _applyFiltersAndSearch();
      } catch (e2) {
        setState(() {
          _isRestaurantLoading = false;
          _restaurantError = e.toString();
        });
      }
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
                    orElse: () => CuisineCategory(id: null, name: ''),
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
        double aDist = _distanceTo(a) ?? double.infinity;
        double bDist = _distanceTo(b) ?? double.infinity;
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
          double aDist = _distanceTo(a) ?? double.infinity;
          double bDist = _distanceTo(b) ?? double.infinity;
          return aDist.compareTo(bDist);
        });
      }
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) return;

    setState(() {
      _mapController = controller;
      _isMapReady = true;
    });

    _onMapReady();
    _updateMapState();
  }

  void _onMapReady() {
    if (_mapController != null && _hasLocationPermission) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _initialPosition,
            zoom: 15,
          ),
        ),
      );
    }
  }

  void _updateMapState() {
    if (_isMapReady && _mapController != null && _hasLocationPermission) {
      setState(() {
        _markers.clear();
        _markers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: _initialPosition,
            infoWindow: const InfoWindow(title: 'Your Location'),
          ),
        );
      });
    }
  }

  Future<void> _getUserLocationAndSort() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _userLat = position.latitude;
        _userLng = position.longitude;
      });
      _sortRestaurantsByDistance();
    } catch (e) {
      // If location fails, just use the original order
      debugPrint('Failed to get user location: $e');
    }
  }

  void _sortRestaurantsByDistance() {
    if (_userLat == null || _userLng == null) return;
    restaurants.sort((a, b) {
      double aDist = Geolocator.distanceBetween(
          _userLat!,
          _userLng!,
          double.tryParse(a.latitude) ?? 0.0,
          double.tryParse(a.longitude) ?? 0.0);
      double bDist = Geolocator.distanceBetween(
          _userLat!,
          _userLng!,
          double.tryParse(b.latitude) ?? 0.0,
          double.tryParse(b.longitude) ?? 0.0);
      return aDist.compareTo(bDist);
    });
    setState(() {});
  }

  List<RestaurantModel> get nearestRestaurantsForMap {
    if (_userLat == null || _userLng == null)
      return restaurants.take(5).toList();
    return restaurants.take(5).toList(); // Already sorted by distance
  }

  double? _distanceTo(RestaurantModel restaurant) {
    if (_userLat == null || _userLng == null) return null;
    return Geolocator.distanceBetween(
        _userLat!,
        _userLng!,
        double.tryParse(restaurant.latitude) ?? 0.0,
        double.tryParse(restaurant.longitude) ?? 0.0);
  }

  Future<void> _toggleFavorite(RestaurantModel restaurant) async {
    final isOnline = context.read<ConnectivityProvider>().isOnline;
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
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

      setState(() {
        _promoBanners = banners;
        _isPromoLoading = false;
      });
    } catch (e) {
      // Try to load from SQLite
      try {
        final db = await DatabaseHelper().db;
        final maps = await db.query('banners');
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
        setState(() {
          _promoBanners = cached;
          _isPromoLoading = false;
        });
      } catch (e2) {
        setState(() => _isPromoLoading = false);
      }
    }
  }

  void _showLocationDeniedDialog({bool permanently = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Location Permission'),
        content: Text(permanently
            ? 'Location permission is permanently denied. Please enable it in Settings to use location features.'
            : 'Location permission is required to show nearby restaurants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
          if (permanently)
            TextButton(
              onPressed: () {
                Geolocator.openAppSettings();
                Navigator.pop(context);
              },
              child: Text('Open Settings'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final name = user != null ? user.firstName : 'Guest';
    final isOnline = context.watch<ConnectivityProvider>().isOnline;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
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
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
              SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            else
              (() {
                // Filter banners for restaurants within 5km
                if (_userLat == null || _userLng == null) {
                  return SizedBox(height: 140); // Or show a message if you want
                }
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
                      website: null,
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
                    ),
                  );
                  if (restaurant.id == -1) return false;
                  final dist = Geolocator.distanceBetween(
                    _userLat!,
                    _userLng!,
                    double.tryParse(restaurant.latitude) ?? 0.0,
                    double.tryParse(restaurant.longitude) ?? 0.0,
                  );
                  return dist < 5000;
                }).toList();
                if (nearBanners.isNotEmpty) {
                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 140,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                    ),
                    items: nearBanners.map((banner) {
                      return Builder(
                        builder: (context) => Container(
                          height: 140,
                          width: MediaQuery.of(context).size.width - 32,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: NetworkImage(banner.imagePath),
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    banner.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    banner.description,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    banner.restaurantName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(80, 32),
                                      backgroundColor: const Color(0xFFFF7F3F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: isOnline
                                        ? () {
                                            final promoRestaurant =
                                                restaurants.firstWhere(
                                              (r) =>
                                                  r.id == banner.restaurantId,
                                              orElse: () => RestaurantModel(
                                                id: -1,
                                                name: '',
                                                description: '',
                                                address: '',
                                                longitude: '',
                                                latitude: '',
                                                phoneNumber: '',
                                                email: '',
                                                website: null,
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
                                              ),
                                            );
                                            if (promoRestaurant.id ==
                                                banner.restaurantId) {
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
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Restaurant not found.')),
                                              );
                                            }
                                          }
                                        : () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'No internet connection. Please try again later.')),
                                            );
                                          },
                                    child: const Text('Order now',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
                // If no banners, show restaurants within 1km as a slider in the same design
                final List<RestaurantModel> nearRestaurants =
                    restaurants.where((r) {
                  final dist = Geolocator.distanceBetween(
                    _userLat!,
                    _userLng!,
                    double.tryParse(r.latitude) ?? 0.0,
                    double.tryParse(r.longitude) ?? 0.0,
                  );
                  return dist <= 1000;
                }).toList();
                if (nearRestaurants.isNotEmpty) {
                  return CarouselSlider(
                    options: CarouselOptions(
                      height: 140,
                      autoPlay: true,
                      enlargeCenterPage: true,
                      viewportFraction: 1.0,
                    ),
                    items: nearRestaurants.map((restaurant) {
                      return Builder(
                        builder: (context) => Container(
                          height: 140,
                          width: MediaQuery.of(context).size.width - 32,
                          margin: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            image: DecorationImage(
                              image: restaurant.image != null &&
                                      restaurant.image!.isNotEmpty
                                  ? NetworkImage(restaurant.image!)
                                  : const AssetImage(
                                          'assets/images/placeholder.png')
                                      as ImageProvider,
                              fit: BoxFit.cover,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Colors.black.withOpacity(0.4),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 4.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    restaurant.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    restaurant.address,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _categories
                                        .firstWhere(
                                          (cat) =>
                                              cat.id == restaurant.cuisineId,
                                          orElse: () => CuisineCategory(
                                              id: null, name: 'Unknown'),
                                        )
                                        .name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size(80, 32),
                                      backgroundColor: const Color(0xFFFF7F3F),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: isOnline
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    RestaurantDetailsScreen(
                                                  restaurant: restaurant,
                                                  cuisines: _categories,
                                                ),
                                              ),
                                            );
                                          }
                                        : () {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                  content: Text(
                                                      'No internet connection. Please try again later.')),
                                            );
                                          },
                                    child: const Text('Order now',
                                        style: TextStyle(fontSize: 13)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
                // If no restaurants within 1km, show placeholder
                return SizedBox(
                  height: 140,
                  child: Center(
                    child: Text(
                      'No nearby banners or restaurants found.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
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
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 16),
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
                        CircleAvatar(
                          backgroundColor: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.surface,
                          radius: 24,
                          child: Icon(
                            Icons.fastfood,
                            color: isSelected
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
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
                    onPressed: isOnline
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
                              SnackBar(
                                  content: Text(
                                      'No internet connection. Please try again later.')),
                            );
                          },
                    child: const Text('See more'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 240,
              child: _isRestaurantLoading
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
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filteredRestaurants.length > 5
                                  ? 5
                                  : _filteredRestaurants.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final restaurant = _filteredRestaurants[index];
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
            const SizedBox(height: 24),
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
  final bool isLoading;
  final double? distance;
  const _ApiRestaurantCard({
    required this.restaurant,
    required this.categories,
    this.onFavoriteToggle,
    this.isLoading = false,
    this.distance,
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
    final isLoading = widget.isLoading;
    final distance = widget.distance;
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
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
          shadowColor: Colors.black.withOpacity(0.25),
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
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: restaurant.image != null &&
                            restaurant.image!.isNotEmpty
                        ? Image.network(
                            restaurant.image!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes !=
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
                              child: const Icon(Icons.restaurant,
                                  color: Colors.grey, size: 40),
                            ),
                          )
                        : Container(
                            color: Colors.grey[200],
                            width: double.infinity,
                            child: const Icon(Icons.restaurant,
                                color: Colors.grey, size: 40),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
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
                Text(
                  categories
                      .firstWhere(
                        (cat) => cat.id == restaurant.cuisineId,
                        orElse: () =>
                            CuisineCategory(id: null, name: 'Unknown'),
                      )
                      .name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  restaurant.address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        fontSize: 11,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (distance != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2, bottom: 2),
                    child: Text(
                      '${(distance / 1000).toStringAsFixed(2)} km away',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 11,
                          ),
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 16),
                        const SizedBox(width: 3),
                        Text(
                          restaurant.averageRating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                        ),
                      ],
                    ),
                    isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: Icon(
                              restaurant.isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.red,
                              size: 20,
                            ),
                            onPressed: onFavoriteToggle,
                            tooltip: restaurant.isFavorite
                                ? 'Unfavorite'
                                : 'Favorite',
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
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
}

// Placeholder for the 'See more' screen
class AllRestaurantsScreen extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  final List<CuisineCategory> categories;
  final double? userLat;
  final double? userLng;
  const AllRestaurantsScreen(
      {Key? key,
      required this.restaurants,
      required this.categories,
      this.userLat,
      this.userLng})
      : super(key: key);

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
            orElse: () => CuisineCategory(id: null, name: 'Unknown'),
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
                          Theme.of(context).colorScheme.surfaceVariant,
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
                            cuisine.name,
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
                                  '${(dist / 1000).toStringAsFixed(2)} km away',
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
