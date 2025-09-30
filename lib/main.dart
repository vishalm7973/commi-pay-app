import 'package:flutter/material.dart';
import 'src/routing/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:commipay_app/utils/app_colors.dart';

// ✅ Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(CommiPayApp());
}

class CommiPayApp extends StatelessWidget {
  const CommiPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'CommiPay',
      theme: ThemeData(
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.caribbeanGreen,
          secondary: AppColors.vividBlue,
          surface: AppColors.lightGreen,
          error: AppColors.voidColor,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: AppColors.cyprus,
          onError: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: AppColors.darkTeal),
          bodyMedium: TextStyle(color: AppColors.darkTeal),
          labelLarge: TextStyle(color: AppColors.darkTeal),
          titleLarge: TextStyle(color: AppColors.darkTeal),
          displayLarge: TextStyle(color: AppColors.darkTeal),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.caribbeanGreen,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            textStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppColors.darkTeal,
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: AppColors.caribbeanGreen),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          labelStyle: TextStyle(color: AppColors.cyprus, fontFamily: 'Poppins'),
        ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
