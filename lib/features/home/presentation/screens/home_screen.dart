import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:dio/dio.dart';
import '../../../restaurant/data/restaurant_remote_datasource.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

class CuisineCategory {
  final int? id; // null for 'All'
  final String name;
  CuisineCategory({this.id, required this.name});
}

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
  List<CuisineCategory> _categories = [CuisineCategory(id: null, name: 'All')];
  bool _isCategoriesLoading = true;
  String? _categoriesError;
  final Set<int> _favoriteLoading = {};

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _initializeMap();
    _fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
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
        _restaurants = restaurants;
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
          ? List.from(_restaurants)
          : _restaurants.where((restaurant) {
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

      // Apply category filter if not "All"
      if (_selectedCategoryIndex > 0) {
        final selectedCategory = _categories[_selectedCategoryIndex];
        _filteredRestaurants = _filteredRestaurants
            .where((r) => r.cuisineId == selectedCategory.id)
            .toList();
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
        _restaurants = _restaurants.map((r) {
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
                    : MediaQuery.of(context).size.height * 0.97,
                transform: Matrix4.translationValues(
                  0,
                  _isMapExpanded
                      ? 0
                      : -MediaQuery.of(context).size.height * 0.03,
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
                        width: 32,
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
                    if (_isCategoriesLoading)
                      const Center(child: CircularProgressIndicator()),
                    if (_categoriesError != null)
                      Center(
                          child: Text(
                              'Failed to load categories: $_categoriesError')),
                    if (_tabController != null)
                      Container(
                        height: 58,
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
                                      child: Text(category.name),
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
                                          childAspectRatio: 0.65,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                        itemCount: _filteredRestaurants.length,
                                        itemBuilder: (context, index) {
                                          final restaurant =
                                              _filteredRestaurants[index];
                                          return _ApiRestaurantCard(
                                            restaurant: restaurant,
                                            categories: _categories,
                                            onFavoriteToggle: () =>
                                                _toggleFavorite(restaurant),
                                            isLoading: _favoriteLoading
                                                .contains(restaurant.id),
                                          )
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
  final List<CuisineCategory> categories;
  final VoidCallback? onFavoriteToggle;
  final bool isLoading;
  const _ApiRestaurantCard({
    required this.restaurant,
    required this.categories,
    this.onFavoriteToggle,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsScreen(
                restaurant: restaurant,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: restaurant.image != null && restaurant.image!.isNotEmpty
                    ? Image.network(
                        restaurant.image!,
                        width: double.infinity,
                        height: 130,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            height: 130,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          height: 130,
                          child: const Icon(Icons.restaurant,
                              color: Colors.grey, size: 40),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        height: 130,
                        child: const Icon(Icons.restaurant,
                            color: Colors.grey, size: 40),
                      ),
              ),
              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey[300]),
              const SizedBox(height: 8),
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
                      orElse: () => CuisineCategory(id: null, name: 'Unknown'),
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
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          tooltip:
                              restaurant.isFavorite ? 'Unfavorite' : 'Favorite',
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
