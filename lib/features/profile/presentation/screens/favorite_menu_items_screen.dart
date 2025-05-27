import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/dio_service.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../home/presentation/screens/main_screen.dart';

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
          content: const Text('Favorite menu items loaded successfully!'),
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
                    builder: (context) => const MainScreen(),
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
          return Slidable(
            key: ValueKey(menuItem['id']),
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
                            'Are you sure you want to remove this menu item from your favorites?'),
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
                    }
                  },
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(16),
                ),
              ],
            ),
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: menuItem['image'] != null &&
                        menuItem['image'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          fixImageUrl(menuItem['image'].toString()),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                title: Text(menuItem['name'] ?? '',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
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
                            if (restaurant != null &&
                                restaurant['name'] != null)
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
                        child: Text(menuItem['description'],
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('₣${menuItem['price']}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }

  String fixImageUrl(String url) {
    if (Platform.isAndroid) {
      return url.replaceFirst('localhost', '10.0.2.2');
    }
    return url;
  }
}
