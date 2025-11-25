import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/footer_widgets.dart';
import '../widgets/slide_up_menu_widget.dart';
import '../widgets/add_new_profile_widget.dart';
import '../providers/font_size_provider.dart';
import '../services/language_api_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool isDarkMode = false;
  bool _showNotificationsMenu = false;
  bool _showProfileMenu = false;
  bool _showFontSizeMenu = false;
  bool _showLanguageMenu = false;
  bool _showCurrencyMenu = false;
  bool _showFreezeAccountMenu = false; // Added freeze account menu state

  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;
  Timer? _wiggleTimer;

  TextEditingController _languageSearchController = TextEditingController();
  List<Map<String, String>> _filteredLanguages = [];
  String _selectedLanguage = 'English (English)';
  String _selectedCurrency = 'USD(\$)';

  // Added freeze account reasons
  final List<String> _freezeReasons = [
    'Temporarily not using account',
    'Security concerns',
    'Traveling abroad',
    'Financial reasons',
    'Other',
  ];
  String? _selectedFreezeReason;

  // Added currency data
  final List<Map<String, String>> _currencies = [
    {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
    {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
    {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
    {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
    {'code': 'CHF', 'symbol': 'CHF', 'name': 'Swiss Franc'},
    {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize languages
    _filteredLanguages = LanguagesService.getLanguages();

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _wiggleAnimation =
        TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.10), weight: 1),
          TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.10, end: -0.10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: -0.10, end: 0.10), weight: 2),
          TweenSequenceItem(tween: Tween(begin: 0.10, end: 0.0), weight: 1),
        ]).animate(
          CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
        );

    _wiggleTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _wiggleController.forward(from: 0);
    });
  }

  void _toggleNotificationsMenu() {
    setState(() {
      _showNotificationsMenu = !_showNotificationsMenu;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;
    });
  }

  void _toggleProfileMenu() {
    setState(() {
      _showProfileMenu = !_showProfileMenu;
      _showNotificationsMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;
    });
  }

  void _toggleFontSizeMenu() {
    setState(() {
      _showFontSizeMenu = !_showFontSizeMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;
    });
  }

  void _toggleLanguageMenu() {
    setState(() {
      _showLanguageMenu = !_showLanguageMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;

      // Reset search when opening menu
      if (_showLanguageMenu) {
        _languageSearchController.clear();
        _filteredLanguages = LanguagesService.getLanguages();
      }
    });
  }

  void _toggleCurrencyMenu() {
    setState(() {
      _showCurrencyMenu = !_showCurrencyMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showFreezeAccountMenu = false;
    });
  }

  // Added freeze account menu toggle
  void _toggleFreezeAccountMenu() {
    setState(() {
      _showFreezeAccountMenu = !_showFreezeAccountMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;

      // Reset selection when opening menu
      if (_showFreezeAccountMenu) {
        _selectedFreezeReason = null;
      }
    });
  }

  void _closeAllMenus() {
    setState(() {
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;
    });
  }

  void _selectFontSize(String size) {
    final fontProvider = Provider.of<FontSizeProvider>(context, listen: false);
    fontProvider.setFontSize(size);
    _closeAllMenus();
  }

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
    print('Selected language: $language');
    _closeAllMenus();
  }

  void _selectCurrency(String currencyCode, String currencySymbol) {
    setState(() {
      _selectedCurrency = '$currencyCode($currencySymbol)';
    });
    print('Selected currency: $currencyCode');
    _closeAllMenus();
  }

  void _searchLanguages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = LanguagesService.getLanguages();
      } else {
        _filteredLanguages = LanguagesService.searchLanguages(query);
      }
    });
  }

  @override
  void dispose() {
    _wiggleController.dispose();
    _wiggleTimer?.cancel();
    _languageSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final notificationsMenuHeight = screenHeight * 0.6;
    final profileMenuHeight = screenHeight * 0.8;
    final fontSizeMenuHeight = screenHeight * 0.35;
    final languageMenuHeight = screenHeight * 0.7;
    final currencyMenuHeight = screenHeight * 0.5;
    final freezeAccountMenuHeight =
        screenHeight * 0.5; // Added freeze account menu height
    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 60,
              bottom: 30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIRST ROW (QR + bell)
                Padding(
                  padding: const EdgeInsets.only(left: 5, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SvgPicture.asset(
                        'assets/images/qrCodeIcon.svg',
                        width: 22,
                        height: 22,
                      ),
                      GestureDetector(
                        onTap: _toggleNotificationsMenu,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            SvgPicture.asset(
                              'assets/images/bellIcon.svg',
                              width: 32,
                              height: 32,
                            ),
                            Positioned(
                              top: -11,
                              right: -9,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF0000),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '3',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: fontProvider.getScaledSize(15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // SECOND ROW (Settings + profile)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/settingsIconSvg.svg',
                          width: 22,
                          height: 22,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Settings",
                          style: TextStyle(
                            color: Color(0xFF00FEFF),
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _toggleProfileMenu,
                      child: Row(
                        children: const [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: AssetImage(
                              'assets/images/image1.png',
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Sara Jones",
                            style: TextStyle(
                              color: Color(0xFF00FEFF),
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 30,
                            color: Color(0xFF00FEFF),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // HEADER OPTIONS
                buildHeaderOption(
                  leftIconPath: 'assets/images/fontSizeIcon.svg',
                  leftText: 'Font size',
                  buttonText: fontProvider.selectedSize,
                  onPressed: _toggleFontSizeMenu,
                  fontProvider: fontProvider,
                ),
                const SizedBox(height: 10),
                buildHeaderOption(
                  leftIconPath: 'assets/images/euroSignIcon.svg',
                  leftText: 'Language',
                  buttonText: _selectedLanguage,
                  onPressed: _toggleLanguageMenu,
                  fontProvider: fontProvider,
                ),
                const SizedBox(height: 10),
                buildHeaderOption(
                  leftIconPath: 'assets/images/euroSignIcon.svg',
                  leftText: 'Currency',
                  buttonText: _selectedCurrency,
                  onPressed: _toggleCurrencyMenu,
                  fontProvider: fontProvider,
                ),

                const SizedBox(height: 20),

                // THEME ROW
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SvgPicture.asset(
                          'assets/images/themeIcon.svg',
                          width: 20,
                          height: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Theme",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: fontProvider.getScaledSize(17),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isDarkMode = !isDarkMode;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 72,
                        height: 31,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF1C3153),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: isDarkMode
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: SvgPicture.asset(
                                isDarkMode
                                    ? 'assets/images/sunIcon.svg'
                                    : 'assets/images/halfMoonIcon.svg',
                                width: 20,
                                height: 20,
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              left: isDarkMode ? 0 : 40,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF058ABF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // CUSTOM BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomButton(
                      text: "Freeze Account",
                      width: 164,
                      height: 32,
                      textColor: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: fontProvider.getScaledSize(15),
                      borderRadius: 10,
                      onTap:
                          _toggleFreezeAccountMenu, // Updated to open freeze menu
                    ),
                    CustomButton(
                      text: "Delete Account",
                      width: 164,
                      height: 32,
                      textColor: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: fontProvider.getScaledSize(15),
                      borderRadius: 10,
                      onTap: () {},
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // PANIC BUTTON
                Center(
                  child: AnimatedBuilder(
                    animation: _wiggleAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _wiggleAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 232,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF42222),
                        border: Border.all(color: const Color(0xFFFF6767)),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.34),
                            blurRadius: 1.1,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/circularExclamationMarkIcon.svg',
                              width: 18,
                              height: 18,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Panic',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(bottom: 40),
                  child: FooterWidget(),
                ),
              ],
            ),
          ),

          // Overlay - Include freeze account menu in overlay
          if (_showNotificationsMenu ||
              _showProfileMenu ||
              _showFontSizeMenu ||
              _showLanguageMenu ||
              _showCurrencyMenu ||
              _showFreezeAccountMenu)
            GestureDetector(
              onTap: _closeAllMenus,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Notifications Menu
          SlideUpMenu(
            menuHeight: notificationsMenuHeight,
            isVisible: _showNotificationsMenu,
            onToggle: _toggleNotificationsMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      CustomButton(
                        text: 'Clear',
                        width: 106,
                        height: 40,
                        onTap: () {
                          print('Clear notifications tapped');
                        },
                        backgroundColor: Colors.transparent,
                        borderColor: const Color(0xFF00F0FF),
                        textColor: Colors.white,
                        fontWeight: FontWeight.w600,
                        borderRadius: 8,
                        fontSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: notificationsMenuHeight * 0.76,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [_buildNotificationItem("11:52 AM")],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Menu
          SlideUpMenu(
            menuHeight: profileMenuHeight,
            isVisible: _showProfileMenu,
            onToggle: _toggleProfileMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Select an Account',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: profileMenuHeight * 0.67,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          AccountFrame(
                            firstName: "Sara",
                            lastName: "Jones",
                            eid: "123456789",
                            imagePath: "assets/images/image1.png",
                            onTap: () {
                              print("Sara Jones account selected");
                              _closeAllMenus();
                            },
                            isTablet: false,
                          ),
                          AccountFrame(
                            firstName: "John",
                            lastName: "Smith",
                            eid: "987654321",
                            imagePath: "assets/images/image2.png",
                            onTap: () {
                              print("John Smith account selected");
                              _closeAllMenus();
                            },
                            isTablet: false,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  AddNewProfileButton(
                    isTablet: false,
                    onTap: () {
                      Navigator.pushNamed(context, '/sign-in');
                    },
                  ),
                ],
              ),
            ),
          ),

          // Font Size Menu
          SlideUpMenu(
            menuHeight: fontSizeMenuHeight,
            isVisible: _showFontSizeMenu,
            onToggle: _toggleFontSizeMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Font Size',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFontSizeOption('Medium', fontProvider),
                  const SizedBox(height: 12),
                  _buildFontSizeOption('Large', fontProvider),
                ],
              ),
            ),
          ),

          // Language Menu
          SlideUpMenu(
            menuHeight: languageMenuHeight,
            isVisible: _showLanguageMenu,
            onToggle: _toggleLanguageMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              child: Column(
                children: [
                  // SEARCH FIELD
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 50),
                    child: TextField(
                      controller: _languageSearchController,
                      onChanged: _searchLanguages,
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

                  // LANGUAGE LIST
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      itemCount: _filteredLanguages.length,
                      itemBuilder: (context, index) {
                        final language = _filteredLanguages[index];
                        return GestureDetector(
                          onTap: () {
                            _selectLanguage(language['name']!);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              children: [
                                // Language flag
                                Container(
                                  width: 40,
                                  height: 30,
                                  child: SvgPicture.asset(
                                    language['flag']!,
                                    width: 30,
                                    height: 20,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              width: 30,
                                              height: 20,
                                              color: Colors.grey,
                                              child: const Icon(
                                                Icons.flag,
                                                size: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    language['name']!,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight:
                                          _selectedLanguage == language['name']!
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (_selectedLanguage == language['name']!)
                                  const Icon(
                                    Icons.check,
                                    color: Color(0xFF00F0FF),
                                    size: 20,
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

          // Currency Menu
          SlideUpMenu(
            menuHeight: currencyMenuHeight,
            isVisible: _showCurrencyMenu,
            onToggle: _toggleCurrencyMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    'Select Currency',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _currencies.length,
                      itemBuilder: (context, index) {
                        final currency = _currencies[index];
                        final displayText =
                            '${currency['code']}(${currency['symbol']}) - ${currency['name']}';
                        final isSelected =
                            _selectedCurrency ==
                            '${currency['code']}(${currency['symbol']})';

                        return _buildCurrencyOption(
                          displayText,
                          isSelected,
                          () => _selectCurrency(
                            currency['code']!,
                            currency['symbol']!,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Freeze Account Menu - NEW
          SlideUpMenu(
            menuHeight: freezeAccountMenuHeight,
            isVisible: _showFreezeAccountMenu,
            onToggle: _toggleFreezeAccountMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Freeze account row with icon and text - centered horizontally
                  Row(
                    mainAxisAlignment: MainAxisAlignment
                        .center, // This centers the row horizontally
                    children: [
                      SvgPicture.asset(
                        'assets/images/freezeIcon.svg',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Freeze Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          // Add other text styling as needed
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ), // Space between row and centered text
                  // Centered confirmation text
                  const Text(
                    'Are you sure you want to freeze your account?\nAll activity will stop until you unfreeze it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey, // Optional: make it less prominent
                      // Add other text styling as needed
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyOption(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: Color(0xFF00F0FF), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language, FontSizeProvider fontProvider) {
    bool isSelected = _selectedLanguage == language;

    return GestureDetector(
      onTap: () => _selectLanguage(language),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              language,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontProvider.getScaledSize(16),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: Color(0xFF00F0FF)),
          ],
        ),
      ),
    );
  }

  Widget _buildFontSizeOption(String size, FontSizeProvider fontProvider) {
    bool isSelected = fontProvider.selectedSize == size;

    return GestureDetector(
      onTap: () => _selectFontSize(size),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F0FF).withOpacity(0.2)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? const Color(0xFF00F0FF) : Colors.transparent,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              size,
              style: TextStyle(
                color: Colors.white,
                fontSize: _getFontSizeForOption(size),
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isSelected) const Icon(Icons.check, color: Color(0xFF00F0FF)),
          ],
        ),
      ),
    );
  }

  double _getFontSizeForOption(String size) {
    switch (size) {
      case 'Medium':
        return 15;
      case 'Large':
        return 20;
      default:
        return 15;
    }
  }

  Widget buildHeaderOption({
    required String leftIconPath,
    required String leftText,
    required String buttonText,
    required VoidCallback onPressed,
    required FontSizeProvider fontProvider,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SvgPicture.asset(leftIconPath, width: 18, height: 18),
            const SizedBox(width: 10),
            Text(
              leftText,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontProvider.getScaledSize(15),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF011221),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FEFF).withOpacity(0.5),
                  offset: const Offset(0, 2),
                  blurRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  buttonText,
                  style: TextStyle(
                    color: Color(0xFF00FEFF),
                    fontSize: fontProvider.getScaledSize(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF00FEFF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationItem(String time) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You have received a notification',
            style: TextStyle(
              color: Colors.white,
              fontSize: 19.0, // Static font size
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: TextStyle(
              color: Color(0xFFA5A6A8),
              fontSize: 19.0, // Static font size
            ),
          ),
        ],
      ),
    );
  }
}

class AccountFrame extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String eid;
  final String imagePath;
  final VoidCallback onTap;
  final bool isTablet;
  final bool includeSpacing;

  const AccountFrame({
    required this.firstName,
    required this.lastName,
    required this.eid,
    required this.imagePath,
    required this.onTap,
    required this.isTablet,
    this.includeSpacing = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = isTablet ? 312.0 : 312.0;
    final height = isTablet ? 69.0 : 69.0;
    final imageSize = isTablet ? 50.0 : 50.0;
    final nameFontSize = isTablet ? 22.0 : 20.0;
    final eidFontSize = isTablet ? 15.0 : 15.0;
    final leftPadding = isTablet ? 90.0 : 95.0;
    final topDivider = isTablet
        ? (height - imageSize) / 3.8
        : (height - imageSize) / 2;

    Widget accountWidget = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00F0FF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              top: topDivider,
              left: 15,
              child: _buildProfileImage(imageSize),
            ),
            Positioned(
              top: isTablet ? 8 : 12,
              left: leftPadding,
              child: Text(
                '$firstName $lastName',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: nameFontSize,
                  height: 1.0,
                ),
              ),
            ),
            Positioned(
              top: isTablet ? 34 : 38,
              left: leftPadding,
              child: Text(
                'EID: $eid',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: eidFontSize,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (includeSpacing) {
      return Column(children: [accountWidget, const SizedBox(height: 16)]);
    } else {
      return accountWidget;
    }
  }

  Widget _buildProfileImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: Icon(Icons.person, color: Colors.white, size: size * 0.6),
            );
          },
        ),
      ),
    );
  }
}
