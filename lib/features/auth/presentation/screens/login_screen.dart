import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'forgot_password_screen.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../home/presentation/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoginMode = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String? fcmToken;
    try {
      fcmToken = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      fcmToken = null;
    }
    if (_isLoginMode) {
      final success = await authProvider.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        fcmToken: fcmToken,
      );
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Login failed'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } else {
      final success = await authProvider.signup(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        fcmToken: fcmToken,
      );
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authProvider.error ?? 'Sign up failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    // Logo
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFFFFF),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 100,
                        ),
                      ),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 40),
                    // Welcome Text
                    Text(
                      _isLoginMode ? 'Welcome Back!' : 'Create Account',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF184C55),
                              ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 200.ms).slideY(),
                    const SizedBox(height: 8),
                    Text(
                      _isLoginMode
                          ? 'Sign in to continue'
                          : 'Sign up to get started',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms).slideY(),
                    const SizedBox(height: 40),
                    if (!_isLoginMode) ...[
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'First Name',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your first name';
                          }
                          return null;
                        },
                        delay: 350,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        prefixIcon: Icons.person,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your last name';
                          }
                          return null;
                        },
                        delay: 360,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Email Field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      delay: 400,
                    ),
                    const SizedBox(height: 16),
                    // Password Field
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (!_isLoginMode && value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      delay: 500,
                    ),
                    // Confirm Password Field (Sign Up only)
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Confirm Password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: !_isPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                        delay: 600,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your phone number';
                          }
                          return null;
                        },
                        delay: 650,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address',
                        prefixIcon: Icons.location_on,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your address';
                          }
                          return null;
                        },
                        delay: 700,
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Forgot Password (Login only)
                    if (_isLoginMode)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ForgotPasswordScreen(),
                              ),
                            );
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 24),
                    // Sign In/Up Button
                    ElevatedButton(
                      onPressed: authProvider.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _isLoginMode ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms).slideY(),
                    const SizedBox(height: 32),
                    // Divider with "Or continue with" text
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Or continue with',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 32),
                    // Social Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialLoginButton(
                          icon: Icons.g_mobiledata,
                          onPressed: () {
                            // Handle Google login
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialLoginButton(
                          icon: Icons.facebook,
                          onPressed: () {
                            // Handle Facebook login
                          },
                        ),
                        const SizedBox(width: 16),
                        _SocialLoginButton(
                          icon: Icons.code,
                          onPressed: () {
                            // Handle GitHub login
                          },
                        ),
                      ],
                    ).animate().fadeIn(delay: 900.ms).slideY(),
                    const SizedBox(height: 32),
                    // Toggle between Login and Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isLoginMode
                              ? "Don't have an account? "
                              : "Already have an account? ",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        TextButton(
                          onPressed: _toggleAuthMode,
                          child: Text(
                            _isLoginMode ? 'Sign Up' : 'Sign In',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF184C55),
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int delay = 0,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Color(0xFFFFFFFF),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    ).animate().fadeIn(delay: delay.ms).slideX();
  }
}

class _SocialLoginButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Icon(
              icon,
              size: 24,
              color: Color(0xFF184C55),
            ),
          ),
        ),
      ),
    );
  }
}
