import 'package:e_resta_app/features/profile/presentation/screens/change_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../order/presentation/screens/order_history_screen.dart';
import '../../../reservation/presentation/screens/my_reservations_screen.dart';
import '../../../payment/presentation/screens/payment_methods_screen.dart';
import 'notification_preferences_screen.dart';
import 'saved_addresses_screen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_resta_app/features/profile/data/profile_remote_datasource.dart';
import 'package:dio/dio.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';
import 'package:e_resta_app/features/auth/data/models/user_model.dart';
import '../../../../core/providers/connectivity_provider.dart';
import 'package:e_resta_app/core/services/dio_service.dart';
import 'package:e_resta_app/features/home/presentation/screens/main_screen.dart';
// import 'package:photofilters/photofilters.dart'; // Uncomment if using photofilters

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProfileScreenBody();
  }
}

class _ProfileScreenBody extends StatefulWidget {
  @override
  State<_ProfileScreenBody> createState() => _ProfileScreenBodyState();
}

class _ProfileScreenBodyState extends State<_ProfileScreenBody> {
  File? _profileImage;
  static const _profileImageKey = 'profile_image_path';
  bool _isUploading = false;
  List<Map<String, dynamic>>? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _fetchStats();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_profileImageKey);
    if (path != null && path.isNotEmpty) {
      setState(() {
        _profileImage = File(path);
      });
    }
  }

  Future<void> _fetchStats() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    try {
      final dio = DioService.getDio();
      final response = await dio.get(
        ApiEndpoints.finalStats, // Define this as '/final-stats'
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data['data'] as List;
      setState(() {
        _stats = data
            .map((e) => {
                  'label': e['label'],
                  'value': e['value'],
                })
            .toList();
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _stats = [];
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _pickAndEditImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery);
    if (picked == null) return;
    // Crop
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9,
          ],
        ),
      ],
    );
    if (cropped == null) return;
    setState(() {
      _profileImage = File(cropped.path);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileImageKey, cropped.path);
    // Upload to backend
    await _uploadProfilePicture(File(cropped.path));
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    setState(() {
      _isUploading = true;
    });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final dio = DioService.getDio();
    final profileDatasource = ProfileRemoteDatasource(dio);
    try {
      final response = await profileDatasource.uploadProfilePicture(
        imageFile,
        token: authProvider.token,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to get the new profile picture URL from the response
        String? newUrl;
        if (response.data is Map && response.data['profile_picture'] != null) {
          newUrl = response.data['profile_picture'] as String;
        }
        if (newUrl != null && newUrl.isNotEmpty) {
          authProvider.updateProfilePicture(newUrl);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to upload: \\${response.statusMessage}')),
        );
      }
    } catch (e) {
      String errorMsg = 'Upload failed. Please try a different image.';
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
          if (data['errors'] != null && data['errors'] is Map) {
            final errors =
                (data['errors'] as Map).values.expand((v) => v).join('\n');
            errorMsg += '\n$errors';
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;
    final name =
        user != null ? ('${user.firstName} ${user.lastName}') : 'Guest';
    final email = user?.email ?? '';
    final profilePic = user?.profilePicture;
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Enhanced Header with Gradient and Glassmorphism
              SliverAppBar(
                automaticallyImplyLeading: false,
                expandedHeight: 270,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                      // Glassmorphism card for profile info
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 16),
                          child: Container(
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).cardColor.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .shadowColor
                                      .withOpacity(0.10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant
                                    .withOpacity(0.4),
                                width: 1.2,
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20, vertical: 28),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Stack(
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.18),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary,
                                                width: 3,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child: _profileImage != null
                                                  ? Image.file(
                                                      _profileImage!,
                                                      width: 88,
                                                      height: 88,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          Icon(
                                                        Icons.person,
                                                        size: 44,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    )
                                                  : (profilePic != null &&
                                                          profilePic.isNotEmpty
                                                      ? Image.network(
                                                          profilePic,
                                                          width: 88,
                                                          height: 88,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context,
                                                                  error,
                                                                  stackTrace) =>
                                                              Icon(
                                                            Icons.person,
                                                            size: 44,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                        )
                                                      : Icon(
                                                          Icons.person,
                                                          size: 44,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        )),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () async {
                                                showModalBottomSheet(
                                                  context: context,
                                                  shape:
                                                      const RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.vertical(
                                                            top:
                                                                Radius.circular(
                                                                    24)),
                                                  ),
                                                  builder: (context) =>
                                                      SafeArea(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: const Icon(
                                                              Icons
                                                                  .photo_camera),
                                                          title: const Text(
                                                              'Take Photo'),
                                                          onTap: () async {
                                                            Navigator.pop(
                                                                context);
                                                            await _pickAndEditImage(
                                                                fromCamera:
                                                                    true);
                                                          },
                                                        ),
                                                        ListTile(
                                                          leading: const Icon(
                                                              Icons
                                                                  .photo_library),
                                                          title: const Text(
                                                              'Choose from Gallery'),
                                                          onTap: () async {
                                                            Navigator.pop(
                                                                context);
                                                            await _pickAndEditImage(
                                                                fromCamera:
                                                                    false);
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                                padding:
                                                    const EdgeInsets.all(3),
                                                child: Icon(
                                                  Icons.camera_alt,
                                                  size: 16,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              email,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface
                                                        .withOpacity(0.7),
                                                  ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 18),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Color(0xFF184C55)),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(24)),
                                            ),
                                            builder: (context) =>
                                                const _EditProfileForm(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                // Floating stats card
                                Positioned(
                                  left: 65,
                                  right: 0,
                                  bottom: 30, // Float below the card
                                  child: Center(
                                    child: Card(
                                      elevation: 4,
                                      color: Theme.of(context).cardColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Container(
                                        width: 200,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          mainAxisSize: MainAxisSize.min,
                                          children: _stats?.map((stat) {
                                                final label = stat['label'];
                                                final icon =
                                                    _getStatIcon(label);
                                                return Flexible(
                                                  child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(icon,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          size: 20),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        stat['value'],
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .titleMedium
                                                            ?.copyWith(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .primary,
                                                              fontSize: 13,
                                                            ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 1),
                                                      Text(
                                                        label,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color: Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .onSurface
                                                                  .withOpacity(
                                                                      0.7),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              fontSize: 10,
                                                            ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              }).toList() ??
                                              [],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Section divider
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Divider(
                    color: Theme.of(context).dividerColor,
                    thickness: 1.2,
                  ),
                ),
              ),
              // Profile Options
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle(context, 'Account'),
                      const SizedBox(height: 16),
                      _buildProfileOptions(context),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, 'Settings'),
                      const SizedBox(height: 16),
                      _buildSettingsOptions(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildProfileOptions(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    return Column(
      children: [
        _ProfileOption(
          icon: Icons.history,
          title: 'Order History',
          subtitle: 'View your past orders',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const OrderHistoryScreen(),
              ),
            );
          },
        ),
        _ProfileOption(
          icon: Icons.calendar_today,
          title: 'My Reservations',
          subtitle: 'Manage your restaurant bookings',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyReservationsScreen(),
              ),
            );
          },
        ),
        _ProfileOption(
          icon: Icons.favorite,
          title: 'Favorites',
          subtitle: 'Your favorite dishes and restaurants',
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const MainScreen(initialIndex: 2),
              ),
              (route) => false,
            );
          },
        ),
        _ProfileOption(
          icon: Icons.location_on,
          title: 'Saved Addresses',
          subtitle: 'Manage your delivery addresses',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SavedAddressesScreen(),
              ),
            );
          },
        ),
        _ProfileOption(
          icon: Icons.payment,
          title: 'Payment Methods',
          subtitle: 'Manage your payment options',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PaymentMethodsScreen(),
              ),
            );
          },
        ),
        _ProfileOption(
          icon: Icons.lock_outline,
          title: 'Change Password',
          subtitle: 'Change your account password',
          onTap: isOnline
              ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen(),
                    ),
                  );
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'No internet connection. Please try again later.')),
                  );
                },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideX();
  }

  Widget _buildSettingsOptions(BuildContext context) {
    return Column(
      children: [
        _ProfileOption(
          icon: Icons.notifications,
          title: 'Notification Settings',
          subtitle: 'Manage your notification preferences',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationPreferencesScreen(),
              ),
            );
          },
        ),
        _ProfileOption(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get assistance and FAQs',
          onTap: () {
            // TODO: Implement help & support
          },
        ),
        _ProfileOption(
          icon: Icons.logout,
          title: 'Logout',
          subtitle: 'Sign out of your account',
          isDestructive: true,
          onTap: () {
            _showLogoutConfirmation(context);
          },
        ),
      ],
    ).animate().fadeIn(delay: 400.ms).slideX();
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Material(
            color: Colors.transparent,
            child: AlertDialog(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(26),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Logout'),
                ],
              ),
              content: const Text('Are you sure you want to logout?'),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Logout'),
                ),
              ],
            ).animate().fadeIn().scale(),
          ),
        ),
      ),
    );
  }

  IconData _getStatIcon(String label) {
    switch (label.toLowerCase()) {
      case 'orders':
        return Icons.shopping_bag;
      case 'favorites':
        return Icons.favorite;
      case 'reservations':
        return Icons.event;
      default:
        return Icons.info;
    }
  }
}

class _ProfileOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? Colors.red : Color(0xFF184C55);
    final backgroundColor = isDestructive
        ? Colors.red.withAlpha(26)
        : const Color(0xFF184C55).withAlpha(26);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: Theme.of(context).cardColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Theme.of(context).colorScheme.error.withOpacity(0.12)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDestructive
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDestructive
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileForm extends StatefulWidget {
  const _EditProfileForm();

  @override
  State<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<_EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitProfileUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Authentication error: No token found.')),
      );
      setState(() => _isSubmitting = false);
      return;
    }
    final data = {
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      "email": _emailController.text.trim(),
      "phone_number": _phoneController.text.trim(),
      "address": _addressController.text.trim(),
    };
    try {
      final profileDatasource = ProfileRemoteDatasource(Dio());
      final response =
          await profileDatasource.updateProfile(token: token, data: data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final respData = response.data;
        if (respData['status'] == 'success') {
          // Optionally update user in provider
          final updated = respData['data'];
          authProvider.setUser(UserModel.fromJson(updated));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(respData['message'] ?? 'Update failed')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${response.statusMessage}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit Profile',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your first name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your last name'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your email'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your phone number'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your address'
                  : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        _isSubmitting ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitProfileUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF184C55),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save',
                            style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
