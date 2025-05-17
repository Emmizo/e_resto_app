import 'package:e_resta_app/features/home/presentation/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:geolocator/geolocator.dart';
import '../../../restaurant/data/models/restaurant_model.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';

class MapScreen extends StatefulWidget {
  final List<RestaurantModel> restaurants;
  final List<CuisineCategory> cuisines;
  const MapScreen(
      {super.key, required this.restaurants, required this.cuisines});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Marker> _restaurantMarkers = [];
  latlong2.LatLng? _userLocation;
  late final MapController _mapController;
  double _currentZoom = 13;
  late latlong2.LatLng _mapCenter;

  @override
  void initState() {
    super.initState();
    final initialLatLng = widget.restaurants.isNotEmpty
        ? latlong2.LatLng(
            double.tryParse(widget.restaurants.first.latitude) ?? 0.0,
            double.tryParse(widget.restaurants.first.longitude) ?? 0.0,
          )
        : const latlong2.LatLng(0, 0);
    _mapController = MapController();
    _mapCenter = initialLatLng;
    _initUserLocation();
    _setRestaurantMarkers(widget.restaurants);
  }

  Future<void> _initUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _userLocation = latlong2.LatLng(position.latitude, position.longitude);
      });
      // Center map on user location
      _mapController.move(_userLocation!, _currentZoom);
    } catch (e) {
      // Could not get location, ignore for now
    }
  }

  void _setRestaurantMarkers(List<RestaurantModel> restaurants) {
    _restaurantMarkers = restaurants
        .where((r) => r.latitude.isNotEmpty && r.longitude.isNotEmpty)
        .map((restaurant) => Marker(
              point: latlong2.LatLng(
                double.tryParse(restaurant.latitude) ?? 0.0,
                double.tryParse(restaurant.longitude) ?? 0.0,
              ),
              width: 48,
              height: 48,
              child: GestureDetector(
                onTap: () => _showDistanceInfo(restaurant),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 40,
                  height: 40,
                ),
              ),
            ))
        .toList();
    setState(() {});
  }

  void _zoomIn() {
    setState(() {
      _currentZoom += 1;
      _mapController.move(_mapCenter, _currentZoom);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentZoom -= 1;
      _mapController.move(_mapCenter, _currentZoom);
    });
  }

  void _recenter() {
    if (_userLocation != null) {
      _mapController.move(_userLocation!, _currentZoom);
    }
  }

  Future<void> _showDistanceInfo(RestaurantModel restaurant) async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      double userLat = position.latitude;
      double userLng = position.longitude;
      double restLat = double.tryParse(restaurant.latitude) ?? 0.0;
      double restLng = double.tryParse(restaurant.longitude) ?? 0.0;
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
              Center(
                child: Container(
                  width: 48,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              if (restaurant.image != null && restaurant.image!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      restaurant.image!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  restaurant.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  restaurant.address,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.place, color: Colors.teal, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Distance: ${distanceKm.toStringAsFixed(2)} km (${distanceMeters.toStringAsFixed(0)} m)',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.directions_walk, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated walking: $walkingMinutes min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.directions_car, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated driving: $drivingMinutes min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF227C9D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailsScreen(
                          restaurant: restaurant,
                          cuisines: widget.cuisines,
                        ),
                      ),
                    );
                  },
                  child: const Text('View Details',
                      style: TextStyle(fontSize: 16)),
                ),
              ),
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
    final initialLatLng = widget.restaurants.isNotEmpty
        ? latlong2.LatLng(
            double.tryParse(widget.restaurants.first.latitude) ?? 0.0,
            double.tryParse(widget.restaurants.first.longitude) ?? 0.0,
          )
        : const latlong2.LatLng(0, 0);
    List<Marker> allMarkers = List.from(_restaurantMarkers);
    if (_userLocation != null) {
      allMarkers.add(
        Marker(
          point: _userLocation!,
          width: 32,
          height: 32,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
            width: 24,
            height: 24,
          ),
        ),
      );
    }
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLatLng,
              initialZoom: _currentZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              onPositionChanged: (pos, hasGesture) {
                setState(() {
                  _currentZoom = pos.zoom;
                  _mapCenter = pos.center;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.e_resta_app',
              ),
              MarkerLayer(markers: _restaurantMarkers),
              // User location marker (not clustered)
              if (_userLocation != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _userLocation!,
                    width: 32,
                    height: 32,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      width: 24,
                      height: 24,
                    ),
                  ),
                ]),
            ],
          ),
          // Top search bar overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search here...',
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF184C55)),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Color(0xFF184C55)),
                    onPressed: () {
                      // TODO: Implement filter action
                    },
                  ),
                ),
              ],
            ),
          ),
          // Zoom and recenter controls
          Positioned(
            bottom: 32,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'zoom_in',
                  mini: true,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'zoom_out',
                  mini: true,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'recenter',
                  mini: true,
                  onPressed: _recenter,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
