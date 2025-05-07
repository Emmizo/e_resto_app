import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../features/restaurant/presentation/screens/restaurant_details_screen.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

class MapScreen extends StatelessWidget {
  final List<RestaurantModel> restaurants;
  const MapScreen({Key? key, required this.restaurants}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final markers = restaurants
        .where((r) => r.latitude.isNotEmpty && r.longitude.isNotEmpty)
        .map((r) => Marker(
              markerId: MarkerId(r.id.toString()),
              position: LatLng(
                double.tryParse(r.latitude) ?? 0.0,
                double.tryParse(r.longitude) ?? 0.0,
              ),
              infoWindow: InfoWindow(title: r.name, snippet: r.address),
            ))
        .toSet();

    final initialLatLng = markers.isNotEmpty
        ? markers.first.position
        : LatLng(-1.95, 30.05); // fallback

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: initialLatLng, zoom: 13),
        markers: markers,
      ),
    );
  }
}
