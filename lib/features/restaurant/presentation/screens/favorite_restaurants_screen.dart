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
import 'package:e_resta_app/features/map/presentation/screens/map_screen.dart';

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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return ErrorStateWidget(
        message: _errorMessage,
        code: _errorCode,
        onRetry: _fetchFavorites,
      );
    } else if (_restaurants.isEmpty) {
      return _buildEmptyState(context);
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final item = _restaurants[index];
          return _RestaurantCard(
            item: item,
            onRemove: () => _unfavoriteRestaurant(
                item['id'] is int
                    ? item['id']
                    : int.tryParse(item['id'].toString()) ?? 0,
                index),
          ).animate(delay: (100 * index).ms).fadeIn().slideX();
        },
      );
    }
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
  final dynamic item;
  final VoidCallback onRemove;

  const _RestaurantCard({
    required this.item,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final restaurant = item['restaurant'] ?? item;
    final averageRating = item['average_rating'] ?? 0;
    final reviewsCount = item['reviews_count'] ?? 0;
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: restaurant['image'] != null &&
                      restaurant['image'].toString().isNotEmpty
                  ? Image.network(
                      restaurant['image'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurant['address'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '($reviewsCount reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                      ),
                      const Spacer(),
                      Icon(Icons.favorite, color: Colors.red, size: 20),
                      // Optionally, add a remove button here
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
