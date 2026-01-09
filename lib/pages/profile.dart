import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Theme Colors
  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF121212);

  // --- FUNCTION: EDIT PROFILE BOTTOM SHEET ---
  // This updates specific user fields in Firestore in real-time
  void _showEditSheet(String field, String currentValue) {
    final TextEditingController _controller = TextEditingController(text: currentValue);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardGrey,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("UPDATE ${field.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                hintText: "Enter new $field",
                hintStyle: const TextStyle(color: Colors.white24),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed, minimumSize: const Size(double.infinity, 55)),
              onPressed: () async {
                String uid = FirebaseAuth.instance.currentUser!.uid;
                // Directly update the document using the specific field name
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  field.toLowerCase(): double.tryParse(_controller.text) ?? currentValue,
                });
                Navigator.pop(context);
              },
              child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser?.uid ?? "";

    return Scaffold(
      backgroundColor: darkBg,
      body: StreamBuilder<DocumentSnapshot>(
        // Use snapshots to ensure UI updates as soon as Firestore data changes
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.red));

          var userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          double weight = (userData['weight'] ?? 0.0).toDouble();
          double height = (userData['height'] ?? 0.0).toDouble();
          double bmi = (userData['bmi'] ?? 0.0).toDouble();
          String name = userData['name'] ?? "ATHLETE";

          return Stack(
            children: [
              _buildGlow(top: -100, right: -50, color: primaryRed.withOpacity(0.1)),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    children: [
                      const Text("MY PROFILE", style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 30),

                      // User Icon & Name Display
                      _buildProfileHeader(name),

                      const SizedBox(height: 30),

                      // Weight, Height, BMI Row using Firestore values
                      _buildGlassStatsRow(weight, height, bmi),

                      const SizedBox(height: 30),

                      _sectionHeader("ACCOUNT SETTINGS"),
                      const SizedBox(height: 15),

                      // Interative tiles to trigger the Edit Bottom Sheet
                      _buildSettingTile(Icons.monitor_weight_rounded, "Update Weight", "${weight}kg",
                          onTap: () => _showEditSheet("weight", weight.toString())),

                      _buildSettingTile(Icons.height_rounded, "Update Height", "${height.toInt()}cm",
                          onTap: () => _showEditSheet("height", height.toString())),

                      _buildSettingTile(Icons.notifications_active_rounded, "Notifications", "ON", onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notification settings updated")));
                      }),

                      const SizedBox(height: 30),

                      // LOGOUT ACTION: signs out of Firebase Auth
                      TextButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text("LOGOUT", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, letterSpacing: 2)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- UI HELPERS ---

  Widget _buildProfileHeader(String name) {
    return Column(
      children: [
        const CircleAvatar(radius: 50, backgroundColor: Color(0xFF1A1A1A), child: Icon(Icons.person, size: 50, color: Colors.white)),
        const SizedBox(height: 15),
        Text(name.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildGlassStatsRow(double w, double h, double b) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(w.toStringAsFixed(1), "WEIGHT"),
          _statItem(h.toInt().toString(), "HEIGHT"),
          _statItem(b.toStringAsFixed(1), "BMI"),
        ],
      ),
    );
  }

  Widget _statItem(String val, String label) {
    return Column(children: [
      Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSettingTile(IconData icon, String title, String trailing, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 22),
            const SizedBox(width: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(trailing, style: TextStyle(color: primaryRed, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Align(alignment: Alignment.centerLeft, child: Padding(
    padding: const EdgeInsets.only(left: 5, bottom: 5),
    child: Text(t, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
  ));

  Widget _buildGlow({double? top, double? right, required Color color}) {
    return Positioned(top: top, right: right, child: CircleAvatar(radius: 120, backgroundColor: color));
  }
}