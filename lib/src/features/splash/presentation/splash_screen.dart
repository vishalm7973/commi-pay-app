import 'dart:async';
import 'package:commipay_app/utils/app_colors.dart';
import 'package:flutter/material.dart';
import '../../../routing/app_router.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate loading for 3 seconds then navigate to Login screen
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacementNamed(AppRouter.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final logoHeight = MediaQuery.of(context).size.height * 0.53;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: logoHeight,
              child: Image.asset(
                'assets/images/logo.png',
              ), // Update path as needed for asset folder
            ),
            Text(
              'COMMIPAY',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.darkTeal,
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
