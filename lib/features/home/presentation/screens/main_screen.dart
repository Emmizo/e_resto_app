import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../map/presentation/screens/map_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../cart/presentation/screens/cart_screen.dart';
import '../../../../core/providers/cart_provider.dart';
import 'home_screen.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'package:e_resta_app/features/profile/presentation/screens/favorite_tab_screen.dart';
import 'dart:ui';
import '../../../../core/providers/connectivity_provider.dart';
import 'package:e_resta_app/core/providers/action_queue_provider.dart';
import 'package:e_resta_app/core/screens/failed_actions_screen.dart';
import 'package:e_resta_app/core/providers/theme_provider.dart';
import 'package:e_resta_app/features/order/presentation/screens/order_history_screen.dart';
import 'package:e_resta_app/features/reservation/presentation/screens/my_reservations_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> get _screens => [
        HomeScreen(key: _homeScreenKey),
        Builder(
          builder: (context) {
            final homeState = _homeScreenKey.currentState;
            final restaurants = homeState?.nearestRestaurantsForMap ?? [];
            final cuisines = homeState?.categories ?? [];
            return MapScreen(restaurants: restaurants, cuisines: cuisines);
          },
        ),
        const ProfileScreen(),
      ];

  void _openCart() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CartScreen()),
    );
  }

  /* void _goToProfileTab() {
    setState(() {
      _currentIndex = 2; // Profile tab index
    });
  } */

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null || authProvider.token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/login', (route) => false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Stack(
              children: [
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
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                  ),
                ),
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(bottom: Radius.circular(24)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ],
            ),
            title: Text(
              'E-Resta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.2,
                shadows: [
                  Shadow(
                    color: Theme.of(context).colorScheme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            centerTitle: true,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            actionsIconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.onPrimary),
            leading: Builder(
              builder: (context) => Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final user = authProvider.user;
                  final profilePic = user?.profilePicture;
                  return GestureDetector(
                    onTap: () => Scaffold.of(context).openDrawer(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: Colors.grey[200],
                          backgroundImage:
                              (profilePic != null && profilePic.isNotEmpty)
                                  ? NetworkImage(profilePic)
                                  : null,
                          child: (profilePic == null || profilePic.isEmpty)
                              ? Icon(Icons.person, color: Colors.grey, size: 22)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart, color: Colors.white),
                    onPressed: _openCart,
                  ),
                  Consumer<CartProvider>(
                    builder: (context, cart, child) {
                      if (cart.isEmpty) return const SizedBox.shrink();
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            cart.itemCount.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Consumer<ActionQueueProvider>(
                      builder: (context, queue, child) {
                        if (queue.pendingCount == 0) return SizedBox.shrink();
                        return Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            queue.pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          drawer: Drawer(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(-40 * (1 - value), 0),
                  child: child,
                ),
              ),
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final user = authProvider.user;
                      final name = user != null
                          ? ('${user.firstName} ${user.lastName}')
                          : 'Guest';
                      final email = user?.email ?? '';
                      final profilePic = user?.profilePicture;
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.secondary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(32),
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(32)),
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                child: Container(
                                  height: 180,
                                  color: Colors.black.withValues(alpha: 0.15),
                                ),
                              ),
                            ),
                            Container(
                              height: 180,
                              alignment: Alignment.bottomLeft,
                              padding:
                                  const EdgeInsets.fromLTRB(20, 32, 20, 20),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onPrimary,
                                          width: 3),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.18),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 38,
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      backgroundImage: profilePic != null &&
                                              profilePic.isNotEmpty
                                          ? NetworkImage(profilePic)
                                              as ImageProvider
                                          : null,
                                      child: (profilePic == null ||
                                              profilePic.isEmpty)
                                          ? Text(
                                              name.isNotEmpty ? name[0] : 'G',
                                              style: const TextStyle(
                                                  fontSize: 36,
                                                  color: Color(0xFF184C55),
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 20,
                                            shadows: [
                                              Shadow(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .shadow,
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          email,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text('Account',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            )),
                  ),
                  _ModernListTile(
                    icon: Icons.person,
                    label: 'Profile',
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 2),
                      ),
                      (route) => false,
                    ),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  _ModernListTile(
                    icon: Icons.history,
                    label: 'Order History',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderHistoryScreen(),
                      ),
                    ),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  _ModernListTile(
                    icon: Icons.calendar_today,
                    label: 'My Reservations',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyReservationsScreen(),
                      ),
                    ),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  _ModernListTile(
                    icon: Icons.favorite,
                    label: 'Favorites',
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 2),
                      ),
                      (route) => false,
                    ),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text('Settings',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            )),
                  ),
                  _ModernListTile(
                    icon: Icons.location_on,
                    label: 'Saved Addresses',
                    onTap: () =>
                        Navigator.pushNamed(context, '/saved-addresses'),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  _ModernListTile(
                    icon: Icons.payment,
                    label: 'Payment Methods',
                    onTap: () =>
                        Navigator.pushNamed(context, '/payment-methods'),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  _ModernListTile(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainScreen(initialIndex: 3),
                      ),
                      (route) => false,
                    ),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) => SwitchListTile(
                      secondary: Icon(
                        themeProvider.themeMode == ThemeMode.dark
                            ? Icons.dark_mode
                            : Icons.light_mode,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      title: Text('Dark Mode'),
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (val) => themeProvider.toggleTheme(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text('Other',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            )),
                  ),
                  _ModernListTile(
                    icon: Icons.error,
                    label: 'Sync Errors',
                    iconColor: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FailedActionsScreen(),
                      ),
                    ),
                    trailing: Icons.arrow_forward_ios,
                  ),
                  _ModernListTile(
                    icon: Icons.logout,
                    label: 'Logout',
                    iconColor: Colors.red,
                    trailing: Icons.arrow_forward_ios,
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Confirm Logout'),
                          content:
                              const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.logout();
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.clear();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    highlightColor: Colors.red.withValues(alpha: 0.08),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          body: _currentIndex == 2
              ? const FavoriteTabScreen()
              : _screens[_currentIndex > 2 ? _currentIndex - 1 : _currentIndex],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.map_outlined),
                selectedIcon: Icon(Icons.map),
                label: 'Map',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Favorite',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
          ),
        ),
        if (!isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: true,
              bottom: false,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange[700],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, color: Colors.white, size: 32),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'No Internet Connection',
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                color: Theme.of(context).colorScheme.onError,
                                fontWeight: FontWeight.w900,
                                fontSize: 26,
                                letterSpacing: 0.5,
                                height: 1.1,
                                shadows: [
                                  Shadow(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .shadow
                                        .withValues(alpha: 0.15),
                                    blurRadius: 2,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              height: 5,
                              width: 180,
                              decoration: BoxDecoration(
                                color: Colors.yellow[600],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onError,
                          side: BorderSide(
                              color: Theme.of(context).colorScheme.onError,
                              width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text('Retry',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () {
                          context.read<ConnectivityProvider>().checkNow();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ModernListTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final IconData? trailing;
  final Color? iconColor;
  final Color? highlightColor;

  const _ModernListTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.iconColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          highlightColor: highlightColor ??
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: Icon(icon,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                  size: 26),
              title: Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
              trailing: trailing != null
                  ? Icon(trailing, size: 18, color: Colors.grey[400])
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              minLeadingWidth: 0,
              dense: true,
            ),
          ),
        ),
      ),
    );
  }
}
