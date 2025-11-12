import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:flutter_project/providers/language_provider.dart';
import '../models/language_model.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'signup.dart';
import 'select_account.dart';
import '../constants/api_constants.dart';
import '../widgets/custom_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _signUpGlow = false;
  bool _selectAccountOpen = false;
  final double _dropdownHeight = 730;
  bool _languageDropdownOpen = false;
  List<LanguageModel> _filteredLanguages = [];

  final TextEditingController _languageSearchController =
      TextEditingController();

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      await userProvider.loadFromStorage(storage); // restore saved registration
      await languageProvider.loadLanguages();

      setState(() {
        _filteredLanguages = languageProvider.languages;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use tablet view for screens wider than 600 pixels
    if (screenWidth >= 600) {
      return RegisterPageTablet();
    } else {
      return RegisterPageMobile();
    }
  }
}

class RegisterPageMobile extends StatefulWidget {
  const RegisterPageMobile({super.key});

  @override
  State<RegisterPageMobile> createState() => _RegisterPageMobileState();
}

class _RegisterPageMobileState extends State<RegisterPageMobile> {
  bool _signUpGlow = false;
  bool _selectAccountOpen = false;
  final double _dropdownHeight = 730;
  bool _languageDropdownOpen = false;
  List<LanguageModel> _filteredLanguages = [];

  final TextEditingController _languageSearchController =
      TextEditingController();

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      await userProvider.loadFromStorage(storage);
      await languageProvider.loadLanguages();

