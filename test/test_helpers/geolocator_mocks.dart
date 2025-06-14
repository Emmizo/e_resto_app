import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation,
      {Object? returnValue, Object? returnValueForMissingStub}) {
    if (invocation.memberName == #getCurrentPosition) {
      return Future.value(Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 1.0,
        altitude: 0.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: true,
      ));
    }
    return super.noSuchMethod(invocation,
        returnValue: returnValue,
        returnValueForMissingStub: returnValueForMissingStub);
  }
}

void setupMockGeolocator() {
  final mockGeolocator = MockGeolocatorPlatform();
  GeolocatorPlatform.instance = mockGeolocator;
}
