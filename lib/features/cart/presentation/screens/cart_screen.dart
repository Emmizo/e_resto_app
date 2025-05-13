import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/providers/cart_provider.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_endpoints.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:e_resta_app/core/services/dio_service.dart';
import 'package:e_resta_app/features/profile/data/address_provider.dart';

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

  void _showPayLaterForm(BuildContext parentContext) async {
    final addressProvider =
        Provider.of<AddressProvider>(parentContext, listen: false);
    if (addressProvider.addresses.isEmpty) {
      await addressProvider.fetchAddresses(parentContext);
    }
    final authProvider =
        Provider.of<AuthProvider>(parentContext, listen: false);
    final userEmail = authProvider.user?.email ?? '';
    final defaultAddress = addressProvider.defaultAddress;
    final addressController =
        TextEditingController(text: defaultAddress?.fullAddress ?? '');
    final instructionsController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController(text: userEmail);
    final tipController = TextEditingController();
    final cartProvider =
        Provider.of<CartProvider>(parentContext, listen: false);
    final cartTotal = cartProvider.total;
    final cartItems = cartProvider.items;
    showDialog(
      context: parentContext,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        int step = 0; // 0: Order, 1: Review
        bool isLoading = false;
        String? errorMessage;
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final dialogWidth =
                    isWide ? 400.0 : MediaQuery.of(context).size.width * 0.95;
                return Container(
                  width: dialogWidth,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
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
                              label: 'Order'),
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
                                orderType:
                                    'delivery', // Always delivery for Pay Later
                                addressController: addressController,
                                phoneController: phoneController,
                                emailController: emailController,
                                instructionsController: instructionsController,
                                tipController: tipController,
                                onOrderTypeChanged: (_) {}, // No-op
                                errorMessage: errorMessage,
                              )
                            : _ReviewStep(
                                cartTotal: cartTotal,
                                cartItems: cartItems,
                                orderType: 'delivery',
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                            ),
                          if (step < 1)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() => errorMessage = null);
                                    if (addressController.text.trim().isEmpty) {
                                      setState(() => errorMessage =
                                          'Delivery address is required.');
                                      return;
                                    }
                                    if (phoneController.text.trim().isEmpty) {
                                      setState(() => errorMessage =
                                          'Contact phone is required.');
                                      return;
                                    }
                                    setState(() => step++);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
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
                                              const Duration(seconds: 1));
                                          setState(() => isLoading = false);
                                          Navigator.pop(context);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('Place Order'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showPayNowForm(BuildContext parentContext) async {
    final addressProvider =
        Provider.of<AddressProvider>(parentContext, listen: false);
    if (addressProvider.addresses.isEmpty) {
      await addressProvider.fetchAddresses(parentContext);
    }
    final defaultAddress = addressProvider.defaultAddress;
    final addressController =
        TextEditingController(text: defaultAddress?.fullAddress ?? '');
    final instructionsController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final tipController = TextEditingController();
    final cardNumberController = TextEditingController();
    final cardExpiryController = TextEditingController();
    final cardCvvController = TextEditingController();
    final mobileMoneyController = TextEditingController();
    final cartProvider =
        Provider.of<CartProvider>(parentContext, listen: false);
    final cartTotal = cartProvider.total;
    final cartItems = cartProvider.items;
    showDialog(
      context: parentContext,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) {
        int step = 0; // 0: Order, 1: Payment, 2: Review
        String orderType = 'dine_in';
        String paymentMethod = 'visa';
        bool isLoading = false;
        String? errorMessage;
        void nextStep() => step < 2 ? step++ : null;
        void prevStep() => step > 0 ? step-- : null;
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            backgroundColor: Theme.of(context).dialogBackgroundColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final dialogWidth =
                    isWide ? 400.0 : MediaQuery.of(context).size.width * 0.95;
                return Container(
                  width: dialogWidth,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).dialogBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
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
                              label: 'Order'),
                          _StepperLine(isActive: step > 0),
                          _StepperCircle(
                              isActive: step == 1,
                              icon: Icons.payment,
                              label: 'Payment'),
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
                                onOrderTypeChanged: (val) =>
                                    setState(() => orderType = val),
                                errorMessage: errorMessage,
                              )
                            : step == 1
                                ? _PaymentStep(
                                    paymentMethod: paymentMethod,
                                    cardNumberController: cardNumberController,
                                    cardExpiryController: cardExpiryController,
                                    cardCvvController: cardCvvController,
                                    mobileMoneyController:
                                        mobileMoneyController,
                                    onPaymentMethodChanged: (val) =>
                                        setState(() => paymentMethod = val),
                                    errorMessage: errorMessage,
                                  )
                                : _ReviewStep(
                                    cartTotal: cartTotal,
                                    cartItems: cartItems,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary)),
                            ),
                          if (step < 2)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() => errorMessage = null);
                                    // Validation for each step
                                    if (step == 0) {
                                      if (orderType == 'delivery' &&
                                          addressController.text
                                              .trim()
                                              .isEmpty) {
                                        setState(() => errorMessage =
                                            'Delivery address is required.');
                                        return;
                                      }
                                      if (phoneController.text.trim().isEmpty) {
                                        setState(() => errorMessage =
                                            'Contact phone is required.');
                                        return;
                                      }
                                    } else if (step == 1) {
                                      if (paymentMethod == 'visa') {
                                        if (cardNumberController.text
                                                .trim()
                                                .length <
                                            16) {
                                          setState(() => errorMessage =
                                              'Enter a valid card number.');
                                          return;
                                        }
                                        if (cardExpiryController.text
                                                    .trim()
                                                    .length !=
                                                5 ||
                                            !cardExpiryController.text
                                                .contains('/')) {
                                          setState(() => errorMessage =
                                              'Enter a valid expiry date (MM/YY).');
                                          return;
                                        }
                                        if (cardCvvController.text
                                                .trim()
                                                .length <
                                            3) {
                                          setState(() => errorMessage =
                                              'Enter a valid CVV.');
                                          return;
                                        }
                                      }
                                      if (paymentMethod == 'mobile_money') {
                                        if (mobileMoneyController.text
                                                .trim()
                                                .length <
                                            10) {
                                          setState(() => errorMessage =
                                              'Enter a valid mobile money number.');
                                          return;
                                        }
                                      }
                                    }
                                    setState(() => step++);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
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
                                          await Future.delayed(
                                              const Duration(seconds: 1));
                                          setState(() => isLoading = false);
                                          Navigator.pop(context);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    foregroundColor:
                                        Theme.of(context).colorScheme.onPrimary,
                                    minimumSize: const Size.fromHeight(48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white),
                                        )
                                      : const Text('Pay & Place Order'),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
  final IconData icon;
  final String label;
  const _StepperCircle(
      {required this.isActive, required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300],
          child: Icon(icon,
              color: isActive ? Colors.white : Colors.grey[600], size: 18),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[600])),
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
  const _OrderDetailsStep(
      {required this.orderType,
      required this.addressController,
      required this.phoneController,
      required this.emailController,
      required this.instructionsController,
      required this.tipController,
      required this.onOrderTypeChanged,
      this.errorMessage});
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('order_details'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: orderType,
          decoration: const InputDecoration(labelText: 'Order Type'),
          items: const [
            DropdownMenuItem(value: 'dine_in', child: Text('Dine In')),
            DropdownMenuItem(value: 'takeaway', child: Text('Takeaway')),
            DropdownMenuItem(value: 'delivery', child: Text('Delivery')),
          ],
          onChanged: (value) {
            if (value != null) onOrderTypeChanged(value);
          },
        ),
        const SizedBox(height: 12),
        if (orderType == 'delivery')
          TextField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Delivery Address',
              prefixIcon: const Icon(Icons.location_on_outlined),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        if (orderType == 'delivery') const SizedBox(height: 12),
        TextField(
          controller: phoneController,
          decoration: InputDecoration(
            labelText: 'Contact Phone',
            prefixIcon: const Icon(Icons.phone),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email (optional)',
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: tipController,
          decoration: InputDecoration(
            labelText: 'Tip (optional)',
            prefixIcon: const Icon(Icons.attach_money),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surfaceVariant,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          keyboardType: TextInputType.number,
        ),
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
            DropdownMenuItem(
              value: 'visa',
              child: Row(
                children: [
                  Icon(Icons.credit_card, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Visa Card'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'mobile_money',
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.green),
                  const SizedBox(width: 8),
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
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.number,
            maxLength: 19,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: cardExpiryController,
                  decoration: InputDecoration(
                    labelText: 'Expiry (MM/YY)',
                    hintText: '08/25',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.datetime,
                  maxLength: 5,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: cardCvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    hintText: '123',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceVariant,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                ),
              ),
            ],
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
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
  final List cartItems;
  final String orderType;
  final String address;
  final String phone;
  final String email;
  final String instructions;
  final String tip;
  final String paymentMethod;
  final String cardNumber;
  final String mobileMoney;
  const _ReviewStep(
      {required this.cartTotal,
      required this.cartItems,
      required this.orderType,
      required this.address,
      required this.phone,
      required this.email,
      required this.instructions,
      required this.tip,
      required this.paymentMethod,
      required this.cardNumber,
      required this.mobileMoney});
  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('review'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Review & Confirm',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Card(
          color: Theme.of(context).colorScheme.surface,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Order Type: ${orderType[0].toUpperCase()}${orderType.substring(1)}'),
                if (orderType == 'delivery') Text('Delivery Address: $address'),
                Text('Contact Phone: $phone'),
                if (email.isNotEmpty) Text('Email: $email'),
                if (instructions.isNotEmpty)
                  Text('Instructions: $instructions'),
                if (tip.isNotEmpty) Text('Tip: $tip'),
                const SizedBox(height: 8),
                Text(
                    'Payment Method: ${paymentMethod == 'visa' ? 'Visa Card' : 'Mobile Money'}'),
                if (paymentMethod == 'visa')
                  Text(
                      'Card: **** **** **** ${cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : ''}'),
                if (paymentMethod == 'mobile_money')
                  Text('Mobile Money: $mobileMoney'),
                const SizedBox(height: 8),
                Text('Total: \$${cartTotal.toStringAsFixed(2)}'),
                Text('Items: ${cartItems.length}'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
