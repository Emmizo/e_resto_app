import 'package:e_resta_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
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
            content: Text('Failed: ${e.toString()}'),
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
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        itemCount: _restaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, index) {
          final item = _restaurants[index];
          return _RestaurantCard(
            item: item,
            onRemove: () => _unfavoriteRestaurant(
                item['id'] is int
                    ? item['id']
                    : int.tryParse(item['id'].toString()) ?? 0,
                index),
          );
        },
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/empty_favorites.png',
              height: 120,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.favorite_border,
                size: 80,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Add restaurants to your favorites to see them here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF184C55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailsScreen(
              restaurant: RestaurantModel.fromJson(restaurant),
              cuisines: const [], // Pass real cuisines if available
            ),
          ),
        );
      },
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restaurant Image
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: restaurant['image'] != null &&
                        restaurant['image'].toString().isNotEmpty
                    ? Image.network(
                        restaurant['image'],
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.restaurant, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 18),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['name'] ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.favorite,
                              color: Colors.red, size: 26),
                          tooltip: 'Remove from favorites',
                          onPressed: onRemove,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      restaurant['address'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          averageRating.toStringAsFixed(1),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '($reviewsCount reviews)',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
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
      ),
    );
  }
}
