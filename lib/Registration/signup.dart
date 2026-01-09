import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Theme Colors
  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  /// --- VALIDATION HELPERS ---

  bool _isValidGmail(String email) {
    return email.toLowerCase().endsWith('@gmail.com');
  }

  bool _isPasswordStrong(String password) {
    // Requirements: 8+ chars, 1 Uppercase, 1 Lowercase, 1 Number, 1 Special Char
    final passwordRegExp = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    return passwordRegExp.hasMatch(password);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// --- DATABASE & AUTH LOGIC ---

  Future<void> _registerUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1. Check for Empty Fields
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    // 2. Restrict to Gmail
    if (!_isValidGmail(email)) {
      _showSnackBar("Access Denied: You must use a @gmail.com address");
      return;
    }

    // 3. Enforce Strong Password
    if (!_isPasswordStrong(password)) {
      _showSnackBar("Weak Password: Need 8+ chars, Uppercase, Number & Symbol");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create Auth Account
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // 2. Create Firestore Document to store profile
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'targetWeight': 0, // Initial user data
      });

      if (mounted) Navigator.pushReplacementNamed(context, '/gym_registration');
    } on FirebaseAuthException catch (e) {
      // Handles common errors like "email-already-in-use"
      _showSnackBar(e.message ?? "Authentication Failed");
    } catch (e) {
      _showSnackBar("An unexpected error occurred");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
              top: 100,
              right: -50,
              child: _buildAmbientGlow(200, primaryRed.withOpacity(0.2))),
          Positioned(
              bottom: 200,
              left: -40,
              child: CircleAvatar(
                  radius: 100, backgroundColor: primaryRed.withOpacity(0.2))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 70),
                  _buildHeader(),
                  const SizedBox(height: 50),
                  _buildFormContainer(),
                  const SizedBox(height: 30),
                  _buildFooter(),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Become The", style: TextStyle(color: Colors.white54, fontSize: 18,fontFamily: 'bbr',fontWeight: FontWeight.bold, letterSpacing: 3)),
        Text("ONE PERCENT", style: TextStyle(color: Colors.white, fontSize: 48, fontFamily: 'bbr', letterSpacing: 1,
            shadows: [Shadow(color: primaryRed.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))])),
      ],
    );
  }


  Widget _buildFormContainer() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildField(Icons.person_outline, "Full Name", _nameController),
              const SizedBox(height: 20),
              _buildField(Icons.email_outlined, "Email Address (@gmail.com)", _emailController),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 40),
              _buildSignUpButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmbientGlow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: [
        BoxShadow(color: color.withOpacity(0.4), blurRadius: 50, spreadRadius: 10),
      ]),
    );
  }

  Widget _buildField(IconData icon, String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white38),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
          hintText: "Strong Password",
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: const Text("BEGIN JOURNEY",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Member of the elite?", style: TextStyle(color: Colors.white38)),
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text("LOG IN",
                style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}