import 'package:flutter/material.dart';
import '../home.dart';
import 'sign_up_page.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await AuthService.login(email, password);
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
        SnackBar(content: Text('Login failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
                  const SizedBox(height: 70),
                  Image.asset(
                    'assets/images/app_icon.png',
                    width: 110,
                    height: 110,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Log In',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212960),
                    ),
                  ),
                  const SizedBox(height: 42),
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
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 85,
                    height: 35,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD4BCE8), Color(0xFFC9AEE0)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Log in',
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
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
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF4F1F4),
          prefixIcon: Icon(icon, color: Colors.black),
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Montserrat',
            color: Color(0xFF212960),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
