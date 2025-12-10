import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_project/models/currency_price_model.dart';
import 'package:flutter_project/services/currency_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/footer_widgets.dart';
import '../widgets/slide_up_menu_widget.dart';
import '../widgets/add_new_profile_widget.dart';
import '../widgets/custom_navigation_widget.dart'; // Add this import
import '../providers/font_size_provider.dart';
import '../services/language_api_service.dart';
import '../widgets/error_widgets.dart';
import '../services/auth_service.dart';

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
  bool _showVerificationMenu = false;

  // PIN Input State
  final List<String> _pin = [];
  bool _obscurePin = true;
  List<String> _numbers = List.generate(10, (i) => i.toString());

  // Pattern Grid State
  final int _patternGridSize = 3;
  List<int> _selectedPatternDots = [];
  bool _patternCompleted = false;
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();
  final double _patternDotSize = 17;
  final GlobalKey _gridKey = GlobalKey();
  bool _showPatternLines = true;
  bool _isPatternEyeVisible = true;

  List<CurrencyPrice> _currencies = [];

  // Verification State
  final TextEditingController _verificationEmailController =
      TextEditingController();
  bool _showEmailCodeSent = false;
  bool _showSMSCodeSent = false;
  bool _showAuthCodeSent = false;

  List<TextEditingController> _emailCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _emailCode = List.generate(6, (_) => '');

  List<TextEditingController> _smsCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _smsFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _smsCode = List.generate(6, (_) => '');

  List<TextEditingController> _authCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _authFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _authCode = List.generate(6, (_) => '');

  Map<String, bool> isCodeCorrectMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  Map<String, bool> isCodeValidMap = {'email': true, 'sms': true, 'auth': true};

  Map<String, int> _countdowns = {'email': 0, 'sms': 0, 'auth': 0};
  Map<String, Timer?> _timers = {'email': null, 'sms': null, 'auth': null};
  String? _activeCodeType;
  bool _codeDisabled = false;

  // Verification PIN state
  final List<String> _verificationPin = [];
  bool _obscureVerificationPin = true;
  List<String> _verificationNumbers = List.generate(10, (i) => i.toString());

  late AnimationController _wiggleController;
  late Animation<double> _wiggleAnimation;
  Timer? _wiggleTimer;

  TextEditingController _languageSearchController = TextEditingController();
  List<Map<String, String>> _filteredLanguages = [];
  String _selectedLanguage = 'English (English)';
  String _selectedCurrency = 'USD(\$)';

  // Freeze account reasons
  final List<String> _freezeReasons = [
    'Temporarily not using account',
    'Security concerns',
    'Traveling abroad',
    'Financial reasons',
    'Other',
  ];
  String? _selectedFreezeReason;

  // Added currency data
  // final List<Map<String, String>> _currencies = [
  //   {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
  //   {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
  //   {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
  //   {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
  //   {'code': 'CAD', 'symbol': 'C\$', 'name': 'Canadian Dollar'},
  //   {'code': 'AUD', 'symbol': 'A\$', 'name': 'Australian Dollar'},
  //   {'code': 'CHF', 'symbol': 'CHF', 'name': 'Swiss Franc'},
  //   {'code': 'CNY', 'symbol': '¥', 'name': 'Chinese Yuan'},
  // ];

  // Freeze account controller
  TextEditingController _freezeTextController = TextEditingController();
  bool _showCheckImage = false;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();

    // Shuffle numbers for security
    _numbers.shuffle();
    _verificationNumbers.shuffle();

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

  Future<void> _loadCurrencies() async {
    try {
      final currencies = await _currencyService.getCurrencies();
      setState(() {
        _currencies = currencies;
      });
    } catch (e) {
      print("Failed to load currencies: $e");
    }
  }

  void _onFreezeTextChanged() {
    final text = _freezeTextController.text;
    setState(() {
      _showCheckImage = text == 'FREEZE ACCOUNT';
    });
  }

  // Verification Methods
  String formatCooldown(int secondsLeft) {
    if (secondsLeft >= 3600) {
      int hours = secondsLeft ~/ 3600;
      int minutes = (secondsLeft % 3600) ~/ 60;
      return "${hours}h ${minutes}m";
    } else {
      int minutes = secondsLeft ~/ 60;
      int seconds = secondsLeft % 60;
      return "${minutes}m ${seconds}s";
    }
  }

  void _fetchCode(String type) async {
    // Disable if ANY type is active
    if (_activeCodeType != null && _activeCodeType != type) return;

    if (_countdowns[type]! > 0) return;

    if (_verificationEmailController.text.isEmpty) {
      _errorStackKey.currentState?.showError("Please enter your EID / Email");
      return;
    }

    final identifier = _verificationEmailController.text.trim();

    try {
      Map<String, dynamic> data;

      if (type == "auth") {
        data = await AuthService.generateTOTP(identifier);
      } else {
        data = await AuthService.sendResetCode(identifier);
      }

      final int cooldown = data["cooldown"] ?? 60;

      // Show "Code Sent"
      _setCodeSentFlag(type, true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _setCodeSentFlag(type, false);
      });

      // Start cooldown + disable ALL buttons
      setState(() {
        _activeCodeType = type;
        _countdowns[type] = cooldown;
        _codeDisabled = true;
      });

      _timers[type]?.cancel();
      _timers[type] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        setState(() {
          if (_countdowns[type]! > 0) {
            _countdowns[type] = _countdowns[type]! - 1;
          } else {
            timer.cancel();
            _timers[type] = null;
            _activeCodeType = null;
            _codeDisabled = false;
          }
        });
      });
    } catch (e) {
      _errorStackKey.currentState?.showError(
        "Failed to send code. Please try again.",
      );
    }
  }

  void _setCodeSentFlag(String type, bool value) {
    setState(() {
      if (type == 'email') _showEmailCodeSent = value;
      if (type == 'sms') _showSMSCodeSent = value;
      if (type == 'auth') _showAuthCodeSent = value;
    });
  }

  void _onVerificationCodeChanged(
    String value,
    int index,
    List<String> codeList,
    List<FocusNode> focusNodes,
    String type,
  ) async {
    codeList[index] = value.isEmpty ? '' : value[0];

    if (value.isNotEmpty && index < focusNodes.length - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // Reset validity while typing
    setState(() {
      isCodeValidMap[type] = true;
      isCodeCorrectMap[type] = false;
    });

    // Only verify when all digits are filled
    if (codeList.every((c) => c.isNotEmpty)) {
      final email = _verificationEmailController.text.trim();
      bool valid = false;

      try {
        if (type == 'auth') {
          valid = await AuthService.verifyTOTP(
            email: email,
            code: codeList.join(),
          );
        } else {
          valid = await AuthService.verifyResetCode(
            identifier: email,
            code: codeList.join(),
          );
        }

        if (valid) {
          setState(() {
            isCodeCorrectMap[type] = true;
            isCodeValidMap[type] = true;
          });
          _timers[type]?.cancel();
          _timers[type] = null;
          _countdowns[type] = 0;
        } else {
          // Show error for 3 seconds, then reset
          setState(() {
            isCodeValidMap[type] = false;
            isCodeCorrectMap[type] = false;
          });

          Timer(const Duration(seconds: 3), () {
            if (!mounted) return;
            setState(() {
              List<TextEditingController> controllers;
              switch (type) {
                case 'email':
                  controllers = _emailCodeControllers;
                  break;
                case 'sms':
                  controllers = _smsCodeControllers;
                  break;
                case 'auth':
                  controllers = _authCodeControllers;
                  break;
                default:
                  return;
              }

              for (var i = 0; i < controllers.length; i++) {
                controllers[i].clear();
                codeList[i] = '';
              }
              isCodeValidMap[type] = true;
              isCodeCorrectMap[type] = false;
            });
            focusNodes[0].requestFocus();
          });
        }
      } catch (e) {
        // On error, show red for 3 seconds, then reset
        setState(() {
          isCodeValidMap[type] = false;
          isCodeCorrectMap[type] = false;
        });

        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            List<TextEditingController> controllers;
            switch (type) {
              case 'email':
                controllers = _emailCodeControllers;
                break;
              case 'sms':
                controllers = _smsCodeControllers;
                break;
              case 'auth':
                controllers = _authCodeControllers;
                break;
              default:
                return;
            }

            for (var i = 0; i < controllers.length; i++) {
              controllers[i].clear();
              codeList[i] = '';
            }
            isCodeValidMap[type] = true;
            isCodeCorrectMap[type] = false;
          });
          focusNodes[0].requestFocus();
        });
      }
    }

    setState(() {});
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
      _showVerificationMenu = false;
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
      _showVerificationMenu = false;
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
      _showVerificationMenu = false;
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
      _showVerificationMenu = false;

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
      _showVerificationMenu = false;
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
      _showVerificationMenu = false;

      if (_showPatternMenu) {
        _selectedPatternDots = [];
        _patternCompleted = false;
        _showPatternLines = true;
        _isPatternEyeVisible = true;
      }
    });
  }

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

      if (_showVerificationMenu) {
        _verificationPin.clear();
        _verificationNumbers.shuffle();
        // Reset all verification states
        _verificationEmailController.clear();
        _showEmailCodeSent = false;
        _showSMSCodeSent = false;
        _showAuthCodeSent = false;
        for (var c in _emailCodeControllers) c.clear();
        for (var c in _smsCodeControllers) c.clear();
        for (var c in _authCodeControllers) c.clear();
        _emailCode = List.generate(6, (_) => '');
        _smsCode = List.generate(6, (_) => '');
        _authCode = List.generate(6, (_) => '');
        isCodeCorrectMap = {'email': false, 'sms': false, 'auth': false};
        isCodeValidMap = {'email': true, 'sms': true, 'auth': true};
        _countdowns = {'email': 0, 'sms': 0, 'auth': 0};
        _activeCodeType = null;
        _codeDisabled = false;
      }
    });
  }

  // Pattern Grid Methods
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

      print("Pattern entered: $_selectedPatternDots");

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
        _closeAllMenus();
      } else {
        if (_pin.length < 4) _pin.add(value);
      }
    });
  }

  void _onVerificationKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _verificationPin.clear();
      } else if (value == 'leftArrow') {
        _closeAllMenus();
      } else {
        if (_verificationPin.length < 4) _verificationPin.add(value);
      }
    });
  }

  void _onFreezeConfirm() {
    final enteredPin = _pin.join();

    if (_freezeTextController.text != 'FREEZE ACCOUNT') {
      _errorStackKey.currentState?.showError(
        "Please type 'FREEZE ACCOUNT' in all capital letters",
      );
      return;
    }

    if (enteredPin.length < 4) {
      _errorStackKey.currentState?.showError("Please enter 4 digits");
      return;
    }

    print("PIN entered: $enteredPin");
    _closeAllMenus();
    _pin.clear();
    _freezeTextController.clear();
    print("Account freeze process initiated");
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
      _showVerificationMenu = false;

      if (_showFreezeAccountMenu) {
        _selectedFreezeReason = null;
        _pin.clear();
        _numbers.shuffle();
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
      _showVerificationMenu = false;
    });
  }

  void _openPatternMenu() {
    setState(() {
      _showFreezeAccountMenu = false;
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _showPatternMenu = true;
        });
      });
    });
  }

  void _openVerificationMenuFromPattern() {
    if (_selectedPatternDots.length >= 4) {
      print("Pattern entered: $_selectedPatternDots");

      setState(() {
        _showPatternMenu = false;
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

  final CurrencyService _currencyService = CurrencyService();
  double? _selectedPrice;

  void _selectCurrency(String currencyCode, String currencySymbol) async {
    setState(() {
      _selectedCurrency = '$currencyCode($currencySymbol)';
    });

    // Build the Binance symbol (ex: BTC → BTCUSDT)
    final currencies = await _currencyService.getCurrencies();

    final selected = currencies.firstWhere(
      (c) => c.symbol == currencyCode,
      orElse: () => CurrencyPrice(code: '', symbol: '', name: '', price: 0),
    );

    setState(() {
      _selectedPrice = selected.price;
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
    _verificationEmailController.dispose();
    for (var c in _emailCodeControllers) c.dispose();
    for (var f in _emailFocusNodes) f.dispose();
    for (var c in _smsCodeControllers) c.dispose();
    for (var f in _smsFocusNodes) f.dispose();
    for (var c in _authCodeControllers) c.dispose();
    for (var f in _authFocusNodes) f.dispose();
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
    final verificationMenuHeight = screenHeight * 0.7;
    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Main content
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

          // Overlay
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
                        final currency =
                            _currencies[index]; // CurrencyPrice object
                        final displayText =
                            '${currency.code}(${currency.symbol}) - ${currency.name}';
                        final isSelected =
                            _selectedCurrency ==
                            '${currency.code}(${currency.symbol})';

                        return _buildCurrencyOption(
                          displayText,
                          isSelected,
                          () => _selectCurrency(currency.code, currency.symbol),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Freeze Account Menu - UPDATED with CustomNavigationWidget
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
                            color: Color(0xFF00FEFF),
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

                      _buildFreezeAccountKeypad(),

                      const SizedBox(height: 20),

                      // UPDATED: Using CustomNavigationWidget for Freeze Account
                      CustomNavigationWidget(
                        onCancel: _closeAllMenus,
                        onNext: _openPatternMenu,
                        cancelText: "Cancel",
                        nextText: "Next",
                        cancelButtonWidth: 106,
                        cancelButtonHeight: 40,
                        cancelFontSize: 20,
                        cancelFontWeight: FontWeight.w600,
                        cancelTextColor: Colors.white,
                        cancelBorderColor: const Color(0xFF00F0FF),
                        cancelBackgroundColor: Colors.transparent,
                        cancelBorderRadius: 10,
                        nextButtonWidth: 106,
                        nextButtonHeight: 40,
                        nextFontSize: 20,
                        nextFontWeight: FontWeight.w600,
                        nextTextColor: Colors.white,
                        nextBorderColor: const Color(0xFF00F0FF),
                        nextBackgroundColor: Colors.transparent,
                        nextBorderRadius: 10,
                        lineHeight: 4,
                        lineRadius: 11,
                        spacing: 16,
                        startGradientColor: const Color(0xFF00F0FF),
                        endGradientColor: const Color(0xFF0B1320),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Pattern Menu - UPDATED with CustomNavigationWidget
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

                  // UPDATED: Using CustomNavigationWidget for Pattern Menu
                  CustomNavigationWidget(
                    onCancel: _closeAllMenus,
                    onNext: _openVerificationMenuFromPattern,
                    cancelText: "Cancel",
                    nextText: "Next",
                    cancelButtonWidth: 106,
                    cancelButtonHeight: 40,
                    cancelFontSize: 20,
                    cancelFontWeight: FontWeight.w600,
                    cancelTextColor: Colors.white,
                    cancelBorderColor: const Color(0xFF00F0FF),
                    cancelBackgroundColor: Colors.transparent,
                    cancelBorderRadius: 10,
                    nextButtonWidth: 106,
                    nextButtonHeight: 40,
                    nextFontSize: 20,
                    nextFontWeight: FontWeight.w600,
                    nextTextColor: Colors.white,
                    nextBorderColor: const Color(0xFF00F0FF),
                    nextBackgroundColor: Colors.transparent,
                    nextBorderRadius: 10,
                    lineHeight: 4,
                    lineRadius: 11,
                    spacing: 16,
                    startGradientColor: const Color(0xFF00F0FF),
                    endGradientColor: const Color(0xFF0B1320),
                  ),
                ],
              ),
            ),
          ),

          // VERIFICATION MENU - UPDATED with CustomNavigationWidget
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      'Please enter your email address or EID\nfor verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: fontProvider.getScaledSize(15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Email/EID Input
                    Center(child: _buildVerificationEmailInput()),
                    const SizedBox(height: 30),

                    // Verification Sections
                    _buildVerificationSection(
                      title: 'Email Verification',
                      showCodeSent: _showEmailCodeSent,
                      codeControllers: _emailCodeControllers,
                      focusNodes: _emailFocusNodes,
                      codeList: _emailCode,
                      type: 'email',
                      codeDisabled: _codeDisabled,
                    ),
                    const SizedBox(height: 10),

                    _buildVerificationSection(
                      title: 'SMS Verification',
                      showCodeSent: _showSMSCodeSent,
                      codeControllers: _smsCodeControllers,
                      focusNodes: _smsFocusNodes,
                      codeList: _smsCode,
                      type: 'sms',
                      codeDisabled: _codeDisabled,
                    ),
                    const SizedBox(height: 10),

                    _buildVerificationSection(
                      title: 'Authenticator App',
                      showCodeSent: _showAuthCodeSent,
                      codeControllers: _authCodeControllers,
                      focusNodes: _authFocusNodes,
                      codeList: _authCode,
                      type: 'auth',
                      codeDisabled: _codeDisabled,
                    ),
                    const SizedBox(height: 15),

                    // UPDATED: Using CustomNavigationWidget for Verification Menu
                    CustomNavigationWidget(
                      onCancel: _closeAllMenus,
                      onNext: () {
                        // TODO: Add your Next button functionality for verification
                        print("Next button tapped in verification menu");
                      },
                      cancelText: "Cancel",
                      nextText: "Next",
                      cancelButtonWidth: 106,
                      cancelButtonHeight: 40,
                      cancelFontSize: 20,
                      cancelFontWeight: FontWeight.w600,
                      cancelTextColor: Colors.white,
                      cancelBorderColor: const Color(0xFF00F0FF),
                      cancelBackgroundColor: Colors.transparent,
                      cancelBorderRadius: 10,
                      nextButtonWidth: 106,
                      nextButtonHeight: 40,
                      nextFontSize: 20,
                      nextFontWeight: FontWeight.w600,
                      nextTextColor: Colors.white,
                      nextBorderColor: const Color(0xFF00F0FF),
                      nextBackgroundColor: Colors.transparent,
                      nextBorderRadius: 10,
                      lineHeight: 4,
                      lineRadius: 11,
                      spacing: 16,
                      startGradientColor: const Color(0xFF00F0FF),
                      endGradientColor: const Color(0xFF0B1320),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Error Stack
          ErrorStack(key: _errorStackKey),
        ],
      ),
    );
  }

  // Email Input for Verification Menu
  Widget _buildVerificationEmailInput() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.92;
    bool hasText = _verificationEmailController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: containerWidth,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1320),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00F0FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 5),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Image.asset(
                    'assets/images/SVGRepo_iconCarrier.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _verificationEmailController,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'EID / Email',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                CustomButton(
                  text: hasText ? 'Clear' : 'Paste',
                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (hasText) {
                      _verificationEmailController.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      final text = clipboardData?.text;
                      if (text != null) {
                        _verificationEmailController.text = text;
                      }
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (hasText)
            Positioned(
              left: 15,
              top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                color: const Color(0xFF0B1320),
                child: const Text(
                  'E-mail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Verification Section
  Widget _buildVerificationSection({
    required String title,
    required bool showCodeSent,
    required List<TextEditingController> codeControllers,
    required List<FocusNode> focusNodes,
    required List<String> codeList,
    required String type,
    required bool codeDisabled,
  }) {
    bool isCodeCorrect = isCodeCorrectMap[type] ?? false;
    bool isCodeValid = isCodeValidMap[type] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: SizedBox(
        height: 85,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Title
            Positioned(
              top: -4,
              left: -1,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
            ),

            // "Code Sent" indicator
            if (showCodeSent)
              Positioned(
                top: 25,
                left: 50,
                child: Container(
                  width: 110,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Code Sent",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

            // OTP Fields
            if (!showCodeSent)
              Positioned(
                top: 12,
                left: 0,
                child: Row(
                  children: [
                    ...List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 35,
                              height: 35,
                              child: TextField(
                                controller: codeControllers[index],
                                focusNode: focusNodes[index],
                                showCursor: !codeDisabled,
                                enabled: !codeDisabled,
                                readOnly: codeDisabled,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: codeDisabled
                                      ? Colors.grey
                                      : isCodeCorrect
                                      ? const Color(0xFF00F0FF)
                                      : (isCodeValid == false
                                            ? Colors.red
                                            : Colors.white),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                cursorColor: codeDisabled
                                    ? Colors.grey
                                    : isCodeCorrect
                                    ? const Color(0xFF00F0FF)
                                    : (isCodeValid == false
                                          ? Colors.red
                                          : Colors.white),
                                decoration: const InputDecoration(
                                  counterText: "",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) =>
                                    _onVerificationCodeChanged(
                                      value,
                                      index,
                                      codeList,
                                      focusNodes,
                                      type,
                                    ),
                              ),
                            ),

                            // Underline
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 35,
                              height: isCodeCorrect ? 0 : 2,
                              color: codeDisabled
                                  ? Colors.grey
                                  : isCodeCorrect
                                  ? Colors.transparent
                                  : (isCodeValid == false
                                        ? Colors.red
                                        : Colors.white),
                            ),
                          ],
                        ),
                      );
                    }),

                    // ✅ or ❌ icon
                    if (isCodeCorrect || isCodeValid == false)
                      Padding(
                        padding: const EdgeInsets.only(left: 6, top: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCodeCorrect
                                ? const Color(0xFF00F0FF)
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCodeCorrect ? Icons.check : Icons.close,
                            color: isCodeCorrect ? Colors.black : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Get Code button
            Positioned(
              top: 21,
              left: 280,
              child: GestureDetector(
                onTap: (_activeCodeType == null || _activeCodeType == type)
                    ? () {
                        if (_verificationEmailController.text.isEmpty) {
                          _errorStackKey.currentState?.showError(
                            "Please enter your EID / Email",
                          );
                          return;
                        }
                        _fetchCode(type);
                      }
                    : null,
                child: Container(
                  width: 94,
                  height: 23,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00F0FF).withOpacity(1),
                        blurRadius: 11.5,
                        spreadRadius: 0,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: _countdowns[type]! > 0
                      ? Text(
                          formatCooldown(_countdowns[type]!),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          "Get Code",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keypad for Freeze Account Menu
  Widget _buildFreezeAccountKeypad() {
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

  // Keypad for Verification PIN
  Widget _buildVerificationKeypad() {
    if (_verificationNumbers.isEmpty) {
      _verificationNumbers = List.generate(10, (i) => i.toString())..shuffle();
    }

    final buttons = [
      [
        _verificationNumbers[0],
        _verificationNumbers[1],
        _verificationNumbers[2],
      ],
      [
        _verificationNumbers[3],
        _verificationNumbers[4],
        _verificationNumbers[5],
      ],
      [
        _verificationNumbers[6],
        _verificationNumbers[7],
        _verificationNumbers[8],
      ],
      ['Clear', _verificationNumbers[9], 'leftArrow'],
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
                onTap: () => _onVerificationKeyTap(text),
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
