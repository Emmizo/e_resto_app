import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'restaurant_details_screen.dart';
import 'package:dio/dio.dart';
import '../../data/restaurant_remote_datasource.dart';
import '../../data/models/restaurant_model.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';

class Restaurant {
  final String name;
  final String cuisine;
  final double distance;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isOpen;
  final String deliveryTime;
  final double deliveryFee;
  final bool hasOffers;

  Restaurant({
    required this.name,
    required this.cuisine,
    required this.distance,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.isOpen,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.hasOffers,
  });
}

class AllRestaurantsScreen extends StatefulWidget {
  const AllRestaurantsScreen({super.key});

  @override
  State<AllRestaurantsScreen> createState() => _AllRestaurantsScreenState();
}

class _AllRestaurantsScreenState extends State<AllRestaurantsScreen> {
  String _selectedSort = 'Rating';
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _sortOptions = [
    'Rating',
    'Distance',
    'Delivery Time',
    'Price'
  ];
  final List<String> _filterOptions = [
    'All',
    'Open Now',
    'Free Delivery',
    'Offers'
  ];

  List<RestaurantModel> _restaurants = [];
  List<RestaurantModel> _filteredRestaurants = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchRestaurants();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _fetchRestaurants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = Dio();
      final datasource = RestaurantRemoteDatasource(dio);
      final restaurants = await datasource.fetchRestaurants();
      setState(() {
        _restaurants = restaurants;
        _filteredRestaurants = restaurants;
        _isLoading = false;
      });
      _applyFiltersAndSort();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFiltersAndSort();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _applyFiltersAndSort();
      }
    });
  }

  void _applyFiltersAndSort() {
    setState(() {
      // Apply search filter first
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

      // Apply other filters
      switch (_selectedFilter) {
        case 'Open Now':
          _filteredRestaurants =
              _filteredRestaurants.where((r) => r.status).toList();
          break;
        case 'Free Delivery':
          // _filteredRestaurants =
          //     _filteredRestaurants.where((r) => r.deliveryFee == 0).toList();
          break;
        case 'Offers':
          // _filteredRestaurants =
          //     _filteredRestaurants.where((r) => r.hasOffers).toList();
          break;
      }

      // Apply sorting
      switch (_selectedSort) {
        case 'Distance':
          // _filteredRestaurants.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'Delivery Time':
          // _filteredRestaurants.sort((a, b) =>
          //     int.parse(a.deliveryTime).compareTo(int.parse(b.deliveryTime)));
          break;
        case 'Price':
          // _filteredRestaurants
          //     .sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleSearch,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search restaurants...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey[400]),
                ),
                style: Theme.of(context).textTheme.titleMedium,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applyFiltersAndSort();
                  });
                },
              )
            : const Text('All Restaurants'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.clear : Icons.search),
            onPressed: () {
              if (_isSearching) {
                _searchController.clear();
                _applyFiltersAndSort();
              }
              _toggleSearch();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    // Filters and Sort Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Sort Dropdown
                          Expanded(
                            child: PopupMenuButton<String>(
                              initialValue: _selectedSort,
                              onSelected: (String value) {
                                setState(() {
                                  _selectedSort = value;
                                  _applyFiltersAndSort();
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return _sortOptions.map((String option) {
                                  return PopupMenuItem<String>(
                                    value: option,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getSortIcon(option),
                                          color: _selectedSort == option
                                              ? Color(0xFF184C55)
                                              : null,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          option,
                                          style: TextStyle(
                                            color: _selectedSort == option
                                                ? Color(0xFF184C55)
                                                : null,
                                            fontWeight: _selectedSort == option
                                                ? FontWeight.bold
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getSortIcon(_selectedSort),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Sort: $_selectedSort',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Filter Dropdown
                          Expanded(
                            child: PopupMenuButton<String>(
                              initialValue: _selectedFilter,
                              onSelected: (String value) {
                                setState(() {
                                  _selectedFilter = value;
                                  _applyFiltersAndSort();
                                });
                              },
                              itemBuilder: (BuildContext context) {
                                return _filterOptions.map((String option) {
                                  return PopupMenuItem<String>(
                                    value: option,
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getFilterIcon(option),
                                          color: _selectedFilter == option
                                              ? Color(0xFF184C55)
                                              : null,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          option,
                                          style: TextStyle(
                                            color: _selectedFilter == option
                                                ? Color(0xFF184C55)
                                                : null,
                                            fontWeight:
                                                _selectedFilter == option
                                                    ? FontWeight.bold
                                                    : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getFilterIcon(_selectedFilter),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Filter: $_selectedFilter',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Restaurant List
                    Expanded(
                      child: _filteredRestaurants.isEmpty
                          ? Center(
                              child: Column(
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
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredRestaurants.length,
                              itemBuilder: (context, index) {
                                final restaurant = _filteredRestaurants[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              RestaurantDetailsScreen(
                                            restaurantName: restaurant.name,
                                            restaurantImage: restaurant.image,
                                            rating:
                                                0.0, // Placeholder, as rating is not available
                                            location: restaurant.address,
                                            openUntil: restaurant.openingHours,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            child: Image.network(
                                              ApiConfig.imageBaseUrl +
                                                  restaurant.image,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons.restaurant,
                                                    color: Colors.grey),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  restaurant.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  restaurant.cuisineType,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  restaurant.address,
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
                                          if (!restaurant.status)
                                            Container(
                                              width: 60,
                                              height: 24,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(4),
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
                              },
                            ),
                    ),
                  ],
                ),
    );
  }

  IconData _getSortIcon(String option) {
    switch (option) {
      case 'Rating':
        return Icons.star_outline;
      case 'Distance':
        return Icons.location_on_outlined;
      case 'Delivery Time':
        return Icons.access_time;
      case 'Price':
        return Icons.attach_money;
      default:
        return Icons.sort;
    }
  }

  IconData _getFilterIcon(String option) {
    switch (option) {
      case 'Open Now':
        return Icons.access_time;
      case 'Free Delivery':
        return Icons.delivery_dining;
      case 'Offers':
        return Icons.local_offer_outlined;
      default:
        return Icons.filter_list;
    }
  }
}
