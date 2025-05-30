// Order, OrderItem, and MenuItem models for order history
class MenuItemModel {
  final int id;
  final String name;
  final String description;
  final String price;
  final String image;
  final String category;
  final String dietaryInfo;
  final bool isAvailable;

  MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    required this.dietaryInfo,
    required this.isAvailable,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: json['price']?.toString() ?? '',
      image: json['image'] ?? '',
      category: json['category'] ?? '',
      dietaryInfo: json['dietary_info']?.toString() ?? '',
      isAvailable: json['is_available'] is bool
          ? json['is_available']
          : json['is_available'] == 1,
    );
  }
}

class OrderItemModel {
  final int id;
  final int menuItemId;
  final int quantity;
  final String price;
  final MenuItemModel menuItem;

  OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.quantity,
    required this.price,
    required this.menuItem,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
        id: json['id'],
        menuItemId: json['menu_item_id'],
        quantity: json['quantity'],
        price: json['price'],
        menuItem: MenuItemModel.fromJson(json['menu_item']),
      );
}

class RestaurantModel {
  final int id;
  final String name;
  final String address;
  final String image;
  final int? acceptsReservations;
  final int? acceptsDelivery;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.image,
    required this.acceptsReservations,
    required this.acceptsDelivery,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      image: json['image'] ?? '',
      acceptsReservations: (json['accepts_reservations'] == true)
          ? 1
          : (json['accepts_reservations'] == false)
              ? 0
              : (json['accepts_reservations'] ?? 0),
      acceptsDelivery: (json['accepts_delivery'] == true)
          ? 1
          : (json['accepts_delivery'] == false)
              ? 0
              : (json['accepts_delivery'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'image': image,
        'accepts_reservations': acceptsReservations ?? 0,
        'accepts_delivery': acceptsDelivery ?? 0,
      };
}

class OrderModel {
  final int? id;
  final List<Map<String, dynamic>> items;
  final double total;
  final String address;
  final String status; // 'pending', 'placed', 'failed'
  final DateTime createdAt;
  final RestaurantModel restaurant;
  final String orderType;
  final String paymentMethod;

  OrderModel({
    this.id,
    required this.items,
    required this.total,
    required this.address,
    required this.status,
    required this.createdAt,
    required this.restaurant,
    required this.orderType,
    required this.paymentMethod,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items,
        'total': total,
        'address': address,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'restaurant': restaurant.toJson(),
        'orderType': orderType,
        'paymentMethod': paymentMethod,
      };

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        items: (json['order_items'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        total: (json['total_amount'] != null &&
                json['total_amount'].toString().isNotEmpty)
            ? double.tryParse(json['total_amount'].toString()) ?? 0.0
            : 0.0,
        address: json['delivery_address'] ?? '',
        status: json['status'],
        createdAt: DateTime.parse(json['created_at']),
        restaurant: RestaurantModel.fromJson(json['restaurant']),
        orderType: json['order_type'] ?? 'delivery',
        paymentMethod: json['payment_method'] ?? '',
      );
}
