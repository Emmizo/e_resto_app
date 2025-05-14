import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:e_resta_app/core/providers/connectivity_provider.dart';
import 'package:e_resta_app/core/services/database_helper.dart';
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
      provider = ConnectivityProvider(
        dio: mockDio,
        dbHelper: mockDbHelper,
        connectivity: mockConnectivity,
      );
    });

    test('uses injected Dio for connectivity check', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => ConnectivityResult.wifi);
      when(mockDio.get(any, options: anyNamed('options')))
          .thenAnswer((_) async => Response(
                requestOptions: RequestOptions(path: '/test'),
                statusCode: 204,
              ));
      await provider.checkNow();
      verify(mockDio.get(any, options: anyNamed('options'))).called(1);
    });
  });
}
