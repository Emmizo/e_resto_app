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
import '../test_helpers/firebase_mocks.dart';

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
  setupFirebaseCoreMocks();
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  setupPlatformMocks();

  mockDio = MockDio();
  setUpAll(() {
    // General stubs
    when(mockDio.get(any, options: anyNamed('options'))).thenAnswer((_) async =>
        Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 204,
            data: {'data': []}));
    when(mockDio.get(any)).thenAnswer((_) async => Response(
        requestOptions: RequestOptions(path: '/test'),
        statusCode: 204,
        data: {'data': []}));
    when(mockDio.post(any,
            data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 204,
            data: {'data': []}));
    when(mockDio.put(any, data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 204,
            data: {'data': []}));
    when(mockDio.delete(any,
            data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 204,
            data: {'data': []}));
    when(mockDio.patch(any,
            data: anyNamed('data'), options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 204,
            data: {'data': []}));

    // Specific endpoint stubs for HomeScreen
    when(mockDio.get(argThat(contains('/cuisines')),
            options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/cuisines'),
            statusCode: 200,
            data: {'data': []}));
    when(mockDio.get(argThat(contains('/promoBanners')),
            options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/promoBanners'),
            statusCode: 200,
            data: {'data': []}));
    when(mockDio.get(argThat(contains('/restaurants')),
            options: anyNamed('options')))
        .thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/restaurants'),
            statusCode: 200,
            data: {'data': []}));

    // DatabaseHelper stubs
    when(mockDbHelper.db).thenAnswer((_) async => _FakeDb());
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
    await tester.pumpAndSettle(const Duration(seconds: 3));
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

class _FakeDb implements Database {
  @override
  Batch batch() => _FakeBatch();
  @override
  Future<List<Map<String, dynamic>>> query(String table,
          {bool? distinct,
          List<String>? columns,
          String? where,
          List<Object?>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset}) async =>
      [];
  @override
  Future<int> delete(String table,
          {String? where, List<Object?>? whereArgs}) async =>
      0;
  @override
  Future<int> insert(String table, Map<String, dynamic> values,
          {String? nullColumnHack,
          ConflictAlgorithm? conflictAlgorithm}) async =>
      1;
  @override
  Future<int> update(String table, Map<String, dynamic> values,
          {String? where,
          List<Object?>? whereArgs,
          ConflictAlgorithm? conflictAlgorithm}) async =>
      1;
  @override
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
          [List<Object?>? arguments]) async =>
      [];
  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action,
          {bool? exclusive}) async =>
      throw UnimplementedError();
  @override
  Future<void> close() async {}
  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {}
  @override
  Future<int> getVersion() async => 1;
  @override
  Future<void> setVersion(int version) async {}
  @override
  Future<void> vacuum() async {}
  @override
  Future<void> checkpoint([String? log]) async {}
  @override
  Future<void> createFunction(
      {required String functionName,
      required Function function,
      int argumentCount = 1,
      bool deterministic = false}) async {}
  @override
  String get path => '';
  @override
  bool get isOpen => true;
  @override
  Future<T> devInvokeMethod<T>(String method, [dynamic arguments]) async =>
      throw UnimplementedError();
  @override
  Future<T> devInvokeSqlMethod<T>(String method, String sql,
          [List<Object?>? arguments]) async =>
      throw UnimplementedError();
  @override
  Future<int> rawDelete(String sql, [List<Object?>? arguments]) async => 0;
  @override
  Future<int> rawInsert(String sql, [List<Object?>? arguments]) async => 1;
  @override
  Future<int> rawUpdate(String sql, [List<Object?>? arguments]) async => 1;
  @override
  Future<void> executeBatch(List<String> sqlStatements) async {}
  @override
  Future<void> onConfigure(Database db) async {}
  @override
  Future<void> onCreate(Database db, int version) async {}
  @override
  Future<void> onDowngrade(Database db, int oldVersion, int newVersion) async {}
  @override
  Future<void> onOpen(Database db) async {}
  @override
  Future<void> onUpgrade(Database db, int oldVersion, int newVersion) async {}
  @override
  Future<T> readTransaction<T>(Future<T> Function(Transaction txn) action,
          {bool? exclusive}) async =>
      throw UnimplementedError();
  @override
  Future<QueryCursor> queryCursor(String table,
          {bool? distinct,
          List<String>? columns,
          String? where,
          List<Object?>? whereArgs,
          String? groupBy,
          String? having,
          String? orderBy,
          int? limit,
          int? offset,
          int? bufferSize}) async =>
      throw UnimplementedError();
  @override
  Future<QueryCursor> rawQueryCursor(String sql, List<Object?>? arguments,
          {int? bufferSize}) async =>
      throw UnimplementedError();
  @override
  Database get database => this;
}

class _FakeBatch implements Batch {
  @override
  void delete(String table, {String? where, List<Object?>? whereArgs}) {}
  @override
  void insert(String table, Map<String, Object?> values,
      {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) {}
  @override
  void update(String table, Map<String, Object?> values,
      {String? where,
      List<Object?>? whereArgs,
      ConflictAlgorithm? conflictAlgorithm}) {}
  @override
  void execute(String sql, [List<Object?>? arguments]) {}
  @override
  void rawDelete(String sql, [List<Object?>? arguments]) {}
  @override
  void rawInsert(String sql, [List<Object?>? arguments]) {}
  @override
  void rawUpdate(String sql, [List<Object?>? arguments]) {}
  @override
  void query(String table,
      {bool? distinct,
      List<String>? columns,
      String? where,
      List<Object?>? whereArgs,
      String? groupBy,
      String? having,
      String? orderBy,
      int? limit,
      int? offset}) {}
  @override
  void rawQuery(String sql, [List<Object?>? arguments]) {}
  @override
  Future<List<Object?>> commit(
          {bool? noResult, bool? continueOnError, bool? exclusive}) async =>
      [];
  @override
  int get length => 0;
  @override
  Future<List<Object?>> apply(
          {bool? noResult, bool? continueOnError, bool? exclusive}) async =>
      [];
}
