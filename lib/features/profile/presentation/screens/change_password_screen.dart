import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import 'package:e_resta_app/core/constants/api_endpoints.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _success = false;
    });
    try {
      final dio = Dio();
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      final response = await dio.post(
        ApiEndpoints.changePassword,
        data: {
          'current_password': _currentPasswordController.text.trim(),
          'new_password': _newPasswordController.text.trim(),
          'new_password_confirmation': _confirmPasswordController.text.trim(),
        },
        options: Options(headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        }),
      );
      setState(() {
        _isLoading = false;
        _success = true;
      });
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 28),
              ),
              const SizedBox(width: 10),
              const Text('Success'),
            ],
          ),
          content: const Text('Password changed successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      String errorMsg = 'An error occurred. Please try again.';
      if (e is DioException && e.response != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        } else if (data is Map && data['errors'] != null) {
          // Laravel-style validation errors
          final errors = data['errors'] as Map;
          errorMsg = errors.values
              .map((v) => v is List ? v.join('\n') : v.toString())
              .join('\n');
        }
      }
      setState(() {
        _isLoading = false;
        _error = errorMsg;
      });
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Current Password',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              TextFormField(
                controller: _currentPasswordController,
                obscureText: true,
                validator: (v) => v == null || v.isEmpty
                    ? 'Enter your current password'
                    : null,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Current password',
                  hintStyle: TextStyle(color: Color(0xFFB0B8C1)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'New Password',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              TextFormField(
                controller: _newPasswordController,
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter a new password';
                  if (v.length < 8)
                    return 'Password must be at least 8 characters';
                  return null;
                },
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'New password',
                  hintStyle: TextStyle(color: Color(0xFFB0B8C1)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Confirm New Password',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Confirm your new password';
                  if (v != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFF5F7FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  hintText: 'Confirm new password',
                  hintStyle: TextStyle(color: Color(0xFFB0B8C1)),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                ),
              ),
              const SizedBox(height: 32),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_success)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Password changed successfully!',
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                ),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF184C55),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
