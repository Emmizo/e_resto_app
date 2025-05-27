import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/database_helper.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  final List<String> _statuses = [
    'pending',
    'confirmed',
    'cancelled',
    'completed',
  ];
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  List<Reservation> _reservations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statuses.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fetchReservations(_statuses[0]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    _fetchReservations(_statuses[_tabController.index]);
  }

  Future<void> _fetchReservations(String status) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _reservations = [];
    });
    if (!mounted) return;
    try {
      final dio = Dio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await dio.get(
        ApiEndpoints.reservations,
        queryParameters: {'status': status},
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      final data = response.data['data'] as List;
      setState(() {
        _reservations = data.map((json) => Reservation.fromJson(json)).toList();
        _isLoading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reservations loaded successfully!'),
          backgroundColor: Colors.green.withValues(alpha: 0.7),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load reservations';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load reservations: $e'),
          backgroundColor: Colors.red.withValues(alpha: 0.7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: _statuses
              .map((status) =>
                  Tab(text: status[0].toUpperCase() + status.substring(1)))
              .toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We couldn\'t load your reservations. Please try again later.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            _fetchReservations(_statuses[_tabController.index]),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No Reservations Found',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "You haven't made any reservations yet.",
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: _statuses.map((status) {
                        if (_statuses[_tabController.index] != status) {
                          return const SizedBox.shrink();
                        }
                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _reservations.length,
                          itemBuilder: (context, index) {
                            final reservation = _reservations[index];
                            return _ReservationCard(
                              reservation: reservation,
                              onDelete: () {
                                _showDeleteConfirmation(context, reservation);
                              },
                            )
                                .animate(delay: (100 * index).ms)
                                .fadeIn()
                                .slideX();
                          },
                        );
                      }).toList(),
                    ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Reservation reservation) {
    final isOnline =
        Provider.of<ConnectivityProvider>(context, listen: false).isOnline;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Text(
          'Are you sure you want to cancel your reservation at \\${reservation.restaurant.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (!isOnline) {
                // Queue the cancel action in SQLite
                final db = await DatabaseHelper().db;
                await db.insert('action_queue', {
                  'actionType': 'cancel_reservation',
                  'payload': '{"id": ${reservation.id}}',
                  'createdAt': DateTime.now().toIso8601String(),
                });
                await Future.delayed(Duration.zero);
                if (!mounted) return;
                setState(() {
                  _reservations.removeWhere((r) => r.id == reservation.id);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reservation will be cancelled when online'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              // ... existing code ...
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Reservation cancelled'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final Reservation reservation;
  final VoidCallback onDelete;

  const _ReservationCard({
    required this.reservation,
    required this.onDelete,
  });

  Color _statusColor(String status, BuildContext context) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: reservation.restaurant.image != null &&
                      reservation.restaurant.image!.isNotEmpty
                  ? Image.network(
                      fixImageUrl(reservation.restaurant.image!),
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 72,
                      height: 72,
                      color: Colors.grey[200],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Tooltip(
                          message: reservation.restaurant.name,
                          child: Text(
                            reservation.restaurant.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 17,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(reservation.status, context)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          reservation.status[0].toUpperCase() +
                              reservation.status.substring(1),
                          style: TextStyle(
                            color: _statusColor(reservation.status, context),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Tooltip(
                    message: reservation.restaurant.address,
                    child: Text(
                      reservation.restaurant.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final dateTimeRow = Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: DateFormat('EEE, MMM d, yyyy')
                                .format(reservation.reservationTime),
                            child: Text(
                              DateFormat('EEE, MMM d, yyyy')
                                  .format(reservation.reservationTime),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: DateFormat('hh:mm a')
                                .format(reservation.reservationTime),
                            child: Text(
                              DateFormat('hh:mm a')
                                  .format(reservation.reservationTime),
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                      final guestsPhoneRow = Row(
                        children: [
                          Icon(Icons.people, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: '${reservation.numberOfPeople} guests',
                            child: Text(
                              '${reservation.numberOfPeople} guests',
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: reservation.phoneNumber,
                            child: Text(
                              reservation.phoneNumber,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                      return Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: dateTimeRow,
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: guestsPhoneRow,
                          ),
                        ],
                      );
                    },
                  ),
                  if (reservation.specialRequests.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Tooltip(
                            message: reservation.specialRequests,
                            child: Text(
                              reservation.specialRequests,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Only show cancel icon if status is pending
            if (reservation.status == 'pending')
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
                color: Colors.red,
                tooltip: 'Cancel Reservation',
              ),
          ],
        ),
      ),
    );
  }
}

class Reservation {
  final int id;
  final String status;
  final DateTime reservationTime;
  final int numberOfPeople;
  final String phoneNumber;
  final String specialRequests;
  final Restaurant restaurant;

  Reservation({
    required this.id,
    required this.status,
    required this.reservationTime,
    required this.numberOfPeople,
    required this.phoneNumber,
    required this.specialRequests,
    required this.restaurant,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      status: json['status'],
      reservationTime: DateTime.parse(json['reservation_time']),
      numberOfPeople: json['number_of_people'],
      phoneNumber: json['phone_number'],
      specialRequests: json['special_requests'] ?? '',
      restaurant: Restaurant.fromJson(json['restaurant']),
    );
  }
}

class Restaurant {
  final int id;
  final String name;
  final String address;
  final String? image;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.image,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      image: json['image'],
    );
  }
}

String fixImageUrl(String url) {
  if (Platform.isAndroid) {
    return url.replaceFirst('localhost', '10.0.2.2');
  }
  return url;
}
