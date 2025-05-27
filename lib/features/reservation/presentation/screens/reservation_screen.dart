import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/services/database_helper.dart';
import '../../../auth/domain/providers/auth_provider.dart';

class Reservation {
  final String id;
  final DateTime date;
  final TimeOfDay time;
  final int guests;
  final String name;
  final String phone;
  final String notes;
  final String restaurantName;

  Reservation({
    required this.id,
    required this.date,
    required this.time,
    required this.guests,
    required this.name,
    required this.phone,
    required this.notes,
    required this.restaurantName,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': '${time.hour}:${time.minute}',
      'guests': guests,
      'name': name,
      'phone': phone,
      'notes': notes,
      'restaurantName': restaurantName,
    };
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final timeParts = (json['reservation_time'] as String).split(':');
    return Reservation(
      id: json['id'].toString(),
      date: DateTime.parse(json['reservation_time']),
      time: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      guests: json['guests'],
      name: json['name'],
      phone: json['phone'],
      notes: json['notes'],
      restaurantName: json['restaurantName'],
    );
  }
}

class ReservationProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  static const String _reservationsKey = 'reservations';
  List<Reservation> _reservations = [];

  ReservationProvider(this._prefs) {
    _loadReservations();
  }

  List<Reservation> get reservations => List.unmodifiable(_reservations);

  void _loadReservations() {
    final reservationsJson = _prefs.getString(_reservationsKey);
    if (reservationsJson != null) {
      final List<dynamic> reservationsList = json.decode(reservationsJson);
      _reservations =
          reservationsList.map((item) => Reservation.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveReservations() async {
    final reservationsJson =
        json.encode(_reservations.map((item) => item.toJson()).toList());
    await _prefs.setString(_reservationsKey, reservationsJson);
  }

  Future<void> addReservation(Reservation reservation) async {
    _reservations.add(reservation);
    await _saveReservations();
    notifyListeners();
  }

  Future<void> removeReservation(String id) async {
    _reservations.removeWhere((reservation) => reservation.id == id);
    await _saveReservations();
    notifyListeners();
  }
}

class ReservationScreen extends StatefulWidget {
  final String? restaurantName;
  final int? restaurantId;

  const ReservationScreen({
    super.key,
    this.restaurantName = 'Restaurant Name',
    this.restaurantId,
  });

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _selectedGuests = 2;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Auto-fill from logged-in user
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user != null) {
      _nameController.text = '${user.firstName} ${user.lastName}';
      _phoneController.text =
          user.phoneNumber; // Using email as contact for now
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _submitReservation([BuildContext? parentContext]) async {
    final ctx = parentContext ?? context;
    final authProvider = Provider.of<AuthProvider>(ctx, listen: false);
    final token = authProvider.token;
    final isOnline =
        Provider.of<ConnectivityProvider>(ctx, listen: false).isOnline;
    if (token == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to make a reservation.'),
          backgroundColor: Colors.red,
        ),
      );
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.of(ctx).pushReplacementNamed('/login');
      });
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });
      try {
        final int restaurantId = widget.restaurantId ?? 1;
        final reservationTime = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
        final data = {
          'restaurant_id': restaurantId,
          'reservation_time': reservationTime
              .toIso8601String()
              .replaceFirst('T', ' ')
              .substring(0, 19),
          'number_of_guests': _selectedGuests,
          'phone_number': _phoneController.text,
          'special_requests': _notesController.text,
        };
        if (!isOnline) {
          // Queue the reservation in SQLite
          final db = await DatabaseHelper().db;
          await Future.delayed(Duration.zero);
          if (!mounted) return;
          await db.insert('action_queue', {
            'actionType': 'make_reservation',
            'payload': jsonEncode(data),
            'createdAt': DateTime.now().toIso8601String(),
          });
          await showDialog(
            context: ctx,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.wifi_off,
                        color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Reservation Queued!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                  'Your reservation will be submitted when you are back online.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(ctx).maybePop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          if (!mounted) return;
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
        final dio = Dio();

        final response = await dio.post(
          '${ApiConfig.baseUrl}/reservations',
          data: data,
          options: Options(
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          ),
        );
        await Future.delayed(Duration.zero);
        if (!mounted) return;

        if (response.statusCode == 200 || response.statusCode == 201) {
          await showDialog(
            context: ctx,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.check_circle,
                        color: Colors.green, size: 28),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Reservation Confirmed!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text('Your reservation has been confirmed.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(ctx).maybePop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception(
              'Failed to make reservation: ${response.statusMessage}');
        }
      } catch (e) {
        String errorMsg = 'An error occurred. Please try again.';
        if (e is DioException && e.response != null) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          } else if (data is Map && data['errors'] != null) {
            final errors = data['errors'] as Map;
            errorMsg = errors.values
                .map((v) => v is List ? v.join('\n') : v.toString())
                .join('\n');
          }
        }
        if (!mounted) return;
        await showDialog(
          context: ctx,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.error_outline,
                      color: Colors.red, size: 28),
                ),
                const SizedBox(width: 10),
                const Text('Error'),
              ],
            ),
            content: Text(errorMsg),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } finally {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.watch<ConnectivityProvider>().isOnline;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make a Reservation'),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _ReservationForm(
                formKey: _formKey,
                nameController: _nameController,
                phoneController: _phoneController,
                notesController: _notesController,
                selectedDate: _selectedDate,
                selectedTime: _selectedTime,
                selectedGuests: _selectedGuests,
                isSubmitting: _isSubmitting,
                onSelectDate: () => _selectDate(context),
                onSelectTime: () => _selectTime(context),
                onGuestsChanged: (int guests) =>
                    setState(() => _selectedGuests = guests),
                onSubmit: !_isSubmitting && isOnline
                    ? () => _submitReservation(context)
                    : () {
                        if (!isOnline) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'No internet connection. Please try again later.'),
                            ),
                          );
                        }
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ReservationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int selectedGuests;
  final bool isSubmitting;
  final VoidCallback onSelectDate;
  final VoidCallback onSelectTime;
  final ValueChanged<int> onGuestsChanged;
  final VoidCallback? onSubmit;

  const _ReservationForm({
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.notesController,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedGuests,
    required this.isSubmitting,
    required this.onSelectDate,
    required this.onSelectTime,
    required this.onGuestsChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Select Date',
            icon: Icons.calendar_today,
          ).animate().fadeIn().slideX(),
          const SizedBox(height: 8),
          InkWell(
            onTap: onSelectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 16),
                  Text(
                    DateFormat('EEEE, MMMM d, y').format(selectedDate),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 200.ms).slideX(),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Select Time',
            icon: Icons.access_time,
          ).animate().fadeIn(delay: 400.ms).slideX(),
          const SizedBox(height: 8),
          InkWell(
            onTap: onSelectTime,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 16),
                  Text(
                    selectedTime.format(context),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 600.ms).slideX(),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Number of Guests',
            icon: Icons.people,
          ).animate().fadeIn(delay: 800.ms).slideX(),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (selectedGuests > 1) {
                      onGuestsChanged(selectedGuests - 1);
                    }
                  },
                ),
                Expanded(
                  child: Text(
                    '$selectedGuests guests',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (selectedGuests < 10) {
                      onGuestsChanged(selectedGuests + 1);
                    }
                  },
                ),
              ],
            ),
          ).animate().fadeIn(delay: 1000.ms).slideX(),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Contact Information',
            icon: Icons.person,
          ).animate().fadeIn(delay: 1200.ms).slideX(),
          const SizedBox(height: 8),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Full Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ).animate().fadeIn(delay: 1400.ms).slideX(),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ).animate().fadeIn(delay: 1600.ms).slideX(),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: 'Additional Notes',
            icon: Icons.note,
          ).animate().fadeIn(delay: 1800.ms).slideX(),
          const SizedBox(height: 8),
          TextFormField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Any special requests?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ).animate().fadeIn(delay: 2000.ms).slideX(),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF227C9D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Confirm Reservation'),
            ),
          ).animate().fadeIn(delay: 2200.ms).slideY(),
        ],
      ),
    );
  }
}
