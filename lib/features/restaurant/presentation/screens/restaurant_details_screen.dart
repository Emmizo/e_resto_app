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

class RestaurantDetailsScreen extends StatelessWidget {
  final RestaurantModel restaurant;
  final List<CuisineCategory> cuisines;
  const RestaurantDetailsScreen(
      {super.key, required this.restaurant, required this.cuisines});

  String getCuisineName(int? id) {
    final CuisineCategory cuisine = cuisines.firstWhere(
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
          restaurantName: restaurant.name,
          restaurantId: restaurant.id,
        ),
      ),
    );
  }

  void _handleOrder(BuildContext context) {
    _showDeliveryMethodDialog(context);
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
                            color: const Color(0xFF184C55).withOpacity(0.1),
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
                    if (restaurant.menus.isEmpty)
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
                    for (final menu in restaurant.menus)
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
                          for (final item in menu.menuItems)
                            _MenuItemCard(
                              item: item,
                              restaurantId: restaurant.id,
                              restaurantName: restaurant.name,
                            ),
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

  void _showReviewDialog(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to review a restaurant.'),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }
    double rating = 5.0;
    final commentController = TextEditingController();
    showDialog(
      context: context,
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
                await _submitReview(context, rating, commentController.text);
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
      BuildContext context, double rating, String comment) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final dio = DioService.getDio(context);
      final data = {
        'restaurant_id': restaurant.id,
        'rating': rating,
        'comment': comment,
      };
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
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Thank you for your review!'),
              backgroundColor: Colors.green),
        );
      } else {
        throw Exception('Failed to submit review: \\${response.statusMessage}');
      }
    } catch (e) {
      final parsed = parseDioError(e);
      showDialog(
        context: context,
        builder: (context) => ErrorStateWidget(
          message: parsed.message,
          code: parsed.code,
          onRetry: () {
            Navigator.pop(context);
            _submitReview(context, rating, comment);
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
                  backgroundColor: Colors.black.withOpacity(0.4),
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
                  backgroundColor: Colors.black.withOpacity(0.4),
                  child: IconButton(
                    icon:
                        const Icon(Icons.favorite_border, color: Colors.white),
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
                    child: const Text('Reserve Table',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
                    child: const Text('Order Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
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
                Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                  ),
                for (final menu in restaurant.menus)
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
                      for (final item in menu.menuItems)
                        _MenuItemCard(
                          item: item,
                          restaurantId: restaurant.id,
                          restaurantName: restaurant.name,
                        ),
                      const SizedBox(height: 16),
                    ],
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
  const _MenuItemCard(
      {required this.item,
      required this.restaurantId,
      required this.restaurantName});

  @override
  State<_MenuItemCard> createState() => _MenuItemCardState();
}

class _MenuItemCardState extends State<_MenuItemCard> {
  bool _isFavorite = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchFavoriteStatus();
  }

  Future<void> _fetchFavoriteStatus() async {
    try {
      final dio = DioService.getDio(context);
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
        _isFavorite = favorites.any((fav) => fav['id'] == widget.item.id);
      });
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    setState(() => _loading = true);
    final dio = DioService.getDio(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final endpoint =
        _isFavorite ? ApiEndpoints.menuUnfavorite : ApiEndpoints.menuFavorite;
    try {
      await dio.post(
        endpoint,
        data: {'menu_item_id': widget.item.id},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      setState(() => _isFavorite = !_isFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              _isFavorite ? 'Added to favorites' : 'Removed from favorites'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.image.isNotEmpty
            ? Image.network(
                item.image.startsWith('http')
                    ? item.image
                    : 'http://localhost:8000/${item.image}',
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              )
            : const Icon(Icons.fastfood),
        title: Text(item.name),
        subtitle: Text(item.description),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('₣${item.price}'),
            IconButton(
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
              onPressed: _loading ? null : _toggleFavorite,
              tooltip: _isFavorite ? 'Unfavorite' : 'Favorite',
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                final cartProvider = context.read<CartProvider>();
                cartProvider.addItem(CartItem(
                  id: item.id.toString(),
                  name: item.name,
                  description: item.description,
                  price: double.tryParse(item.price) ?? 0.0,
                  imageUrl: item.image,
                  restaurantId: widget.restaurantId.toString(),
                  restaurantName: widget.restaurantName,
                ));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${item.name} to cart')),
                );
              },
            ),
          ],
        ),
      ),
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
