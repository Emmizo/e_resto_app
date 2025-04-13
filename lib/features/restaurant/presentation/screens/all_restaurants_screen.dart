import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'restaurant_details_screen.dart';

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

  late List<Restaurant> _restaurants;
  late List<Restaurant> _filteredRestaurants;

  @override
  void initState() {
    super.initState();
    _initializeRestaurants();
    _searchController.addListener(_onSearchChanged);
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

  void _initializeRestaurants() {
    // Create mock restaurant data
    _restaurants = List.generate(
      20,
      (index) => Restaurant(
        name: 'Restaurant ${index + 1}',
        cuisine: index % 2 == 0 ? 'Italian' : 'Japanese',
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
    _applyFiltersAndSort();
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
                  restaurant.cuisine
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase());
            }).toList();

      // Apply other filters
      switch (_selectedFilter) {
        case 'Open Now':
          _filteredRestaurants =
              _filteredRestaurants.where((r) => r.isOpen).toList();
          break;
        case 'Free Delivery':
          _filteredRestaurants =
              _filteredRestaurants.where((r) => r.deliveryFee == 0).toList();
          break;
        case 'Offers':
          _filteredRestaurants =
              _filteredRestaurants.where((r) => r.hasOffers).toList();
          break;
      }

      // Apply sorting
      switch (_selectedSort) {
        case 'Rating':
          _filteredRestaurants.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Distance':
          _filteredRestaurants.sort((a, b) => a.distance.compareTo(b.distance));
          break;
        case 'Delivery Time':
          _filteredRestaurants.sort((a, b) =>
              int.parse(a.deliveryTime).compareTo(int.parse(b.deliveryTime)));
          break;
        case 'Price':
          _filteredRestaurants
              .sort((a, b) => a.deliveryFee.compareTo(b.deliveryFee));
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
      body: Column(
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
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option,
                                style: TextStyle(
                                  color: _selectedSort == option
                                      ? Theme.of(context).colorScheme.primary
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
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option,
                                style: TextStyle(
                                  color: _selectedFilter == option
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                  fontWeight: _selectedFilter == option
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
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      return _RestaurantCard(
                        name: restaurant.name,
                        cuisine: restaurant.cuisine,
                        distance: restaurant.distance,
                        rating: restaurant.rating,
                        reviews: restaurant.reviews,
                        imageUrl: restaurant.imageUrl,
                        isOpen: restaurant.isOpen,
                        deliveryTime: '${restaurant.deliveryTime} min',
                        deliveryFee: restaurant.deliveryFee,
                      ).animate(delay: (50 * index).ms).fadeIn().slideX();
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

class _RestaurantCard extends StatelessWidget {
  final String name;
  final String cuisine;
  final double distance;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isOpen;
  final String deliveryTime;
  final double deliveryFee;

  const _RestaurantCard({
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
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (!isOpen)
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(8),
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
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$cuisine • ${distance.toStringAsFixed(1)} km away',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          rating.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($reviews reviews)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deliveryTime,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.delivery_dining,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          deliveryFee == 0
                              ? 'Free Delivery'
                              : '\$${deliveryFee.toStringAsFixed(2)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
