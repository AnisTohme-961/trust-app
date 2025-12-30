import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:flutter_project/providers/language_provider.dart';
import '../models/language_model.dart';
import 'package:provider/provider.dart';
import 'select_account.dart';
import '../widgets/custom_button.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/language_api_service.dart';
import '../widgets/slide_up_menu_widget.dart';
import '../widgets/select_account_slide_up_menu_widget.dart';
import 'package:flutter/services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _signUpGlow = false;
  bool _selectAccountOpen = false;
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

      // 1️⃣ Load saved users
      await userProvider.loadFromStorage();
      await userProvider.syncAccountsWithServer();

      // 2️⃣ Load languages
      await languageProvider.loadLanguages();

      // 3️⃣ Update filtered languages list
      setState(() {
        _filteredLanguages = languageProvider.languages;
        _selectAccountOpen = false;
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
  bool _languageDropdownOpen = false;
  List<LanguageModel> _filteredLanguages = [];

  final TextEditingController _languageSearchController =
      TextEditingController();

  final storage = const FlutterSecureStorage();

  // dynamic list from language_api_service.dart:
  List<Map<String, String>> get _languages => LanguagesService.getLanguages();
  List<Map<String, String>> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = _languages;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );

      await userProvider.loadFromStorage();
      await languageProvider.loadLanguages();

      setState(() {
        _filteredLanguages = languageProvider.languages;
      });
    });
  }

  void _navigateToNextPage(BuildContext context) {
    Navigator.pushNamed(context, '/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double dropdownHeight = screenHeight * 0.559;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content column
            Column(
              children: [
                // Top section with vector icon
                Stack(
                  children: [
                    // Vector icon at top-right
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _languageDropdownOpen = !_languageDropdownOpen;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20, right: 20),
                          child: Image.asset(
                            'assets/images/Vector.png',
                            width: 23,
                            height: 23,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Welcome texts
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Welcome to',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 30.0,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Egety Trust',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 50.0,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Description text
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 20,
                  ),
                  child: Text(
                    'Step into a dynamic realm powered by decentralization, '
                    'where true data ownership and assets belong to you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20.0,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Central image
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 153,
                      height: 200,
                      child: Image.asset(
                        'assets/images/Unlocked animstion.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Buttons section
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Sign In Button
                      CustomButton(
                        text: 'Sign In',
                        width: 150,
                        height: 40,
                        fontSize: 20,
                        onTap: () {
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
                        onTap: () {
                          _navigateToNextPage(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Bottom-right rectangle
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                "assets/images/Rectangle2.png",
                width: 140,
                fit: BoxFit.contain,
              ),
            ),

            // BACKGROUND OVERLAY WHEN ANY POPUP IS OPEN
            if (_languageDropdownOpen || _selectAccountOpen)
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectAccountOpen = false;
                      _languageDropdownOpen = false;
                    });
                  },
                  child: Container(color: Colors.black.withOpacity(0.6)),
                ),
              ),

            // SELECT ACCOUNT POPUP - USING SelectAccountSlideUpMenu
            if (_selectAccountOpen)
              SelectAccountSlideUpMenu(
                menuHeight: dropdownHeight,
                isVisible: _selectAccountOpen,
                onToggle: () {
                  setState(() {
                    _selectAccountOpen = !_selectAccountOpen;
                  });
                },
                onClose: () {
                  setState(() {
                    _selectAccountOpen = false;
                  });
                },
                backgroundColor: const Color(0xFF0B1320),
                shadowColor: const Color(0xFF00F0FF),
                borderRadius: 20.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                minHeight: 300,
                dragHandle: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: CustomPaint(
                    size: const Size(120, 20),
                    painter: VLinePainter(),
                  ),
                ),
                child: SizedBox(
                  height: dropdownHeight - 50, // Subtract drag handle height
                  child: SelectAccountContent(
                    onClose: () {
                      setState(() {
                        _selectAccountOpen = false;
                      });
                    },
                  ),
                ),
              ),

            // LANGUAGE DROPDOWN POPUP - USING SlideUpMenu
            if (_languageDropdownOpen)
              SlideUpMenu(
                menuHeight: dropdownHeight,
                isVisible: _languageDropdownOpen,
                onToggle: () {
                  setState(() {
                    _languageDropdownOpen = !_languageDropdownOpen;
                  });
                },
                onClose: () {
                  setState(() {
                    _languageDropdownOpen = false;
                  });
                },
                backgroundColor: const Color(0xFF0B1320),
                shadowColor: const Color(0xFF00F0FF),
                borderRadius: 20.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                minHeight: 100,
                maxHeight: dropdownHeight,
                dragHandle: Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: CustomPaint(
                    size: const Size(120, 20),
                    painter: VLinePainter(),
                  ),
                ),
                child: SizedBox(
                  height: dropdownHeight - 50, // Subtract drag handle height
                  child: Column(
                    children: [
                      // SEARCH FIELD - Fixed height
                      // SEARCH FIELD - Fixed height
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 50,
                          vertical: 10,
                        ),
                        child: TextField(
                          controller: _languageSearchController,
                          inputFormatters: [
                            // Capitalize first letter of every word
                            TextInputFormatter.withFunction((
                              oldValue,
                              newValue,
                            ) {
                              if (newValue.text.isEmpty) {
                                return newValue;
                              }

                              final text = newValue.text;
                              final words = text.split(' ');
                              final capitalizedWords = words.map((word) {
                                if (word.isEmpty) return '';
                                return word[0].toUpperCase() +
                                    word.substring(1);
                              }).toList();

                              final capitalizedText = capitalizedWords.join(
                                ' ',
                              );

                              return TextEditingValue(
                                text: capitalizedText,
                                selection: newValue.selection.copyWith(
                                  baseOffset:
                                      newValue.selection.baseOffset +
                                      (capitalizedText.length - text.length),
                                  extentOffset:
                                      newValue.selection.extentOffset +
                                      (capitalizedText.length - text.length),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            final query = value.toLowerCase();
                            setState(() {
                              _filteredCountries = _languages
                                  .where(
                                    (c) => c['name']!.toLowerCase().contains(
                                      query,
                                    ),
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
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),

                      // DIVIDER
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 50),
                        child: Divider(
                          color: Colors.white24,
                          thickness: 0.5,
                          height: 1,
                        ),
                      ),

                      // LANGUAGE LIST - Takes remaining space
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 8,
                          ),
                          itemCount: _filteredCountries.length,
                          physics: const ClampingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final country = _filteredCountries[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _languageSearchController.text =
                                      country['name']!;
                                  _languageDropdownOpen = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    SvgPicture.asset(
                                      country['flag']!,
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
                                    Expanded(
                                      child: Text(
                                        country['name']!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
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
          ],
        ),
      ),
    );
  }
}

class RegisterPageTablet extends StatefulWidget {
  const RegisterPageTablet({super.key});

  @override
  State<RegisterPageTablet> createState() => _RegisterPageTabletState();
}

class _RegisterPageTabletState extends State<RegisterPageTablet>
    with TickerProviderStateMixin {
  bool _selectAccountOpen = false;
  bool _languageDropdownOpen = false;
  List<Map<String, String>> _filteredLanguages = [];

  final double _sheetHeight = 650;
  final TextEditingController _languageSearchController =
      TextEditingController();

  final storage = const FlutterSecureStorage();

  // dynamic list from language_api_service.dart:
  List<Map<String, String>> get _languages => LanguagesService.getLanguages();

  @override
  void initState() {
    super.initState();
    _filteredLanguages = _languages;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.isRegistered) {
        // Automatically open Sign In
        setState(() {
          _selectAccountOpen = true;
        });
      }
    });
  }

  bool get _anySheetOpen => _selectAccountOpen || _languageDropdownOpen;

  void _closeAllSheets() {
    setState(() {
      _selectAccountOpen = false;
      _languageDropdownOpen = false;
    });
  }

  void _navigateToNextPage(BuildContext context) {
    Navigator.pushNamed(context, '/sign-up');
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    // MAIN CONTENT ---------------------------------------------------------
    Widget content = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(height: isLandscape ? screenHeight * .10 : screenHeight * .13),

        const Text(
          'Welcome to',
          style: TextStyle(
            fontSize: 30,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Egety Trust',
          style: TextStyle(
            fontSize: 50,
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: 30),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * .1),
          child: const Text(
            'Step into a dynamic realm powered by decentralization, '
            'where true data ownership and assets belong to you.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18, height: 1.2, color: Colors.white),
          ),
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: 153,
          height: 200,
          child: Image.asset(
            'assets/images/Unlocked animstion.png',
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 50),

        Column(
          children: [
            CustomButton(
              text: 'Sign In',
              width: 180,
              height: 50,
              fontSize: 22,
              onTap: !userProvider.isRegistered
                  ? null
                  : () => setState(() => _selectAccountOpen = true),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Sign Up',
              width: 180,
              height: 50,
              fontSize: 22,
              onTap: userProvider.isRegistered
                  ? null
                  : () => _navigateToNextPage(context),
            ),
          ],
        ),

        if (isLandscape) SizedBox(height: screenHeight * .1),
      ],
    );

    if (isLandscape) {
      content = SingleChildScrollView(child: content);
    } else {
      content = Center(child: content);
    }

    // ---------------------------------------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Positioned.fill(child: content),

          // TOP-RIGHT LANGUAGE ICON
          Positioned(
            top: 60,
            right: 60,
            child: GestureDetector(
              onTap: () => setState(() {
                _languageDropdownOpen = !_languageDropdownOpen;
              }),
              child: Image.asset(
                'assets/images/Vector.png',
                width: 28,
                height: 28,
                color: Colors.white,
              ),
            ),
          ),

          // FIXED BOTTOM RIGHT DECORATION
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/Rectangle2.png",
              width: 150,
              fit: BoxFit.contain,
            ),
          ),

          // 🔥 OVERLAY FADE WHEN SHEETS OPEN
          if (_anySheetOpen)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1,
              child: GestureDetector(
                onTap: _closeAllSheets,
                child: Container(color: Colors.black.withOpacity(0.45)),
              ),
            ),

          // SELECT ACCOUNT SHEET - Using same animation as main.dart
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _selectAccountOpen ? 0 : -_sheetHeight,
            height: _sheetHeight,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Container(
                color: const Color(0xFF0B1320),
                child: Column(
                  children: [
                    const SizedBox(height: 18),

                    // HANDLE
                    GestureDetector(
                      onTap: () => setState(() => _selectAccountOpen = false),
                      child: CustomPaint(
                        size: const Size(120, 20),
                        painter: VLinePainter(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SELECT ACCOUNT CONTENT
                    Expanded(
                      child: SelectAccountContent(
                        onClose: () =>
                            setState(() => _selectAccountOpen = false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // LANGUAGE DROPDOWN SHEET
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _languageDropdownOpen ? 0 : -_sheetHeight,
            height: _sheetHeight,
            child: _buildLanguageSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        color: const Color(0xFF0B1320),
        child: Column(
          children: [
            const SizedBox(height: 18),

            // HANDLE
            GestureDetector(
              onTap: () => setState(() => _languageDropdownOpen = false),
              child: CustomPaint(
                size: const Size(120, 20),
                painter: VLinePainter(),
              ),
            ),

            const SizedBox(height: 20),

            // SEARCH FIELD
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: TextField(
                controller: _languageSearchController,
                onChanged: (value) {
                  final query = value.toLowerCase();
                  setState(() {
                    _filteredLanguages = _languages
                        .where(
                          (lang) => lang['name']!.toLowerCase().contains(query),
                        )
                        .toList();
                  });
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search Language',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 22),
                  border: InputBorder.none,
                ),
              ),
            ),

            const Divider(color: Colors.white24),

            // LANGUAGES GRID
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                itemCount: _filteredLanguages.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, i) {
                  final lang = _filteredLanguages[i];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _languageSearchController.text = lang['name']!;
                        _languageDropdownOpen = false;
                      });
                    },
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          lang['flag']!,
                          width: 35,
                          height: 35,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                width: 35,
                                height: 35,
                                color: Colors.grey,
                                child: const Icon(
                                  Icons.flag,
                                  color: Colors.white,
                                ),
                              ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            lang['name']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
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
