import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import 'restaurant_details_screen.dart';
import '../../data/models/restaurant_model.dart';

class FavoriteRestaurantsScreen extends StatelessWidget {
  const FavoriteRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for favorite restaurants
    final restaurants = [
      _Restaurant(
        id: 'rest-1',
        name: 'Italian Bistro',
        cuisine: 'Italian',
        rating: 4.8,
        reviews: 245,
        distance: 1.2,
        imageUrl: 'assets/images/tea.jpg',
        isOpen: true,
        deliveryTime: '25-35 min',
        deliveryFee: 2.99,
        minOrder: 15.00,
      ),
      _Restaurant(
        id: 'rest-2',
        name: 'Sushi Master',
        cuisine: 'Japanese',
        rating: 4.6,
        reviews: 189,
        distance: 0.8,
        imageUrl: 'assets/images/tea-m.jpg',
        isOpen: true,
        deliveryTime: '30-40 min',
        deliveryFee: 3.99,
        minOrder: 20.00,
      ),
      _Restaurant(
        id: 'rest-3',
        name: 'Burger Joint',
        cuisine: 'American',
        rating: 4.5,
        reviews: 312,
        distance: 1.5,
        imageUrl: 'assets/images/tea.jpg',
        isOpen: true,
        deliveryTime: '20-30 min',
        deliveryFee: 1.99,
        minOrder: 10.00,
      ),
      _Restaurant(
        id: 'rest-4',
        name: 'Pasta Paradise',
        cuisine: 'Italian',
        rating: 4.7,
        reviews: 156,
        distance: 2.1,
        imageUrl: 'assets/images/tea-m.jpg',
        isOpen: true,
        deliveryTime: '35-45 min',
        deliveryFee: 3.49,
        minOrder: 18.00,
      ),
      _Restaurant(
        id: 'rest-5',
        name: 'Taco Tuesday',
        cuisine: 'Mexican',
        rating: 4.4,
        reviews: 278,
        distance: 1.8,
        imageUrl: 'assets/images/tea.jpg',
        isOpen: true,
        deliveryTime: '25-35 min',
        deliveryFee: 2.49,
        minOrder: 12.00,
      ),
      _Restaurant(
        id: 'rest-6',
        name: 'Pizza Palace',
        cuisine: 'Italian',
        rating: 4.3,
        reviews: 423,
        distance: 2.5,
        imageUrl: 'assets/images/tea-m.jpg',
        isOpen: true,
        deliveryTime: '30-40 min',
        deliveryFee: 2.99,
        minOrder: 15.00,
      ),
      _Restaurant(
        id: 'rest-7',
        name: 'Green Garden',
        cuisine: 'Vegetarian',
        rating: 4.9,
        reviews: 98,
        distance: 3.2,
        imageUrl: 'assets/images/tea.jpg',
        isOpen: true,
        deliveryTime: '35-45 min',
        deliveryFee: 3.99,
        minOrder: 20.00,
      ),
      _Restaurant(
        id: 'rest-8',
        name: 'Dessert Delight',
        cuisine: 'Desserts',
        rating: 4.7,
        reviews: 167,
        distance: 1.7,
        imageUrl: 'assets/images/tea-m.jpg',
        isOpen: true,
        deliveryTime: '25-35 min',
        deliveryFee: 2.99,
        minOrder: 15.00,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Restaurants'),
        actions: [
          IconButton(
            icon: Icon(
              context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              final themeProvider = context.read<ThemeProvider>();
              themeProvider.toggleTheme();
            },
          ),
        ],
      ),
      body: restaurants.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: restaurants.length,
              itemBuilder: (context, index) {
                return _RestaurantCard(
                  restaurant: restaurants[index],
                  onRemove: () {
                    _showRemoveConfirmation(context, restaurants[index]);
                  },
                ).animate(delay: (100 * index).ms).fadeIn().slideX();
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Favorites Yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add restaurants to your favorites',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.restaurant),
            label: const Text('Discover Restaurants'),
          ),
        ],
      ),
    ).animate().fadeIn();
  }

  void _showRemoveConfirmation(BuildContext context, _Restaurant restaurant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Favorites'),
        content: Text(
            'Are you sure you want to remove ${restaurant.name} from your favorites?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${restaurant.name} removed from favorites'),
                  action: SnackBarAction(
                    label: 'Undo',
                    onPressed: () {
                      // TODO: Implement undo functionality
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final _Restaurant restaurant;
  final VoidCallback onRemove;

  const _RestaurantCard({
    required this.restaurant,
    required this.onRemove,
  });

  RestaurantModel _toRestaurantModel(_Restaurant r) {
    return RestaurantModel(
      id: int.tryParse(r.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      name: r.name,
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
      image: r.imageUrl,
      ownerId: 0,
      isApproved: true,
      status: r.isOpen,
      menus: [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailsScreen(
                restaurant: _toRestaurantModel(restaurant),
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
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  restaurant.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.cuisine} • ${restaurant.distance.toStringAsFixed(1)} km away',
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
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.rating.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${restaurant.reviews} reviews)',
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
                          restaurant.deliveryTime,
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
                          '\$${restaurant.deliveryFee.toStringAsFixed(2)}',
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
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Restaurant {
  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final int reviews;
  final double distance;
  final String imageUrl;
  final bool isOpen;
  final String deliveryTime;
  final double deliveryFee;
  final double minOrder;

  _Restaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.imageUrl,
    required this.isOpen,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
  });
}
