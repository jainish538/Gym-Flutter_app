import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:device_preview/device_preview.dart';
import 'package:one_percent_improve/Botto_nav.dart';
import 'package:one_percent_improve/Registration/login.dart';
import 'package:one_percent_improve/Registration/signup.dart';
import 'package:one_percent_improve/Registration/user_data.dart';
import 'package:one_percent_improve/pages/splash_scree.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();

  runApp(
    DevicePreview(
      enabled: false,
      builder: (context) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      title: 'One Percent Better',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF0000),
          brightness: Brightness.dark,
        ),
      ),
      // Use home with StreamBuilder instead of initialRoute for Auth
      home: const AuthWrapper(),

      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/signup': page = const SignUpPage(); break;
          case '/login': page = const LoginPage(); break;
          case '/gym_registration': page = const GymOnboarding(); break;
          case '/home': page = const MainLayout(); break;
          default: page = const SignUpPage();
        }
        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }
}

// THE FIX: This widget decides which page to show based on Firebase Auth State
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // While checking auth state, keep the splash screen visible
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(backgroundColor: Colors.black);
        }

        // Once we have a result, remove the native splash
        FlutterNativeSplash.remove();

        if (snapshot.hasData) {
          // User is logged in
          return const MainLayout();
        } else {
          // User is NOT logged in
          return const SignUpPage();
        }
      },
    );
  }
}