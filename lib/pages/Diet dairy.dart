import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DietDiaryPage extends StatelessWidget {
  const DietDiaryPage({super.key});

  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF121212);

  // --- LOGIC: REMOVE FOOD ITEM (STRICT SYNC) ---
  Future<void> _removeFoodItem(BuildContext context, String docId, Map<String, dynamic> item) async {
    try {
      // 1. We must ensure the item values match the database types exactly for arrayRemove to work.
      // Firestore is sensitive to int vs double.
      await FirebaseFirestore.instance.collection('user_diary').doc(docId).update({
        // Remove the exact object from the list
        'foodList': FieldValue.arrayRemove([item]),

        // Subtract ALL macro values using negative increments
        // .toDouble() ensures we don't have type conflicts during the math operation
        'totalKcal': FieldValue.increment(-(item['kcal'] ?? 0).toDouble()),
        'totalProtein': FieldValue.increment(-(item['protein'] ?? 0).toDouble()),
        'totalCarbs': FieldValue.increment(-(item['carbs'] ?? 0).toDouble()),
        'totalFats': FieldValue.increment(-(item['fats'] ?? 0).toDouble()),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${item['name']} removed"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String docId = "${uid}_$today";

    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          Positioned(
            top: -50,
            left: -50,
            child: CircleAvatar(radius: 100, backgroundColor: primaryRed.withOpacity(0.05)),
          ),
          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('user_diary').doc(docId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                }

                // Initialize defaults to 0 if document doesn't exist yet
                var data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                List meals = data['foodList'] ?? [];

                // Strict parsing to avoid null/type errors in the Summary UI
                double kcal = (data['totalKcal'] ?? 0).toDouble();
                double pro = (data['totalProtein'] ?? 0).toDouble();
                double carb = (data['totalCarbs'] ?? 0).toDouble();
                double fat = (data['totalFats'] ?? 0).toDouble();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text("TODAY'S DIARY",
                          style: TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ),

                    // UI Summary with all 4 cleaned macros
                    _buildDailySummary(kcal.toInt(), pro, carb, fat),

                    const SizedBox(height: 20),

                    Expanded(
                      child: meals.isEmpty
                          ? const Center(child: Text("No meals logged yet", style: TextStyle(color: Colors.white38)))
                          : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                        itemCount: meals.length,
                        itemBuilder: (context, index) {
                          // Important: We cast to Map<String, dynamic> for the logic function
                          var item = Map<String, dynamic>.from(meals[index]);
                          return _buildMealTile(context, item, docId);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(int kcal, double p, double c, double f) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardGrey,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Column(
        children: [
          _summaryRow("TOTAL CALORIES", "$kcal kcal", primaryRed),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _macroItem("${p.toStringAsFixed(1)}g", "Protein", Colors.green),
              _macroItem("${c.toStringAsFixed(1)}g", "Carbs", Colors.blue),
              _macroItem("${f.toStringAsFixed(1)}g", "Fats", Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMealTile(BuildContext context, Map<String, dynamic> item, String docId) {
    return Dismissible(
      key: UniqueKey(), // Use UniqueKey to prevent list sync issues after deletion
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _removeFoodItem(context, docId, item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardGrey,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? "Unknown",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(
                    "P: ${item['protein']}g | C: ${item['carbs']}g | F: ${item['fats']}g",
                    style: const TextStyle(color: Colors.white38, fontSize: 11)
                ),
              ],
            ),
            const Spacer(),
            Text("${item['kcal']} kcal",
                style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
            IconButton(
              onPressed: () => _removeFoodItem(context, docId, item),
              icon: const Icon(Icons.close_rounded, color: Colors.white24, size: 18),
            )
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _macroItem(String value, String label, Color col) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: col, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}