import 'package:flutter/material.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _emailSent = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Blue header, flush to the top
            ClipPath(
              clipper: _TopAngleClipper(),
              child: Container(
                width: double.infinity,
                color: const Color(0xFFD6E9FF),
                padding: const EdgeInsets.only(
                    top: 80, left: 32, right: 32, bottom: 120),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      height: 48,
                      width: 48,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'The Resto',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Color(0xFF227C9D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Find Your Favorite Restaurant',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF227C9D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Card content
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                boxShadow: [],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24),
                child: _emailSent
                    ? _buildSuccessView(context)
                    : _buildResetForm(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            'Forgot Password',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: Color(0xFF227C9D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Text(
            'Email',
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v == null || !v.contains('@') ? 'Enter a valid email' : null,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: Color(0xFFF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              hintText: 'your email',
              hintStyle: TextStyle(color: Color(0xFFB0B8C1)),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF227C9D),
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
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Reset Link',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Remember your password? ',
                style: TextStyle(
                  color: Colors.black.withOpacity(0.6),
                  fontSize: 15,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF227C9D),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_outline,
          size: 80,
          color: Colors.green,
        ),
        const SizedBox(height: 24),
        Text(
          'Email Sent!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 28,
            color: Colors.green,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'We\'ve sent password reset instructions to your email address.',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B1623),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopAngleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 40);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
