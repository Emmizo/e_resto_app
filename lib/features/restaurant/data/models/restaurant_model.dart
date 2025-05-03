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
        description: json['description'],
        price: json['price'],
        image: json['image'],
        category: json['category'],
        dietaryInfo: json['dietary_info'],
        isAvailable: json['is_available'] is bool
            ? json['is_available']
            : json['is_available'] == 1,
      );
}

class MenuModel {
  final int id;
  final String name;
  final String description;
  final List<MenuItemModel> menuItems;

  MenuModel({
    required this.id,
    required this.name,
    required this.description,
    required this.menuItems,
  });

  factory MenuModel.fromJson(Map<String, dynamic> json) => MenuModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        menuItems: (json['menu_items'] as List)
            .map((item) => MenuItemModel.fromJson(item))
            .toList(),
      );
}

class RestaurantModel {
  final int id;
  final String name;
  final String description;
  final String address;
  final String longitude;
  final String latitude;
  final String phoneNumber;
  final String email;
  final String? website;
  final String openingHours;
  final int? cuisineId;
  final String priceRange;
  final String? image;
  final int ownerId;
  final bool isApproved;
  final bool status;
  final List<MenuModel> menus;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.longitude,
    required this.latitude,
    required this.phoneNumber,
    required this.email,
    this.website,
    required this.openingHours,
    required this.cuisineId,
    required this.priceRange,
    required this.image,
    required this.ownerId,
    required this.isApproved,
    required this.status,
    required this.menus,
  });

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        address: json['address'],
        longitude: json['longitude'],
        latitude: json['latitude'],
        phoneNumber: json['phone_number'],
        email: json['email'],
        website: json['website'],
        openingHours: json['opening_hours'],
        cuisineId: (() {
          final val = json['cuisine_id'];
          if (val == null) return null;
          if (val is int) return val;
          if (val is String) {
            final parsed = int.tryParse(val);
            return parsed;
          }
          return null;
        })(),
        priceRange: json['price_range'],
        image: json['image'],
        ownerId: json['owner_id'],
        isApproved: json['is_approved'] is bool
            ? json['is_approved']
            : json['is_approved'] == 1,
        status: json['status'] is bool ? json['status'] : json['status'] == 1,
        menus: (json['menus'] as List)
            .map((menu) => MenuModel.fromJson(menu))
            .toList(),
      );
}
