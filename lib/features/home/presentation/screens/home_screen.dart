import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';
import '../../../restaurant/presentation/screens/all_restaurants_screen.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../restaurant/data/restaurant_remote_datasource.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
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
  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  bool _isRestaurantLoading = true;
  String? _restaurantError;

  final List<String> _categories = [
    'All',
    'Italian',
    'Japanese',
    'Chinese',
    'Indian',
    'Mexican',
    'American',
    'Thai',
  ];

  @override
  void initState() {
    super.initState();
    _initializeTabController();
    _initializeMap();
    _fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeTabController() {
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController?.addListener(() {
      if (_tabController?.indexIsChanging ?? false) {
        setState(() {
          _selectedCategoryIndex = _tabController?.index ?? 0;
        });
      }
    });
  }

  @override
  void dispose() {
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
      final restaurants = await datasource.fetchRestaurants();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isRestaurantLoading = false;
      });
      _applyFiltersAndSearch();
    } catch (e) {
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
          ? List.from(_restaurants)
          : _restaurants.where((restaurant) {
              return restaurant.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  restaurant.cuisineType
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
            }).toList();

      // Apply category filter if not "All"
      if (_selectedCategoryIndex > 0) {
        _filteredRestaurants = _filteredRestaurants
            .where((r) => r.cuisineType == _categories[_selectedCategoryIndex])
            .toList();
      }
      // Optionally sort by name or other field
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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final name = user != null ? user.firstName : 'Guest';

    return Scaffold(
      body: Stack(
        children: [
          // Map View
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isMapExpanded
                ? MediaQuery.of(context).size.height
                : MediaQuery.of(context).size.height * 0.3,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasLocationPermission
                    ? GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initialPosition,
                          zoom: 15,
                        ),
                        onMapCreated: _onMapCreated,
                        markers: _markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        mapType: isDarkMode ? MapType.normal : MapType.normal,
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Location permission required',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _initializeMap,
                              icon: const Icon(Icons.location_on),
                              label: const Text('Grant Permission'),
                            ),
                          ],
                        ),
                      ),
          ),

          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          final profileUrl = authProvider.user?.profilePicture;
                          debugPrint('HomeScreen profileUrl: $profileUrl');
                          String? fullUrl;
                          if (profileUrl != null && profileUrl.isNotEmpty) {
                            fullUrl = profileUrl.startsWith('http')
                                ? profileUrl
                                : profileUrl;
                          }
                          if (fullUrl != null && fullUrl.isNotEmpty) {
                            return CircleAvatar(
                              radius: 20,
                              backgroundImage: NetworkImage(fullUrl),
                              backgroundColor: Colors.transparent,
                            );
                          } else {
                            return CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  const Color(0xFF184C55).withAlpha(16),
                              child: Icon(
                                Icons.person,
                                color: Color(0xFF184C55),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, $name!',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            Text(
                              'Find your favorite restaurant',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isDarkMode ? Icons.light_mode : Icons.dark_mode,
                          color: Color(0xFF184C55),
                        ),
                        onPressed: () {
                          final themeProvider = context.read<ThemeProvider>();
                          themeProvider.toggleTheme();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          // Handle notifications
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _applyFiltersAndSearch();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search restaurants...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _applyFiltersAndSearch();
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.2),

          // Restaurant List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.primaryDelta! < -10) {
                  setState(() => _isMapExpanded = false);
                } else if (details.primaryDelta! > 10) {
                  setState(() => _isMapExpanded = true);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isMapExpanded
                    ? MediaQuery.of(context).size.height * 0.4
                    : MediaQuery.of(context).size.height * 0.7,
                transform: Matrix4.translationValues(
                  0,
                  _isMapExpanded
                      ? 0
                      : -MediaQuery.of(context).size.height * 0.3,
                  0,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Drag handle with tap functionality
                    GestureDetector(
                      onTap: () {
                        setState(() => _isMapExpanded = !_isMapExpanded);
                      },
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Scroll indicator text
                    if (_isMapExpanded)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Scroll down to see more restaurants',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ).animate().fadeIn(),

                    // Categories TabBar
                    if (_tabController != null)
                      Container(
                        height: 48,
                        alignment: Alignment.centerLeft,
                        child: TabBar(
                          controller: _tabController!,
                          isScrollable: true,
                          indicatorSize: TabBarIndicatorSize.label,
                          indicatorColor: Theme.of(context).colorScheme.primary,
                          labelColor: Color(0xFF184C55),
                          unselectedLabelColor: Colors.grey,
                          tabs: _categories
                              .map((category) => Tab(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _selectedCategoryIndex ==
                                                _categories.indexOf(category)
                                            ? const Color(0xFF184C55)
                                                .withAlpha(16)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(category),
                                    ),
                                  ))
                              .toList(),
                          onTap: (index) {
                            setState(() {
                              _selectedCategoryIndex = index;
                              _applyFiltersAndSearch();
                            });
                          },
                        ),
                      ),

                    // Featured Section and Restaurant List
                    Expanded(
                      child: _isRestaurantLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _restaurantError != null
                              ? Center(child: Text('Error: $_restaurantError'))
                              : _filteredRestaurants.isEmpty
                                  ? Center(
                                      child: Card(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 24),
                                        elevation: 2,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.restaurant_outlined,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'No restaurants found',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleLarge,
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
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
                                              const SizedBox(height: 16),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  setState(() {
                                                    _searchController.clear();
                                                    _searchQuery = '';
                                                    _selectedCategoryIndex = 0;
                                                    _tabController
                                                        ?.animateTo(0);
                                                    _applyFiltersAndSearch();
                                                  });
                                                },
                                                icon: const Icon(Icons.refresh),
                                                label:
                                                    const Text('Clear Filters'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        padding: const EdgeInsets.all(16),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          childAspectRatio: 0.75,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: _filteredRestaurants.length,
                                        itemBuilder: (context, index) {
                                          final restaurant =
                                              _filteredRestaurants[index];
                                          return _ApiRestaurantCard(
                                                  restaurant: restaurant)
                                              .animate(delay: (50 * index).ms)
                                              .fadeIn()
                                              .slideY();
                                        },
                                      ),
                                    ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApiRestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  const _ApiRestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsScreen(
                restaurantName: restaurant.name,
                restaurantImage: ApiConfig.imageBaseUrl + restaurant.image,
                rating: 0.0, // Placeholder, as rating is not available
                location: restaurant.address,
                openUntil: restaurant.openingHours,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  ApiConfig.imageBaseUrl + restaurant.image,
                  width: double.infinity,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 100,
                    color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                restaurant.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                restaurant.cuisineType,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                restaurant.address,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (!restaurant.status)
                Container(
                  width: 60,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'CLOSED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
