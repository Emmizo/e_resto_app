import 'package:e_resta_app/core/services/auth_service.dart';
import 'package:e_resta_app/core/services/firebase_auth_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_resta_app/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => FirebaseAuthService()),
        // ...other providers
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}
