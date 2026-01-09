import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  /// --- DATABASE LOGIC ---

  // 1. FORGOT PASSWORD LOGIC
  Future<void> _handleForgotPassword() async {
    final String email = _emailController.text.trim();

    if (email.isEmpty || !email.endsWith("@gmail.com")) {
      _showSnackBar("Please enter your @gmail.com address above first");
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121212),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("RESET PASSWORD",
            style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, letterSpacing: 1)),
        content: Text("We will send a password reset link to:\n$email",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CANCEL", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                _showSnackBar("Reset link sent! Check your inbox.");
              } on FirebaseAuthException catch (e) {
                _showSnackBar(e.message ?? "Error sending reset email");
              }
            },
            child: const Text("SEND LINK",
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 2. LOGIN LOGIC
  Future<void> _handleLogin() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Credentials cannot be empty");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // Navigation to Home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Login Failed";
      if (e.code == 'user-not-found') errorMessage = "No account found for this email";
      if (e.code == 'wrong-password') errorMessage = "Incorrect password";
      if (e.code == 'invalid-email') errorMessage = "Invalid email format";
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar("Check your internet connection");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryRed,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          _buildAmbientGlow(top: 100, right: -50, color: primaryRed.withOpacity(0.2)),
          _buildAmbientGlow(bottom: 150, left: -60, color: primaryRed.withOpacity(0.15)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  _buildHeader(),
                  const SizedBox(height: 50),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("EMAIL"),
                            _buildField(Icons.alternate_email_rounded, "you@gmail.com", _emailController),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildInputLabel("PASSWORD"),
                                GestureDetector(
                                  onTap: _handleForgotPassword,
                                  child: Text("FORGOT?",
                                      style: TextStyle(color: primaryRed, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                )
                              ],
                            ),
                            _buildPasswordField(),
                            const SizedBox(height: 30),
                            _isLoading
                                ? Center(child: CircularProgressIndicator(color: primaryRed))
                                : _buildLoginButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Not in the elite yet?", style: TextStyle(color: Colors.white38, fontSize: 15)),
                        TextButton(
                          onPressed: () => Navigator.pushNamed(context, '/signup'),
                          child: Text("Join Now", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI COMPONENTS ---
  Widget _buildField(IconData icon, String hint, TextEditingController controller) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white38, size: 20),
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
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), borderRadius: BorderRadius.circular(15)),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscureText,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white38, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 18),
            onPressed: () => setState(() => _obscureText = !_obscureText),
          ),
          hintText: "••••••••",
          hintStyle: const TextStyle(color: Colors.white24),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity, height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: primaryRed.withOpacity(0.4), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        child: const Text("ACCESS ACCOUNT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildAmbientGlow({double? top, double? bottom, double? left, double? right, required Color color}) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 220, height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle, color: color,
          boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 70, spreadRadius: 20)],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("WELCOME BACK", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 3)),
        Text("ONE PERCENT", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: 1,
            shadows: [Shadow(color: primaryRed.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 5))])),
      ],
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: TextStyle(color: primaryRed.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
    );
  }
}