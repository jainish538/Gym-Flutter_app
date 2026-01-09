import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF121212);

  // --- LOGIC: PICK & SAVE IMAGE ---
  Future<void> _pickImage(String label) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image == null) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      // Storing local path. Note: For production, you'd upload to Firebase Storage
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'photos': { label.toLowerCase(): image.path }
      }, SetOptions(merge: true));

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- LOGIC: CHALLENGE STREAK ---
  int _calculateChallengeStreak(List<QueryDocumentSnapshot> diaries) {
    if (diaries.isEmpty) return 0;

    List<DateTime> loggedDates = diaries.map((doc) {
      return DateFormat('yyyy-MM-dd').parse(doc.id.split('_').last);
    }).toList();
    loggedDates.sort((a, b) => b.compareTo(a));

    DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    DateTime lastLoggedDate = loggedDates.first;

    if (today.difference(lastLoggedDate).inDays > 1) return 0;

    int streak = 0;
    for (int i = 0; i < loggedDates.length; i++) {
      if (i == 0) { streak++; continue; }
      if (loggedDates[i-1].difference(loggedDates[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: darkBg,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.red));

          var userData = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
          double currentWeight = (userData['weight'] ?? 0.0).toDouble();
          Map photos = userData['photos'] ?? {};

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('weight_entries')
                .where('uid', isEqualTo: uid)
                .orderBy('timestamp', descending: true)
                .limit(7)
                .snapshots(),
            builder: (context, weightSnapshot) {
              List<double> graphPoints = [currentWeight, currentWeight];
              if (weightSnapshot.hasData && weightSnapshot.data!.docs.isNotEmpty) {
                graphPoints = weightSnapshot.data!.docs
                    .map((doc) => (doc['weight'] as num).toDouble())
                    .toList()
                    .reversed
                    .toList();
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('user_diary')
                    .where('uid', isEqualTo: uid)
                    .snapshots(),
                builder: (context, diarySnapshot) {
                  int streak = 0;
                  if (diarySnapshot.hasData) streak = _calculateChallengeStreak(diarySnapshot.data!.docs);

                  return CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      _buildHeader(),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              _sectionHeader("60-DAY ELITE CHALLENGE"),
                              const SizedBox(height: 15),
                              _buildChallengeCard(streak),
                              const SizedBox(height: 30),
                              _sectionHeader("WEIGHT ANALYTICS"),
                              const SizedBox(height: 15),
                              _buildWeightChart(currentWeight, graphPoints),
                              const SizedBox(height: 30),
                              _sectionHeader("PROGRESS PHOTOS"),
                              const SizedBox(height: 15),
                              Row(
                                children: [
                                  _buildPhotoTile("Day 1", photos['day 1'], Colors.white24),
                                  const SizedBox(width: 15),
                                  _buildPhotoTile("Day 60", photos['day 60'], primaryRed),
                                ],
                              ),
                              const SizedBox(height: 120),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  // --- UI: CHALLENGE CARD ---
  Widget _buildChallengeCard(int day) {
    double progress = (day / 60).clamp(0.0, 1.0);
    bool isReset = day == 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(25), border: Border.all(color: isReset ? Colors.orange.withOpacity(0.3) : primaryRed.withOpacity(0.3))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(isReset ? "STREAK BROKEN" : "CHALLENGE PROGRESS", style: TextStyle(color: isReset ? Colors.orange : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
            Text(isReset ? "RESET TO DAY 1" : "DAY $day OF 60", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          ]),
          Icon(isReset ? Icons.history_rounded : Icons.bolt, color: isReset ? Colors.orange : primaryRed, size: 30),
        ]),
        const SizedBox(height: 20),
        ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: progress, minHeight: 12, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(isReset ? Colors.orange : primaryRed))),
      ]),
    );
  }

  // --- UI: PHOTO TILES ---
  Widget _buildPhotoTile(String label, String? localPath, Color color) {
    bool hasFile = localPath != null && File(localPath).existsSync();
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickImage(label),
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: cardGrey, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            image: hasFile ? DecorationImage(image: FileImage(File(localPath!)), fit: BoxFit.cover) : null,
          ),
          child: !hasFile ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo_rounded, color: color, size: 30), const SizedBox(height: 10), Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold))]) : null,
        ),
      ),
    );
  }

  // --- UI: WEIGHT CHART ---
  Widget _buildWeightChart(double current, List<double> points) {
    return Container(
      height: 220, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(25)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("CURRENT WEIGHT", style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        Text("${current.toStringAsFixed(1)} kg", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Spacer(),
        SizedBox(height: 100, width: double.infinity, child: CustomPaint(painter: WeightChartPainter(points, primaryRed))),
      ]),
    );
  }

  Widget _buildHeader() => SliverAppBar(backgroundColor: darkBg, pinned: true, centerTitle: true, title: const Text("MY PROGRESS", style: TextStyle(color: Colors.white, fontSize: 16, letterSpacing: 2, fontWeight: FontWeight.bold)));
  Widget _sectionHeader(String t) => Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5));
}

// --- CUSTOM PAINTER FOR GRAPH ---
class WeightChartPainter extends CustomPainter {
  final List<double> weights;
  final Color color;
  WeightChartPainter(this.weights, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (weights.length < 2) return;
    final paint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    final path = Path();
    double minW = weights.reduce((a, b) => a < b ? a : b) - 1;
    double maxW = weights.reduce((a, b) => a > b ? a : b) + 1;
    double range = maxW - minW;
    double stepX = size.width / (weights.length - 1);

    for (int i = 0; i < weights.length; i++) {
      double x = i * stepX;
      double y = size.height - ((weights[i] - minW) / range) * size.height;
      if (i == 0) path.moveTo(x, y); else path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }
  @override bool shouldRepaint(CustomPainter old) => true;
}