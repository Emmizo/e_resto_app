import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../reservation/presentation/screens/reservation_screen.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

class RestaurantDetailsScreen extends StatelessWidget {
  final RestaurantModel restaurant;
  const RestaurantDetailsScreen({super.key, required this.restaurant});

  void _handleReservation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationScreen(
          restaurantName: restaurant.name,
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
                    if (restaurant.menus.isEmpty) Text('No menu available.'),
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
                            Card(
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
                                      icon:
                                          const Icon(Icons.add_circle_outline),
                                      onPressed: () {
                                        _addMenuItemToCart(context, item);
                                      },
                                    ),
                                  ],
                                ),
                              ),
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

  void _addMenuItemToCart(BuildContext context, MenuItemModel item) {
    try {
      final cartProvider = context.read<CartProvider>();
      cartProvider.addItem(CartItem(
        id: item.id.toString(),
        name: item.name,
        description: item.description,
        price: double.tryParse(item.price) ?? 0.0,
        imageUrl: item.image,
        restaurantId: restaurant.id.toString(),
        restaurantName: restaurant.name,
      ));

      // Capture the parent context
      final parentContext = context;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added \\${item.name} to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              Navigator.push(
                parentContext,
                MaterialPageRoute(builder: (context) => const CartScreen()),
              );
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: \\${e.toString()}'),
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
                  restaurant.image != null && restaurant.image!.isNotEmpty
                      ? Image.network(
                          restaurant.image!,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/tea.jpg',
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
                restaurant.name,
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
                      const Icon(Icons.location_on, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.address,
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
                        'Open • Closes at ${restaurant.openingHours}',
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
                  if (restaurant.menus.isEmpty) Text('No menu available.'),
                  for (final menu in restaurant.menus)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          menu.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        for (final item in menu.menuItems)
                          Card(
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
                              trailing: Text('₣${item.price}'),
                            ),
                          ),
                        const SizedBox(height: 16),
                      ],
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
