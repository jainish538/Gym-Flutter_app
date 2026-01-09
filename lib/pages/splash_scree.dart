import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    // 1. Remove the Native Splash immediately
    FlutterNativeSplash.remove();

    // 2. Let the animation play for 3 seconds
    await Future.delayed(const Duration(milliseconds: 3000));

    // 3. Go to Signup/Login
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your Lottie Animation File
            Lottie.asset(
              'assets/Lifestyle of when weighing gym.json', // Path to your Lottie file
              width: 250,
              height: 250,
              fit: BoxFit.fill,
            ),
            const SizedBox(height: 20),
            const Text(
              "ONE PERCENT",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}