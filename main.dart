import 'package:e_resta_app/core/services/auth_service.dart';
import 'package:e_resta_app/core/services/firebase_auth_service.dart';
import 'package:e_resta_app/core/services/notification_service.dart';
import 'package:e_resta_app/main.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(MyAppWithNotification(prefs: prefs));
}

class MyAppWithNotification extends StatelessWidget {
  final SharedPreferences prefs;
  const MyAppWithNotification({required this.prefs, super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize notification service here
    NotificationService().initialize(context);

    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => FirebaseAuthService()),
        // ...other providers
      ],
      child: MyApp(prefs: prefs),
    );
  }
}
