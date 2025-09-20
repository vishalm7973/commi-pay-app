import 'package:commipay_app/src/features/auth/data/auth_service.dart';
import 'package:commipay_app/src/routing/app_router.dart';
import 'package:commipay_app/utils/token_storage.dart';
import 'package:flutter/material.dart';
import 'package:commipay_app/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;

  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // final email = _emailController.text.trim();
    // final password = _passwordController.text;

    final email = 'vishalmaurya7973@gmail.com';
    final password = 'RootAdmin.@7973';

    try {
      final token = await _authService.login(email, password);
      await TokenStorage.saveToken(token);
      Navigator.of(context).pushReplacementNamed(AppRouter.home);
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed. Please check your credentials.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    bool password = false,
  }) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: EdgeInsets.only(left: 0, right: 8),
        child: Icon(icon, size: 18, color: Colors.grey[500]),
      ),
      prefixIconConstraints: BoxConstraints(minWidth: 40, minHeight: 40),
      suffixIcon: password
          ? IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: Colors.grey[500],
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              splashRadius: 20,
              padding: EdgeInsets.zero,
            )
          : null,
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: Color(0xFF0070F3),
        ), // Focused blue underline
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign In',
                style: TextStyle(fontSize: 32, color: AppColors.darkTeal),
              ),
              SizedBox(height: 32),
              Text(
                'Email Address',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email Address', Icons.email),
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 18),
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[500],
                ),
              ),
              SizedBox(height: 5),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  'Password',
                  Icons.lock,
                  password: true,
                ),
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              SizedBox(height: 30),
              if (_errorMessage != null)
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          // backgroundColor: Color(0xFF0070F3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTeal,
                          ),
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
