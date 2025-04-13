import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'reservation_screen.dart';

class MyReservationsScreen extends StatelessWidget {
  const MyReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reservations'),
      ),
      body: Consumer<ReservationProvider>(
        builder: (context, reservationProvider, child) {
          final reservations = reservationProvider.reservations;

          if (reservations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reservations yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make a reservation to see it here',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ).animate().fadeIn();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return _ReservationCard(
                reservation: reservation,
                onDelete: () {
                  _showDeleteConfirmation(context, reservation);
                },
              ).animate(delay: (100 * index).ms).fadeIn().slideX();
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Reservation reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Text(
          'Are you sure you want to cancel your reservation at ${reservation.restaurantName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              context
                  .read<ReservationProvider>()
                  .removeReservation(reservation.id);
              Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  reservation.restaurantName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              icon: Icons.calendar_today,
              label: 'Date',
              value: DateFormat('EEEE, MMMM d, y').format(reservation.date),
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              icon: Icons.access_time,
              label: 'Time',
              value: reservation.time.format(context),
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              icon: Icons.people,
              label: 'Guests',
              value: '${reservation.guests}',
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              icon: Icons.person,
              label: 'Name',
              value: reservation.name,
            ),
            const SizedBox(height: 8),
            _ReservationInfoRow(
              icon: Icons.phone,
              label: 'Phone',
              value: reservation.phone,
            ),
            if (reservation.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              _ReservationInfoRow(
                icon: Icons.note,
                label: 'Notes',
                value: reservation.notes,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReservationInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ReservationInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
