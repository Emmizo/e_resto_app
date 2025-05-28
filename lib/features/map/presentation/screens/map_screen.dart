import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import 'package:latlong2/latlong.dart' as latlong2;

import '../../../home/presentation/screens/home_screen.dart';
import '../../../restaurant/data/models/restaurant_model.dart';
import '../../../restaurant/presentation/screens/restaurant_details_screen.dart';
import 'route_map_screen.dart';

String fixImageUrl(String url) {
  if (Platform.isAndroid) {
    return url.replaceFirst('localhost', '10.0.2.2');
  }
  return url;
}

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

  // Live search additions
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<RestaurantModel> _filteredRestaurants = [];

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
    _filteredRestaurants = List.from(widget.restaurants);
    _setRestaurantMarkers(_filteredRestaurants);
    _searchController.addListener(_onSearchChanged);
    
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim();
      if (_searchQuery.isEmpty) {
        _filteredRestaurants = List.from(widget.restaurants);
      } else {
        _filteredRestaurants = widget.restaurants
            .where((r) =>
                r.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
      _setRestaurantMarkers(_filteredRestaurants);
      // If only one match, center map on it
      if (_filteredRestaurants.length == 1) {
        final r = _filteredRestaurants.first;
        final lat = double.tryParse(r.latitude) ?? 0.0;
        final lng = double.tryParse(r.longitude) ?? 0.0;
        _mapController.move(latlong2.LatLng(lat, lng), _currentZoom);
      }
    });
  }

  Future<void> _initUserLocation() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _userLocation = latlong2.LatLng(position.latitude, position.longitude);
      });
      _setRestaurantMarkers(_filteredRestaurants);
      // Center map on user location
      _mapController.move(_userLocation!, _currentZoom);
    } catch (e) {
      // Could not get location, ignore for now
    }
  }

  void _setRestaurantMarkers(List<RestaurantModel> restaurants) {
    RestaurantModel? nearest;
    if (_userLocation != null && restaurants.isNotEmpty) {
      nearest = restaurants.reduce((a, b) {
        final aDist = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          double.tryParse(a.latitude) ?? 0.0,
          double.tryParse(a.longitude) ?? 0.0,
        );
        final bDist = Geolocator.distanceBetween(
          _userLocation!.latitude,
          _userLocation!.longitude,
          double.tryParse(b.latitude) ?? 0.0,
          double.tryParse(b.longitude) ?? 0.0,
        );
        return aDist < bDist ? a : b;
      });
    }
    _restaurantMarkers = restaurants
        .where((r) => r.latitude.isNotEmpty && r.longitude.isNotEmpty)
        .map((restaurant) {
      final isNearest = nearest != null && restaurant.id == nearest.id;
      return Marker(
        point: latlong2.LatLng(
          double.tryParse(restaurant.latitude) ?? 0.0,
          double.tryParse(restaurant.longitude) ?? 0.0,
        ),
        width: 48,
        height: 48,
        child: isNearest
            ? _BlinkingMarker(
                restaurant: restaurant,
                onTap: () => _showDistanceInfo(restaurant))
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _showDistanceInfo(restaurant),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF184C55),
                        width: 4,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: (restaurant.image != null &&
                              restaurant.image!.isNotEmpty)
                          ? NetworkImage(fixImageUrl(restaurant.image!))
                          : null,
                      child: (restaurant.image == null ||
                              restaurant.image!.isEmpty)
                          ? const Icon(Icons.restaurant,
                              color: Colors.teal, size: 24)
                          : null,
                    ),
                  ),
                ),
              ),
      );
    }).toList();
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
    if (!mounted) return;
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;

      final double userLat = position.latitude;
      final double userLng = position.longitude;
      final double restLat = double.tryParse(restaurant.latitude) ?? 0.0;
      final double restLng = double.tryParse(restaurant.longitude) ?? 0.0;
      final double distanceMeters =
          Geolocator.distanceBetween(userLat, userLng, restLat, restLng);
      final double distanceKm = distanceMeters / 1000.0;
      // Walking: ~5 km/h (divide meters by 83.33 for minutes)
      final int walkingMinutes = (distanceMeters / 83.33).round();
      // Driving: ~40 km/h (divide meters by 666.67 for minutes)
      final int drivingMinutes = (distanceMeters / 666.67).round();

      if (!mounted) return;
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
                      fixImageUrl(restaurant.image!),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              if (restaurant.image == null || restaurant.image!.isEmpty)
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      size: 40,
                      color: Colors.grey,
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
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.place, color: Colors.teal, size: 20),
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
                  const Icon(Icons.directions_walk,
                      color: Colors.orange, size: 20),
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
                  const Icon(Icons.directions_car,
                      color: Colors.blue, size: 20),
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
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    if (_userLocation != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RouteMapScreen(
                            userLocation: gmaps.LatLng(
                              _userLocation!.latitude,
                              _userLocation!.longitude,
                            ),
                            restaurantLocation: gmaps.LatLng(
                              double.tryParse(restaurant.latitude) ?? 0.0,
                              double.tryParse(restaurant.longitude) ?? 0.0,
                            ),
                            restaurantName: restaurant.name,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('User location not available.')),
                      );
                    }
                  },
                  child: const Text(
                    'Show Route',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('Error'),
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
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLatLng,
              initialZoom: _currentZoom,
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
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search here...',
                        prefixIcon:
                            Icon(Icons.search, color: Color(0xFF184C55)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
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

// Add this widget at the bottom of the file
class _BlinkingMarker extends StatefulWidget {
  final RestaurantModel restaurant;
  final VoidCallback onTap;
  const _BlinkingMarker({required this.restaurant, required this.onTap});

  @override
  State<_BlinkingMarker> createState() => _BlinkingMarkerState();
}

class _BlinkingMarkerState extends State<_BlinkingMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 0.4).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restaurant = widget.restaurant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.withValues(alpha: _animation.value),
                width: 5,
              ),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              backgroundImage:
                  (restaurant.image != null && restaurant.image!.isNotEmpty)
                      ? NetworkImage(fixImageUrl(restaurant.image!))
                      : null,
              child: (restaurant.image == null || restaurant.image!.isEmpty)
                  ? const Icon(Icons.restaurant, color: Colors.teal, size: 24)
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
