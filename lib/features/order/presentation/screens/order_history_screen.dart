import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../order/data/models/order_model.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:e_resta_app/core/providers/cart_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:e_resta_app/core/services/dio_service.dart';

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
              Text('Total: Frw${order.total}'),
              const SizedBox(height: 12),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => ListTile(
                    leading: Image.network(item['image'],
                        width: 40, height: 40, fit: BoxFit.cover),
                    title: Text(item['name']),
                    subtitle: Text('Qty: ${item['quantity']}'),
                    trailing: Text('₣${item['price']}'),
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
                        for (final item in order.items) {
                          await cartProvider.addItem(CartItem(
                            id: item['id'],
                            name: item['name'],
                            description: item['description'],
                            price: double.tryParse(item['price']) ?? 0,
                            imageUrl: item['image'],
                            restaurantId: order.restaurant.id.toString(),
                            restaurantName: order.restaurant.name,
                            quantity: item['quantity'],
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
                                Text('Total: ₣${order.total}'),
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
