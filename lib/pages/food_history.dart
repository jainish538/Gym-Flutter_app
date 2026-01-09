import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: const Text("30 DAY HISTORY", style: TextStyle(letterSpacing: 2, fontSize: 16))),
      body: ListView.builder(
        itemCount: 30, // Show last 30 days
        itemBuilder: (context, index) {
          // Calculate date for each row
          DateTime dateToShow = DateTime.now().subtract(Duration(days: index));
          String dateKey = DateFormat('yyyy-MM-dd').format(dateToShow);
          String displayDate = DateFormat('EEEE, MMM d').format(dateToShow);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('user_diary')
                .where('uid', isEqualTo: uid)
                .where('date', isEqualTo: dateKey)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();

              double totalKcal = 0;
              double totalPro = 0;
              for (var doc in snapshot.data!.docs) {
                totalKcal += (doc['kcal'] ?? 0);
                totalPro += (doc['protein'] ?? 0);
              }

              if (totalKcal == 0) return const SizedBox(); // Hide empty days

              return Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFF121212), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(displayDate, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text("${snapshot.data!.docs.length} Items Eaten", style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    ]),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text("${totalKcal.toInt()} kcal", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      Text("${totalPro.toInt()}g Protein", style: const TextStyle(color: Colors.green, fontSize: 12)),
                    ]),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}