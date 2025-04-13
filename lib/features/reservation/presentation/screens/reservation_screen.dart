import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
    final timeParts = (json['time'] as String).split(':');
    return Reservation(
      id: json['id'],
      date: DateTime.parse(json['date']),
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

  const ReservationScreen({
    super.key,
    this.restaurantName = 'Restaurant Name',
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

  Future<void> _submitReservation() async {
    if (_formKey.currentState!.validate()) {
      try {
        final reservationProvider = context.read<ReservationProvider>();
        final reservation = Reservation(
          id: const Uuid().v4(),
          date: _selectedDate,
          time: _selectedTime,
          guests: _selectedGuests,
          name: _nameController.text,
          phone: _phoneController.text,
          notes: _notesController.text,
          restaurantName: widget.restaurantName!,
        );

        await reservationProvider.addReservation(reservation);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reservation confirmed!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Make a Reservation'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: 'Select Date',
                  icon: Icons.calendar_today,
                ).animate().fadeIn().slideX(),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
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
                          DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms).slideX(),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Select Time',
                  icon: Icons.access_time,
                ).animate().fadeIn(delay: 400.ms).slideX(),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectTime(context),
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
                          _selectedTime.format(context),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideX(),
                const SizedBox(height: 24),
                _SectionTitle(
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
                          if (_selectedGuests > 1) {
                            setState(() => _selectedGuests--);
                          }
                        },
                      ),
                      Expanded(
                        child: Text(
                          '$_selectedGuests guests',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_selectedGuests < 10) {
                            setState(() => _selectedGuests++);
                          }
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1000.ms).slideX(),
                const SizedBox(height: 24),
                _SectionTitle(
                  title: 'Contact Information',
                  icon: Icons.person,
                ).animate().fadeIn(delay: 1200.ms).slideX(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
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
                  controller: _phoneController,
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
                _SectionTitle(
                  title: 'Additional Notes',
                  icon: Icons.note,
                ).animate().fadeIn(delay: 1800.ms).slideX(),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
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
                    onPressed: _submitReservation,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm Reservation'),
                  ),
                ).animate().fadeIn(delay: 2200.ms).slideY(),
              ],
            ),
          ),
        ),
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
