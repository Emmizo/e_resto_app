import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/cart_provider.dart';
import '../../../../core/services/dio_service.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../order/data/models/order_model.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final dio = DioService.getDio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await dio.get(
        ApiEndpoints.orders,
        options: Options(
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );
      if (!mounted) return;
      setState(() {
        _orders = (response.data['data'] as List)
            .map((json) => OrderModel.fromJson(json))
            .toList();
        _orders.sort((a, b) {
          final aCancelled = a.status.toLowerCase() == 'cancelled';
          final bCancelled = b.status.toLowerCase() == 'cancelled';
          if (aCancelled && !bCancelled) return 1;
          if (!aCancelled && bCancelled) return -1;
          return -1;
        });
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orders loaded successfully!')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: $_error'),
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        ),
      );
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Restaurant: ${order.restaurant.name}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _OrderTypeChip(orderType: order.orderType),
                    const SizedBox(width: 8),
                    _OrderStatusChip(status: order.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total: ₣${order.total}',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                Text('Placed: ${order.createdAt.toLocal()}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey[700])),
                if (order.address.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Delivery Address: ${order.address}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                if (order.toJson()['special_instructions'] != null &&
                    order
                        .toJson()['special_instructions']
                        .toString()
                        .isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Row(
                      children: [
                        const Icon(Icons.note_alt_outlined, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                            child:
                                Text(order.toJson()['special_instructions'])),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                const Text('Items:',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 6),
                ...order.items.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  final menuItem = item['menu_item'] ?? {};
                  final dietaryInfo =
                      item['dietary_info'] as List<dynamic>? ?? [];
                  final imageUrl = menuItem['image'];
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: (imageUrl != null &&
                                    imageUrl.toString().isNotEmpty)
                                ? Image.network(fixImageUrl(imageUrl),
                                    width: 44, height: 44, fit: BoxFit.cover)
                                : Container(
                                    width: 44,
                                    height: 44,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood,
                                        size: 28, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(menuItem['name'] ?? '',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold)),
                                Text('Qty: ${item['quantity']}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                if (dietaryInfo.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Wrap(
                                      spacing: 4,
                                      children: dietaryInfo
                                          .map((tag) => Chip(
                                              label: Text(tag.toString(),
                                                  style: const TextStyle(
                                                      fontSize: 11))))
                                          .toList(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('₣${item['price']}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (i < order.items.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(height: 1, color: Colors.grey[300]),
                        ),
                    ],
                  );
                }),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final isDifferentRestaurant = cartProvider.items.isNotEmpty &&
                  cartProvider.currentRestaurantId !=
                      order.restaurant.id.toString();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDifferentRestaurant)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        'Cannot reorder: your cart contains items from a different restaurant.',
                        style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_checkout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDifferentRestaurant
                          ? Colors.grey[400]
                          : Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isDifferentRestaurant
                        ? null
                        : () async {
                            // Add items to cart
                            for (final item in order.items) {
                              final menuItem = item['menu_item'] ?? {};
                              await cartProvider.addItem(CartItem(
                                id: item['id'].toString(),
                                name: menuItem['name'] ?? '',
                                description: menuItem['description'] ?? '',
                                price:
                                    double.tryParse(item['price'].toString()) ??
                                        0,
                                imageUrl: menuItem['image'] ?? '',
                                restaurantId: order.restaurant.id.toString(),
                                restaurantName: order.restaurant.name,
                                restaurantAddress: order.restaurant.address,
                                quantity: item['quantity'],
                                dietaryInfo:
                                    (item['dietary_info'] as List<dynamic>?)
                                        ?.cast<String>(),
                              ));
                            }
                            if (!mounted) return;
                            Navigator.pop(context); // Close dialog
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Order added to cart!')),
                            );
                            // Navigate to cart screen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const CartScreen()),
                            );
                          },
                    label: const Text('Reorder'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We couldn\'t load your orders. Please try again later.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _fetchOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Orders Found',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You haven't placed any orders yet.",
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
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        final isCompleted =
                            order.status.toLowerCase() == 'completed';
                        final isCancelled =
                            order.status.toLowerCase() == 'cancelled';
                        return Card(
                          elevation: isCompleted ? 2 : 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          color: isCompleted
                              ? Colors.green[50]
                              : isCancelled
                                  ? Colors.grey[200]
                                  : Colors.white,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => _showOrderDetails(order),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: order.restaurant.image.isNotEmpty
                                            ? Image.network(
                                                fixImageUrl(
                                                    order.restaurant.image),
                                                width: 54,
                                                height: 54,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Container(
                                                  width: 54,
                                                  height: 54,
                                                  color: Colors.grey[200],
                                                  child: const Icon(
                                                      Icons.restaurant,
                                                      color: Colors.grey),
                                                ),
                                              )
                                            : Container(
                                                width: 54,
                                                height: 54,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                    Icons.restaurant,
                                                    color: Colors.grey),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  order.restaurant.name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 17,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                if (isCancelled) ...[
                                                  const SizedBox(width: 6),
                                                  const Icon(Icons.cancel,
                                                      color: Colors.red,
                                                      size: 20),
                                                ]
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                _OrderTypeChip(
                                                    orderType: order.orderType),
                                                const SizedBox(width: 8),
                                                _OrderStatusChip(
                                                    status: order.status),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money,
                                          size: 18, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Total: ₣${order.total}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Placed: ${order.createdAt.toLocal()}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.grey[700],
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

class _OrderTypeChip extends StatelessWidget {
  final String orderType;
  const _OrderTypeChip({required this.orderType});

  Color get _color {
    switch (orderType.toLowerCase()) {
      case 'dine_in':
        return const Color.fromARGB(255, 202, 224, 244);
      case 'takeaway':
        return const Color.fromARGB(255, 126, 133, 139);
      case 'delivery':
        return const Color.fromARGB(255, 63, 66, 69);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        orderType.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final String status;
  const _OrderStatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFC107);
      case 'confirmed':
        return const Color(0xFF1E88E5);
      case 'completed':
        return const Color(0xFF43A047);
      case 'cancelled':
        return const Color(0xFFBDBDBD);
      default:
        return const Color(0xFFBDBDBD);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
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
