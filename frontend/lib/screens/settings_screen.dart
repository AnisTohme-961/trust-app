import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_project/services/binance_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/footer_widgets.dart';
import '../widgets/slide_up_menu_widget.dart';
import '../widgets/add_new_profile_widget.dart';
import '../providers/font_size_provider.dart';
import '../services/language_api_service.dart';

// Custom painter for pattern lines
class _PatternPainter extends CustomPainter {
  final List<int> selectedDots;
  final List<Offset> dotCenters;

  _PatternPainter({required this.selectedDots, required this.dotCenters});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedDots.length < 2) return;

    Paint paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < selectedDots.length - 1; i++) {
      int first = selectedDots[i];
      int second = selectedDots[i + 1];
      canvas.drawLine(dotCenters[first], dotCenters[second], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Error Stack Widget (Updated version)
class ErrorBanner extends StatefulWidget {
  final String message;
  final Duration duration;

  const ErrorBanner({
    Key? key,
    required this.message,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1320),
                border: Border(
                  top: const BorderSide(color: Color(0xFFF42222), width: 2),
                  left: const BorderSide(color: Color(0xFFF42222), width: 2),
                  right: const BorderSide(color: Color(0xFFF42222), width: 2),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFAF2222),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(23, 20, 23, 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF42222),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                height: 1.3,
                                letterSpacing: 0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Progress bar as bottom border
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 1 - _progressController.value,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFF42222),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class ErrorStack extends StatefulWidget {
  const ErrorStack({Key? key}) : super(key: key);

  @override
  State<ErrorStack> createState() => ErrorStackState();
}

class ErrorStackState extends State<ErrorStack> {
  final List<_ErrorItem> _errors = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createOverlay();
    });
  }

  void _createOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: IgnorePointer(
          ignoring: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _errors.length; i++) ...[
                if (i != 0) const SizedBox(height: 16),
                AnimatedSlide(
                  key: ValueKey(_errors[i]),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  offset: const Offset(0, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    opacity: 1.0,
                    child: ErrorBanner(
                      message: _errors[i].message,
                      duration: const Duration(seconds: 3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final item = _ErrorItem(message: message);
    setState(() => _errors.add(item));

    // Update the overlay
    _overlayEntry?.markNeedsBuild();

    // Auto-remove after duration
    item.timer = Timer(duration, () {
      if (mounted) {
        setState(() => _errors.remove(item));
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  @override
  void dispose() {
    for (var e in _errors) {
      e.timer?.cancel();
    }
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return an empty container since we're using Overlay
    return const SizedBox.shrink();
  }
}

class _ErrorItem {
  final String message;
  Timer? timer;
  _ErrorItem({required this.message});
}

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
  bool _showFreezeAccountMenu = false;
  bool _showPatternMenu = false;
  bool _showVerificationMenu = false; // NEW: Verification menu state

  // PIN Input State - FIXED: Initialize directly
  final List<String> _pin = [];
  bool _obscurePin = true;
  List<String> _numbers = List.generate(10, (i) => i.toString());

  // Pattern Grid State (Simplified - no confirm mode)
  final int _patternGridSize = 3;
  List<int> _selectedPatternDots = [];
  bool _patternCompleted = false;
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();
  final double _patternDotSize = 17;
  final GlobalKey _gridKey = GlobalKey();
  bool _showPatternLines = true;
  bool _isPatternEyeVisible = true;

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

  //{"code": "BTC", "symbol": "₿", "name": "Bitcoin", "symbolapi":"BTCUSDT"},
  
  {"code": "ADA", "symbol": "₳", "name": "Cardano"},
  {"code": "AVAX", "symbol": "A", "name": "Avalanche"},
  {"code": "BCH", "symbol": "B", "name": "Bitcoin Cash"},
  {"code": "BNB", "symbol": "Ⓑ", "name": "Binance Coin"},
  {"code": "BTC", "symbol": "₿", "name": "Bitcoin"},
  {"code": "DOGE", "symbol": "Ð", "name": "Dogecoin"},
  {"code": "ETC", "symbol": "ℰ", "name": "Ethereum Classic"},
  {"code": "ETH", "symbol": "Ξ", "name": "Ethereum"},
  {"code": "EUR", "symbol": "€", "name": "Euro"},
  {"code": "LINK", "symbol": "🔗", "name": "Chainlink"},
  {"code": "LTC", "symbol": "Ł", "name": "Litecoin"},
  {"code": "PAXG", "symbol": "🥇", "name": "PAX Gold"},
  {"code": "PLA", "symbol": "P", "name": "PlayDapp"},
  {"code": "SOL", "symbol": "◎", "name": "Solana"},
  {"code": "TON", "symbol": "⧉", "name": "Toncoin"},
  {"code": "TRX", "symbol": "T", "name": "TRON"},
  {"code": "XMR", "symbol": "ɱ", "name": "Monero"},
  {"code": "XRP", "symbol": "✕", "name": "XRP"},
  {"code": "ZEC", "symbol": "Ⓩ", "name": "Zcash"},
];


  // New controller and state for freeze account text field
  TextEditingController _freezeTextController = TextEditingController();
  bool _showCheckImage = false;

  // NEW: Verification PIN state
  final List<String> _verificationPin = [];
  bool _obscureVerificationPin = true;
  List<String> _verificationNumbers = List.generate(10, (i) => i.toString());

  @override
  void initState() {
    super.initState();

    // Shuffle numbers for security
    _numbers.shuffle();
    _verificationNumbers.shuffle(); // NEW: Shuffle verification numbers

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

    // Listen to freeze text field changes
    _freezeTextController.addListener(_onFreezeTextChanged);
  }

  void _onFreezeTextChanged() {
    final text = _freezeTextController.text;
    setState(() {
      _showCheckImage = text == 'FREEZE ACCOUNT';
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
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu
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
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu
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
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu
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
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu

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
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu
    });
  }

  void _togglePatternMenu() {
    setState(() {
      _showPatternMenu = !_showPatternMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu

      // Reset pattern state when opening menu
      if (_showPatternMenu) {
        _selectedPatternDots = [];
        _patternCompleted = false;
        _showPatternLines = true;
        _isPatternEyeVisible = true;
      }
    });
  }

  // NEW: Toggle verification menu
  void _toggleVerificationMenu() {
    setState(() {
      _showVerificationMenu = !_showVerificationMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showFreezeAccountMenu = false;
      _showPatternMenu = false;

      // Reset verification PIN when opening menu
      if (_showVerificationMenu) {
        _verificationPin.clear();
        _verificationNumbers.shuffle(); // Shuffle numbers for security
      }
    });
  }

  // Pattern Grid Methods (Simplified)
  void _onPatternPanStart(DragStartDetails details) {
    setState(() {
      _selectedPatternDots = [];
      _patternCompleted = false;
    });
  }

  void _onPatternPanUpdate(DragUpdateDetails details) {
    RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    Offset localPos = box.globalToLocal(details.globalPosition);
    double cellSize = box.size.width / _patternGridSize;
    int row = (localPos.dy / cellSize).floor();
    int col = (localPos.dx / cellSize).floor();
    int idx = row * _patternGridSize + col;

    if (row >= 0 &&
        row < _patternGridSize &&
        col >= 0 &&
        col < _patternGridSize &&
        !_selectedPatternDots.contains(idx)) {
      setState(() {
        _selectedPatternDots.add(idx);
      });
    }
  }

  void _onPatternPanEnd(DragEndDetails details) {
    if (_selectedPatternDots.length >= 4) {
      setState(() {
        _patternCompleted = true;
      });

      // Here you would typically save/verify the pattern
      print("Pattern entered: $_selectedPatternDots");

      // Close menu after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _closeAllMenus();
        }
      });
    } else {
      _errorStackKey.currentState?.showError("Minimum 4 dots required");
      setState(() {
        _selectedPatternDots = [];
        _patternCompleted = false;
      });
    }
  }

  // PIN Input Methods
  void _onKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _pin.clear();
      } else if (value == 'leftArrow') {
        // Close the slide-up menu when left arrow is tapped
        _closeAllMenus();
      } else {
        if (_pin.length < 4) _pin.add(value);
      }
    });
  }

  // NEW: Verification PIN input methods
  void _onVerificationKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _verificationPin.clear();
      } else if (value == 'leftArrow') {
        // Close the verification menu when left arrow is tapped
        _closeAllMenus();
      } else {
        if (_verificationPin.length < 4) _verificationPin.add(value);
      }
    });
  }

  void _onFreezeConfirm() {
    final enteredPin = _pin.join();

    // FIXED: Check if "FREEZE ACCOUNT" is typed in ALL CAPS exactly
    if (_freezeTextController.text != 'FREEZE ACCOUNT') {
      _errorStackKey.currentState?.showError(
        "Please type 'FREEZE ACCOUNT' in all capital letters",
      );
      return;
    }

    // Check PIN length
    if (enteredPin.length < 4) {
      _errorStackKey.currentState?.showError("Please enter 4 digits");
      return;
    }

    // Here you would typically verify the PIN with your backend
    print("PIN entered: $enteredPin");

    // If PIN is correct, proceed with freezing account
    _closeAllMenus();
    _pin.clear();
    _freezeTextController.clear();

    // Show success message or navigate as needed
    print("Account freeze process initiated");
  }

  // NEW: Verification confirm method
  void _onVerificationConfirm() {
    final enteredPin = _verificationPin.join();

    // Check PIN length
    if (enteredPin.length < 4) {
      _errorStackKey.currentState?.showError("Please enter 4 digits");
      return;
    }

    // Here you would typically verify the PIN with your backend
    print("Verification PIN entered: $enteredPin");

    // If PIN is correct, proceed with verification
    _closeAllMenus();
    _verificationPin.clear();

    // Show success message or navigate as needed
    print("Verification process completed");
  }

  void _toggleFreezeAccountMenu() {
    setState(() {
      _showFreezeAccountMenu = !_showFreezeAccountMenu;
      _showNotificationsMenu = false;
      _showProfileMenu = false;
      _showFontSizeMenu = false;
      _showLanguageMenu = false;
      _showCurrencyMenu = false;
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu

      // Reset PIN and selection when opening menu
      if (_showFreezeAccountMenu) {
        _selectedFreezeReason = null;
        _pin.clear();
        _numbers.shuffle(); // Shuffle numbers for security
        _freezeTextController.clear();
        _showCheckImage = false;
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
      _showPatternMenu = false;
      _showVerificationMenu = false; // NEW: Close verification menu
    });
  }

  void _openPatternMenu() {
    setState(() {
      // Close freeze account menu
      _showFreezeAccountMenu = false;

      // Open pattern menu after a short delay for smooth transition
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _showPatternMenu = true;
        });
      });
    });
  }

  // NEW: Method to open verification menu from pattern menu
  void _openVerificationMenuFromPattern() {
    if (_selectedPatternDots.length >= 4) {
      // Pattern is valid, process it
      print("Pattern entered: $_selectedPatternDots");

      setState(() {
        // Hide pattern menu
        _showPatternMenu = false;

        // Open verification menu after a short delay for smooth transition
        Future.delayed(const Duration(milliseconds: 100), () {
          setState(() {
            _showVerificationMenu = true;
          });
        });
      });
    } else {
      _errorStackKey.currentState?.showError("Minimum 4 dots required");
    }
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

  final BinanceService _binanceService = BinanceService();
  double? _selectedPrice;

  void _selectCurrency(String currencyCode, String currencySymbol) async {
  setState(() {
    _selectedCurrency = '$currencyCode($currencySymbol)';
  });

  // Build the Binance symbol (ex: BTC → BTCUSDT)
  final binanceSymbol = currencyCode + "USDT";

  // Fetch price
  final priceData = await _binanceService.getPrice(binanceSymbol);

  setState(() {
    _selectedPrice = priceData?.price;
  });

  print('Selected currency: $currencyCode');
  print('Price: $_selectedPrice');

  _closeAllMenus();
}

  // void _selectCurrency(String currencyCode, String currencySymbol) {
  //   setState(() {
  //     _selectedCurrency = '$currencyCode($currencySymbol)';
  //   });
  //   print('Selected currency: $currencyCode');
  //   _closeAllMenus();
  // }

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
    _freezeTextController.dispose();
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
    final freezeAccountMenuHeight = screenHeight * 0.9;
    final patternMenuHeight = screenHeight * 0.62;
    final verificationMenuHeight =
        705.0; // NEW: Fixed 705 height for verification menu
    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Main content - REMOVED extra bottom padding
          Padding(
            padding: const EdgeInsets.only(
              left: 15,
              right: 15,
              top: 60,
              bottom: 30, // Removed the extra 62px for bottom nav bar
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
                      onTap: _toggleFreezeAccountMenu,
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

          // Overlay - Include all menus in overlay
          if (_showNotificationsMenu ||
              _showProfileMenu ||
              _showFontSizeMenu ||
              _showLanguageMenu ||
              _showCurrencyMenu ||
              _showFreezeAccountMenu ||
              _showPatternMenu ||
              _showVerificationMenu)
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
                            imagePath: "assets/images/image1.png",
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

          // Freeze Account Menu - UPDATED with PIN Input
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/images/freezeIcon.svg',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Freeze Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Centered confirmation text
                  Text(
                    'All activity will stop until you unfreeze it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 30),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Please type "',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: 'FREEZE ACCOUNT',
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xFF00FEFF), // #00FEFF
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        TextSpan(
                          text: '" below to freeze your account',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Text field with check image - UPDATED
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      child: Stack(
                        children: [
                          Container(
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.white,
                                  width: 1.1,
                                ),
                              ),
                            ),
                            child: TextField(
                              controller: _freezeTextController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.left,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.only(bottom: 8),
                              ),
                            ),
                          ),
                          // Blue circle check image on the right
                          if (_showCheckImage)
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 8,
                              child: Image.asset(
                                'assets/images/blueCircleCheck.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PIN Input Section
                  Column(
                    children: [
                      // "Enter PIN To Continue" title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Enter PIN To Continue',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 28,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _obscurePin = !_obscurePin),
                            icon: Icon(
                              _obscurePin
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // PIN Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < _pin.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 50,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withOpacity(0.9),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              filled ? (_obscurePin ? '*' : _pin[index]) : '',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: fontProvider.getScaledSize(24),
                                color: Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 30),

                      // Keypad - UPDATED
                      _buildFreezeAccountKeypad(),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 64,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Color(0xFF00F0FF),
                                    Color(0xFF0B1320),
                                  ],
                                ),
                              ),
                            ),

                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                },
                                child: Container(
                                  width: 106,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      CustomButton(
                                        text: "Back",
                                        width: 100,
                                        height: 40,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        textColor: Colors.white,
                                        backgroundColor: Colors.transparent,
                                        borderColor: Colors.transparent,
                                        onTap: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: CustomButton(
                                text: "Next",
                                width: 105,
                                height: 40,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                textColor: Colors.white,
                                backgroundColor: Colors.transparent,
                                borderColor: const Color(0xFF00F0FF),
                                onTap: _openPatternMenu,
                              ),
                            ),

                            Container(
                              width: 64,
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Color(0xFF0B1320),
                                    Color(0xFF00F0FF),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pattern Menu
          SlideUpMenu(
            menuHeight: patternMenuHeight,
            isVisible: _showPatternMenu,
            onToggle: _togglePatternMenu,
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

                  // Pattern Menu Title with Eye Icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Enter Pattern To Continue',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showPatternLines = !_showPatternLines;
                            _isPatternEyeVisible = !_isPatternEyeVisible;
                          });
                        },
                        child: Image.asset(
                          _isPatternEyeVisible
                              ? 'assets/images/whiteEye.png'
                              : 'assets/images/whiteEyeSlash.png',
                          width: 24,
                          height: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Pattern Grid
                  Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        key: _gridKey,
                        width: 280,
                        height: 280,
                        child: GestureDetector(
                          onPanStart: _onPatternPanStart,
                          onPanUpdate: _onPatternPanUpdate,
                          onPanEnd: _onPatternPanEnd,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double cellSize =
                                  constraints.maxWidth / _patternGridSize;
                              List<Offset> dotCenters = [];
                              for (int row = 0; row < _patternGridSize; row++) {
                                for (
                                  int col = 0;
                                  col < _patternGridSize;
                                  col++
                                ) {
                                  double x = (col + 0.5) * cellSize;
                                  double y = (row + 0.5) * cellSize;
                                  dotCenters.add(Offset(x, y));
                                }
                              }

                              return Stack(
                                children: [
                                  Opacity(
                                    opacity: _patternCompleted ? 0.7 : 1.0,
                                    child: Stack(
                                      children: [
                                        if (_showPatternLines)
                                          CustomPaint(
                                            size: Size.infinite,
                                            painter: _PatternPainter(
                                              selectedDots:
                                                  _selectedPatternDots,
                                              dotCenters: dotCenters,
                                            ),
                                          ),
                                        for (
                                          int i = 0;
                                          i < dotCenters.length;
                                          i++
                                        )
                                          Positioned(
                                            left:
                                                dotCenters[i].dx -
                                                _patternDotSize / 2,
                                            top:
                                                dotCenters[i].dy -
                                                _patternDotSize / 2,
                                            child: Container(
                                              width: _patternDotSize,
                                              height: _patternDotSize,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: _showPatternLines
                                                    ? (_selectedPatternDots
                                                              .contains(i)
                                                          ? const Color(
                                                              0xFF00F0FF,
                                                            )
                                                          : Colors.white)
                                                    : Colors.white,
                                                boxShadow:
                                                    (_showPatternLines &&
                                                        _selectedPatternDots
                                                            .contains(i))
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFF00F0FF,
                                                          ).withOpacity(0.7),
                                                          blurRadius: 7,
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Back & Next Buttons - UPDATED to open verification menu
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 64,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF00F0FF), Color(0xFF0B1320)],
                            ),
                          ),
                        ),

                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: CustomButton(
                            text: "Back",
                            width: 106,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            textColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            borderColor: const Color(0xFF00F0FF),
                            onTap: _closeAllMenus,
                          ),
                        ),

                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: CustomButton(
                            text: "Next",
                            width: 106,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            textColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            borderColor: const Color(0xFF00F0FF),
                            onTap:
                                _openVerificationMenuFromPattern, // UPDATED: Call new method
                          ),
                        ),

                        Container(
                          width: 64,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Verification Menu
          SlideUpMenu(
            menuHeight: verificationMenuHeight,
            isVisible: _showVerificationMenu,
            onToggle: _toggleVerificationMenu,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(children: [const SizedBox(height: 20)]),
            ),
          ),

          // Error Stack
          ErrorStack(key: _errorStackKey),
        ],
      ),
    );
  }

  // Keypad for Freeze Account Menu
  Widget _buildFreezeAccountKeypad() {
    // Safety check - ensure _numbers is properly initialized
    if (_numbers.isEmpty) {
      _numbers = List.generate(10, (i) => i.toString())..shuffle();
    }

    final buttons = [
      [_numbers[0], _numbers[1], _numbers[2]],
      [_numbers[3], _numbers[4], _numbers[5]],
      [_numbers[6], _numbers[7], _numbers[8]],
      ['Clear', _numbers[9], 'leftArrow'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((text) {
              final isLeftArrow = text == 'leftArrow';
              final isClear = text == 'Clear';

              return GestureDetector(
                onTap: () => _onKeyTap(text),
                child: Container(
                  width: 104,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLeftArrow
                          ? const Color(0xFF00F0FF)
                          : (isClear
                                ? const Color(0xFFFF0000)
                                : const Color(0xFF00F0FF)),
                      width: isLeftArrow || isClear ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: isLeftArrow
                      ? SvgPicture.asset(
                          'assets/images/leftArrowWhite.svg',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        )
                      : isClear
                      ? Text(
                          'clear',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          text,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            time,
            style: const TextStyle(color: Color(0xFFA5A6A8), fontSize: 19.0),
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
