import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../features/restaurant/presentation/screens/restaurant_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  bool _isMapReady = false;
  LatLng _initialPosition = const LatLng(0, 0);
  bool _isLoading = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          setState(() {
            _initialPosition = LatLng(position.latitude, position.longitude);
            _isLoading = false;
          });

          // Add sample restaurants
          _addSampleRestaurants();
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addSampleRestaurants() {
    // Add sample restaurants around the user's location
    final List<Map<String, dynamic>> restaurants = [
      {
        'name': 'Italian Restaurant',
        'position': LatLng(
          _initialPosition.latitude + 0.001,
          _initialPosition.longitude + 0.001,
        ),
        'rating': 4.5,
        'cuisine': 'Italian',
        'image': 'assets/images/tea.jpg',
      },
      {
        'name': 'Japanese Restaurant',
        'position': LatLng(
          _initialPosition.latitude - 0.001,
          _initialPosition.longitude - 0.001,
        ),
        'rating': 4.7,
        'cuisine': 'Japanese',
        'image': 'assets/images/tea-m.jpg',
      },
      {
        'name': 'Chinese Restaurant',
        'position': LatLng(
          _initialPosition.latitude + 0.002,
          _initialPosition.longitude - 0.002,
        ),
        'rating': 4.3,
        'cuisine': 'Chinese',
        'image': 'assets/images/tea.jpg',
      },
    ];

    for (final restaurant in restaurants) {
      _markers.add(
        Marker(
          markerId: MarkerId(restaurant['name']),
          position: restaurant['position'],
          infoWindow: InfoWindow(
            title: restaurant['name'],
            snippet: '${restaurant['cuisine']} • ${restaurant['rating']} ★',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantDetailsScreen(
                    restaurantName: restaurant['name'],
                    restaurantImage: restaurant['image'],
                    rating: restaurant['rating'],
                    location: '${restaurant['cuisine']} • 0.5 km away',
                    openUntil: '10:00 PM',
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Restaurants'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 15,
              ),
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                  _isMapReady = true;
                });
              },
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
    );
  }
}
