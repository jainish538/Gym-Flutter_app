import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:one_percent_improve/pages/Diet%20dairy.dart';
import 'package:one_percent_improve/pages/add%20food.dart';
import 'package:one_percent_improve/pages/home.dart';
import 'package:one_percent_improve/pages/profile.dart';
import 'package:one_percent_improve/pages/progeress.dart';


class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final Color primaryRed = const Color(0xFFFF0000);
  final Color darkBg = const Color(0xFF000000);

  // 2. UPDATE THE SCREENS LIST
  final List<Widget> _screens = [
    const Home(),          // Index 0
    const AddFoodPage(),   // Index 1
    const ProfilePage(),   // Index 2
    const DietDiaryPage(), // Index 3
    const ProgressPage(),  // Index 4 (NEW)
  ];

  @override
  Widget build(BuildContext context) {
    int displayIndex;

    // 3. UPDATE THE LOGIC
    if (_selectedIndex == 4) {
      displayIndex = 2; // Profile icon -> Profile Page
    } else if (_selectedIndex == 2) {
      displayIndex = 1; // Center Plus -> Add Food Page
    } else if (_selectedIndex == 3) {
      displayIndex = 3; // Fast Food icon -> Diet Diary
    } else if (_selectedIndex == 1) {
      displayIndex = 4; // Bolt (Flash) icon -> Progress Page (NEW)
    } else {
      displayIndex = 0; // Dashboard icon -> Home Page
    }

    return Scaffold(
      backgroundColor: darkBg,
      extendBody: true,
      body: IndexedStack(
        index: displayIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildGlassNavbar(),
    );
  }

  Widget _buildGlassNavbar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
      // ADDED THE GLOBAL GLOW HERE
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: primaryRed.withOpacity(0.15),
            blurRadius: 40,
            spreadRadius: 5,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.grid_view_rounded),
                _buildNavItem(1, Icons.bolt_rounded), // NOW OPENS PROGRESS

                GestureDetector(
                  onTap: () => setState(() => _selectedIndex = 2),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _selectedIndex == 2 ? primaryRed : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedIndex == 2
                              ? primaryRed.withOpacity(0.6)
                              : Colors.white.withOpacity(0.2),
                          blurRadius: 15,
                        )
                      ],
                    ),
                    child: Icon(
                      Icons.add,
                      color: _selectedIndex == 2 ? Colors.white : Colors.black,
                      size: 30,
                    ),
                  ),
                ),

                _buildNavItem(3, Icons.fastfood_rounded),
                _buildNavItem(4, Icons.person_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return IconButton(
      onPressed: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      icon: Icon(
        icon,
        color: isSelected ? primaryRed : Colors.white.withOpacity(0.4),
        size: 28,
      ),
    );
  }
}