import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({super.key});

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  String _searchQuery = "";

  final Color primaryRed = Colors.red;
  final Color darkBg = Colors.black;
  final Color cardGrey = const Color(0xFF121212);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _calController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbsController = TextEditingController();
  final TextEditingController _fatsController = TextEditingController();
  final TextEditingController _qunController = TextEditingController();

  // ---------------- SAVE FOOD ----------------
  Future<void> _saveFoodToDatabase() async {
    if (_nameController.text.isEmpty) return;

    String name = _nameController.text.trim().toLowerCase();

    await FirebaseFirestore.instance.collection('Foods').add({
      'name': _nameController.text.trim(),
      'name_lowercase': name,
      'calories': double.tryParse(_calController.text) ?? 0,
      'protein': double.tryParse(_proteinController.text) ?? 0,
      'carbs': double.tryParse(_carbsController.text) ?? 0,
      'fats': double.tryParse(_fatsController.text) ?? 0,
      'quantity': _qunController.text,
    });

    _nameController.clear();
    _calController.clear();
    _proteinController.clear();
    _carbsController.clear();
    _fatsController.clear();
    _qunController.clear();
  }

  // ---------------- LOG FOOD ----------------
  Future<void> _logFoodToDiary(Map<String, dynamic> food, double multiplier) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    String today = DateTime.now().toIso8601String().split('T')[0];
    String docId = "${uid}_$today";

    int kcal = ((food['calories'] ?? 0) * multiplier).round();
    double protein = ((food['protein'] ?? 0) * multiplier);
    double carbs = ((food['carbs'] ?? 0) * multiplier);
    double fats = ((food['fats'] ?? 0) * multiplier);

    await FirebaseFirestore.instance.collection('user_diary').doc(docId).set({
      'uid': uid,
      'date': today,
      'lastUpdated': FieldValue.serverTimestamp(),
      'totalKcal': FieldValue.increment(kcal),
      'totalProtein': FieldValue.increment(protein),
      'totalCarbs': FieldValue.increment(carbs),
      'totalFats': FieldValue.increment(fats),
      'foodList': FieldValue.arrayUnion([
        {
          'name': food['name'],
          'kcal': kcal,
          'protein': protein,
          'carbs': carbs,
          'fats': fats,
          'time': TimeOfDay.now().format(context),
        }
      ])
    }, SetOptions(merge: true));
  }

  // ---------------- QUANTITY SHEET ----------------
  void _showQuantityDialog(Map<String, dynamic> food) {
    final TextEditingController qty = TextEditingController(text: "1");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // Forces sheet to stay above system bars
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheet) {
            // Parse the multiplier (e.g., 2 servings)
            double m = double.tryParse(qty.text) ?? 1;

            // Get the base quantity from database (e.g., "100")
            // We extract only numbers to multiply them
            String baseQtyString = food['quantity'] ?? "0";
            double baseQtyValue = double.tryParse(baseQtyString.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
            String unit = baseQtyString.replaceAll(RegExp(r'[0-9.]'), '').trim();
            if (unit.isEmpty) unit = "g"; // Default to grams if no unit found

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 25,
                left: 25,
                right: 25,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1c1c1c),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
                reverse: true, // Keeps textfield visible when keyboard opens
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(food['name'],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),

                    // --- SHOWING GRAMS HERE ---
                    const SizedBox(height: 5),
                    Text(
                      "Portion: ${(baseQtyValue * m).toStringAsFixed(0)}$unit",
                      style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _macro("KCAL", ((food['calories'] ?? 0) * m).round().toString(), Colors.white),
                        _macro("P", "${((food['protein'] ?? 0) * m).toStringAsFixed(1)}g", Colors.green),
                        _macro("C", "${((food['carbs'] ?? 0) * m).toStringAsFixed(1)}g", Colors.blue),
                        _macro("F", "${((food['fats'] ?? 0) * m).toStringAsFixed(1)}g", Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text("HOW MANY SERVINGS?", style: TextStyle(color: Colors.white38, fontSize: 12)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: qty,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 22),
                      onChanged: (_) => setSheet(() {}),
                      decoration: InputDecoration(
                        hintText: "Enter servings",
                        hintStyle: const TextStyle(color: Colors.white12),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        _logFoodToDiary(food, m);
                        Navigator.pop(context);
                      },
                      child: const Text("LOG FOOD", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _macro(String t, String v, Color c) {
    return Column(
      children: [
        Text(v, style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(t, style: const TextStyle(color: Colors.white38)),
      ],
    );
  }

  // ---------------- ADD FOOD SHEET ----------------
  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true, // 1. ADD THIS: Forces the sheet to respect screen boundaries
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // 2. Wrap everything in a Padding that listens to the keyboard (viewInsets)
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
              color: cardGrey,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25))
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: SingleChildScrollView(
            // 3. Reverse ensures the focused field stays visible
            reverse: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                const Text("NEW DATABASE ENTRY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _field(_nameController, "Food Name"),
                _field(_qunController, "Serving Size"),
                Row(
                  children: [
                    Expanded(child: _field(_calController, "Kcal", num: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_proteinController, "Protein", num: true)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(child: _field(_carbsController, "Carbs", num: true)),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_fatsController, "Fats", num: true)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                  ),
                  onPressed: () {
                    _saveFoodToDatabase();
                    Navigator.pop(context);
                  },
                  child: const Text("SAVE TO DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                // 4. Add a tiny bit of extra padding to clear the keyboard's top edge
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String h, {bool num = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType: num ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: h,
          hintStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.white10,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0), // Adjust this value (80-100) based on your navbar height
        child: FloatingActionButton(
          backgroundColor: primaryRed,
          onPressed: _showAddFoodSheet,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
// ... (rest of your existing code below)
          children: [
            const SizedBox(height: 20),
            const Text(
              "NUTRITION SEARCH",
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextField(
                onChanged: (v) {
                  setState(() {
                    _searchQuery = v.trim().toLowerCase();
                  });
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search food...",
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  filled: true,
                  fillColor: cardGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('Foods').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.red),
                    );
                  }

                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name_lowercase'] ?? "").toString();
                    return _searchQuery.isEmpty || name.contains(_searchQuery);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(
                      child: Text("No food found", style: TextStyle(color: Colors.white38)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _foodTile(data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _foodTile(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              data['name'],
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "${data['protein']}g P • ${data['carbs']}g C • ${data['fats']}g F",
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ]),
          GestureDetector(
            onTap: () => _showQuantityDialog(data),
            child: CircleAvatar(
              backgroundColor: primaryRed.withOpacity(0.15),
              child: Icon(Icons.add, color: primaryRed),
            ),
          )
        ],
      ),
    );
  }
}
