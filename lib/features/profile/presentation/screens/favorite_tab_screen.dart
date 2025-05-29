import 'package:flutter/material.dart';

import '../../../restaurant/presentation/screens/favorite_restaurants_screen.dart';
import 'favorite_menu_items_screen.dart';

class FavoriteTabScreen extends StatefulWidget {
  const FavoriteTabScreen({super.key});

  @override
  State<FavoriteTabScreen> createState() => _FavoriteTabScreenState();
}

class _FavoriteTabScreenState extends State<FavoriteTabScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 42,
        title: const Text('Favorites',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.fastfood), text: 'Menu'),
            Tab(icon: Icon(Icons.restaurant), text: 'Restaurant'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FavoriteMenuItemsScreen(),
          FavoriteRestaurantsScreen(),
        ],
      ),
    );
  }
}
