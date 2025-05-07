import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/providers/theme_provider.dart';
import 'restaurant_details_screen.dart';
import '../../data/models/restaurant_model.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:e_resta_app/core/widgets/error_state_widget.dart';
import 'package:e_resta_app/core/utils/error_utils.dart';

class FavoriteRestaurantsScreen extends StatefulWidget {
  const FavoriteRestaurantsScreen({super.key});

  @override
  State<FavoriteRestaurantsScreen> createState() =>
      _FavoriteRestaurantsScreenState();
}

class _FavoriteRestaurantsScreenState extends State<FavoriteRestaurantsScreen> {
  List<dynamic> _restaurants = [];
  bool _isLoading = true;
  String? _error;
  String? _errorMessage;
  int? _errorCode;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorMessage = null;
      _errorCode = null;
    });
    try {
      final dio = Dio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await dio.get(
        ApiEndpoints.restaurantFavorites,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      setState(() {
        _restaurants = response.data['data'] as List;
        _isLoading = false;
      });
    } catch (e) {
      final parsed = parseDioError(e);
      setState(() {
        _isLoading = false;
        _error = parsed.message;
        _errorMessage = parsed.message;
        _errorCode = parsed.code;
      });
    }
  }

  Future<void> _unfavoriteRestaurant(int restaurantId, int index) async {
    try {
      final dio = Dio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      await dio.post(
        ApiEndpoints.restaurantUnfavorite,
        data: {'restaurant_id': restaurantId},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      setState(() {
        _restaurants.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed: [0m${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorStateWidget(
                  message: _errorMessage,
                  code: _errorCode,
                  onRetry: _fetchFavorites,
                )
              : _restaurants.isEmpty
                  ? _buildEmptyState(context)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _restaurants.length,
                      itemBuilder: (context, index) {
                        final item = _restaurants[index];
                        final restaurant = item['restaurant'] ??
                            item; // fallback if API returns just restaurant
                        return _RestaurantCard(
                          restaurant: restaurant,
                          onRemove: () => _unfavoriteRestaurant(
                              restaurant['id'] is int
                                  ? restaurant['id']
                                  : int.tryParse(restaurant['id'].toString()) ??
                                      0,
                              index),
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
}

class _RestaurantCard extends StatelessWidget {
  final dynamic restaurant;
  final VoidCallback onRemove;

  const _RestaurantCard({
    required this.restaurant,
    required this.onRemove,
  });

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
                restaurant: RestaurantModel(
                  id: restaurant['id'] is int
                      ? restaurant['id']
                      : int.tryParse(restaurant['id'].toString()) ?? 0,
                  name: restaurant['name'] ?? '',
                  description: restaurant['description'] ?? '',
                  address: restaurant['address'] ?? '',
                  longitude: restaurant['longitude']?.toString() ?? '',
                  latitude: restaurant['latitude']?.toString() ?? '',
                  phoneNumber: restaurant['phone_number'] ?? '',
                  email: restaurant['email'] ?? '',
                  website: restaurant['website'],
                  openingHours: restaurant['opening_hours'] ?? '',
                  cuisineId: restaurant['cuisine_id'] is int
                      ? restaurant['cuisine_id']
                      : int.tryParse(
                          restaurant['cuisine_id']?.toString() ?? ''),
                  priceRange: restaurant['price_range'] ?? '',
                  image: restaurant['image'],
                  ownerId: restaurant['owner_id'] is int
                      ? restaurant['owner_id']
                      : int.tryParse(
                              restaurant['owner_id']?.toString() ?? '') ??
                          0,
                  isApproved: restaurant['is_approved'] is bool
                      ? restaurant['is_approved']
                      : restaurant['is_approved'] == 1,
                  status: restaurant['status'] is bool
                      ? restaurant['status']
                      : restaurant['status'] == 1,
                  menus: [],
                  averageRating: (restaurant['average_rating'] is int)
                      ? (restaurant['average_rating'] as int).toDouble()
                      : (restaurant['average_rating'] is double)
                          ? restaurant['average_rating']
                          : double.tryParse(
                                  restaurant['average_rating']?.toString() ??
                                      '0') ??
                              0.0,
                ),
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
                child: restaurant['image'] != null &&
                        restaurant['image'].toString().isNotEmpty
                    ? Image.network(
                        restaurant['image'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        'assets/images/tea.jpg',
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
                      restaurant['name'] ?? '',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant['cuisine'] ?? ''}${restaurant['distance'] != null ? ' • ${restaurant['distance'].toStringAsFixed(1)} km away' : ''}',
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
                          (restaurant['average_rating'] ??
                                  restaurant['rating'] ??
                                  0)
                              .toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${restaurant['reviews'] ?? 0} reviews)',
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
                          restaurant['delivery_time'] ?? '',
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
                          restaurant['delivery_fee'] != null
                              ? '\$${restaurant['delivery_fee']}'
                              : '',
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
