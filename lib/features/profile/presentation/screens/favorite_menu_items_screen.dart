import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';

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
    try {
      final dio = Dio();
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
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 42,
        title: const Text(
          'Favorite Menu Items',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: [0m$_error'))
              : _favoriteMenuItems.isEmpty
                  ? const Center(child: Text('No favorite menu items found.'))
                  : ListView.builder(
                      itemCount: _favoriteMenuItems.length,
                      itemBuilder: (context, index) {
                        final item = _favoriteMenuItems[index];
                        final menuItem = item['menu_item'];
                        final menu = menuItem['menu'];
                        final restaurant =
                            menu != null ? menu['restaurant'] : null;
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: menuItem['image'] != null &&
                                    menuItem['image'].toString().isNotEmpty
                                ? Image.network(
                                    menuItem['image']
                                            .toString()
                                            .startsWith('http')
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
                                    (restaurant != null &&
                                        restaurant['name'] != null))
                                  Row(
                                    children: [
                                      if (restaurant != null &&
                                          restaurant['name'] != null)
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
                                      if (menu != null &&
                                          menu['name'] != null) ...[
                                        if (restaurant != null &&
                                            restaurant['name'] != null)
                                          const Text(' • ',
                                              style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 13)),
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
                                if ((menuItem['description'] ?? '')
                                    .toString()
                                    .isNotEmpty)
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
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  tooltip: 'Remove from favorites',
                                  onPressed: () async {
                                    final dio = Dio();
                                    final authProvider =
                                        Provider.of<AuthProvider>(context,
                                            listen: false);
                                    final token = authProvider.token;
                                    try {
                                      await dio.post(
                                        ApiEndpoints.menuUnfavorite,
                                        data: {'menu_item_id': menuItem['id']},
                                        options: Options(headers: {
                                          if (token != null)
                                            'Authorization': 'Bearer $token',
                                        }),
                                      );
                                      setState(() {
                                        _favoriteMenuItems.removeAt(index);
                                      });
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Removed from favorites')),
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Failed: [0m${e.toString()}'),
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
                    ),
    );
  }
}
