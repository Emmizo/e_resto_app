import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:e_resta_app/core/providers/connectivity_provider.dart';
import 'package:e_resta_app/core/services/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';

import 'connectivity_provider_test.mocks.dart';

@GenerateMocks([Dio, DatabaseHelper, Connectivity])
void main() {
  group('ConnectivityProvider', () {
    late MockDio mockDio;
    late MockDatabaseHelper mockDbHelper;
    late MockConnectivity mockConnectivity;
    late ConnectivityProvider provider;

    setUp(() {
      mockDio = MockDio();
      mockDbHelper = MockDatabaseHelper();
      mockConnectivity = MockConnectivity();
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => const Stream.empty());
      when(mockDbHelper.db).thenAnswer((_) async => _FakeDb());
      when(mockDio.get(any, options: anyNamed('options')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 204,
              ));
      when(mockDio.get(any)).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/test'),
            statusCode: 204,
          ));
      provider = ConnectivityProvider(
        dio: mockDio,
        dbHelper: mockDbHelper,
        connectivity: mockConnectivity,
      );
    });

    test('uses injected Dio for connectivity check', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(mockDio.get(any, options: anyNamed('options')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 204,
              ));
      clearInteractions(mockDio);
      await provider.checkNow();
      verify(mockDio.get(any, options: anyNamed('options'))).called(1);
    });
  });
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
