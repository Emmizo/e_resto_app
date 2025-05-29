import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/dio_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/widgets/error_state_widget.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';
import '../../data/models/restaurant_model.dart';

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
      _errorCode = null;
    });
    try {
      final dio = DioService.getDio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await dio.get(
        ApiEndpoints.restaurantFavorites,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      if (!mounted) return;
      setState(() {
        _restaurants = response.data['data'] as List;
        _isLoading = false;
      });
    } catch (e) {
      final parsed = parseDioError(e);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = parsed.message;
        _errorCode = parsed.code;
      });
    }
  }

  Future<void> _unfavoriteRestaurant(int restaurantId, int index) async {
    try {
      final dio = DioService.getDio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      await dio.post(
        ApiEndpoints.restaurantUnfavorite,
        data: {'restaurant_id': restaurantId},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      if (!mounted) return;
      setState(() {
        _restaurants.removeAt(index);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      String message = 'Failed to remove favorite';
      if (e is DioException && e.response != null) {
        // Try to extract a backend error message
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data is String) {
          message = data;
        } else {
          message = e.toString();
        }
      } else {
        message = e.toString();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return ErrorStateWidget(
        message:
            "We couldn't load your favorite restaurants. Please try again.",
        code: _errorCode,
        onRetry: _fetchFavorites,
      );
    } else if (_restaurants.isEmpty) {
      return _buildEmptyState(context);
    } else {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: _restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final item = _restaurants[index];
          final restaurant = item['restaurant'] ?? item;
          final restaurantId = restaurant['id'];
          return Slidable(
            key: ValueKey(restaurantId),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (context) async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Remove from favorites?'),
                        content: const Text(
                            'Are you sure you want to remove this restaurant from your favorites?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete',
                                style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _unfavoriteRestaurant(restaurantId, index);
                    }
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(20),
                ),
              ],
            ),
            child: GestureDetector(
              onTap: () {
                final restaurantObj = item['restaurant'] ?? item;

                final restaurantModel = RestaurantModel.fromJson(restaurantObj);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailsScreen(
                      restaurant: restaurantModel,
                      cuisines: const [], // Pass cuisines if available
                    ),
                  ),
                );
              },
              child: _RestaurantCard(
                item: item,
                onRemove: () => _unfavoriteRestaurant(restaurantId, index),
              ).animate(delay: (100 * index).ms).fadeIn(),
            ),
          );
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(),
                ),
              );
            },
            icon: const Icon(Icons.restaurant),
            label: const Text('Discover Restaurants'),
          ),
        ],
      ),
    );
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
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: restaurant['image'] != null &&
                      restaurant['image'].toString().isNotEmpty
                  ? Image.network(
                      fixImageUrl(restaurant['image']),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant['name'] ?? '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: 0.1,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          restaurant['address'] ?? '',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($reviewsCount reviews)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (restaurant['cuisine'] != null)
                    Row(
                      children: [
                        const Icon(Icons.local_dining,
                            size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          restaurant['cuisine'],
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                        ),
                      ],
                    ),
                  if (restaurant['distance'] != null)
                    Row(
                      children: [
                        const Icon(Icons.directions_walk,
                            size: 16, color: Colors.blueGrey),
                        const SizedBox(width: 4),
                        Text(
                          '${restaurant['distance'].toStringAsFixed(2)} km',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[700],
                                    fontSize: 13,
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
    );
  }
}

String fixImageUrl(String url) {
  if (Platform.isAndroid) {
    return url.replaceFirst('localhost', '10.0.2.2');
  }
  return url;
}
