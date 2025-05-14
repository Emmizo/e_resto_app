import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:e_resta_app/features/home/presentation/screens/main_screen.dart';
import 'package:provider/provider.dart';
import 'package:e_resta_app/core/providers/theme_provider.dart';
import 'package:e_resta_app/features/auth/domain/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_resta_app/features/auth/data/repositories/auth_repository.dart';
import 'package:e_resta_app/features/auth/data/models/user_model.dart';
import 'package:dio/dio.dart';
import 'package:e_resta_app/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:e_resta_app/core/providers/connectivity_provider.dart';
import 'package:e_resta_app/core/providers/cart_provider.dart';
import 'package:e_resta_app/core/providers/action_queue_provider.dart';
import 'package:e_resta_app/features/reservation/presentation/screens/reservation_screen.dart';
import 'package:e_resta_app/features/profile/data/address_provider.dart';
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:e_resta_app/core/services/database_helper.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import '../unit/connectivity_provider_test.mocks.dart';

late MockDio mockDio;
late MockDatabaseHelper mockDbHelper;

void setupPlatformMocks() {
  // Mock geolocator
  const MethodChannel geolocatorChannel =
      MethodChannel('flutter.baseflow.com/geolocator');
  geolocatorChannel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'checkPermission')
      return 1; // PermissionStatus.granted
    if (methodCall.method == 'requestPermission') return 1;
    if (methodCall.method == 'getCurrentPosition')
      return {'latitude': 0.0, 'longitude': 0.0};
    return null;
  });

  // Mock path_provider
  const MethodChannel pathProviderChannel =
      MethodChannel('plugins.flutter.io/path_provider');
  pathProviderChannel.setMockMethodCallHandler((MethodCall methodCall) async {
    if (methodCall.method == 'getApplicationDocumentsDirectory') return '/tmp';
    return null;
  });
}

@GenerateMocks([Dio, DatabaseHelper])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  setupPlatformMocks();

  mockDio = MockDio();
  setUpAll(() {
    when(mockDio.get(any, options: anyNamed('options'))).thenAnswer((_) async =>
        Response(
            requestOptions: RequestOptions(path: '/test'), statusCode: 204));
    when(mockDio.get(any)).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/test'), statusCode: 204));
    when(mockDio.post(any,
            data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'), statusCode: 204));
    when(mockDio.put(any, data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'), statusCode: 204));
    when(mockDio.delete(any,
            data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'), statusCode: 204));
    when(mockDio.patch(any,
            data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'), statusCode: 204));
  });
  mockDbHelper = MockDatabaseHelper();

  testWidgets('MainScreen golden test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(FakeAuthRepository(prefs, mockDio))),
          ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(prefs)),
          ChangeNotifierProvider<ConnectivityProvider>(
            create: (_) => FakeConnectivityProvider(),
          ),
          ChangeNotifierProvider<CartProvider>(
              create: (_) => CartProvider(prefs)),
          ChangeNotifierProvider<ReservationProvider>(
              create: (_) => ReservationProvider(prefs)),
          ChangeNotifierProvider<ActionQueueProvider>(
              create: (_) => ActionQueueProvider()),
          ChangeNotifierProvider<AddressProvider>(
              create: (_) => AddressProvider(mockDio)),
        ],
        child: MaterialApp(
          home: MainScreen(),
          routes: {
            '/login': (context) =>
                Scaffold(body: Center(child: Text('Login Screen'))),
            // Add other routes as needed for navigation
          },
        ),
      ),
    );
    await expectLater(
      find.byType(MainScreen),
      matchesGoldenFile('goldens/main_screen_golden.png'),
    );
  });
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(SharedPreferences prefs, Dio dio)
      : super(AuthRemoteDatasource(dio), prefs);
  @override
  String? getToken() => null;
  @override
  UserModel? getUser() => null;
  @override
  Future<void> logout() async {}
  @override
  Future<UserModel?> login(String email, String password,
          {String? fcmToken}) async =>
      null;
  @override
  Future<UserModel?> signup(
          {required String firstName,
          required String lastName,
          required String email,
          required String phoneNumber,
          String? fcmToken}) async =>
      null;
}

class FakeConnectivityProvider extends ChangeNotifier
    implements ConnectivityProvider {
  @override
  bool get isOnline => true;
  @override
  Future<void> checkNow() async {}
  @override
  Dio get dio => mockDio;
  @override
  DatabaseHelper get dbHelper => mockDbHelper;
}
