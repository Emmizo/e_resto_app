import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:mockito/mockito.dart';

class MockGeolocatorPlatform extends Mock implements GeolocatorPlatform {}

void setupMockGeolocator() {
  final mockGeolocator = MockGeolocatorPlatform();
  GeolocatorPlatform.instance = mockGeolocator;
  when(mockGeolocator.getCurrentPosition(
    locationSettings: anyNamed('locationSettings'),
  )).thenAnswer((_) async => Position(
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
        floor: null,
        isMocked: true,
      ));
}
