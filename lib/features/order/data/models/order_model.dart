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

  factory MenuItemModel.fromJson(Map<String, dynamic> json) => MenuItemModel(
        id: json['id'],
        name: json['name'],
        description: json['description'] ?? '',
        price: json['price'],
        image: json['image'],
        category: json['category'] ?? '',
        dietaryInfo: json['dietary_info'] ?? '',
        isAvailable: json['is_available'] is bool
            ? json['is_available']
            : json['is_available'] == 1,
      );
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

  RestaurantModel({
    required this.id,
    required this.name,
    required this.address,
    required this.image,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        id: json['id'],
        name: json['name'],
        address: json['address'],
        image: json['image'],
      );
}

class OrderModel {
  final int id;
  final String orderType;
  final String totalAmount;
  final String status;
  final String paymentStatus;
  final String deliveryAddress;
  final String specialInstructions;
  final DateTime createdAt;
  final RestaurantModel restaurant;
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.id,
    required this.orderType,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.deliveryAddress,
    required this.specialInstructions,
    required this.createdAt,
    required this.restaurant,
    required this.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'],
        orderType: json['order_type'],
        totalAmount: json['total_amount'],
        status: json['status'],
        paymentStatus: json['payment_status'],
        deliveryAddress: json['delivery_address'],
        specialInstructions: json['special_instructions'],
        createdAt: DateTime.parse(json['created_at']),
        restaurant: RestaurantModel.fromJson(json['restaurant']),
        orderItems: (json['order_items'] as List)
            .map((item) => OrderItemModel.fromJson(item))
            .toList(),
      );
}
