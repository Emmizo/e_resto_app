import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../order/data/models/order_model.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:e_resta_app/core/providers/cart_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
      final dio = Dio();
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
      final orders = (response.data['data'] as List)
          .map((json) => OrderModel.fromJson(json))
          .toList();
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Restaurant: ${order.restaurant.name}'),
              Row(
                children: [
                  _OrderTypeChip(orderType: order.orderType),
                  const SizedBox(width: 8),
                  _OrderStatusChip(status: order.status),
                ],
              ),
              Text('Total: Frw${order.totalAmount}'),
              const SizedBox(height: 12),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.orderItems.map((item) => ListTile(
                    leading: Image.network(item.menuItem.image,
                        width: 40, height: 40, fit: BoxFit.cover),
                    title: Text(item.menuItem.name),
                    subtitle: Text('Qty: ${item.quantity}'),
                    trailing: Text('₣${item.price}'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              final isDifferentRestaurant = cartProvider.items.isNotEmpty &&
                  cartProvider.currentRestaurantId !=
                      order.restaurant.id.toString();
              return ElevatedButton(
                onPressed: isDifferentRestaurant
                    ? null
                    : () async {
                        for (final item in order.orderItems) {
                          await cartProvider.addItem(CartItem(
                            id: item.menuItem.id.toString(),
                            name: item.menuItem.name,
                            description: item.menuItem.description,
                            price: double.tryParse(item.menuItem.price) ?? 0,
                            imageUrl: item.menuItem.image,
                            restaurantId: order.restaurant.id.toString(),
                            restaurantName: order.restaurant.name,
                            quantity: item.quantity,
                          ));
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order added to cart!')),
                        );
                      },
                child: Text(isDifferentRestaurant
                    ? 'Cannot reorder (different restaurant)'
                    : 'Reorder'),
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
              ? Center(child: Text('Error: $_error'))
              : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Orders Yet',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You haven't placed any orders yet.\nStart exploring and order your favorite meal!",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/');
                            },
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Browse Restaurants'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ListTile(
                            leading: Image.network(
                              order.restaurant.image,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 56,
                                height: 56,
                                color: Colors.grey[200],
                                child: const Icon(Icons.restaurant,
                                    color: Colors.grey),
                              ),
                            ),
                            title: Text(order.restaurant.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    _OrderTypeChip(orderType: order.orderType),
                                    const SizedBox(width: 8),
                                    _OrderStatusChip(status: order.status),
                                  ],
                                ),
                                Text('Total: ₣${order.totalAmount}'),
                                Text('Placed: ${order.createdAt.toLocal()}'),
                              ],
                            ),
                            onTap: () => _showOrderDetails(order),
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
        return Colors.green;
      case 'takeaway':
        return Colors.orange;
      case 'delivery':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String get _label => orderType.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(_label, style: const TextStyle(color: Colors.white)),
      backgroundColor: _color,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final String status;
  const _OrderStatusChip({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        status[0].toUpperCase() + status.substring(1),
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: _color,
      visualDensity: VisualDensity.compact,
    );
  }
}
