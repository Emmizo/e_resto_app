class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String email;
  final bool has2faEnabled;
  final int status;
  final String? fcmToken;
  final String? google2faSecret;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
    required this.email,
    required this.has2faEnabled,
    required this.status,
    this.fcmToken,
    this.google2faSecret,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    print('UserModel.fromJson input: $json');
    return UserModel(
      id: json['id'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      profilePicture: json['profile_picture'],
      email: json['email'],
      has2faEnabled: json['has_2fa_enabled'] is bool
          ? json['has_2fa_enabled']
          : json['has_2fa_enabled'] == 1,
      status: json['status'],
      fcmToken: json['fcm_token'],
      google2faSecret: json['google2fa_secret'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'profile_picture': profilePicture,
        'email': email,
        'has_2fa_enabled': has2faEnabled,
        'status': status,
        'fcm_token': fcmToken,
        'google2fa_secret': google2faSecret,
      };
}
