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
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        price: json['price']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        category: json['category']?.toString() ?? '',
        dietaryInfo: json['dietary_info']?.toString() ?? '',
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
  final double averageRating;
  final bool isFavorite;
  final String? _cuisineNameFromJson;
  final Map<String, dynamic>? _cuisineObjFromJson;

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
    required this.averageRating,
    required this.isFavorite,
    String? cuisineNameFromJson,
    Map<String, dynamic>? cuisineObjFromJson,
  })  : _cuisineNameFromJson = cuisineNameFromJson,
        _cuisineObjFromJson = cuisineObjFromJson,
        super();

  String? get cuisineName {
    if (_cuisineNameFromJson != null && _cuisineNameFromJson.isNotEmpty) {
      return _cuisineNameFromJson;
    }
    if (_cuisineObjFromJson != null && _cuisineObjFromJson['name'] != null) {
      return _cuisineObjFromJson['name'].toString();
    }
    return null;
  }

  factory RestaurantModel.fromJson(Map<String, dynamic> json) =>
      RestaurantModel(
        id: json['id'],
        name: json['name']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        address: json['address']?.toString() ?? '',
        longitude: json['longitude']?.toString() ?? '',
        latitude: json['latitude']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        website: json['website']?.toString(),
        openingHours: json['opening_hours']?.toString() ?? '',
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
        priceRange: json['price_range']?.toString() ?? '',
        image: json['image']?.toString() ?? '',
        ownerId: json['owner_id'] ?? -1,
        isApproved: json['is_approved'] is bool
            ? json['is_approved']
            : json['is_approved'] == 1,
        status: json['status'] is bool ? json['status'] : json['status'] == 1,
        menus: (json['menus'] as List? ?? [])
            .map((menu) => MenuModel.fromJson(menu))
            .toList(),
        averageRating: (json['average_rating'] is int)
            ? (json['average_rating'] as int).toDouble()
            : (json['average_rating'] is double)
                ? json['average_rating']
                : double.tryParse(json['average_rating']?.toString() ?? '0') ??
                    0.0,
        isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
        cuisineNameFromJson: json['cuisine_name']?.toString(),
        cuisineObjFromJson:
            json['cuisine'] is Map<String, dynamic> ? json['cuisine'] : null,
      );

  RestaurantModel copyWith({
    bool? isFavorite,
  }) {
    return RestaurantModel(
      id: id,
      name: name,
      description: description,
      address: address,
      longitude: longitude,
      latitude: latitude,
      phoneNumber: phoneNumber,
      email: email,
      website: website,
      openingHours: openingHours,
      cuisineId: cuisineId,
      priceRange: priceRange,
      image: image,
      ownerId: ownerId,
      isApproved: isApproved,
      status: status,
      menus: menus,
      averageRating: averageRating,
      isFavorite: isFavorite ?? this.isFavorite,
      cuisineNameFromJson: _cuisineNameFromJson,
      cuisineObjFromJson: _cuisineObjFromJson,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'address': address,
        'longitude': longitude,
        'latitude': latitude,
        'phoneNumber': phoneNumber,
        'email': email,
        'website': website,
        'openingHours': openingHours,
        'cuisineId': cuisineId,
        'priceRange': priceRange,
        'image': image,
        'ownerId': ownerId,
        'isApproved': isApproved ? 1 : 0,
        'status': status ? 1 : 0,
        'averageRating': averageRating,
        'isFavorite': isFavorite ? 1 : 0,
        'cuisine_name': _cuisineNameFromJson,
        'cuisine': _cuisineObjFromJson,
      };
}
