// bottom_nav_bar_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavBarWidget extends StatefulWidget {
  final Function(int) onItemSelected;
  final int currentIndex;

  const BottomNavBarWidget({
    super.key,
    required this.onItemSelected,
    required this.currentIndex,
  });

  @override
  State<BottomNavBarWidget> createState() => _BottomNavBarWidgetState();
}

class _BottomNavBarWidgetState extends State<BottomNavBarWidget> {
  final List<Map<String, dynamic>> items = [
    {"icon": "assets/images/homeIcon.svg", "label": "Home"},
    {"icon": "assets/images/profileIcon.svg", "label": "Profile"},
    {"icon": "assets/images/settingsIcon.svg", "label": "Settings"},
    {"icon": "assets/images/securityIcon.svg", "label": "Security"},
    {"icon": "assets/images/addressIcon.svg", "label": "Address"},
    {"icon": "assets/images/addressIcon.svg", "label": "Loc"},
    {"icon": "assets/images/addressIcon.svg", "label": "Old"},
    {"icon": "assets/images/addressIcon.svg", "label": "New"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: const BoxDecoration(
        color: Color(0xFF0592C6),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF0592C6),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = widget.currentIndex == index;

            return GestureDetector(
              onTap: () => widget.onItemSelected(index),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF041C55), Color(0x00051F29)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0xFF0592C6),
                            offset: Offset(0, 3),
                            blurRadius: 4,
                          ),
                        ],
                      )
                    : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(item["icon"], width: 20, height: 20),
                    const SizedBox(height: 2),
                    Text(
                      item["label"],
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                        decoration: isSelected
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: Colors.white,
                        decorationThickness: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
