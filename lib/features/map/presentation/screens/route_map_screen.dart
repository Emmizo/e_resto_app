import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RouteMapScreen extends StatefulWidget {
  final LatLng userLocation;
  final LatLng restaurantLocation;
  final String restaurantName;
  const RouteMapScreen({
    super.key,
    required this.userLocation,
    required this.restaurantLocation,
    required this.restaurantName,
  });

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  List<LatLng> _routePoints = [];
  static const String _apiKey = 'AIzaSyD1fGhQFakeKeyValue1234567890abcdefg';

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.userLocation.latitude},${widget.userLocation.longitude}&destination=${widget.restaurantLocation.latitude},${widget.restaurantLocation.longitude}&key=$_apiKey';
    final response = await http.get(Uri.parse(url));
    if (!mounted) return;
    final data = json.decode(response.body);
    if (data['status'] == 'OK') {
      final points = data['routes'][0]['overview_polyline']['points'];
      setState(() {
        _routePoints = _decodePolyline(points);
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not fetch route: ${data['status']}')),
      );
    }
  }

  List<LatLng> _decodePolyline(String poly) {
    final list = poly.codeUnits;
    final lList = <double>[];
    int index = 0;
    final int len = poly.length;
    int c = 0;
    do {
      var shift = 0;
      int result = 0;
      do {
        c = list[index] - 63;
        result |= (c & 0x1F) << (shift * 5);
        index++;
        shift++;
      } while (c >= 32);
      if (result & 1 == 1) {
        result = ~result;
      }
      final result1 = (result >> 1) * 0.00001;
      lList.add(result1);
    } while (index < len);
    final List<LatLng> positions = [];
    double lat = 0;
    double lng = 0;
    for (var i = 0; i < lList.length; i++) {
      if (i % 2 == 0) {
        lat += lList[i];
      } else {
        lng += lList[i];
        positions.add(LatLng(lat, lng));
      }
    }
    return positions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Route to ${widget.restaurantName}')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.userLocation,
          zoom: 14,
        ),
        polylines: {
          if (_routePoints.isNotEmpty)
            Polyline(
              polylineId: const PolylineId('route'),
              points: _routePoints,
              color: Colors.blue,
              width: 5,
            ),
        },
        markers: {
          Marker(
            markerId: const MarkerId('user'),
            position: widget.userLocation,
            infoWindow: const InfoWindow(title: 'You'),
          ),
          Marker(
            markerId: const MarkerId('restaurant'),
            position: widget.restaurantLocation,
            infoWindow: InfoWindow(title: widget.restaurantName),
          ),
        },
      ),
    );
  }
}
