import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:e_resta_app/core/services/dio_service.dart';
import 'package:e_resta_app/features/home/presentation/screens/main_screen.dart';

class FavoriteMenuItemsScreen extends StatefulWidget {
  const FavoriteMenuItemsScreen({super.key});

  @override
  State<FavoriteMenuItemsScreen> createState() =>
      _FavoriteMenuItemsScreenState();
}

class _FavoriteMenuItemsScreenState extends State<FavoriteMenuItemsScreen> {
  List<dynamic> _favoriteMenuItems = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    if (!mounted) return;
    try {
      final dio = DioService.getDio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await dio.get(
        ApiEndpoints.menuFavorites,
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      setState(() {
        _favoriteMenuItems = response.data['data'] as List;
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorite menu items loaded successfully!'),
          backgroundColor: Colors.green.withValues(alpha: 0.7),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load favorite menu items: $_error'),
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load your favorite menu items. Please try again later.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchFavorites,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (_favoriteMenuItems.isEmpty) {
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
              'Add menu items to your favorites',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(initialIndex: 0),
                  ),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.restaurant),
              label: const Text('Discover Restaurants'),
            ),
          ],
        ),
      ).animate().fadeIn();
    } else {
      return ListView.builder(
        itemCount: _favoriteMenuItems.length,
        itemBuilder: (context, index) {
          final item = _favoriteMenuItems[index];
          final menuItem = item['menu_item'];
          final menu = menuItem['menu'];
          final restaurant = menu != null ? menu['restaurant'] : null;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: menuItem['image'] != null &&
                      menuItem['image'].toString().isNotEmpty
                  ? Image.network(
                      menuItem['image'].toString().startsWith('http')
                          ? menuItem['image']
                          : 'http://localhost:8000/${menuItem['image']}',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : const Icon(Icons.fastfood),
              title: Text(menuItem['name'] ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((menu != null && menu['name'] != null) ||
                      (restaurant != null && restaurant['name'] != null))
                    Row(
                      children: [
                        if (restaurant != null && restaurant['name'] != null)
                          Flexible(
                            child: Text(
                              restaurant['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (menu != null && menu['name'] != null) ...[
                          if (restaurant != null && restaurant['name'] != null)
                            const Text(' • ',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 13)),
                          Flexible(
                            child: Text(
                              menu['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.deepOrange,
                                  fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                  if ((menuItem['description'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(menuItem['description']),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('₣${menuItem['price']}'),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remove from favorites',
                    onPressed: () async {
                      final dio = DioService.getDio();
                      final authProvider =
                          Provider.of<AuthProvider>(context, listen: false);
                      final token = authProvider.token;
                      try {
                        await dio.post(
                          ApiEndpoints.menuUnfavorite,
                          data: {'menu_item_id': menuItem['id']},
                          options: Options(headers: {
                            if (token != null) 'Authorization': 'Bearer $token',
                          }),
                        );
                        setState(() {
                          _favoriteMenuItems.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Removed from favorites')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Failed:  $_error'),
                              backgroundColor: Colors.red),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }
}
