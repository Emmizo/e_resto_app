import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_resta_app/core/services/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:e_resta_app/core/providers/connectivity_provider.dart';

class CartItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String restaurantId;
  final String restaurantName;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.restaurantId,
    required this.restaurantName,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      imageUrl: json['imageUrl'],
      restaurantId: json['restaurantId'],
      restaurantName: json['restaurantName'],
      quantity: json['quantity'],
    );
  }

  double get total => price * quantity;
}

class CartProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _cartKey = 'cart_items';
  List<CartItem> _items = [];
  String? _currentRestaurantId;

  CartProvider(this._prefs) {
    _loadCart();
  }

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get total => _items.fold(0, (sum, item) => sum + item.total);
  String? get currentRestaurantId => _currentRestaurantId;
  bool get isEmpty => _items.isEmpty;

  void _loadCart() {
    final cartJson = _prefs.getString(_cartKey);
    if (cartJson != null) {
      final List<dynamic> cartList = json.decode(cartJson);
      _items = cartList.map((item) => CartItem.fromJson(item)).toList();
      if (_items.isNotEmpty) {
        _currentRestaurantId = _items.first.restaurantId;
      }
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final cartJson = json.encode(_items.map((item) => item.toJson()).toList());
    await _prefs.setString(_cartKey, cartJson);
  }

  Future<void> addItem(CartItem item, {BuildContext? context}) async {
    final isOffline = context != null &&
        !Provider.of<ConnectivityProvider>(context, listen: false).isOnline;
    if (_currentRestaurantId != null &&
        _currentRestaurantId != item.restaurantId) {
      throw CartException(
        'You cannot order from two restaurants at the same time. Please clear your cart to add items from this restaurant.',
        type: CartErrorType.differentRestaurant,
      );
    }
    final existingItemIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingItemIndex >= 0) {
      _items[existingItemIndex].quantity += item.quantity;
    } else {
      _items.add(item);
      _currentRestaurantId = item.restaurantId;
    }
    await _saveCart();
    notifyListeners();
    if (isOffline) {
      final db = await DatabaseHelper().db;
      await db.insert('action_queue', {
        'actionType': 'add_to_cart',
        'payload': json.encode(item.toJson()),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> removeItem(String itemId, {BuildContext? context}) async {
    final isOffline = context != null &&
        !Provider.of<ConnectivityProvider>(context, listen: false).isOnline;
    _items.removeWhere((item) => item.id == itemId);
    if (_items.isEmpty) {
      _currentRestaurantId = null;
    }
    await _saveCart();
    notifyListeners();
    if (isOffline) {
      final db = await DatabaseHelper().db;
      await db.insert('action_queue', {
        'actionType': 'remove_from_cart',
        'payload': json.encode({'id': itemId}),
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> updateQuantity(String itemId, int quantity,
      {BuildContext? context}) async {
    final isOffline = context != null &&
        !Provider.of<ConnectivityProvider>(context, listen: false).isOnline;
    final itemIndex = _items.indexWhere((item) => item.id == itemId);
    if (itemIndex >= 0) {
      if (quantity <= 0) {
        _items.removeAt(itemIndex);
      } else {
        _items[itemIndex].quantity = quantity;
      }
      if (_items.isEmpty) {
        _currentRestaurantId = null;
      }
      await _saveCart();
      notifyListeners();
      if (isOffline) {
        final db = await DatabaseHelper().db;
        await db.insert('action_queue', {
          'actionType': 'update_cart_quantity',
          'payload': json.encode({'id': itemId, 'quantity': quantity}),
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    _currentRestaurantId = null;
    await _saveCart();
    notifyListeners();
  }
}

enum CartErrorType { differentRestaurant, other }

class CartException implements Exception {
  final String message;
  final CartErrorType type;

  CartException(this.message, {this.type = CartErrorType.other});

  @override
  String toString() => message;
}
