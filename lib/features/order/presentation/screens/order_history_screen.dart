import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/cart_provider.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Pending', 'Delivered', 'Cancelled'];
  List<_Order> _allOrders = [];
  List<_Order> _filteredOrders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initializeOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {
        _filterOrders(_tabController.index);
      });
    }
  }

  void _filterOrders(int tabIndex) {
    if (tabIndex == 0) {
      _filteredOrders = _allOrders;
    } else {
      final status = _tabs[tabIndex];
      _filteredOrders =
          _allOrders.where((order) => order.status == status).toList();
    }
  }

  void _initializeOrders() {
    // Mock data for orders
    _allOrders = [
      _Order(
        id: 'ORD-12345',
        restaurantName: 'Italian Bistro',
        date: DateTime.now().subtract(const Duration(days: 1)),
        total: 45.99,
        status: 'Delivered',
        items: [
          _OrderItem(name: 'Margherita Pizza', quantity: 1, price: 12.99),
          _OrderItem(name: 'Caesar Salad', quantity: 2, price: 8.99),
          _OrderItem(name: 'Tiramisu', quantity: 1, price: 6.99),
        ],
      ),
      _Order(
        id: 'ORD-12344',
        restaurantName: 'Sushi Master',
        date: DateTime.now().subtract(const Duration(days: 3)),
        total: 32.50,
        status: 'Pending',
        items: [
          _OrderItem(name: 'California Roll', quantity: 2, price: 8.50),
          _OrderItem(name: 'Miso Soup', quantity: 2, price: 4.50),
          _OrderItem(name: 'Green Tea', quantity: 2, price: 3.50),
        ],
      ),
      _Order(
        id: 'ORD-12343',
        restaurantName: 'Burger Joint',
        date: DateTime.now().subtract(const Duration(days: 5)),
        total: 28.75,
        status: 'Delivered',
        items: [
          _OrderItem(name: 'Classic Burger', quantity: 2, price: 9.99),
          _OrderItem(name: 'French Fries', quantity: 2, price: 4.39),
        ],
      ),
      _Order(
        id: 'ORD-12342',
        restaurantName: 'Pasta Paradise',
        date: DateTime.now().subtract(const Duration(days: 7)),
        total: 37.20,
        status: 'Cancelled',
        items: [
          _OrderItem(name: 'Spaghetti Carbonara', quantity: 1, price: 14.99),
          _OrderItem(name: 'Garlic Bread', quantity: 1, price: 5.99),
          _OrderItem(name: 'Chocolate Cake', quantity: 1, price: 7.99),
        ],
      ),
      _Order(
        id: 'ORD-12341',
        restaurantName: 'Taco Tuesday',
        date: DateTime.now().subtract(const Duration(days: 2)),
        total: 22.50,
        status: 'Pending',
        items: [
          _OrderItem(name: 'Chicken Tacos', quantity: 3, price: 4.50),
          _OrderItem(name: 'Guacamole', quantity: 1, price: 5.00),
          _OrderItem(name: 'Horchata', quantity: 2, price: 3.50),
        ],
      ),
      _Order(
        id: 'ORD-12340',
        restaurantName: 'Pizza Palace',
        date: DateTime.now().subtract(const Duration(days: 8)),
        total: 42.99,
        status: 'Cancelled',
        items: [
          _OrderItem(name: 'Pepperoni Pizza', quantity: 2, price: 15.99),
          _OrderItem(name: 'Cheese Sticks', quantity: 1, price: 6.99),
          _OrderItem(name: 'Soda', quantity: 2, price: 2.99),
        ],
      ),
    ];
    _filteredOrders = _allOrders;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          indicatorWeight: 3,
        ),
      ),
      body: _filteredOrders.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ).animate().fade().scale(),
                  const SizedBox(height: 16),
                  Text(
                    _tabController.index == 0
                        ? 'No orders yet'
                        : 'No ${_tabs[_tabController.index].toLowerCase()} orders',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).animate().fade().slideY(begin: 0.3),
                  const SizedBox(height: 8),
                  Text(
                    'Browse restaurants and place your first order!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                  ).animate().fade().slideY(begin: 0.3),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      // TODO: Navigate to restaurants screen
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Browse Restaurants'),
                  ).animate().fade().slideY(begin: 0.3),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _filteredOrders.length,
              itemBuilder: (context, index) {
                final order = _filteredOrders[index];
                return _OrderCard(order: order).animate().fade().slideX(
                    begin: 0.3, delay: Duration(milliseconds: index * 50));
              },
            ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final _Order order;

  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.order.restaurantName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      _buildStatusChip(context),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order #${widget.order.id}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        DateFormat('MMM d, y').format(widget.order.date),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total: \$${widget.order.total.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...widget.order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.name}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              '\$${(item.price * item.quantity).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          _reorder(context);
                        },
                        icon: const Icon(Icons.replay),
                        label: const Text('Reorder'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implement view details
                        },
                        icon: const Icon(Icons.receipt),
                        label: const Text('View Details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color color;
    switch (widget.order.status) {
      case 'Delivered':
        color = Colors.green;
        break;
      case 'In Progress':
        color = Colors.orange;
        break;
      case 'Cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.order.status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  void _reorder(BuildContext context) {
    try {
      final cartProvider = context.read<CartProvider>();

      // Clear the cart first
      cartProvider.clearCart();

      // Add all items from the order to the cart
      for (final item in widget.order.items) {
        cartProvider.addItem(
          CartItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: item.name,
            description: 'Reordered from ${widget.order.restaurantName}',
            price: item.price,
            imageUrl: 'assets/images/tea.jpg', // Default image
            restaurantId: 'restaurant-1',
            restaurantName: widget.order.restaurantName,
            quantity: item.quantity,
          ),
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${widget.order.items.length} items to cart'),
          action: SnackBarAction(
            label: 'View Cart',
            onPressed: () {
              // TODO: Navigate to cart screen
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
}

class _Order {
  final String id;
  final String restaurantName;
  final DateTime date;
  final double total;
  final String status;
  final List<_OrderItem> items;

  _Order({
    required this.id,
    required this.restaurantName,
    required this.date,
    required this.total,
    required this.status,
    required this.items,
  });
}

class _OrderItem {
  final String name;
  final int quantity;
  final double price;

  _OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });
}
