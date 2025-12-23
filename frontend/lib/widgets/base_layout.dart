// widgets/base_layout.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/bottom_nav_bar_widget.dart';

class BaseLayout extends StatefulWidget {
  final List<Widget> pages;

  const BaseLayout({super.key, required this.pages});

  @override
  State<BaseLayout> createState() => _BaseLayoutState();
}

class _BaseLayoutState extends State<BaseLayout> {
  @override
  Widget build(BuildContext context) {
    final navProvider = Provider.of<NavigationProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          Padding(
            padding: EdgeInsets.only(bottom: 32), // Space for bottom nav
            child: widget.pages[navProvider.currentIndex],
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBarWidget(
              onItemSelected: (index) {
                navProvider.updateIndex(index);
              },
              currentIndex: navProvider.currentIndex,
            ),
          ),
        ],
      ),
    );
  }
}
