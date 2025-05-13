import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/providers/auth_provider.dart';
import '../../../home/presentation/screens/main_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.signup(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
    );
    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MainScreen(initialIndex: 0)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authProvider.error ?? 'Sign up failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.zero,
              boxShadow: [],
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top angled blue section
                  ClipPath(
                    clipper: _TopAngleClipper(),
                    child: Container(
                      width: double.infinity,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.12),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Find Your Favorite Restaurant',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Sign Up',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'First Name',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          TextFormField(
                            controller: _firstNameController,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your first name'
                                : null,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                      .inputDecorationTheme
                                      .fillColor ??
                                  Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'First Name',
                              hintStyle: Theme.of(context)
                                  .inputDecorationTheme
                                  .hintStyle,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Last Name',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          TextFormField(
                            controller: _lastNameController,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your last name'
                                : null,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                      .inputDecorationTheme
                                      .fillColor ??
                                  Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Last Name',
                              hintStyle: Theme.of(context)
                                  .inputDecorationTheme
                                  .hintStyle,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Email',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => v == null || !v.contains('@')
                                ? 'Enter a valid email'
                                : null,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                      .inputDecorationTheme
                                      .fillColor ??
                                  Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Email',
                              hintStyle: Theme.of(context)
                                  .inputDecorationTheme
                                  .hintStyle,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Phone Number',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Enter your phone number'
                                : null,
                            style: Theme.of(context).textTheme.bodyLarge,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Theme.of(context)
                                      .inputDecorationTheme
                                      .fillColor ??
                                  Theme.of(context).cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              hintText: 'Your Phone Number',
                              hintStyle: Theme.of(context)
                                  .inputDecorationTheme
                                  .hintStyle,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16, horizontal: 16),
                            ),
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed:
                                  Provider.of<AuthProvider>(context).isLoading
                                      ? null
                                      : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Sign Up',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFDFE6F1),
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'Or continue with',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Colors.black.withOpacity(0.5),
                                      ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: Color(0xFFDFE6F1),
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Image.asset('assets/icons/google.png',
                                      height: 20),
                                  label: const Text('Google',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: const BorderSide(
                                        color: Color(0xFFDFE6F1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: Image.asset('assets/icons/facebook.png',
                                      height: 20),
                                  label: const Text('Facebook',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15)),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    side: const BorderSide(
                                        color: Color(0xFFDFE6F1)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {},
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.black.withOpacity(0.6),
                                    ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pushReplacementNamed(
                                      context, '/login');
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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

class _SocialButton extends StatelessWidget {
  final Widget icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF232A38) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
