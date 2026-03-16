import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../auth/login.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Text(
          "WorkByte",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 40,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
