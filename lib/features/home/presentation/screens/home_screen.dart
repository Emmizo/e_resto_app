import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';
import '../../../restaurant/presentation/screens/all_restaurants_screen.dart';

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
  List<Restaurant> _restaurants = [];
  List<Restaurant> _filteredRestaurants = [];

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
    _initializeRestaurants();
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

  void _initializeRestaurants() {
    // Create mock restaurant data
    _restaurants = List.generate(
      20,
      (index) => Restaurant(
        name: 'Restaurant ${index + 1}',
        cuisine: _categories[1 + (index % (_categories.length - 1))],
        distance: (index + 1) * 0.5,
        rating: 4.0 + (index % 10) / 10,
        reviews: 50 + index * 10,
        imageUrl: index % 2 == 0
            ? 'assets/images/tea.jpg'
            : 'assets/images/tea-m.jpg',
        isOpen: index % 3 != 0,
        deliveryTime: '${15 + index * 5}',
        deliveryFee: (index % 2 == 0) ? 2.99 : 0.0,
        hasOffers: index % 4 == 0,
      ),
    );
    _applyFiltersAndSearch();
  }

  void _onSearchChanged() {
    _applyFiltersAndSearch();
  }

  void _applyFiltersAndSearch() {
    setState(() {
      // Apply search filter first
      _filteredRestaurants = _searchQuery.isEmpty
          ? List.from(_restaurants)
          : _restaurants.where((restaurant) {
              return restaurant.name
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()) ||
                  restaurant.cuisine
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
            }).toList();

      // Apply category filter if not "All"
      if (_selectedCategoryIndex > 0) {
        _filteredRestaurants = _filteredRestaurants
            .where((r) => r.cuisine == _categories[_selectedCategoryIndex])
            .toList();
      }

      // Sort by rating by default
      _filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
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
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF184C55).withAlpha(16),
                        child: Icon(
                          Icons.person,
                          color: Color(0xFF184C55),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, John!',
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
                      child: _filteredRestaurants.isEmpty
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
                                            _tabController?.animateTo(0);
                                            _applyFiltersAndSearch();
                                          });
                                        },
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Clear Filters'),
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
                                physics: const NeverScrollableScrollPhysics(),
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
                                  return _CompactRestaurantCard(
                                    name: restaurant.name,
                                    cuisine: restaurant.cuisine,
                                    distance: restaurant.distance,
                                    rating: restaurant.rating,
                                    reviews: restaurant.reviews,
                                    imageUrl: restaurant.imageUrl,
                                    isOpen: restaurant.isOpen,
                                    deliveryTime:
                                        '${restaurant.deliveryTime} min',
                                    deliveryFee: restaurant.deliveryFee,
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

class _CompactRestaurantCard extends StatelessWidget {
  final String name;
  final String cuisine;
  final double distance;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isOpen;
  final String deliveryTime;
  final double deliveryFee;

  const _CompactRestaurantCard({
    required this.name,
    required this.cuisine,
    required this.distance,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    this.isOpen = true,
    this.deliveryTime = '30 min',
    this.deliveryFee = 2.99,
  });

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
                restaurantName: name,
                restaurantImage: imageUrl,
                rating: rating,
                location: '$cuisine • ${distance.toStringAsFixed(1)} km away',
                openUntil: '10:00 PM',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.asset(
                    imageUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                if (!isOpen)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(128),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
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
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(179),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 14,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cuisine,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${distance.toStringAsFixed(1)} km',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.delivery_dining,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          deliveryFee == 0
                              ? 'Free'
                              : '\$${deliveryFee.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 2),
                        Text(
                          deliveryTime,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 10,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
