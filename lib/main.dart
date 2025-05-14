import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:dio/dio.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/presentation/screens/main_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/cart_provider.dart';
import 'features/reservation/presentation/screens/reservation_screen.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/order/presentation/screens/order_history_screen.dart';
import 'features/reservation/presentation/screens/my_reservations_screen.dart';
import 'features/restaurant/presentation/screens/favorite_restaurants_screen.dart';
import 'features/profile/presentation/screens/saved_addresses_screen.dart';
import 'features/payment/presentation/screens/payment_methods_screen.dart';
import 'features/profile/presentation/screens/notification_preferences_screen.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/providers/auth_provider.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/services/notification_service.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/action_queue_provider.dart';
import 'features/profile/data/address_provider.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final dio = Dio();
  final authRepo = AuthRepository(AuthRemoteDatasource(dio), prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authRepo)),
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider(create: (_) => CartProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ReservationProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),
        ChangeNotifierProvider(create: (_) => ActionQueueProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider(dio)),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'E-Resta',
          color: Colors.white,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/profile': (context) => const ProfileScreen(),
            '/order-history': (context) => const OrderHistoryScreen(),
            '/my-reservations': (context) => const MyReservationsScreen(),
            '/favorite-restaurants': (context) =>
                const FavoriteRestaurantsScreen(),
            '/saved-addresses': (context) => const SavedAddressesScreen(),
            '/payment-methods': (context) => const PaymentMethodsScreen(),
            '/settings': (context) => const NotificationPreferencesScreen(),
            '/signup': (context) => const SignupScreen(),
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    try {
      // Start NotificationService initialization in the background
      NotificationService().initialize();
      await Future.delayed(const Duration(seconds: 2));
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn =
          authProvider.user != null && authProvider.token != null;
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) =>
                isLoggedIn ? const MainScreen() : const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to home: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'E-Resto',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            )
                .animate()
                .fadeIn(duration: const Duration(milliseconds: 800))
                .scale(delay: const Duration(milliseconds: 400)),
            const SizedBox(height: 20),
            Text(
              'Discover Your Perfect Meal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 800))
                .slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}
