import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:one_percent_improve/pages/add%20food.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);
  final Color cardGrey = const Color(0xFF121212);
  int _selectedIndex = 0;

  // 1. IMPROVED GOAL SAVING (Saves to Global Profile)
  void _showEditGoalsSheet(Map<String, dynamic> currentGoals) {
    final TextEditingController calController = TextEditingController(text: (currentGoals['targetCalories'] ?? 2000).toString());
    final TextEditingController proController = TextEditingController(text: (currentGoals['targetProtein'] ?? 150).toString());
    final TextEditingController carbController = TextEditingController(text: (currentGoals['targetCarbs'] ?? 200).toString());
    final TextEditingController fatController = TextEditingController(text: (currentGoals['targetFats'] ?? 60).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardGrey,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 25, right: 25, top: 25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 25),
            Text("UPDATE DAILY TARGETS", style: TextStyle(color: primaryRed, fontWeight: FontWeight.w900, letterSpacing: 1)),
            const SizedBox(height: 20),
            _goalInput("Daily Calories", calController, Icons.local_fire_department, Colors.orange),
            _goalInput("Protein (g)", proController, Icons.bolt, Colors.green),
            _goalInput("Carbs (g)", carbController, Icons.eco, Colors.blue),
            _goalInput("Fats (g)", fatController, Icons.opacity, Colors.yellow),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: () async {
                final String uid = FirebaseAuth.instance.currentUser!.uid;

                // Saving to 'users' collection ensures persistence across days
                await FirebaseFirestore.instance.collection('users').doc(uid).set({
                  'targetCalories': int.tryParse(calController.text) ?? 2000,
                  'targetProtein': int.tryParse(proController.text) ?? 150,
                  'targetCarbs': int.tryParse(carbController.text) ?? 200,
                  'targetFats': int.tryParse(fatController.text) ?? 60,
                }, SetOptions(merge: true));

                if (mounted) Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: const Text("Targets Updated!"), backgroundColor: primaryRed, behavior: SnackBarBehavior.floating)
                );
              },
              child: const Text("SAVE PERMANENT TARGETS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _goalInput(String label, TextEditingController controller, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: color),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: primaryRed)),
        ),
      ),
    );
  }

  Future<void> _addSpecificWater(int ml) async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await FirebaseFirestore.instance.collection('water_logs').doc("${uid}_$today").set({
      'uid': uid, 'date': today, 'timestamp': FieldValue.serverTimestamp(),
      'amount': FieldValue.increment(ml),
    }, SetOptions(merge: true));
  }

  void _showWaterMenu() {
    showModalBottomSheet(
      context: context, backgroundColor: cardGrey, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(25),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _waterOption(250, "Glass"), _waterOption(500, "Bottle"), _waterOption(1000, "1 Liter"),
        ]),
      ),
    );
  }

  Widget _waterOption(int ml, String label) {
    return GestureDetector(
      onTap: () { _addSpecificWater(ml); Navigator.pop(context); },
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_drink_rounded, color: Colors.blueAccent, size: 45),
        const SizedBox(height: 8), Text("${ml}ml", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final DateTime now = DateTime.now();
    final String todayDate = DateFormat('yyyy-MM-dd').format(now);

    return Scaffold(
      backgroundColor: darkBg,
      extendBody: true,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, userSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('user_diary').doc("${uid}_$todayDate").snapshots(),
            builder: (context, diarySnapshot) {
              if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryRed));

              var userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
              var diaryData = diarySnapshot.data?.data() as Map<String, dynamic>? ?? {};

              // Persisted goals from 'users' collection
              int goalCal = userData['targetCalories'] ?? 2000;
              int goalPro = userData['targetProtein'] ?? 150;
              int goalCarb = userData['targetCarbs'] ?? 200;
              int goalFat = userData['targetFats'] ?? 60;

              // Consumed data from 'user_diary' (Resets daily)
              double consumedCal = (diaryData['totalKcal'] ?? 0).toDouble();
              double consumedPro = (diaryData['totalProtein'] ?? 0).toDouble();
              double consumedCarb = (diaryData['totalCarbs'] ?? 0).toDouble();
              double consumedFat = (diaryData['totalFats'] ?? 0).toDouble();

              int dayNumber = 1;
              if (userData['createdAt'] != null) {
                DateTime createdAt = (userData['createdAt'] as Timestamp).toDate();
                dayNumber = now.difference(createdAt).inDays + 1;
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildHeader(dayNumber),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCalorieDashboard(
                              goalCal, consumedCal.toInt(), (goalCal - consumedCal).toInt(), (consumedCal / goalCal).clamp(0.0, 1.0),
                              consumedPro, goalPro.toDouble(),
                              consumedCarb, goalCarb.toDouble(),
                              consumedFat, goalFat.toDouble()
                          ),
                          const SizedBox(height: 30),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            _sectionHeader("NUTRITION TRACKER"),
                            IconButton(onPressed: () => _showEditGoalsSheet(userData), icon: const Icon(Icons.tune_rounded, color: Colors.white38))
                          ]),
                          const SizedBox(height: 12),
                          Row(children: [
                            _buildAnimatedLiquidCard(title: "PROTEIN", current: consumedPro, goal: goalPro.toDouble(), icon: Icons.bolt, color: Colors.green, unit: "g"),
                            const SizedBox(width: 12),
                            StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance.collection('water_logs').doc("${uid}_$todayDate").snapshots(),
                              builder: (context, waterDoc) {
                                double totalWater = 0;
                                if (waterDoc.hasData && waterDoc.data!.exists) {
                                  totalWater = (waterDoc.data!.get('amount') ?? 0).toDouble();
                                }
                                return _buildAnimatedLiquidCard(title: "WATER", current: totalWater / 1000, goal: 4.0, icon: Icons.local_drink_rounded, color: Colors.blue, unit: "L", onTap: _showWaterMenu);
                              },
                            ),
                          ]),
                          const SizedBox(height: 30),
                          _sectionHeader("WEEKLY STREAK"),
                          const SizedBox(height: 12),
                          Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(25)),
                              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(7, (index) => _buildDayCircle(index, now.weekday - 1)))),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _buildGlassNavbar(),
    );
  }

  // --- UI COMPONENTS ---
  Widget _navIcon(int i, IconData ic) {
    return IconButton(
      onPressed: () => setState(() => _selectedIndex = i),
      icon: Icon(ic, color: _selectedIndex == i ? primaryRed : Colors.white24, size: 28),
    );
  }

  Widget _buildHeader(int day) => SliverAppBar(
    expandedHeight: 200.0, pinned: true, backgroundColor: darkBg,
    flexibleSpace: FlexibleSpaceBar(
      centerTitle: true, title: const Text("ONE PERCENT", style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 2)),
      background: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryRed.withOpacity(0.3), darkBg])),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const SizedBox(height: 40), Text("DAY $day", style: const TextStyle(color: Colors.white, fontSize: 60, fontWeight: FontWeight.w900))])),
    ),
  );

  Widget _buildCalorieDashboard(int goal, int food, int left, double percent, double pC, double pG, double cC, double cG, double fC, double fG) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withOpacity(0.05))),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildStat("$goal", "GOAL"),
          Stack(alignment: Alignment.center, children: [
            SizedBox(height: 130, width: 130, child: CircularProgressIndicator(value: percent, strokeWidth: 10, backgroundColor: Colors.white10, valueColor: AlwaysStoppedAnimation<Color>(primaryRed))),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text("$left", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
              const Text("KCAL LEFT", style: TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ]),
          _buildStat("$food", "FOOD"),
        ]),
        const SizedBox(height: 30),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _buildMacroBar("PRO", "${pC.toInt()}g", Colors.green, (pG == 0 ? 0 : pC / pG)),
          _buildMacroBar("CARB", "${cC.toInt()}g", Colors.blue, (cG == 0 ? 0 : cC / cG)),
          _buildMacroBar("FAT", "${fC.toInt()}g", Colors.orange, (fG == 0 ? 0 : fC / fG)),
        ]),
      ]),
    );
  }

  Widget _buildMacroBar(String label, String val, Color col, double per) {
    return Column(children: [
      Text(label, style: TextStyle(color: col, fontSize: 10, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Container(width: 70, height: 6, decoration: BoxDecoration(color: col.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Align(alignment: Alignment.centerLeft, child: AnimatedContainer(duration: const Duration(seconds: 1), width: (70 * per).clamp(0, 70), decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(10))))),
      const SizedBox(height: 8), Text(val, style: const TextStyle(color: Colors.white, fontSize: 12))
    ]);
  }

  Widget _buildAnimatedLiquidCard({required String title, required double current, required double goal, required IconData icon, required Color color, required String unit, VoidCallback? onTap}) {
    double fillPercent = (current / goal).clamp(0.0, 1.0);
    return Expanded(child: GestureDetector(onTap: onTap, child: Container(height: 150, clipBehavior: Clip.antiAlias, decoration: BoxDecoration(color: cardGrey, borderRadius: BorderRadius.circular(25)),
        child: Stack(children: [
          Align(alignment: Alignment.bottomCenter, child: AnimatedContainer(duration: const Duration(milliseconds: 1500), width: double.infinity, height: 150 * fillPercent, decoration: BoxDecoration(color: color.withOpacity(0.15)))),
          Padding(padding: const EdgeInsets.all(20.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 30), const Spacer(), Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)), Text("${current.toStringAsFixed(1)}$unit / ${goal.toInt()}$unit", style: const TextStyle(color: Colors.white38, fontSize: 11))])),
        ]))));
  }

  Widget _buildDayCircle(int index, int current) {
    List<String> days = ["M", "T", "W", "T", "F", "S", "S"];
    bool isToday = index == current;
    return Column(children: [
      Text(days[index], style: TextStyle(color: isToday ? primaryRed : Colors.white38, fontSize: 11, fontWeight: FontWeight.w900)),
      const SizedBox(height: 10),
      Container(height: 40, width: 40, decoration: BoxDecoration(shape: BoxShape.circle, color: isToday ? primaryRed : Colors.white10), child: Icon(index <= current ? Icons.bolt : Icons.lock, color: isToday ? Colors.black : Colors.white24, size: 20)),
    ]);
  }

  Widget _buildGlassNavbar() {
    return Container(height: 110, padding: const EdgeInsets.fromLTRB(20, 0, 20, 30), child: ClipRRect(borderRadius: BorderRadius.circular(35), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.white.withOpacity(0.1))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _navIcon(0, Icons.dashboard_rounded), _navIcon(1, Icons.fitness_center_rounded),
              IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AddFoodPage())), icon: const Icon(Icons.add_circle, color: Colors.white, size: 40)),
              _navIcon(2, Icons.restaurant_rounded), _navIcon(3, Icons.person_rounded),
            ])))));
  }

  Widget _buildStat(String val, String label) => Column(children: [Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10))]);
  Widget _sectionHeader(String t) => Text(t, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2));
}