      setState(() {
        _filteredLanguages = languageProvider.languages;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    const double dropdownHeight = 550;

    final filteredLanguages = _languageSearchController.text.isEmpty
        ? languageProvider.languages
        : languageProvider.languages
              .where(
                (lang) => lang.name.toLowerCase().contains(
                  _languageSearchController.text.toLowerCase(),
                ),
              )
              .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Positioned(
            top: 60,
            left: 389,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _languageDropdownOpen =
                      !_languageDropdownOpen; // toggle dropdown
                });
              },
              child: Image.asset(
                'assets/images/Vector.png',
                width: 23,
                height: 23,
                color: Colors.white,
              ),
            ),
          ),
          // Welcome texts
          const Positioned(
            top: 100,
            left: 100,
            child: SizedBox(
              width: 220,
              height: 50,
              child: Text(
                'Welcome to',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 28,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Positioned(
            top: 144,
            left: 100,
            child: Text(
              'Egety Trust',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 40,
                color: Colors.white,
              ),
            ),
          ),
          const Positioned(
            top: 225,
            left: 1,
            child: SizedBox(
              width: 425,
              height: 72,
              child: Text(
                'Step into a dynamic realm powered by decentralization, '
                'where true data ownership and assets belong to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Bottom-right rectangle
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/Rectangle2.png",
              width: 180,
              fit: BoxFit.contain,
            ),
          ),

          // Central image
          Positioned(
            top: 318,
            left: 138,
            child: SizedBox(
              width: 153,
              height: 200,
              child: Image.asset(
                'assets/images/Unlocked animstion.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Buttons Column
          Positioned(
            top: 600,
            left: 138,
            child: SizedBox(
              width: 153,
              child: Column(
                children: [
                  // Sign In Button
                  CustomButton(
                    text: 'Sign In',
                    width: 150,
                    height: 40,
                    fontSize: 20,
                    onTap: !userProvider.isRegistered
                        ? null
                        : () {
                            setState(() {
                              _selectAccountOpen = true;
                            });
                          },
                  ),
                  const SizedBox(height: 30),
                  // Sign Up Button
                  CustomButton(
                    text: 'Sign Up',
                    width: 150,
                    height: 40,
                    fontSize: 20,
                    onTap: userProvider.isRegistered
                        ? null
                        : () {
                            Navigator.pushNamed(context, '/sign-up');
                          },
                  ),
                ],
              ),
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _selectAccountOpen ? 0 : -_dropdownHeight,
            left: 0,
            right: 0,
            height: _dropdownHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                color: const Color(0xFF0B1320),
                child: SelectAccountContent(
                  onClose: () {
                    setState(() {
                      _selectAccountOpen = false;
                    });
                  },
                ),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _languageDropdownOpen ? 0 : -dropdownHeight,
            left: 0,
            right: 0,
            height: dropdownHeight,
            child: ClipRect(
              child: Container(
                color: const Color(0xFF0B1320),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    // V-line handle
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _languageDropdownOpen = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: CustomPaint(
                            size: const Size(120, 20),
                            painter: VLinePainter(),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search TextField
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      child: TextField(
                        controller: _languageSearchController,
                        onChanged: (value) {
                          final query = value.toLowerCase();
                          setState(() {
                            _filteredLanguages = languageProvider.languages
                                .where(
                                  (lang) =>
                                      lang.name.toLowerCase().startsWith(query),
                                )
                                .toList();
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search Language',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, thickness: 0.5),

                    // Language list
                    Expanded(
                      child: languageProvider.isLoading
                          ? const Center(
                              child: Text(
                                "No languages found",
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 50,
                                vertical: 16,
                              ),
                              itemCount: _filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final lang = _filteredLanguages[index];
                                return GestureDetector(
                                  onTap: () {
                                    userProvider.setLanguage(lang);
                                    setState(() {
                                      _languageSearchController.text =
                                          lang.name;
                                      _languageDropdownOpen = false;
                                    });
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Image.network(
                                          "${ApiConstants.baseUrl}${lang.flag}",
                                          width: 30,
                                          height: 30,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 30,
                                                    height: 30,
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.flag,
                                                      size: 20,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          lang.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterPageTablet extends StatefulWidget {
  const RegisterPageTablet({super.key});

  @override
  State<RegisterPageTablet> createState() => _RegisterPageTabletState();
}

class _RegisterPageTabletState extends State<RegisterPageTablet> {
  bool _signUpGlow = false;
  bool _selectAccountOpen = false;
  final double _dropdownHeight = 730;
  bool _languageDropdownOpen = false;
  List<LanguageModel> _filteredLanguages = [];

  final TextEditingController _languageSearchController =
      TextEditingController();

  final storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      await userProvider.loadFromStorage(storage);
      await languageProvider.loadLanguages();

      setState(() {
        _filteredLanguages = languageProvider.languages;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    const double dropdownHeight = 550;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    final filteredLanguages = _languageSearchController.text.isEmpty
        ? languageProvider.languages
        : languageProvider.languages
              .where(
                (lang) => lang.name.toLowerCase().contains(
                  _languageSearchController.text.toLowerCase(),
                ),
              )
              .toList();

    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Add top spacing only for landscape
        SizedBox(
          height: isLandscape ? screenHeight * 0.12 : screenHeight * 0.13,
        ),

        // Welcome section
        Column(
          children: [
            const Text(
              'Welcome to',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Egety Trust',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
              child: const Text(
                'Step into a dynamic realm powered by decentralization, '
                'where true data ownership and assets belong to you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  height: 1.2,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Central image
        SizedBox(
          width: 153,
          height: 200,
          child: Image.asset(
            'assets/images/Unlocked animstion.png',
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 50),

        // Buttons Column
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sign In Button
            CustomButton(
              text: 'Sign In',
              width: 180,
              height: 50,
              fontSize: 22,
              onTap: !userProvider.isRegistered
                  ? null
                  : () {
                      setState(() {
                        _selectAccountOpen = true;
                      });
                    },
            ),
            const SizedBox(height: 20),
            // Sign Up Button
            CustomButton(
              text: 'Sign Up',
              width: 180,
              height: 50,
              fontSize: 22,
              onTap: userProvider.isRegistered
                  ? null
                  : () {
                      Navigator.pushNamed(context, '/sign-up');
                    },
            ),
          ],
        ),

        // Add bottom spacing only for landscape
        if (isLandscape) SizedBox(height: screenHeight * 0.1),
      ],
    );

    // Wrap with SingleChildScrollView only in landscape mode
    if (isLandscape) {
      content = SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: content, // Remove the fixed height SizedBox
      );
    } else {
      // For portrait mode, center the content
      content = Center(child: content);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Language dropdown icon - positioned top right
          Positioned(
            top: 60,
            right: 60,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _languageDropdownOpen = !_languageDropdownOpen;
                });
              },
              child: Image.asset(
                'assets/images/Vector.png',
                width: 28,
                height: 28,
                color: Colors.white,
              ),
            ),
          ),

          // Content (scrollable only in landscape)
          Positioned.fill(child: content),

          // Bottom-right rectangle (stays fixed)
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/Rectangle2.png",
              width: 150,
              fit: BoxFit.contain,
            ),
          ),

          // Select Account Bottom Sheet (stays fixed)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _selectAccountOpen ? 0 : -_dropdownHeight,
            left: 0,
            right: 0,
            height: _dropdownHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                color: const Color(0xFF0B1320),
                child: SelectAccountContent(
                  onClose: () {
                    setState(() {
                      _selectAccountOpen = false;
                    });
                  },
                ),
              ),
            ),
          ),

          // Language Dropdown Bottom Sheet (stays fixed)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _languageDropdownOpen ? 0 : -dropdownHeight,
            left: 0,
            right: 0,
            height: dropdownHeight,
            child: ClipRect(
              child: Container(
                color: const Color(0xFF0B1320),
                child: Column(
                  children: [
                    const SizedBox(height: 16),

                    // V-line handle
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _languageDropdownOpen = false;
                          });
                        },
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 20),
                            child: CustomPaint(
                              size: const Size(120, 20),
                              painter: VLinePainter(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Search TextField
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 100),
                      child: TextField(
                        controller: _languageSearchController,
                        onChanged: (value) {
                          final query = value.toLowerCase();
                          setState(() {
                            _filteredLanguages = languageProvider.languages
                                .where(
                                  (lang) =>
                                      lang.name.toLowerCase().startsWith(query),
                                )
                                .toList();
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search Language',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 22,
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, thickness: 0.5),

                    // Language list
                    Expanded(
                      child: languageProvider.isLoading
                          ? const Center(
                              child: Text(
                                "No languages found",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 100,
                                vertical: 20,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 4,
                                  ),
                              itemCount: _filteredLanguages.length,
                              itemBuilder: (context, index) {
                                final lang = _filteredLanguages[index];
                                return GestureDetector(
                                  onTap: () {
                                    userProvider.setLanguage(lang);
                                    setState(() {
                                      _languageSearchController.text =
                                          lang.name;
                                      _languageDropdownOpen = false;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    child: Row(
                                      children: [
                                        Image.network(
                                          "${ApiConstants.baseUrl}${lang.flag}",
                                          width: 35,
                                          height: 35,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  Container(
                                                    width: 35,
                                                    height: 35,
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                      Icons.flag,
                                                      size: 24,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                        ),
                                        const SizedBox(width: 15),
                                        Expanded(
                                          child: Text(
                                            lang.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to draw the cyan V-line
class VLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(0, size.height / 2);
    path.lineTo(size.width / 2 - 10, size.height / 2);
    path.lineTo(size.width / 2, size.height / 2 + 5);
    path.lineTo(size.width / 2 + 10, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
