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
  bool _isMapExpanded = true;
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

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _initializeMap();
    _fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
    _getUserLocationAndSort();
    _startLocationAutoRefresh();
    _fetchPromoBanners();

    // Start real-time location updates
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
      final dio = Dio();
      final response = await dio.get(ApiEndpoints.cuisines);
      final data = response.data['data'] as List;
      final cuisineCategories = data
          .map((c) =>
              CuisineCategory(id: c['id'] as int, name: c['name'] as String))
          .toList();
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
      setState(() {
        _isCategoriesLoading = false;
        _categoriesError = e.toString();
      });
    }
  }

  @override
  void dispose() {
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
      final dio = Dio();
      final datasource = RestaurantRemoteDatasource(dio);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final restaurants = await datasource.fetchRestaurants(token: token);

      setState(() {
        this.restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isRestaurantLoading = false;
      });
      _applyFiltersAndSearch();
    } catch (e) {
      debugPrint('Error fetching restaurants: \\${e.toString()}');
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

  Future<void> _initializeMap() async {
    try {
      // Check location permission
      final status = await Permission.location.request();
      if (status.isGranted) {
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          setState(() {
            _initialPosition = LatLng(position.latitude, position.longitude);
            _isLoading = false;
            _hasLocationPermission = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasLocationPermission = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasLocationPermission = false;
        });
      }
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
    final dio = Dio();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final isCurrentlyFavorite = restaurant.isFavorite;
    setState(() {
      _favoriteLoading.add(restaurant.id);
    });
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
    } finally {
      setState(() {
        _favoriteLoading.remove(restaurant.id);
      });
    }
  }

  Future<void> _fetchPromoBanners() async {
    setState(() => _isPromoLoading = true);
    try {
      final dio = Dio();
      final response = await dio.get(ApiEndpoints.promoBanners);
      final data = response.data['data'] as List;
      setState(() {
        _promoBanners = data.map((e) => PromoBanner.fromJson(e)).toList();
        _isPromoLoading = false;
      });
    } catch (e) {
      setState(() => _isPromoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final name = user != null ? user.firstName : 'Guest';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF184C55)),
                    const SizedBox(width: 4),
                    Text(
                      '19687 Sun Cir',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.person, color: Color(0xFF184C55)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Promo Banner
            if (_isPromoLoading)
              SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_promoBanners.isNotEmpty)
              CarouselSlider(
                options: CarouselOptions(
                  height: 140,
                  autoPlay: true,
                  enlargeCenterPage: true,
                  viewportFraction: 0.95,
                ),
                items: _promoBanners.map((banner) {
                  return Builder(
                    builder: (context) => Container(
                      height: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
                              horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                banner.title,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                banner.description,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF7F3F),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  // Optionally: Navigate to the restaurant
                                },
                                child: const Text('Order now'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            else
              SizedBox(height: 140),
            const SizedBox(height: 24),
            // Category Selector
            Text(
              'Select by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
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
                              ? Color(0xFF184C55)
                              : Color(0xFFF5F6FA),
                          radius: 24,
                          child: Icon(
                            Icons.fastfood,
                            color:
                                isSelected ? Colors.white : Color(0xFF184C55),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: isSelected ? Color(0xFF184C55) : null,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fastest Near You',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('See more'),
                ),
              ],
            ),
            SizedBox(
              height: 240,
              child: _isRestaurantLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _restaurantError != null
                      ? Center(child: Text('Error: \\$_restaurantError'))
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
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filteredRestaurants.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 16),
                              itemBuilder: (context, index) {
                                final restaurant = _filteredRestaurants[index];
                                return SizedBox(
                                  width: 180,
                                  child: _ApiRestaurantCard(
                                    restaurant: restaurant,
                                    categories: _categories,
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
                Divider(height: 1, color: Colors.grey[300]),
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
                        color: Colors.grey[600],
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
                        color: Colors.grey[500],
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
                            color: Colors.blueGrey,
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
                        Icon(Icons.star, color: Colors.amber, size: 16),
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
