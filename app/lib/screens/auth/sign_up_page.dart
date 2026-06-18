import 'package:flutter/material.dart';
import '../home.dart';
import 'login_page.dart';
import '../../services/auth_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.register(email, password, name);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(isFirstLaunch: false),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back_wallpaper.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 110,
                    height: 110,
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212960),
                    ),
                  ),
                  const SizedBox(height: 35),
                  _buildField(
                    controller: _nameController,
                    icon: Icons.person,
                    hint: 'Full Name',
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _emailController,
                    icon: Icons.email,
                    hint: 'Email',
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _passwordController,
                    icon: Icons.lock,
                    hint: 'Password',
                    obscure: true,
                  ),
                  const SizedBox(height: 18),
                  _buildField(
                    controller: _confirmController,
                    icon: Icons.lock,
                    hint: 'Confirm Password',
                    obscure: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 118,
                    height: 42,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4BCE8), Color(0xFFC9AEE0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _signUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    ),
                    child: const Text(
                      'Already have an account? Log in',
                      style: TextStyle(
                        fontFamily: 'Montserrat',
                        color: Color(0xFF785C9F),
                        decoration: TextDecoration.underline,
                        fontSize: 14,
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

  Widget _buildField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType:
            hint == 'Email' ? TextInputType.emailAddress : TextInputType.text,
        style: const TextStyle(
          fontFamily: 'Montserrat',
          color: Color(0xFF212960),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF4F1F4),
          prefixIcon: Icon(icon, color: Colors.black, size: 22),
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Montserrat',
            color: Color(0xFF212960),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Color(0xFF785C9F)),
          ),
        ),
      ),
    );
  }
}
