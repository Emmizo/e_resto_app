import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../order/presentation/screens/order_history_screen.dart';
import '../../../reservation/presentation/screens/my_reservations_screen.dart';
import '../../../restaurant/presentation/screens/favorite_restaurants_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
          toolbarColor: Color(0xFF184C55),
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
    final dio = Dio();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: \\${e.toString()}')),
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
        user != null ? (user.firstName + ' ' + user.lastName) : 'Guest';
    final email = user?.email ?? '';
    final profilePic = user?.profilePicture;
    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Custom App Bar with Profile Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFFFFFF),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    GestureDetector(
                                      onTap: _pickAndEditImage,
                                      child: CircleAvatar(
                                        radius: 40,
                                        backgroundColor:
                                            const Color(0xFFFFFFFF),
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : (profilePic != null &&
                                                    profilePic.isNotEmpty
                                                ? NetworkImage(profilePic)
                                                    as ImageProvider<Object>?
                                                : null),
                                        child: _profileImage == null &&
                                                (profilePic == null ||
                                                    profilePic.isEmpty)
                                            ? Icon(Icons.person,
                                                size: 40,
                                                color: Color(0xFF184C55))
                                            : null,
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () async {
                                          showModalBottomSheet(
                                            context: context,
                                            shape: const RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.vertical(
                                                      top: Radius.circular(24)),
                                            ),
                                            builder: (context) => SafeArea(
                                              child: Wrap(
                                                children: [
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.photo_camera),
                                                    title: const Text(
                                                        'Take Photo'),
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      await _pickAndEditImage(
                                                          fromCamera: true);
                                                    },
                                                  ),
                                                  ListTile(
                                                    leading: const Icon(
                                                        Icons.photo_library),
                                                    title: const Text(
                                                        'Choose from Gallery'),
                                                    onTap: () async {
                                                      Navigator.pop(context);
                                                      await _pickAndEditImage(
                                                          fromCamera: false);
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
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.edit,
                                              size: 18,
                                              color: Color(0xFF184C55)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF184C55),
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Colors.grey[600],
                                            ),
                                      ),
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
                                        borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(24)),
                                      ),
                                      builder: (context) =>
                                          const _EditProfileForm(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      context.watch<ThemeProvider>().themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: Color(0xFF184C55),
                    ),
                    onPressed: () {
                      final themeProvider = context.read<ThemeProvider>();
                      themeProvider.toggleTheme();
                    },
                  ),
                ],
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
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: Color(0xFF184C55),
          ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildProfileOptions(BuildContext context) {
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
          title: 'Favorite Restaurants',
          subtitle: 'Your saved restaurants',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FavoriteRestaurantsScreen(),
              ),
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
      ],
    ).animate().fadeIn(delay: 200.ms).slideX();
  }

  Widget _buildSettingsOptions(BuildContext context) {
    return Column(
      children: [
        _ProfileOption(
          icon: Icons.settings,
          title: 'Settings',
          subtitle: 'App preferences and configurations',
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.color
                                ?.withAlpha(179),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.color
                    ?.withAlpha(128),
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
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    // In a real app, fetch these from user profile provider or state
    _nameController = TextEditingController(text: 'John Doe');
    _emailController = TextEditingController(text: 'john.doe@example.com');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please enter your name'
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
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // TODO: Save profile changes
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save'),
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
