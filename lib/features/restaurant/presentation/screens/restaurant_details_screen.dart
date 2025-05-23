import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../reservation/presentation/screens/reservation_screen.dart';
import '../../../restaurant/data/models/restaurant_model.dart';
import 'package:dio/dio.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:e_resta_app/core/widgets/error_state_widget.dart';
import 'package:e_resta_app/core/utils/error_utils.dart';
import '../../../home/presentation/screens/home_screen.dart';
import 'package:e_resta_app/core/services/dio_service.dart';
import 'dart:convert';

class RestaurantDetailsScreen extends StatefulWidget {
  final RestaurantModel restaurant;
  final List<CuisineCategory> cuisines;
  const RestaurantDetailsScreen(
      {super.key, required this.restaurant, required this.cuisines});

  @override
  State<RestaurantDetailsScreen> createState() =>
      _RestaurantDetailsScreenState();
}

class _RestaurantDetailsScreenState extends State<RestaurantDetailsScreen> {
  Set<int> _favoriteMenuItemIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFavoriteMenuItemIds();
  }

  Future<void> _fetchFavoriteMenuItemIds() async {
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
      final favorites = response.data['data'] as List;
      setState(() {
        _favoriteMenuItemIds = favorites
            .where((fav) => fav['status'] == true)
            .map<int>((fav) => fav['menu_item_id'] as int)
            .toSet();
      });
    } catch (_) {}
  }

  String getCuisineName(int? id) {
    final CuisineCategory cuisine = widget.cuisines.firstWhere(
      (c) => c.id == id,
      orElse: () => CuisineCategory(id: null, name: 'Unknown'),
    );
    return cuisine.name;
  }

  void _handleReservation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          restaurantName: widget.restaurant.name,
          restaurantId: widget.restaurant.id,
        ),
      ),
    );
  }

  void _showDeliveryMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Order Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DeliveryMethodOption(
              icon: Icons.restaurant,
              title: 'Dine In',
              subtitle: 'Eat at the restaurant',
              onTap: () {
                Navigator.pop(context);
                _showMenu(context, 'Dine In');
              },
            ),
            const SizedBox(height: 8),
            _DeliveryMethodOption(
              icon: Icons.takeout_dining,
              title: 'Takeaway',
              subtitle: 'Pick up your order',
              onTap: () {
                Navigator.pop(context);
                _showMenu(context, 'Takeaway');
              },
            ),
            const SizedBox(height: 8),
            _DeliveryMethodDialog(
              icon: Icons.delivery_dining,
              title: 'Delivery',
              subtitle: 'Get it delivered to you',
              onTap: () {
                Navigator.pop(context);
                _showMenu(context, 'Delivery');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, String orderType) {
    // Show bottom sheet with menu items
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Menu',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF184C55).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            orderType,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Color(0xFF184C55),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (widget.restaurant.menus.isEmpty)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 54,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'No Menu Available',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'This restaurant has not published a menu yet.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),
                    for (final menu in widget.restaurant.menus)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...(() {
                            final items =
                                List<MenuItemModel>.from(menu.menuItems);
                            items.sort((a, b) {
                              final aFav = _favoriteMenuItemIds.contains(a.id);
                              final bFav = _favoriteMenuItemIds.contains(b.id);
                              if (aFav == bFav) return 0;
                              return aFav ? -1 : 1;
                            });
                            return items
                                .map((item) => _MenuItemCard(
                                      item: item,
                                      restaurantId: widget.restaurant.id,
                                      restaurantName: widget.restaurant.name,
                                      restaurantAddress:
                                          widget.restaurant.address,
                                    ))
                                .toList();
                          })(),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('View Cart'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewDialog(BuildContext parentContext) {
    final authProvider =
        Provider.of<AuthProvider>(parentContext, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to review a restaurant.'),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(parentContext).pushReplacementNamed('/login');
      });
      return;
    }
    double rating = 5.0;
    final commentController = TextEditingController();
    showDialog(
      context: parentContext,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate & Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('Rating:'),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: rating > 1.0
                        ? () => setState(
                            () => rating = (rating - 0.5).clamp(1.0, 10.0))
                        : null,
                  ),
                  Expanded(
                    child: Slider(
                      value: rating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18, // 0.5 steps
                      label: rating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() => rating = value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: rating < 10.0
                        ? () => setState(
                            () => rating = (rating + 0.5).clamp(1.0, 10.0))
                        : null,
                  ),
                  Text(rating.toStringAsFixed(1)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _submitReview(
                    parentContext, rating, commentController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
      BuildContext parentContext, double rating, String comment) async {
    try {
      final authProvider =
          Provider.of<AuthProvider>(parentContext, listen: false);
      final token = authProvider.token;
      final dio = DioService.getDio();
      final data = {
        'restaurant_id': widget.restaurant.id,
        'rating': rating,
        'comment': comment,
      };
      print('Submitting review:');
      print(data);
      final response = await dio.post(
        '${ApiConfig.baseUrl}/reviews',
        data: data,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      print('Review submission response:');
      print(response.data);
      if (!mounted) return;
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(parentContext).showSnackBar(
          const SnackBar(
              content: Text('Thank you for your review!'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Failed to submit review: \\${response.statusMessage}');
      }
    } catch (e) {
      print('Review submission error:');
      print(e);
      if (!mounted) return;
      final parsed = parseDioError(e);
      showDialog(
        context: parentContext,
        builder: (context) => ErrorStateWidget(
          message: parsed.message,
          code: parsed.code,
          onRetry: () {
            Navigator.pop(context);
            _submitReview(parentContext, rating, comment);
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // For demo: static time and distance (replace with real logic if needed)
    const String time = '26 min';
    const String distance = '0.6 mi';
    final restaurant = widget.restaurant;
    return Scaffold(
      body: ListView(
        children: [
          // Large image
          Stack(
            children: [
              Hero(
                tag: 'restaurant_image_${restaurant.id}',
                child: restaurant.image != null && restaurant.image!.isNotEmpty
                    ? Image.network(
                        restaurant.image!,
                        height: 280,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      )
                    : Container(
                        height: 280,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant,
                            size: 80, color: Colors.grey),
                      ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 12,
                right: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.4),
                  child: IconButton(
                    icon: const Icon(Icons.star, color: Colors.white),
                    onPressed: () => _showReviewDialog(context),
                  ),
                ),
              ),
            ],
          ),
          // Info Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Icon(Icons.local_dining,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 6),
                          Text(getCuisineName(restaurant.cuisineId),
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(width: 16),
                          Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text(restaurant.averageRating.toStringAsFixed(1)),
                          const SizedBox(width: 16),
                          Icon(Icons.timer, color: Colors.grey, size: 20),
                          const SizedBox(width: 4),
                          Text(time),
                          const SizedBox(width: 16),
                          Icon(Icons.location_on, color: Colors.grey, size: 20),
                          const SizedBox(width: 4),
                          Text(distance),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      restaurant.description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Reservation and Order Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF227C9D),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _handleReservation(context),
                    child: const Text(
                      'Reserve Table',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F3F),
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _showDeliveryMethodDialog(context),
                    child: const Text(
                      'Order Now',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Menu Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                    ),
                    if (restaurant.menus.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color:
                              Theme.of(context).primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 18,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.menus.length} ${restaurant.menus.length == 1 ? 'Menu' : 'Menus'}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (restaurant.menus.isEmpty)
                  Card(
                    elevation: 0,
                    color: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.menu_book,
                              size: 54, color: Colors.grey[400]),
                          const SizedBox(height: 14),
                          Text(
                            'No Menu Available',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'This restaurant has not published a menu yet.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(),
                for (final menu in restaurant.menus)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.restaurant_menu,
                                color: Theme.of(context).primaryColor,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      menu.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                    ),
                                    if (menu.description.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        menu.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.8),
                                            ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${menu.menuItems.length} items',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        for (final item in menu.menuItems)
                          _MenuItemCard(
                            item: item,
                            restaurantId: restaurant.id,
                            restaurantName: restaurant.name,
                            restaurantAddress: restaurant.address,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 300),
                                delay: Duration(
                                  milliseconds:
                                      menu.menuItems.indexOf(item) * 100,
                                ),
                              ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatefulWidget {
  final MenuItemModel item;
  final int restaurantId;
  final String restaurantName;
  final String restaurantAddress;
  const _MenuItemCard({
    required this.item,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantAddress,
  });

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  bool _isFavorite = false;
  bool _loading = false;
  final Set<int> _favoriteMenuItemIds = {};

  @override
  void initState() {
    super.initState();
    _fetchFavoriteStatus();
  }

  Future<void> _fetchFavoriteStatus() async {
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
      final favorites = response.data['data'] as List;
      // Check if this menu item is in favorites and status is true
      setState(() {
        _isFavorite = favorites.any((fav) =>
            fav['menu_item_id'] == widget.item.id && fav['status'] == true);
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    setState(() => _loading = true);
    final dio = DioService.getDio();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final endpoint =
        _isFavorite ? ApiEndpoints.menuUnfavorite : ApiEndpoints.menuFavorite;
    try {
      final response = await dio.post(
        endpoint,
        data: {'menu_item_id': widget.item.id},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _isFavorite = !_isFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _isFavorite ? 'Added to favorites' : 'Removed from favorites'),
          ),
        );
      } else {
        throw Exception('Failed: ${response.statusMessage}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update favorite: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _addToCartWithDietarySelection(
      BuildContext context, MenuItemModel item) async {
    if (item.dietaryInfo.isEmpty) {
      _addToCart(context, item);
      return;
    }
    Map<String, dynamic>? info;
    try {
      info = json.decode(item.dietaryInfo);
    } catch (_) {}
    if (info == null || info.isEmpty) {
      _addToCart(context, item);
      return;
    }
    final List<String> tags = [];
    if (info['contains'] is List) {
      tags.addAll((info['contains'] as List).map((e) => e.toString()));
    }
    if (info['suitable_for'] is List) {
      tags.addAll((info['suitable_for'] as List).map((e) => e.toString()));
    }
    if (tags.isEmpty) {
      _addToCart(context, item);
      return;
    }
    List<String> selected = [];
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Dietary Info'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Please select at least one dietary tag:'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      final isSelected = selected.contains(tag);
                      // Determine type for icon/color
                      final isContains = info != null &&
                          info['contains'] is List &&
                          (info['contains'] as List).contains(tag);
                      final isSuitable = info != null &&
                          info['suitable_for'] is List &&
                          (info['suitable_for'] as List).contains(tag);
                      Icon? chipIcon;
                      Color? selectedColor;
                      if (isContains) {
                        chipIcon = const Icon(Icons.warning,
                            color: Colors.red, size: 16);
                        selectedColor = Colors.red[100];
                      } else if (isSuitable) {
                        chipIcon = const Icon(Icons.eco,
                            color: Colors.green, size: 16);
                        selectedColor = Colors.green[100];
                      }
                      // Optional: tag descriptions
                      final tagDescriptions = {
                        'gluten': 'Contains gluten',
                        'dairy': 'Contains dairy',
                        'eggs': 'Contains eggs',
                        'vegan': 'Suitable for vegans',
                        'vegetarian': 'Suitable for vegetarians',
                      };
                      final tagDesc = tagDescriptions[tag];
                      return Tooltip(
                        message: tagDesc ?? '',
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          child: FilterChip(
                            label: Text(tag),
                            avatar: chipIcon,
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() {
                                if (val) {
                                  selected.add(tag);
                                } else {
                                  selected.remove(tag);
                                }
                              });
                            },
                            selectedColor: selectedColor,
                            checkmarkColor: isContains
                                ? Colors.red[800]
                                : Colors.green[800],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (selected.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('You must select at least one.',
                          style:
                              TextStyle(color: Colors.red[700], fontSize: 12)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context, selected);
                        },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result is List<String> && result.isNotEmpty) {
        _addToCart(context, widget.item, selectedDietary: result);
      }
    });
  }

  void _addToCart(BuildContext context, MenuItemModel item,
      {List<String>? selectedDietary}) async {
    try {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      await cartProvider.addItem(CartItem(
        id: item.id.toString(),
        name: item.name,
        description: item.description,
        price: double.tryParse(item.price) ?? 0.0,
        imageUrl: item.image,
        restaurantId: widget.restaurantId.toString(),
        restaurantName: widget.restaurantName,
        restaurantAddress: widget.restaurantAddress,
        dietaryInfo: selectedDietary,
      ));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${item.name} to cart'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      if (e is CartException && e.type == CartErrorType.differentRestaurant) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Clear Cart',
              textColor: Colors.white,
              onPressed: () {
                if (!context.mounted) return;
                Provider.of<CartProvider>(context, listen: false).clearCart();
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add item to cart'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _addToCartWithDietarySelection(context, item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.image.isNotEmpty
                    ? Image.network(
                        item.image.startsWith('http')
                            ? item.image
                            : 'http://localhost:8000/${item.image}',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[200],
                          child: Icon(Icons.fastfood,
                              color: Colors.grey[400], size: 32),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.fastfood,
                            color: Colors.grey[400], size: 32),
                      ),
              ),
              const SizedBox(width: 16),
              // Item Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                          ),
                        ),
                        IconButton(
                          icon: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.red,
                                  size: 22,
                                ),
                          onPressed: _loading ? null : _toggleFavorite,
                          tooltip: _isFavorite
                              ? 'Remove from favorites'
                              : 'Add to favorites',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Price and Add to Cart Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Price with currency
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '₣${item.price}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        // Add to Cart Button
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_shopping_cart,
                                color: Colors.white, size: 20),
                            onPressed: () =>
                                _addToCartWithDietarySelection(context, item),
                            tooltip: 'Add to cart',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                    if (item.dietaryInfo.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _DietaryInfoWidget(dietaryInfo: item.dietaryInfo),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 300));
  }
}

class _DietaryInfoWidget extends StatelessWidget {
  final String dietaryInfo;
  const _DietaryInfoWidget({required this.dietaryInfo});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? info;
    try {
      info = json.decode(dietaryInfo);
    } catch (_) {}

    if (info == null || info.isEmpty) return const SizedBox.shrink();

    List<Widget> chips = [];
    if (info['contains'] is List) {
      chips.addAll((info['contains'] as List).map((e) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text(e.toString()),
              backgroundColor: Colors.red[50],
              labelStyle: TextStyle(color: Colors.red[800], fontSize: 12),
              avatar: Icon(Icons.warning, color: Colors.red[400], size: 16),
            ),
          )));
    }
    if (info['suitable_for'] is List) {
      chips.addAll((info['suitable_for'] as List).map((e) => Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Chip(
              label: Text(e.toString()),
              backgroundColor: Colors.green[50],
              labelStyle: TextStyle(color: Colors.green[800], fontSize: 12),
              avatar: Icon(Icons.eco, color: Colors.green[400], size: 16),
            ),
          )));
    }

    return Wrap(
      children: chips,
    );
  }
}

class _DeliveryMethodOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DeliveryMethodOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryMethodDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DeliveryMethodDialog({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
