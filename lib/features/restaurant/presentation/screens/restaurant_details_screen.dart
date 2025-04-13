import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../reservation/presentation/screens/reservation_screen.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final String? restaurantName;
  final String? restaurantImage;
  final double? rating;
  final String? location;
  final String? openUntil;

  const RestaurantDetailsScreen({
    super.key,
    this.restaurantName = 'Restaurant Name',
    this.restaurantImage,
    this.rating = 4.5,
    this.location = '123 Restaurant Street, City',
    this.openUntil = '10:00 PM',
  });

  void _handleReservation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          restaurantName: restaurantName,
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
            _DeliveryMethodOption(
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
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            orderType,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _MenuCategory(
                      title: 'Popular Items',
                      items: List.generate(
                        3,
                        (index) => _MenuItem(
                          id: const Uuid().v4(),
                          name: 'Popular Item ${index + 1}',
                          description:
                              'Delicious description for item ${index + 1}',
                          price: (index + 1) * 10.99,
                          imageUrl: 'assets/images/tea-m.jpg',
                          restaurantId: 'restaurant-1',
                          restaurantName: restaurantName!,
                          onAddToCart: () {
                            _addToCart(context, index);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _MenuCategory(
                      title: 'Starters',
                      items: List.generate(
                        3,
                        (index) => _MenuItem(
                          id: const Uuid().v4(),
                          name: 'Starter ${index + 1}',
                          description: 'Tasty starter description ${index + 1}',
                          price: (index + 1) * 5.99,
                          imageUrl: 'assets/images/tea.jpg',
                          restaurantId: 'restaurant-1',
                          restaurantName: restaurantName!,
                          onAddToCart: () {
                            _addToCart(context, index + 3);
                          },
                        ),
                      ),
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

  void _addToCart(BuildContext context, int index) {
    try {
      final cartProvider = context.read<CartProvider>();
      final item = CartItem(
        id: const Uuid().v4(),
        name: index < 3 ? 'Popular Item ${index + 1}' : 'Starter ${index - 2}',
        description: index < 3
            ? 'Delicious description for item ${index + 1}'
            : 'Tasty starter description ${index - 2}',
        price: index < 3 ? (index + 1) * 10.99 : (index - 2) * 5.99,
        imageUrl:
            index < 3 ? 'assets/images/tea-m.jpg' : 'assets/images/tea.jpg',
        restaurantId: 'restaurant-1',
        restaurantName: restaurantName!,
      );

      cartProvider.addItem(item);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${item.name} to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Restaurant Image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    restaurantImage ?? 'assets/images/tea.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                restaurantName!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),

          // Restaurant Info
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: rating!,
                        itemBuilder: (context, _) => const Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        itemCount: 5,
                        itemSize: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$rating (120 reviews)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        location!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Open • Closes at $openUntil',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleReservation(context),
                          icon: const Icon(Icons.calendar_today),
                          label: const Text('Reserve Table'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleOrder(context),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Order Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Menu Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                  _MenuCategory(
                    title: 'Popular Items',
                    items: List.generate(
                      3,
                      (index) => _MenuItem(
                        id: const Uuid().v4(),
                        name: 'Popular Item ${index + 1}',
                        description:
                            'Delicious description for item ${index + 1}',
                        price: (index + 1) * 10.99,
                        imageUrl: 'assets/images/tea-m.jpg',
                        restaurantId: 'restaurant-1',
                        restaurantName: restaurantName!,
                        onAddToCart: () {
                          _addToCart(context, index);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _MenuCategory(
                    title: 'Starters',
                    items: List.generate(
                      3,
                      (index) => _MenuItem(
                        id: const Uuid().v4(),
                        name: 'Starter ${index + 1}',
                        description: 'Tasty starter description ${index + 1}',
                        price: (index + 1) * 5.99,
                        imageUrl: 'assets/images/tea.jpg',
                        restaurantId: 'restaurant-1',
                        restaurantName: restaurantName!,
                        onAddToCart: () {
                          _addToCart(context, index + 3);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCategory extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _MenuCategory({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Column(
          children: items
              .map((item) => item.animate(delay: 200.ms).fadeIn().slideX())
              .toList(),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String restaurantId;
  final String restaurantName;
  final VoidCallback? onAddToCart;

  const _MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.restaurantId,
    required this.restaurantName,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imageUrl,
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
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: onAddToCart,
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
