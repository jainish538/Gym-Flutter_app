import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class GymOnboarding extends StatefulWidget {
  const GymOnboarding({super.key});

  @override
  State<GymOnboarding> createState() => _GymOnboardingState();
}

class _GymOnboardingState extends State<GymOnboarding> {
  final PageController _pageController = PageController();
  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);

  // Data State
  String weightGoal = "Muscle Gain";
  String consistencyStraggle = "Sometimes";
  String trainFreq = "3-4 days/week";
  String workoutPrefer = "Gym";
  String gender = "Male";
  DateTime birthDate = DateTime(2000, 1, 1);
  double height = 170;
  double weight = 70;

  // Calculated Results State
  double bmiScore = 0.0;
  String bmiCategory = "Unknown";
  int dailyCalories = 0;
  int dailyProtein = 0;
  int dailyCarbs = 0;
  int dailyFats = 0;

  int _currentPage = 0;
  bool _isLoading = false;

  void _nextPage() {
    _pageController.nextPage(
        duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  // --- LOGIC: Macro & Calorie Calculation ---

  void _calculateNutritionalTargets() {
    // 1. Calculate Age
    int age = DateTime.now().year - birthDate.year;

    // 2. Calculate BMR (Mifflin-St Jeor)
    double bmr;
    if (gender == "Male") {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    // 3. Activity Multiplier (TDEE)
    double multiplier = 1.2;
    if (trainFreq == "3-4 days/week") multiplier = 1.55;
    else if (trainFreq == "5+ days/week") multiplier = 1.725;
    else if (trainFreq == "1-2 days") multiplier = 1.375;

    double tdee = bmr * multiplier;

    // 4. Goal Adjustment
    if (weightGoal == "Weight Loss") {
      dailyCalories = (tdee - 500).round();
    } else if (weightGoal == "Muscle Gain") {
      dailyCalories = (tdee + 300).round();
    } else {
      dailyCalories = tdee.round();
    }

    // 5. Macro Splits (Standard Fitness Ratio)
    dailyProtein = (weight * 2.2).round(); // 2.2g per kg
    dailyFats = ((dailyCalories * 0.25) / 9).round(); // 25% of calories
    dailyCarbs = ((dailyCalories - (dailyProtein * 4) - (dailyFats * 9)) / 4).round();
  }

  // --- LOGIC: BMI API Call ---

  Future<void> _fetchBMIData() async {
    setState(() => _isLoading = true);

    double heightInMeters = height / 100; // Conversion for API
    final url = Uri.parse("https://body-mass-index-bmi-calculator.p.rapidapi.com/metric?weight=$weight&height=$heightInMeters");

    try {
      final response = await http.get(url, headers: {
        "x-rapidapi-key": "cc0cf01ce1msh9bcf60bcd41ba11p1c52ebjsncd4c3d4706b1",
        "x-rapidapi-host": "body-mass-index-bmi-calculator.p.rapidapi.com"
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          bmiScore = data['bmi'];
          if (bmiScore < 18.5) bmiCategory = "Underweight";
          else if (bmiScore < 25) bmiCategory = "Normal";
          else if (bmiScore < 30) bmiCategory = "Overweight";
          else bmiCategory = "Obese";

          _calculateNutritionalTargets(); // Run math after getting BMI
        });
        _nextPage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _completeProfile() async {
    setState(() => _isLoading = true);
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'weightGoal': weightGoal,
        'gender': gender,
        'height': height,
        'weight': weight,
        'bmi': bmiScore,
        'targetCalories': dailyCalories, // Save calculated math
        'targetProtein': dailyProtein,
        'targetCarbs': dailyCarbs,
        'targetFats': dailyFats,
        'onboardingCompleted': true,
      });
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      body: Stack(
        children: [
          _buildGlow(top: -100, right: -50),
          Column(
            children: [
              const SizedBox(height: 60),
              _buildProgressBar(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (int page) => setState(() => _currentPage = page),
                  children: [
                    _buildSelectionPage("WHAT IS YOUR GOAL?", ["Weight Loss", "Muscle Gain", "Powerlifting"], (v) => weightGoal = v),
                    _buildSelectionPage("STRUGGLE WITH CONSISTENCY?", ["Always", "Sometimes", "Never"], (v) => consistencyStraggle = v),
                    _buildSelectionPage("HOW OFTEN DO YOU TRAIN?", ["1-2 days", "3-4 days", "5+ days"], (v) => trainFreq = v),
                    _buildSpecialPage("WE HAVE THE PERFECT PROGRAM", "Based on your stats, we've tailored a routine."),
                    _buildSelectionPage("WORKOUT PREFERENCE?", ["Gym", "Home", "Outdoor"], (v) => workoutPrefer = v),
                    _buildSelectionPage("SELECT GENDER", ["Male", "Female", "Other"], (v) => gender = v),
                    _buildMeasurementPage(),
                    _buildBMIAndTargetsPage(), // Result Page
                    _buildFinalSwipePage(),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator(color: Colors.red)),
        ],
      ),
    );
  }

  // --- PAGE BUILDERS ---

  Widget _buildBMIAndTargetsPage() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("YOUR PERSONAL TARGETS", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryRed, width: 2)),
            child: Column(
              children: [
                Text(bmiScore.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                Text(bmiCategory, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          _targetTile("Daily Calories", "$dailyCalories kcal"),
          _targetTile("Protein Goal", "${dailyProtein}g"),
          _targetTile("Carbs / Fats", "${dailyCarbs}g / ${dailyFats}g"),
          const SizedBox(height: 40),
          _buildNextButton(),
        ],
      ),
    );
  }

  Widget _targetTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMeasurementPage() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("BODY STATS", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 30),
          _buildSlider("Height", height, 120, 220, "cm", (v) => setState(() => height = v)),
          const SizedBox(height: 20),
          _buildSlider("Weight", weight, 40, 150, "kg", (v) => setState(() => weight = v)),
          const SizedBox(height: 40),
          SizedBox(
            width: 200, height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              onPressed: _fetchBMIData,
              child: const Text("ANALYZE STATS", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // --- REUSED HELPERS ---

  Widget _buildSelectionPage(String title, List<String> options, Function(String) onSelect) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
          const SizedBox(height: 40),
          ...options.map((opt) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: SizedBox(
              width: double.infinity, height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), side: const BorderSide(color: Colors.white10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () { onSelect(opt); _nextPage(); },
                child: Text(opt, style: const TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildSpecialPage(String title, String subtitle) {
    return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.bolt, color: Colors.red, size: 80),
      Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54)),
      const SizedBox(height: 40), _buildNextButton()
    ]);
  }

  Widget _buildFinalSwipePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("EVOLUTION READY", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
          const SizedBox(height: 60),
          Container(
            height: 70, width: double.infinity,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(50)),
            child: Stack(children: [
              const Center(child: Text("SWIPE TO START", style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold))),
              Dismissible(
                key: const Key("swipeKey"),
                direction: DismissDirection.startToEnd,
                confirmDismiss: (dir) async { _completeProfile(); return false; },
                child: Align(alignment: Alignment.centerLeft, child: Container(width: 70, height: 70, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.black))),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: LinearProgressIndicator(value: (_currentPage + 1) / 9, backgroundColor: Colors.white10, color: primaryRed, minHeight: 4),
    );
  }

  Widget _buildSlider(String label, double val, double min, double max, String unit, Function(double) onChanged) {
    return Column(children: [
      Text("$label: ${val.round()} $unit", style: const TextStyle(color: Colors.white)),
      Slider(value: val, min: min, max: max, activeColor: Colors.red, onChanged: onChanged),
    ]);
  }

  Widget _buildNextButton() {
    return SizedBox(width: 200, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _nextPage, child: const Text("NEXT", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))));
  }

  Widget _buildGlow({double? top, double? right}) {
    return Positioned(top: top, right: right, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryRed.withOpacity(0.15), boxShadow: [BoxShadow(color: primaryRed.withOpacity(0.1), blurRadius: 100, spreadRadius: 50)])));
  }
}