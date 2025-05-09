import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../restaurant/data/models/restaurant_model.dart';

class MapScreen extends StatefulWidget {
  final List<RestaurantModel> restaurants;
  const MapScreen({Key? key, required this.restaurants}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<Marker> _restaurantMarkers = {};
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();

    _setRestaurantMarkers(widget.restaurants);
  }

  void _setRestaurantMarkers(List<RestaurantModel> restaurants) {
    _restaurantMarkers = restaurants
        .where((r) => r.latitude.isNotEmpty && r.longitude.isNotEmpty)
        .map((restaurant) => Marker(
              markerId: MarkerId(restaurant.id.toString()),
              position: LatLng(
                double.tryParse(restaurant.latitude) ?? 0.0,
                double.tryParse(restaurant.longitude) ?? 0.0,
              ),
              infoWindow: InfoWindow(
                title: restaurant.name,
                snippet: restaurant.address,
                onTap: () => _showDistanceInfo(restaurant),
              ),
              onTap: () => _showDistanceInfo(restaurant),
            ))
        .toSet();
    setState(() {});
    // Fit camera to all markers
    if (_restaurantMarkers.isNotEmpty && _mapController != null) {
      final bounds = _createLatLngBounds(
          _restaurantMarkers.map((m) => m.position).toList());
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    }
  }

  LatLngBounds _createLatLngBounds(List<LatLng> positions) {
    double x0 = positions.first.latitude, x1 = positions.first.latitude;
    double y0 = positions.first.longitude, y1 = positions.first.longitude;
    for (LatLng latLng in positions) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(x0, y0),
      northeast: LatLng(x1, y1),
    );
  }

  Future<void> _showDistanceInfo(RestaurantModel restaurant) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      double userLat = position.latitude;
      double userLng = position.longitude;
      double restLat = double.tryParse(restaurant.latitude) ?? 0.0;
      double restLng = double.tryParse(restaurant.longitude) ?? 0.0;
      print('User location: $userLat, $userLng');
      print('Restaurant location: $restLat, $restLng');
      double distanceMeters =
          Geolocator.distanceBetween(userLat, userLng, restLat, restLng);
      double distanceKm = distanceMeters / 1000.0;
      // Walking: ~5 km/h (divide meters by 83.33 for minutes)
      int walkingMinutes = (distanceMeters / 83.33).round();
      // Driving: ~40 km/h (divide meters by 666.67 for minutes)
      int drivingMinutes = (distanceMeters / 666.67).round();
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                restaurant.name,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(restaurant.address,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 16),
              Text(
                  'Distance: ${distanceKm.toStringAsFixed(2)} km (${distanceMeters.toStringAsFixed(0)} m)'),
              const SizedBox(height: 8),
              Text('Estimated walking time: $walkingMinutes min'),
              Text('Estimated driving time: $drivingMinutes min'),
            ],
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Could not get location or calculate distance.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Restaurants Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.restaurants.isNotEmpty
              ? LatLng(
                  double.tryParse(widget.restaurants.first.latitude) ?? 0.0,
                  double.tryParse(widget.restaurants.first.longitude) ?? 0.0,
                )
              : const LatLng(0, 0),
          zoom: 13,
        ),
        markers: _restaurantMarkers,
        onMapCreated: (controller) {
          _mapController = controller;
          // Fit camera after map is created and markers are set
          if (_restaurantMarkers.isNotEmpty) {
            final bounds = _createLatLngBounds(
                _restaurantMarkers.map((m) => m.position).toList());
            _mapController!
                .animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
          }
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }
}
