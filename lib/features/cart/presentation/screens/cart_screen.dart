import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/cart_provider.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../../order/data/models/order_model.dart';
import '../../../order/data/order_service.dart';
import '../../../profile/data/address_provider.dart';
import '../../../restaurant/data/restaurant_provider.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your cart is empty',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add items to your cart to see them here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return _CartItemCard(item: item)
                        .animate(delay: (100 * index).ms)
                        .fadeIn()
                        .slideX();
                  },
                ),
              ),
              _CartSummary(total: cart.total),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  void _editDietaryInfo(BuildContext context) async {
    final List<String> allTags = item.dietaryInfo ?? [];
    if (allTags.isEmpty) return;
    final List<String> selected = List<String>.from(item.dietaryInfo ?? []);
    final result = await showDialog<List<String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Dietary Info'),
              content: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTags.map((tag) {
                  final isSelected = selected.contains(tag);
                  return FilterChip(
                    label: Text(tag),
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
                    selectedColor: Colors.green[100],
                    checkmarkColor: Colors.green[800],
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () => Navigator.pop(context, selected),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!context.mounted) return;
    if (result != null &&
        result.isNotEmpty &&
        result
            .toSet()
            .difference((item.dietaryInfo ?? []).toSet())
            .isNotEmpty) {
      // Update dietary info in cart
      final cartProvider = context.read<CartProvider>();
      final updatedItem = CartItem(
        id: item.id,
        name: item.name,
        description: item.description,
        price: item.price,
        imageUrl: item.imageUrl,
        restaurantId: item.restaurantId,
        restaurantName: item.restaurantName,
        restaurantAddress: item.restaurantAddress,
        quantity: item.quantity,
        dietaryInfo: result,
      );
      cartProvider.removeItem(item.id);
      cartProvider.addItem(updatedItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  if (item.dietaryInfo != null &&
                      item.dietaryInfo!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: item.dietaryInfo!
                                .map((tag) => Chip(
                                      label: Text(tag,
                                          style: const TextStyle(fontSize: 12)),
                                      backgroundColor: Colors.green[50],
                                      labelStyle:
                                          TextStyle(color: Colors.green[800]),
                                      avatar: Icon(Icons.eco,
                                          color: Colors.green[400], size: 16),
                                    ))
                                .toList(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit,
                              size: 18, color: Colors.green),
                          tooltip: 'Edit dietary info',
                          onPressed: () => _editDietaryInfo(context),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${item.total.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: () {
                              context.read<CartProvider>().updateQuantity(
                                    item.id,
                                    item.quantity - 1,
                                  );
                            },
                          ),
                          Text(
                            item.quantity.toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              context.read<CartProvider>().updateQuantity(
                                    item.id,
                                    item.quantity + 1,
                                  );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                context.read<CartProvider>().removeItem(item.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatefulWidget {
  final double total;
  const _CartSummary({required this.total});

  @override
  State<_CartSummary> createState() => _CartSummaryState();
}

class _CartSummaryState extends State<_CartSummary> {
  void _showPaymentOptions(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (context) => AlertDialog(
        title: const Text('Choose Payment Option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payments),
              title: const Text('Pay Now'),
              onTap: () {
                Navigator.pop(context);
                _showPayNowForm(parentContext);
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Pay Later'),
              onTap: () {
                Navigator.pop(context);
                _showPayLaterForm(parentContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPayNowForm(BuildContext parentContext) async {
    final cartProvider =
        Provider.of<CartProvider>(parentContext, listen: false);
    final addressProvider =
        Provider.of<AddressProvider>(parentContext, listen: false);
    final cartTotal = cartProvider.total;
    final cartItems = cartProvider.items;
    final defaultAddress = addressProvider.defaultAddress;
    final addressController =
        TextEditingController(text: defaultAddress?.fullAddress ?? '');
    // Get restaurantId from first cart item
    final restaurantId =
        cartItems.isNotEmpty ? cartItems.first.restaurantId : null;
    final restaurants =
        Provider.of<RestaurantProvider>(context, listen: false).restaurants;
    final restaurant = restaurants.firstWhere(
      (r) => r.id.toString() == restaurantId,
      orElse: () => restaurants.first,
    );
    final acceptsDelivery = restaurant.acceptsDelivery == 1;

    showDialog(
      context: parentContext,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => PayNowDialog(
        parentContext: parentContext,
        cartTotal: cartTotal,
        cartItems: cartItems,
        cartProvider: cartProvider,
        acceptsDelivery: acceptsDelivery,
      ),
    );
  }

  void _showPayLaterForm(BuildContext parentContext) async {
    final cartProvider =
        Provider.of<CartProvider>(parentContext, listen: false);
    final addressProvider =
        Provider.of<AddressProvider>(parentContext, listen: false);
    final cartTotal = cartProvider.total;
    final cartItems = cartProvider.items;
    final defaultAddress = addressProvider.defaultAddress;
    final addressController =
        TextEditingController(text: defaultAddress?.fullAddress ?? '');
    // Get restaurantId from first cart item
    final restaurantId =
        cartItems.isNotEmpty ? cartItems.first.restaurantId : null;
    final restaurants =
        Provider.of<RestaurantProvider>(context, listen: false).restaurants;
    final restaurant = restaurants.firstWhere(
      (r) => r.id.toString() == restaurantId,
      orElse: () => restaurants.first,
    );
    final acceptsDelivery = restaurant.acceptsDelivery == 1;

    showDialog(
      context: parentContext,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (context) => PayLaterDialog(
        parentContext: parentContext,
        cartTotal: cartTotal,
        cartItems: cartItems,
        cartProvider: cartProvider,
        acceptsDelivery: acceptsDelivery,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '\$${widget.total.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showPaymentOptions(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Proceed to Checkout'),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

// Stepper widgets
class _StepperCircle extends StatelessWidget {
  final bool isActive;
  final bool isValid;
  final bool isInvalid;
  final IconData icon;
  final String label;
  const _StepperCircle(
      {required this.isActive,
      required this.icon,
      required this.label,
      this.isValid = false,
      this.isInvalid = false});
  @override
  Widget build(BuildContext context) {
    Color color;
    IconData displayIcon = icon;
    if (isValid) {
      color = Colors.green;
      displayIcon = Icons.check_circle;
    } else if (isInvalid) {
      color = Colors.red;
      displayIcon = Icons.error;
    } else if (isActive) {
      color = Theme.of(context).colorScheme.primary;
    } else {
      color = Colors.grey[300]!;
    }
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Icon(displayIcon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}

class _StepperLine extends StatelessWidget {
  final bool isActive;
  const _StepperLine({required this.isActive});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 2,
      color:
          isActive ? Theme.of(context).colorScheme.primary : Colors.grey[300],
      margin: const EdgeInsets.symmetric(horizontal: 2),
    );
  }
}

// Step 1: Order Details
class _OrderDetailsStep extends StatelessWidget {
  final String orderType;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController instructionsController;
  final TextEditingController tipController;
  final void Function(String) onOrderTypeChanged;
  final String? errorMessage;
  final String? addressError;
  final String? phoneError;
  final List<CartItem> cartItems;
  final bool acceptsDelivery;
  const _OrderDetailsStep({
    required this.orderType,
    required this.addressController,
    required this.phoneController,
    required this.emailController,
    required this.instructionsController,
    required this.tipController,
    required this.onOrderTypeChanged,
    this.errorMessage,
    this.addressError,
    this.phoneError,
    required this.cartItems,
    required this.acceptsDelivery,
  });
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('order_details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: orderType.isNotEmpty ? orderType : null,
          decoration: const InputDecoration(labelText: 'Order Type'),
          items: [
            const DropdownMenuItem(
                value: null, child: Text('Select Order Type')),
            const DropdownMenuItem(value: 'dine_in', child: Text('Dine In')),
            const DropdownMenuItem(value: 'takeaway', child: Text('Takeaway')),
            if (acceptsDelivery)
              const DropdownMenuItem(
                  value: 'delivery', child: Text('Delivery')),
          ],
          onChanged: (value) {
            if (value != null) onOrderTypeChanged(value);
          },
        ),
        const SizedBox(height: 12),
        if (orderType != null && orderType.isNotEmpty)
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: orderType == 'delivery'
                  ? 'Delivery Address'
                  : 'Restaurant Address',
              hintText: orderType == 'delivery'
                  ? 'Enter your delivery address'
                  : 'Restaurant address will appear here',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: addressError != null
                  ? const Icon(Icons.error, color: Colors.red)
                  : null,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.2,
                ),
              ),
              errorText: addressError,
            ),
            enabled: true,
          ),
        if (orderType == 'delivery' && addressController.text.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 4.0, right: 4.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No default address found. Please add one in your profile.',
                    style: TextStyle(color: Colors.orange[800], fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context)
                        .pushNamed('/profile'); // Adjust route as needed
                  },
                  child: const Text('Go to Profile'),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Contact Phone',
                prefixIcon: const Icon(Icons.phone),
                suffixIcon: phoneError != null
                    ? const Icon(Icons.error, color: Colors.red)
                    : null,
                filled: true,
                fillColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 1.2,
                  ),
                ),
                errorText: phoneError,
              ),
              keyboardType: TextInputType.phone,
            ),
            if (phoneError != null)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 2),
                child: Text(phoneError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email (optional)',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: instructionsController,
          decoration: InputDecoration(
            labelText: 'Special Instructions',
            prefixIcon: const Icon(Icons.note_alt_outlined),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: tipController,
          decoration: InputDecoration(
            labelText: 'Tip (optional)',
            prefixIcon: const Icon(Icons.attach_money),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.2,
              ),
            ),
          ),
          keyboardType: TextInputType.number,
        ),
        if (orderType != 'delivery' && addressController.text.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0),
            child: Row(
              children: [
                const Icon(Icons.restaurant, color: Colors.teal, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    // Use the restaurant name from the first cart item
                    (cartItems.isNotEmpty &&
                            cartItems.first.restaurantName.isNotEmpty)
                        ? cartItems.first.restaurantName
                        : 'Restaurant',
                    style: TextStyle(
                        color: Colors.teal[800],
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// Step 2: Payment
class _PaymentStep extends StatelessWidget {
  final String paymentMethod;
  final TextEditingController cardNumberController;
  final TextEditingController cardExpiryController;
  final TextEditingController cardCvvController;
  final TextEditingController mobileMoneyController;
  final void Function(String) onPaymentMethodChanged;
  final String? errorMessage;
  const _PaymentStep(
      {required this.paymentMethod,
      required this.cardNumberController,
      required this.cardExpiryController,
      required this.cardCvvController,
      required this.mobileMoneyController,
      required this.onPaymentMethodChanged,
      this.errorMessage});
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('payment'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: paymentMethod,
          decoration: const InputDecoration(labelText: 'Payment Method'),
          items: [
            const DropdownMenuItem(
              value: 'visa',
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Visa Card'),
                ],
              ),
            ),
            const DropdownMenuItem(
              value: 'mobile_money',
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Mobile Money'),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) onPaymentMethodChanged(value);
          },
        ),
        const SizedBox(height: 12),
        if (paymentMethod == 'visa') ...[
          TextField(
            controller: cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
              hintText: '1234 5678 9012 3456',
              prefixIcon: const Icon(Icons.credit_card),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberInputFormatter(),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cardExpiryController,
            decoration: InputDecoration(
              labelText: 'Expiry (MM/YY)',
              hintText: '08/25',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.datetime,
            maxLength: 5,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: cardCvvController,
            decoration: InputDecoration(
              labelText: 'CVV',
              hintText: '123',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
          ),
        ],
        if (paymentMethod == 'mobile_money')
          TextField(
            controller: mobileMoneyController,
            decoration: InputDecoration(
              labelText: 'Mobile Money Number',
              hintText: '07XX XXX XXX',
              prefixIcon: const Icon(Icons.phone_android),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
          ),
      ],
    );
  }
}

// Step 3: Review & Confirm
class _ReviewStep extends StatelessWidget {
  final double cartTotal;
  final List<CartItem> cartItems;
  final String orderType;
  final String address;
  final String phone;
  final String email;
  final String instructions;
  final String tip;
  final String paymentMethod;
  final String cardNumber;
  final String mobileMoney;
  const _ReviewStep({
    required this.cartTotal,
    required this.cartItems,
    required this.orderType,
    required this.address,
    required this.phone,
    required this.email,
    required this.instructions,
    required this.tip,
    required this.paymentMethod,
    required this.cardNumber,
    required this.mobileMoney,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('review'),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Order Summary',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              ...cartItems.map<Widget>((item) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(item.imageUrl,
                                width: 40, height: 40, fit: BoxFit.cover),
                          )
                        : Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                const Icon(Icons.fastfood, color: Colors.grey),
                          ),
                    title: Text(item.name,
                        style: Theme.of(context).textTheme.bodyMedium),
                    subtitle: Text('Qty: ${item.quantity}',
                        style: Theme.of(context).textTheme.bodySmall),
                    trailing: Text('₣${item.total.toStringAsFixed(2)}',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  )),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text('₣${cartTotal.toStringAsFixed(2)}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 18),
              Text('Contact & Delivery',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (orderType != 'delivery' && cartItems.isNotEmpty) ...[
                Row(children: [
                  const Icon(Icons.restaurant, size: 18),
                  const SizedBox(width: 6),
                  Text(cartItems.first.restaurantName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                ]),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(address,
                          style: Theme.of(context).textTheme.bodyMedium)),
                ]),
              ],
              Row(children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(phone,
                        style: Theme.of(context).textTheme.bodyMedium))
              ]),
              if (email.isNotEmpty)
                Row(children: [
                  const Icon(Icons.email_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(email,
                          style: Theme.of(context).textTheme.bodyMedium))
                ]),
              if (instructions.isNotEmpty)
                Row(children: [
                  const Icon(Icons.note_alt_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(instructions,
                          style: Theme.of(context).textTheme.bodyMedium))
                ]),
              if (tip.isNotEmpty)
                Row(children: [
                  const Icon(Icons.attach_money, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text('Tip: $tip',
                          style: Theme.of(context).textTheme.bodyMedium))
                ]),
              const SizedBox(height: 18),
              Text('Payment',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    paymentMethod == 'visa'
                        ? Icons.credit_card
                        : paymentMethod == 'mobile_money'
                            ? Icons.phone_android
                            : Icons.money,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      paymentMethod == 'visa'
                          ? 'Visa Card: **** **** **** ${cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : ''}'
                          : paymentMethod == 'mobile_money'
                              ? 'Mobile Money: $mobileMoney'
                              : paymentMethod,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// Add this at the end of the file (before any closing braces if needed):
class PayLaterDialog extends StatefulWidget {
  final BuildContext parentContext;
  final double cartTotal;
  final List cartItems;
  final CartProvider cartProvider;
  final bool acceptsDelivery;

  const PayLaterDialog({
    super.key,
    required this.parentContext,
    required this.cartTotal,
    required this.cartItems,
    required this.cartProvider,
    required this.acceptsDelivery,
  });

  @override
  State<PayLaterDialog> createState() => _PayLaterDialogState();
}

class _PayLaterDialogState extends State<PayLaterDialog> {
  int step = 0;
  bool orderStepCompleted = false;
  bool isLoading = false;
  String? errorMessage;
  String? addressError;
  String? phoneError;

  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController instructionsController;
  late TextEditingController tipController;

  String orderType = '';

  void _setAddressForOrderType(String? type) {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (type == 'delivery') {
      addressController.text =
          (addressProvider.defaultAddress?.fullAddress.isNotEmpty == true)
              ? addressProvider.defaultAddress!.fullAddress
              : (authProvider.user?.address ?? '');
    } else if (type == 'dine_in' || type == 'takeaway') {
      addressController.text = widget.cartItems.isNotEmpty
          ? widget.cartItems.first.restaurantAddress
          : '';
    } else {
      addressController.text = '';
    }
  }

  @override
  void initState() {
    super.initState();
    Provider.of<AddressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? '';
    final userPhone = authProvider.user?.phoneNumber ?? '';
    addressController = TextEditingController();
    phoneController = TextEditingController(text: userPhone);
    emailController = TextEditingController(text: userEmail);
    instructionsController = TextEditingController();
    tipController = TextEditingController();
    _setAddressForOrderType(orderType);
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    instructionsController.dispose();
    tipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = widget.cartTotal;
    final cartItems = widget.cartItems;
    final cartProvider = widget.cartProvider;
    final parentContext = widget.parentContext;
    final addressProvider = Provider.of<AddressProvider>(context);

    // Auto-fill address if orderType is delivery and address is empty
    if (orderType == 'delivery' &&
        addressController.text.isEmpty &&
        addressProvider.defaultAddress != null) {
      addressController.text = addressProvider.defaultAddress!.fullAddress;
    }

    // Ensure orderType is valid for the dropdown
    if (!widget.acceptsDelivery && orderType == 'delivery') {
      orderType = 'dine_in';
    }

    return Dialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          final dialogWidth =
              isWide ? 440.0 : MediaQuery.of(context).size.width * 0.98;
          return Container(
            width: dialogWidth,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepperCircle(
                          isActive: step == 0,
                          icon: Icons.receipt_long,
                          label: 'Order',
                          isValid: orderStepCompleted,
                          isInvalid: !orderStepCompleted && step > 0),
                      _StepperLine(isActive: step > 0),
                      _StepperCircle(
                          isActive: step == 1,
                          icon: Icons.check_circle,
                          label: 'Review'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: step == 0
                        ? _OrderDetailsStep(
                            orderType: orderType,
                            addressController: addressController,
                            phoneController: phoneController,
                            emailController: emailController,
                            instructionsController: instructionsController,
                            tipController: tipController,
                            onOrderTypeChanged: (val) async {
                              setState(() => orderType = val);
                              _setAddressForOrderType(val);
                              final addressProvider =
                                  Provider.of<AddressProvider>(context,
                                      listen: false);
                              final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);
                              if (val == 'delivery') {
                                final user = authProvider.user;
                                if (addressProvider.defaultAddress != null &&
                                    addressProvider.defaultAddress!.fullAddress
                                        .isNotEmpty) {
                                  addressController.text = addressProvider
                                      .defaultAddress!.fullAddress;
                                } else if (user != null &&
                                    (user.address?.isNotEmpty ?? false)) {
                                  addressController.text = user.address ?? '';
                                } else {
                                  addressController.text = '';
                                }
                              } else {
                                if (widget.cartItems.isNotEmpty) {
                                  final firstItem = widget.cartItems.first;
                                  addressController.text =
                                      firstItem.restaurantAddress;
                                } else {
                                  addressController.text = '';
                                }
                              }
                            },
                            errorMessage: errorMessage,
                            addressError: addressError,
                            phoneError: phoneError,
                            cartItems: cartItems.cast<CartItem>(),
                            acceptsDelivery: widget.acceptsDelivery,
                          )
                        : _ReviewStep(
                            cartTotal: cartTotal,
                            cartItems: cartItems.cast<CartItem>(),
                            orderType: orderType,
                            address: addressController.text,
                            phone: phoneController.text,
                            email: emailController.text,
                            instructions: instructionsController.text,
                            tip: tipController.text,
                            paymentMethod: 'Pay Later',
                            cardNumber: '',
                            mobileMoney: '',
                          ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (step > 0)
                        TextButton(
                          onPressed: () => setState(() => step--),
                          child: Text('Back',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                        ),
                      if (step == 0)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ElevatedButton(
                              onPressed: () async {
                                setState(() {
                                  errorMessage = null;
                                  addressError = null;
                                  phoneError = null;
                                });
                                bool valid = true;
                                if (addressController.text.trim().isEmpty) {
                                  setState(() => addressError =
                                      'Delivery address is required.');
                                  valid = false;
                                }
                                if (phoneController.text.trim().isEmpty) {
                                  setState(() => phoneError =
                                      'Contact phone is required.');
                                  valid = false;
                                }
                                if (valid) {
                                  setState(() {
                                    orderStepCompleted = true;
                                    step++;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Review'),
                            ),
                          ),
                        ),
                      if (step == 1)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);
                                      await Future.delayed(
                                          Duration.zero); // ensure async gap
                                      if (!mounted) return;
                                      try {
                                        final items = cartItems.map((item) {
                                          final map = item.toJson()
                                              as Map<String, dynamic>;
                                          if (item.dietaryInfo != null) {
                                            map['dietaryInfo'] =
                                                item.dietaryInfo;
                                          }
                                          return map;
                                        }).toList();
                                        final firstItem = cartItems.isNotEmpty
                                            ? cartItems.first
                                            : null;
                                        if (firstItem == null) {
                                          setState(() {
                                            errorMessage = 'Cart is empty!';
                                            isLoading = false;
                                          });
                                          return;
                                        }
                                        final restaurant = RestaurantModel(
                                          id: int.tryParse(
                                                  firstItem.restaurantId) ??
                                              0,
                                          name: firstItem.restaurantName,
                                          address: firstItem.restaurantAddress,
                                          image: '',
                                          acceptsReservations: 0,
                                          acceptsDelivery: 0,
                                        );
                                        await OrderService.placeOrder(
                                          context: context,
                                          items: items,
                                          total: cartTotal,
                                          address: addressController.text,
                                          restaurant: restaurant,
                                          paymentMethod: 'Pay Later',
                                          instructions:
                                              instructionsController.text,
                                          orderType: orderType,
                                          dietaryInfo:
                                              _collectDietaryInfo(cartItems),
                                        );
                                        await Future.delayed(
                                            Duration.zero); // async gap
                                        if (!context.mounted) return;
                                        cartProvider.clearCart();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(parentContext)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('Order placed!')),
                                        );
                                      } catch (e) {
                                        setState(() {
                                          errorMessage =
                                              'Failed to place order';
                                          isLoading = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Place Order'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _collectDietaryInfo(List cartItems) {
    final Set<String> allDietary = {};
    for (final item in cartItems) {
      if (item.dietaryInfo != null) {
        allDietary.addAll(item.dietaryInfo);
      }
    }
    return allDietary.toList();
  }
}

class PayNowDialog extends StatefulWidget {
  final BuildContext parentContext;
  final double cartTotal;
  final List cartItems;
  final CartProvider cartProvider;
  final bool acceptsDelivery;

  const PayNowDialog({
    super.key,
    required this.parentContext,
    required this.cartTotal,
    required this.cartItems,
    required this.cartProvider,
    required this.acceptsDelivery,
  });

  @override
  State<PayNowDialog> createState() => _PayNowDialogState();
}

class _PayNowDialogState extends State<PayNowDialog> {
  int step = 0;
  bool orderStepCompleted = false;
  bool paymentStepCompleted = false;
  bool isLoading = false;
  String? errorMessage;
  String? addressError;
  String? phoneError;

  late TextEditingController addressController;
  late TextEditingController phoneController;
  late TextEditingController emailController;
  late TextEditingController instructionsController;
  late TextEditingController tipController;
  late TextEditingController cardNumberController;
  late TextEditingController cardExpiryController;
  late TextEditingController cardCvvController;
  late TextEditingController mobileMoneyController;

  String orderType = '';
  String paymentMethod = 'visa';

  void _setAddressForOrderType(String? type) {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (type == 'delivery') {
      addressController.text =
          (addressProvider.defaultAddress?.fullAddress?.isNotEmpty == true)
              ? addressProvider.defaultAddress!.fullAddress
              : (authProvider.user?.address ?? '');
    } else if (type == 'dine_in' || type == 'takeaway') {
      addressController.text = widget.cartItems.isNotEmpty
          ? widget.cartItems.first.restaurantAddress
          : '';
    } else {
      addressController.text = '';
    }
  }

  @override
  void initState() {
    super.initState();
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.user?.email ?? '';
    final userPhone = authProvider.user?.phoneNumber ?? '';
    addressController = TextEditingController();
    phoneController = TextEditingController(text: userPhone);
    emailController = TextEditingController(text: userEmail);
    instructionsController = TextEditingController();
    tipController = TextEditingController();
    cardNumberController = TextEditingController();
    cardExpiryController = TextEditingController();
    cardCvvController = TextEditingController();
    mobileMoneyController = TextEditingController();
    _setAddressForOrderType(orderType);
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    emailController.dispose();
    instructionsController.dispose();
    tipController.dispose();
    cardNumberController.dispose();
    cardExpiryController.dispose();
    cardCvvController.dispose();
    mobileMoneyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartTotal = widget.cartTotal;
    final cartItems = widget.cartItems;
    final cartProvider = widget.cartProvider;
    final parentContext = widget.parentContext;
    final addressProvider = Provider.of<AddressProvider>(context);

    // Auto-fill address if orderType is delivery and address is empty
    if (orderType == 'delivery' &&
        addressController.text.isEmpty &&
        addressProvider.defaultAddress != null) {
      addressController.text = addressProvider.defaultAddress!.fullAddress;
    }

    return Dialog(
      backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
          Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 500;
          final dialogWidth =
              isWide ? 440.0 : MediaQuery.of(context).size.width * 0.98;
          return Container(
            width: dialogWidth,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).dialogTheme.backgroundColor ??
                  Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StepperCircle(
                          isActive: step == 0,
                          icon: Icons.receipt_long,
                          label: 'Order',
                          isValid: orderStepCompleted,
                          isInvalid: !orderStepCompleted && step > 0),
                      _StepperLine(isActive: step > 0),
                      _StepperCircle(
                          isActive: step == 1,
                          icon: Icons.payment,
                          label: 'Payment',
                          isValid: paymentStepCompleted,
                          isInvalid: !paymentStepCompleted && step > 1),
                      _StepperLine(isActive: step > 1),
                      _StepperCircle(
                          isActive: step == 2,
                          icon: Icons.check_circle,
                          label: 'Review'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: step == 0
                        ? _OrderDetailsStep(
                            orderType: orderType,
                            addressController: addressController,
                            phoneController: phoneController,
                            emailController: emailController,
                            instructionsController: instructionsController,
                            tipController: tipController,
                            onOrderTypeChanged: (val) async {
                              setState(() => orderType = val);
                              _setAddressForOrderType(val);
                              final addressProvider =
                                  Provider.of<AddressProvider>(context,
                                      listen: false);
                              final authProvider = Provider.of<AuthProvider>(
                                  context,
                                  listen: false);
                              if (val == 'delivery') {
                                final user = authProvider.user;
                                if (addressProvider.defaultAddress != null &&
                                    addressProvider.defaultAddress!.fullAddress
                                        .isNotEmpty) {
                                  addressController.text = addressProvider
                                      .defaultAddress!.fullAddress;
                                } else if (user != null &&
                                    (user.address?.isNotEmpty ?? false)) {
                                  addressController.text = user.address ?? '';
                                } else {
                                  addressController.text = '';
                                }
                              } else {
                                if (widget.cartItems.isNotEmpty) {
                                  final firstItem = widget.cartItems.first;
                                  addressController.text =
                                      firstItem.restaurantAddress;
                                } else {
                                  addressController.text = '';
                                }
                              }
                            },
                            errorMessage: errorMessage,
                            addressError: addressError,
                            phoneError: phoneError,
                            cartItems: cartItems.cast<CartItem>(),
                            acceptsDelivery: widget.acceptsDelivery,
                          )
                        : step == 1
                            ? _PaymentStep(
                                paymentMethod: paymentMethod,
                                cardNumberController: cardNumberController,
                                cardExpiryController: cardExpiryController,
                                cardCvvController: cardCvvController,
                                mobileMoneyController: mobileMoneyController,
                                onPaymentMethodChanged: (val) =>
                                    setState(() => paymentMethod = val),
                                errorMessage: errorMessage,
                              )
                            : _ReviewStep(
                                cartTotal: cartTotal,
                                cartItems: cartItems.cast<CartItem>(),
                                orderType: orderType,
                                address: addressController.text,
                                phone: phoneController.text,
                                email: emailController.text,
                                instructions: instructionsController.text,
                                tip: tipController.text,
                                paymentMethod: paymentMethod,
                                cardNumber: cardNumberController.text,
                                mobileMoney: mobileMoneyController.text,
                              ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (step > 0)
                        TextButton(
                          onPressed: () => setState(() => step--),
                          child: Text('Back',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.primary)),
                        ),
                      if (step < 2)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() {
                                        errorMessage = null;
                                        addressError = null;
                                        phoneError = null;
                                      });
                                      bool valid = true;
                                      if (step == 0) {
                                        if (orderType == 'delivery' &&
                                            addressController.text
                                                .trim()
                                                .isEmpty) {
                                          setState(() => addressError =
                                              'Delivery address is required.');
                                          valid = false;
                                        }
                                        if (phoneController.text
                                            .trim()
                                            .isEmpty) {
                                          setState(() => phoneError =
                                              'Contact phone is required.');
                                          valid = false;
                                        }
                                        if (valid) {
                                          setState(() {
                                            orderStepCompleted = true;
                                            step++;
                                          });
                                        }
                                      } else if (step == 1) {
                                        // Payment validation
                                        if (paymentMethod == 'visa') {
                                          if (cardNumberController.text
                                                  .trim()
                                                  .replaceAll(' ', '')
                                                  .length <
                                              16) {
                                            setState(() => errorMessage =
                                                'Enter a valid card number.');
                                            valid = false;
                                          }
                                          if (cardExpiryController.text
                                                      .trim()
                                                      .length !=
                                                  5 ||
                                              !cardExpiryController.text
                                                  .contains('/')) {
                                            setState(() => errorMessage =
                                                'Enter a valid expiry date (MM/YY).');
                                            valid = false;
                                          }
                                          if (cardCvvController.text
                                                  .trim()
                                                  .length <
                                              3) {
                                            setState(() => errorMessage =
                                                'Enter a valid CVV.');
                                            valid = false;
                                          }
                                        }
                                        if (paymentMethod == 'mobile_money') {
                                          if (mobileMoneyController.text
                                                  .trim()
                                                  .length <
                                              10) {
                                            setState(() => errorMessage =
                                                'Enter a valid mobile money number.');
                                            valid = false;
                                          }
                                        }
                                        if (valid) {
                                          setState(() {
                                            paymentStepCompleted = true;
                                            step++;
                                          });
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(step == 1 ? 'Review' : 'Next'),
                            ),
                          ),
                        ),
                      if (step == 2)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () async {
                                      setState(() => isLoading = true);
                                      try {
                                        final items = cartItems.map((item) {
                                          final map = item.toJson()
                                              as Map<String, dynamic>;
                                          if (item.dietaryInfo != null) {
                                            map['dietaryInfo'] =
                                                item.dietaryInfo;
                                          }
                                          return map;
                                        }).toList();
                                        final firstItem = cartItems.isNotEmpty
                                            ? cartItems.first
                                            : null;
                                        if (firstItem == null) {
                                          setState(() {
                                            errorMessage = 'Cart is empty!';
                                            isLoading = false;
                                          });
                                          return;
                                        }
                                        final restaurant = RestaurantModel(
                                          id: int.tryParse(
                                                  firstItem.restaurantId) ??
                                              0,
                                          name: firstItem.restaurantName,
                                          address: firstItem.restaurantAddress,
                                          image: '',
                                          acceptsReservations: 0,
                                          acceptsDelivery: 0,
                                        );
                                        await OrderService.placeOrder(
                                          context: context,
                                          items: items,
                                          total: cartTotal,
                                          address: addressController.text,
                                          restaurant: restaurant,
                                          paymentMethod: paymentMethod,
                                          instructions:
                                              instructionsController.text,
                                          orderType: orderType,
                                          dietaryInfo:
                                              _collectDietaryInfo(cartItems),
                                        );
                                        await Future.delayed(
                                            Duration.zero); // async gap
                                        if (!context.mounted) return;
                                        cartProvider.clearCart();
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(parentContext)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text('Order placed!')),
                                        );
                                      } catch (e) {
                                        setState(() {
                                          errorMessage =
                                              'Failed to place order';
                                          isLoading = false;
                                        });
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                minimumSize: const Size.fromHeight(48),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Text('Pay & Place Order'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<String> _collectDietaryInfo(List cartItems) {
    final Set<String> allDietary = {};
    for (final item in cartItems) {
      if (item.dietaryInfo != null) {
        allDietary.addAll(item.dietaryInfo);
      }
    }
    return allDietary.toList();
  }
}
