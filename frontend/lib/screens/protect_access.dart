import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_project/screens/password.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter_project/widgets/footer_widgets.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:flutter_project/providers/font_size_provider.dart';
import 'package:flutter_project/widgets/error_widgets.dart';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../widgets/custom_button.dart';
import '../services/country_service.dart';
import 'package:flutter_project/widgets/slide_up_menu_widget.dart';
import 'package:intl/intl.dart'; // Add this import

class ResponsiveProtectAccess extends StatelessWidget {
  const ResponsiveProtectAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const TabletProtectAccess();
        } else {
          return const MobileProtectAccess();
        }
      },
    );
  }
}

class MobileProtectAccess extends StatefulWidget {
  const MobileProtectAccess({super.key});

  @override
  State<MobileProtectAccess> createState() => _MobileProtectAccessState();
}

class _MobileProtectAccessState extends State<MobileProtectAccess> {
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();

  // Button hover states
  bool _isBackHovered = false;
  bool _isNextHovered = false;
  bool _isGetCodeHovered = false;
  bool _isGetCodeClicked = false;

  // Dropdown states
  bool _countryDropdownOpen = false;
  bool _dobDropdownOpen = false;

  // Selected values
  String _selectedCountry = '';
  String _selectedCountryId = '';
  bool _datePicked = false;
  bool _isFirstTimeOpeningDob =
      true; // Track if it's the first time opening DOB picker

  // Validation states
  bool _countryValid = false;
  bool _dobValid = false;
  bool _emailValid = false;
  bool _codeValid = false;
  String? _emailError;

  bool _hasCodeBeenSentBefore = false;

  // Controllers
  final TextEditingController _countryFieldController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Code input controllers
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  List<String> _code = ["", "", "", "", "", ""];

  // Focus nodes
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;

  // Date picker controllers
  late final ScrollController _monthController;
  late final ScrollController _dayController;
  late final ScrollController _yearController;

  // Date values - Initialize to null (no selection initially)
  int _selectedMonth = 0; // Will be set to 0 (January) when picker opens
  int _selectedDay = 0; // Will be set to 0 (Day 1) when picker opens
  int _selectedYear = 0; // Will be set to 0 (1970) when picker opens

  // Email verification states
  String _serverCode = "";
  int _attempts = 0;
  bool _showCodeSent = false;
  bool _codeDisabled = false;
  bool? _isCodeVerified;

  // Timer and cooldown
  Timer? _timer;
  int _cooldownSeconds = 0;

  // Country list
  List<Map<String, String>> get countries => CountriesService.getCountries();
  List<Map<String, String>> _filteredCountries = [];

  // Date lists - Will be dynamically generated
  late List<String> _months;
  late List<int> _days;
  late List<int> _years;

  // Cache to save scroll positions when menu closes
  double _cachedMonthScrollOffset = 0.0;
  double _cachedDayScrollOffset = 0.0;
  double _cachedYearScrollOffset = 0.0;
  bool _shouldRestoreScrollPosition = false;

  // Configuration
  static const int _startYear = 1970; // Start year

  @override
  void initState() {
    super.initState();

    // Initialize date lists
    _initializeDateLists();

    // Initialize controllers
    _monthController = ScrollController();
    _dayController = ScrollController();
    _yearController = ScrollController();

    // Initialize countries
    _filteredCountries = List.from(countries);

    // Add focus listener for email validation
    _emailFocusNode.addListener(_validateEmailOnUnfocus);

    // Add search listener
    _countrySearchController.addListener(
      () => _filterCountries(_countrySearchController.text),
    );

    // Initialize date picker after widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDatePickerListeners();
    });
  }

  void _initializeDateLists() {
    // Generate months (January to December)
    _months = List.generate(12, (index) {
      // Create a date with the month index + 1 (months are 1-based in DateTime)
      final date = DateTime(2000, index + 1, 1);
      return DateFormat('MMMM').format(date); // Full month name
    });

    // Generate years (from 1970 to current year)
    final currentYear = DateTime.now().year;
    _years = List.generate(currentYear - _startYear + 1, (i) => _startYear + i);

    // Initialize days list with default month (January)
    _updateDaysList();
  }

  void _updateDaysList() {
    // Use the selected year or default to 1970 if not set yet
    final year = _selectedYear < _years.length ? _years[_selectedYear] : 1970;
    final month = _selectedMonth + 1; // Convert to 1-based

    // Get number of days in the selected month/year
    final daysInMonth = DateTime(year, month + 1, 0).day;

    _days = List.generate(daysInMonth, (i) => i + 1);

    // Adjust selected day if it's out of range
    if (_selectedDay >= daysInMonth) {
      _selectedDay = daysInMonth - 1;
    }
  }

  void _setupDatePickerListeners() {
    void _updateDobController() {
      if (_datePicked) {
        _dobController.text = _dobDisplayText;
        onDobPicked();
      }
    }

    // Month controller listener
    _monthController.addListener(() {
      if (!_monthController.hasClients) return;

      final itemHeight = 40.0;
      final scrollOffset = _monthController.offset;
      final newIndex = (scrollOffset / itemHeight).round();
      final clampedIndex = newIndex.clamp(0, _months.length - 1);

      if (clampedIndex != _selectedMonth) {
        setState(() {
          _selectedMonth = clampedIndex;
          _datePicked = true;
          _updateDaysList();
          _updateDobController();
          _validateDob();
        });
      }
    });

    // Day controller listener
    _dayController.addListener(() {
      if (!_dayController.hasClients) return;

      final itemHeight = 40.0;
      final scrollOffset = _dayController.offset;
      final newIndex = (scrollOffset / itemHeight).round();
      final clampedIndex = newIndex.clamp(0, _days.length - 1);

      if (clampedIndex != _selectedDay) {
        setState(() {
          _selectedDay = clampedIndex;
          _datePicked = true;
          _updateDobController();
          _validateDob();
        });
      }
    });

    // Year controller listener
    _yearController.addListener(() {
      if (!_yearController.hasClients) return;

      final itemHeight = 40.0;
      final scrollOffset = _yearController.offset;
      final newIndex = (scrollOffset / itemHeight).round();
      final clampedIndex = newIndex.clamp(0, _years.length - 1);

      if (clampedIndex != _selectedYear) {
        setState(() {
          _selectedYear = clampedIndex;
          _datePicked = true;
          _updateDaysList();
          _updateDobController();
          _validateDob();
        });
      }
    });
  }

  void _scrollToSelectedDate() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure controllers are attached before scrolling
      if (_monthController.hasClients) {
        _snapToCenter(_monthController, _selectedMonth);
      }
      if (_dayController.hasClients) {
        _snapToCenter(_dayController, _selectedDay);
      }
      if (_yearController.hasClients) {
        _snapToCenter(_yearController, _selectedYear);
      }
    });
  }

  // NEW METHOD: Save scroll positions before closing the menu
  void _saveScrollPositions() {
    if (_monthController.hasClients) {
      _cachedMonthScrollOffset = _monthController.offset;
    }
    if (_dayController.hasClients) {
      _cachedDayScrollOffset = _dayController.offset;
    }
    if (_yearController.hasClients) {
      _cachedYearScrollOffset = _yearController.offset;
    }
    _shouldRestoreScrollPosition = true;
  }

  // NEW METHOD: Restore scroll positions when opening the menu
  void _restoreScrollPositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always snap to the selected date values when opening
      if (_monthController.hasClients) {
        _snapToCenter(_monthController, _selectedMonth);
      }
      if (_dayController.hasClients) {
        _snapToCenter(_dayController, _selectedDay);
      }
      if (_yearController.hasClients) {
        _snapToCenter(_yearController, _selectedYear);
      }
    });
  }

  // Method to set default values when opening the picker for the first time
  void _setDefaultDateValues() {
    if (_isFirstTimeOpeningDob) {
      setState(() {
        _selectedMonth = 0; // January
        _selectedDay = 0; // Day 1
        _selectedYear = 0; // 1970
        _updateDaysList(); // Update days list for January 1970
      });
      _isFirstTimeOpeningDob = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = context.read<UserProvider>();

    // Prefill country
    if (userProvider.country.isNotEmpty && _selectedCountry.isEmpty) {
      _selectedCountry = userProvider.country;
      _selectedCountryId = userProvider.countryId;
      _countryFieldController.text = userProvider.country;
      _countryValid = true;
    }

    // Prefill email
    if (_emailController.text.isEmpty) {
      _emailController.text = userProvider.email;
      _validateEmail();
    }

    // Prefill date of birth from user provider
    if (_dobController.text.isEmpty && userProvider.dob.isNotEmpty) {
      try {
        final parts = userProvider.dob.split('-');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);

          // Find indices
          final yearIndex = _years.indexOf(year);
          if (yearIndex != -1) {
            _selectedYear = yearIndex;
          }

          final monthIndex = month - 1;
          if (monthIndex >= 0 && monthIndex < _months.length) {
            _selectedMonth = monthIndex;
          }

          // Update days list for the selected month/year
          _updateDaysList();

          final dayIndex = day - 1;
          if (dayIndex >= 0 && dayIndex < _days.length) {
            _selectedDay = dayIndex;
          }

          _datePicked = true;
          _dobController.text = "${_months[monthIndex]} $day $year";
          _dobValid = true;
          _isFirstTimeOpeningDob = false; // User has already picked a date

          // Initialize positions after widgets are built
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_monthController.hasClients &&
                _dayController.hasClients &&
                _yearController.hasClients) {
              _snapToCenter(_monthController, _selectedMonth);
              _snapToCenter(_dayController, _selectedDay);
              _snapToCenter(_yearController, _selectedYear);
            }
          });
        }
      } catch (e) {
        print("Error parsing date of birth: $e");
      }
    }

    // Prefill code if already verified
    if (userProvider.emailCode.isNotEmpty && _code.every((c) => c.isEmpty)) {
      final saved = userProvider.emailCode;
      for (int i = 0; i < saved.length; i++) {
        _codeControllers[i].text = saved[i];
        _code[i] = saved[i];
      }
      setState(() {
        _codeValid = true;
        _isCodeVerified = true;
      });
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    _timer?.cancel();
    _emailFocusNode.removeListener(_validateEmailOnUnfocus);
    for (var f in _focusNodes) f.dispose();
    for (var c in _codeControllers) c.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // Validation methods
  void _validateEmailOnUnfocus() {
    if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
      _validateEmailAndShowError();
    }
  }

  void _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailValid = false;
        _emailError = null;
      });
      return;
    }

    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      setState(() {
        _emailValid = false;
        _emailError = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      _emailValid = true;
      _emailError = null;
    });
  }

  void _validateEmailAndShowError() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailValid = false;
        _emailError = null;
      });
      return;
    }

    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      setState(() {
        _emailValid = false;
        _emailError = "Please enter a valid email address.";
      });
      errorStackKey.currentState?.showError(_emailError!);
      return;
    }

    setState(() {
      _emailValid = true;
      _emailError = null;
    });
  }

  void _validateCountry() {
    setState(() {
      _countryValid = _selectedCountry.isNotEmpty;
    });
  }

  void _validateDob() {
    setState(() {
      _dobValid = _datePicked;
    });
  }

  void _validateCode() {
    final allFilled = _code.every((c) => c.isNotEmpty);
    setState(() {
      _codeValid = allFilled && (_isCodeVerified == true);
    });
  }

  // Check if all fields are valid
  bool get _allFieldsValid =>
      _countryValid && _dobValid && _emailValid && _codeValid;

  // Validate all fields and show errors
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate country
    _validateCountry();
    if (!_countryValid) {
      errorStackKey.currentState?.showError("Please select your country.");
      hasError = true;
    }

    // Validate date of birth
    _validateDob();
    if (!_dobValid) {
      errorStackKey.currentState?.showError(
        "Please select your date of birth.",
      );
      hasError = true;
    }

    // Validate email
    _validateEmail();
    if (!_emailValid && _emailError != null) {
      errorStackKey.currentState?.showError(_emailError!);
      hasError = true;
    } else if (!_emailValid) {
      errorStackKey.currentState?.showError("Please enter your email address.");
      hasError = true;
    }

    // Validate code
    _validateCode();
    if (!_codeValid && _code.any((c) => c.isNotEmpty)) {
      errorStackKey.currentState?.showError("Verification code is incorrect.");
      hasError = true;
    } else if (!_codeValid) {
      errorStackKey.currentState?.showError(
        "Please enter the verification code.",
      );
      hasError = true;
    }
  }

  // Fixed Date picker helper method
  void _snapToCenter(ScrollController controller, int selectedIndex) {
    if (!controller.hasClients) return;

    final itemHeight = 40.0;
    final targetOffset = selectedIndex * itemHeight;
    final maxScroll = controller.position.maxScrollExtent;
    final clampedPosition = targetOffset.clamp(0.0, maxScroll);

    controller.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _filterCountries(String value) {
    setState(() {
      _filteredCountries = countries
          .where((c) => c['name']!.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  void _selectCountry(Map<String, String> country) {
    setState(() {
      _selectedCountry = country['name']!;
      _selectedCountryId = country['name']!;
      _countryFieldController.text = country['name']!;
      _countryDropdownOpen = false;
      _validateCountry();
    });
    final userProvider = context.read<UserProvider>();
    userProvider.setCountry(_selectedCountry, _selectedCountryId);
  }

  String get _dobForApi {
    final month = (_selectedMonth + 1).toString().padLeft(2, '0');
    final day = _days[_selectedDay].toString().padLeft(2, '0');
    final year = _years[_selectedYear].toString();
    return "$year-$month-$day";
  }

  String get _dobDisplayText {
    if (!_datePicked) return "";
    final day = _days[_selectedDay].toString();
    final month = _months[_selectedMonth];
    final year = _years[_selectedYear].toString();
    return "$month $day $year";
  }

  void onDobPicked() {
    final userProvider = context.read<UserProvider>();
    userProvider.setDob(_dobForApi);
  }

  void _onCodeChanged(String value, int index) async {
    // Remove non-digit characters
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      _code[index] = '';
      setState(() {});
      return;
    }

    // If user pasted multiple digits in any field, distribute them
    for (int i = 0; i < 6; i++) {
      if (i >= index && (i - index) < digits.length) {
        _codeControllers[i].text = digits[i - index];
        _code[i] = digits[i - index];
      }
    }

    // Move focus to next empty field
    int nextIndex = _code.indexWhere((c) => c.isEmpty);
    if (nextIndex != -1) {
      _focusNodes[nextIndex].requestFocus();
    } else {
      _focusNodes[5].unfocus(); // All filled
    }

    setState(() {});

    // Auto verify if complete
    if (_code.every((c) => c.isNotEmpty)) {
      await _verifyAndHandleCode();
    }
  }

  Future<void> _verifyAndHandleCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      errorStackKey.currentState?.showError("Email is required.");
      return;
    }

    final userProvider = context.read<UserProvider>();
    bool valid = await _verifyCode(email, _code.join());

    if (valid) {
      userProvider.setEmailCode(_code.join());
      setState(() {
        _isCodeVerified = true;
        _codeValid = true;
        // _codeDisabled = true;
      });
    } else {
      setState(() => _isCodeVerified = false);

      Timer(const Duration(seconds: 3), () {
        if (!mounted) return;

        setState(() {
          for (var c in _codeControllers) c.clear();
          _code = ["", "", "", "", "", ""];
          _isCodeVerified = null;
          _codeDisabled = false;
        });

        _focusNodes[0].requestFocus();
      });
    }
  }

  // API methods
  Future<void> _fetchCodeFromGo() async {
    final email = _emailController.text.trim();
    final userProvider = context.read<UserProvider>();

    if (email.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your email first.");
      return;
    }

    if (!_emailValid) {
      _validateEmailAndShowError();
      return;
    }

    for (var controller in _codeControllers) controller.clear();

    for (var node in _focusNodes) node.unfocus();

    setState(() {
      _code = ["", "", "", "", "", ""];
      _isCodeVerified = null;
      _codeValid = false;
    });

    // Show click animation
    setState(() {
      _isGetCodeClicked = true;
    });

    // Cancel existing timer
    _timer?.cancel();

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/get-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    // Reset animation after short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isGetCodeClicked = false;
        });
      }
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _serverCode = data['code'];
      _attempts = data['attempts'] ?? 0;
      _cooldownSeconds = data['cooldown'] ?? 0;

      setState(() {
        _showCodeSent = true;
        _codeDisabled = _cooldownSeconds > 0;
        _hasCodeBeenSentBefore = true;
      });

      if (_cooldownSeconds > 0) {
        _startCooldownTimer();
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showCodeSent = false);
      });
    } else {
      final data = jsonDecode(response.body);
      errorStackKey.currentState?.showError(
        data['error'] ?? "Failed to send code. Please try again.",
      );
    }
  }

  Future<bool> _verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email.trim(), "code": code.trim()}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['valid'] == true;
    }
    return false;
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _codeDisabled = false;
        });
      }
    });
  }

  String _formatCooldown(int seconds) {
    if (seconds >= 3600) {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      return "${hours}h ${minutes}m";
    } else {
      int minutes = seconds ~/ 60;
      int secs = seconds % 60;
      return "${minutes}m ${secs}s";
    }
  }

  void _handleNextTap() {
    if (_allFieldsValid) {
      _navigateToNext();
    } else {
      _validateAllFieldsAndShowErrors();
    }
  }

  void _handleBackspace(int index) {
    if (_code[index].isEmpty && index > 0) {
      _codeControllers[index - 1].clear();
      _code[index - 1] = '';
      _focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  void _navigateToNext() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => ResponsivePasswordPage(),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // Helper method to close all dropdowns
  void _closeAllDropdowns() {
    // Save scroll positions before closing the date picker
    if (_dobDropdownOpen) {
      _saveScrollPositions();
    }

    setState(() {
      _countryDropdownOpen = false;
      _dobDropdownOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final double dropdownHeight = screenHeight * 0.559;

    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  ErrorStack(key: errorStackKey),
                  const SizedBox(height: 20),

                  // Sign In / Sign Up Buttons
                  SizedBox(
                    width: 230,
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 126,
                          child: CustomButton(
                            text: 'Sign Up',
                            width: 104,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            onTap: () {},
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          child: GestureDetector(
                            child: Container(
                              width: 106,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  width: 1,
                                  color: const Color(0xFF00F0FF),
                                ),
                              ),
                              child: CustomButton(
                                text: 'Sign In',
                                width: 106,
                                height: 40,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                onTap: () {
                                  Navigator.of(context).pushNamed('/sign-in');
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  const Text(
                    "Your Digital Pass Into Egety",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 29,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Progress Steps
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 9.5,
                          left: 26,
                          right: 26,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              const totalSteps = 5;
                              const completedSteps = 2;
                              final segmentCount = totalSteps - 1;
                              final filledSegments = completedSteps - 1;
                              final totalWidth = constraints.maxWidth;
                              final filledWidth =
                                  totalWidth * (filledSegments / segmentCount);
                              final remainingWidth = totalWidth - filledWidth;

                              return Row(
                                children: [
                                  Container(
                                    width: filledWidth,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(100),
                                        bottomLeft: Radius.circular(100),
                                      ),
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF00F0FF),
                                          Color(0xFF0EA0BB),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: remainingWidth,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(100),
                                        bottomRight: Radius.circular(100),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var i = 0; i < 5; i++)
                              Expanded(
                                child: _buildStep(
                                  i == 1 ? "Contact and Verify" : "",
                                  filled: i <= 1,
                                  filledColor: i == 1
                                      ? const Color(0xFF0EA0BB)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Country Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "What Is Your Country Of Residence?",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          height: 1.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _countryDropdownOpen = !_countryDropdownOpen;
                          });
                        },
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              height: 50,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B1320),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF00F0FF),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: SvgPicture.asset(
                                        'assets/images/iconFlag.svg',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  Expanded(
                                    child: TextField(
                                      controller: _countryFieldController,
                                      readOnly: true,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: fontProvider.getScaledSize(15),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                      decoration: InputDecoration(
                                        hintText: "Country",
                                        hintStyle: TextStyle(
                                          color: Color(0xFFA5A6A8),
                                          fontSize: fontProvider.getScaledSize(15),
                                          fontWeight: FontWeight.w500,
                                          fontFamily: 'Inter',
                                          height: 1.0,
                                        ),
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 16,
                              right: 16,
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: Image.asset(
                                  'assets/images/Blacksun-icon-chevron-down.png',
                                  width: 18,
                                  height: 18,
                                  fit: BoxFit.contain,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Date of Birth Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: Text(
                          "When Were You Born?",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          final willOpen = !_dobDropdownOpen;
                          // Set default values when opening the picker for the first time
                          if (willOpen && _isFirstTimeOpeningDob) {
                            _setDefaultDateValues();
                          }

                          setState(() {
                            _dobDropdownOpen = !_dobDropdownOpen;
                          });

                          // When opening, restore the saved scroll positions
                          if (willOpen) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _restoreScrollPositions();
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          height: 50,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1320),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF00F0FF),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/images/DOB.png',
                                width: 16,
                                height: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  _datePicked
                                      ? _dobDisplayText
                                      : "Date Of Birth",
                                  style: TextStyle(
                                    color: _datePicked
                                        ? Colors.white
                                        : const Color(0xFFA5A6A8),
                                    fontSize: fontProvider.getScaledSize(15),
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Email Input
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        child: Text(
                          "Where Can We Reach You?",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 50,
                            padding: const EdgeInsets.only(left: 12, right: 70),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1320),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF00F0FF),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Image.asset(
                                    'assets/images/SVGRepo_iconCarrier.png',
                                    width: 16,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Focus(
                                    onFocusChange: (hasFocus) {
                                      setState(
                                        () => _isEmailFocused = hasFocus,
                                      );
                                    },
                                    child: TextField(
                                      controller: _emailController,
                                      focusNode: _emailFocusNode,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          vertical: 0.0,
                                        ),
                                      ),
                                      onChanged: (value) {
                                        final userProvider = context
                                            .read<UserProvider>();
                                        userProvider.setEmail(value.trim());
                                        _validateEmail();
                                      },
                                      onEditingComplete: () {
                                        _validateEmailAndShowError();
                                        FocusScope.of(context).unfocus();
                                      },
                                      style: TextStyle(
                                        fontSize: fontProvider.getScaledSize(15),
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                        color: Color(0xFF00F0FF),
                                        height: 1.0,
                                      ),
                                      strutStyle: const StrutStyle(
                                        height: 1.0,
                                        leading: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            left: 40,
                            top:
                                (_emailController.text.isNotEmpty ||
                                    _isEmailFocused)
                                ? -6
                                : 20,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize:
                                    (_emailController.text.isNotEmpty ||
                                        _isEmailFocused)
                                    ? 13
                                    : 15,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'Inter',
                                backgroundColor:
                                    (_emailController.text.isNotEmpty ||
                                        _isEmailFocused)
                                    ? const Color(0xFF0B1320)
                                    : Colors.transparent,
                                height: 1.0,
                              ),
                              child: const Text("Email"),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  final userProvider = context
                                      .read<UserProvider>();
                                  if (_emailController.text.isEmpty) {
                                    ClipboardData? clipboardData =
                                        await Clipboard.getData(
                                          Clipboard.kTextPlain,
                                        );
                                    if (clipboardData?.text != null) {
                                      setState(() {
                                        _emailController.text =
                                            clipboardData!.text!;
                                        userProvider.setEmail(
                                          _emailController.text,
                                        );
                                        _validateEmail();
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _emailController.clear();
                                      userProvider.setEmail("");
                                      _validateEmail();
                                    });
                                  }
                                },
                                child: Container(
                                  width: 55,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF),
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child: Center(
                                    child: Text(
                                      _emailController.text.isEmpty
                                          ? "Paste"
                                          : "Clear",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: fontProvider.getScaledSize(15),
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Email Verification
                  Container(
                    width: double.infinity,
                    height: 44,
                    color: Colors.transparent,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -4,
                          left: -1,
                          child: Text(
                            "Email Verification",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              height: 1.0,
                              color: Colors.white,
                              letterSpacing: -0.08,
                            ),
                          ),
                        ),

                        if (_showCodeSent)
                          Positioned(
                            top: 25,
                            left: 50,
                            child: Opacity(
                              opacity: 1,
                              child: Transform.rotate(
                                angle: 0,
                                child: Container(
                                  width: 88,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00F0FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "Code Sent",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: fontProvider.getScaledSize(15),
                                      height: 1.0,
                                      letterSpacing: -1.6,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Positioned(
                            top: 0,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 23.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ...List.generate(6, (index) {
                                    return GestureDetector(
                                      onTap: () =>
                                          _focusNodes[index].requestFocus(),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 5,
                                        ),
                                        child: Column(
                                          children: [
                                            // Show either TextField or colored Text widget
                                            SizedBox(
                                              width: 30,
                                              height: 24,
                                              child:
                                                  _isCodeVerified == true &&
                                                      _code[index].isNotEmpty
                                                  ? Center(
                                                      child: Text(
                                                        _code[index],
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF00F0FF,
                                                          ),
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    )
                                                  : RawKeyboardListener(
                                                      focusNode:
                                                          FocusNode(), // separate focus node (required)
                                                      onKey: (event) {
                                                        if (event
                                                                is RawKeyDownEvent &&
                                                            event.logicalKey ==
                                                                LogicalKeyboardKey
                                                                    .backspace) {
                                                          _handleBackspace(
                                                            index,
                                                          );
                                                        }
                                                      },
                                                      child: TextField(
                                                        enabled: !_codeDisabled,
                                                        readOnly: _codeDisabled,
                                                        showCursor:
                                                            !_codeDisabled,
                                                        controller:
                                                            _codeControllers[index],
                                                        focusNode:
                                                            _focusNodes[index],
                                                        textAlign:
                                                            TextAlign.center,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        style: TextStyle(
                                                          color: _codeDisabled
                                                              ? Colors.grey
                                                              : (_isCodeVerified ==
                                                                        true
                                                                    ? const Color(
                                                                        0xFF00F0FF,
                                                                      )
                                                                    : (_isCodeVerified ==
                                                                              false
                                                                          ? Colors.red
                                                                          : Colors.white)),
                                                          fontSize: 20,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                        cursorColor:
                                                            Colors.white,
                                                        decoration:
                                                            const InputDecoration(
                                                              counterText: "",
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                            ),
                                                        onChanged: _codeDisabled
                                                            ? null
                                                            : (value) =>
                                                                  _onCodeChanged(
                                                                    value,
                                                                    index,
                                                                  ),
                                                      ),
                                                    ),
                                            ),
                                            if (_isCodeVerified != true)
                                              Container(
                                                width: 30,
                                                height: 2,
                                                color: _codeDisabled
                                                    ? Colors.grey
                                                    : (_code[index].isEmpty
                                                          ? Colors.white
                                                          : Colors.transparent),
                                              ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  if (_isCodeVerified != null) ...[
                                    const SizedBox(width: 10),
                                    Transform.translate(
                                      offset: const Offset(-5, 0),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _isCodeVerified == true
                                              ? const Color(0xFF00F0FF)
                                              : Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _isCodeVerified == true
                                              ? Icons.check
                                              : Icons.close,
                                          color: _isCodeVerified == true
                                              ? Colors.black
                                              : Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 21,
                          right: 0,
                          child: MouseRegion(
                            onEnter: (_cooldownSeconds == 0 && _emailValid)
                                ? (_) =>
                                      setState(() => _isGetCodeHovered = true)
                                : null,
                            onExit: (_) =>
                                setState(() => _isGetCodeHovered = false),
                            cursor: (_cooldownSeconds == 0 && _emailValid)
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.forbidden,
                            child: GestureDetector(
                              onTap: (_cooldownSeconds == 0 && _emailValid)
                                  ? _fetchCodeFromGo
                                  : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 100),
                                width: 100,
                                height: 30,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF00F0FF),
                                      const Color(0xFF0177B3),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: _isGetCodeClicked
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00F0FF,
                                            ).withOpacity(0.4),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 0),
                                          ),
                                        ]
                                      : (_isGetCodeHovered
                                            ? [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ).withOpacity(0.4),
                                                  blurRadius: 8,
                                                  spreadRadius: 1,
                                                  offset: const Offset(0, 0),
                                                ),
                                              ]
                                            : [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ).withOpacity(0.8),
                                                  blurRadius: 15,
                                                  spreadRadius: 2,
                                                  offset: const Offset(0, 0),
                                                ),
                                              ]),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: _cooldownSeconds > 0
                                      ? Text(
                                          _formatCooldown(_cooldownSeconds),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 18,
                                            color: Colors.black,
                                          ),
                                        )
                                      : Text(
                                          _hasCodeBeenSentBefore
                                              ? "Send Again"
                                              : "Get Code",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Navigation Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: Row(
                      children: [
                        // Left gradient line - takes available space
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: 8),
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
                        ),

                        MouseRegion(
                          onEnter: (_) => setState(() => _isBackHovered = true),
                          onExit: (_) => setState(() => _isBackHovered = false),
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
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
                                    textColor: _isBackHovered
                                        ? const Color(0xFF00F0FF)
                                        : Colors.white,
                                    backgroundColor: Colors.transparent,
                                    borderColor: Colors.transparent,
                                    onTap: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Spacer between buttons
                        SizedBox(width: 8),

                        MouseRegion(
                          onEnter: (_) => _allFieldsValid
                              ? setState(() => _isNextHovered = true)
                              : null,
                          onExit: (_) => setState(() => _isNextHovered = false),
                          cursor: _allFieldsValid
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.forbidden,
                          child: CustomButton(
                            text: "Next",
                            width: 105,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            textColor: _allFieldsValid
                                ? (_isNextHovered
                                      ? const Color(0xFF00F0FF)
                                      : Colors.white)
                                : const Color(0xFF718096),
                            backgroundColor: Colors.transparent,
                            borderColor: _allFieldsValid
                                ? const Color(0xFF00F0FF)
                                : const Color(0xFF4A5568),
                            onTap: _handleNextTap,
                          ),
                        ),

                        // Right gradient line - takes available space
                        Expanded(
                          child: Container(
                            margin: EdgeInsets.only(left: 8),
                            height: 4,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: const [
                                  Color(0xFF0B1320),
                                  Color(0xFF00F0FF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  const Center(
                    child: Text(
                      "Your ID is now verified\nYour vault is a step closer to being yours",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.normal,
                        fontSize: 20,
                        height: 1.0,
                        letterSpacing: 0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const FooterWidget(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // BACKGROUND OVERLAY WHEN DROPDOWN IS OPEN
          if (_countryDropdownOpen || _dobDropdownOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeAllDropdowns,
                child: Container(color: Colors.black.withOpacity(0.6)),
              ),
            ),
          SlideUpMenu(
            menuHeight: dropdownHeight, // can be smaller now
            isVisible: _countryDropdownOpen,
            onToggle: () {
              setState(() {
                _countryDropdownOpen = !_countryDropdownOpen;
              });
            },
            onClose: () {
              setState(() {
                _countryDropdownOpen = false;
              });
            },
            backgroundColor: const Color(0xFF0B1320),
            shadowColor: const Color(0xFF00F0FF),
            borderRadius: 20.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            minHeight: 100,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            dragHandle: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: CustomPaint(
                size: const Size(120, 20),
                painter: VLinePainter(),
              ),
            ),
            child: SizedBox(
              // height: dropdownHeight,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // SEARCH FIELD
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 5,
                      ),
                      child: TextField(
                        controller: _countrySearchController,
                        onChanged: _filterCountries,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search Country',
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

                    // COUNTRY LIST
                    _filteredCountries.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                "No countries found",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 50,
                              vertical: 8,
                            ),
                            itemCount: _filteredCountries.length,
                            itemBuilder: (context, index) {
                              final country = _filteredCountries[index];
                              final isSelected =
                                  country['name'] == _selectedCountry;
                              return GestureDetector(
                                onTap: () => _selectCountry(country),
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
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          country['name'] ?? '',
                                          style: TextStyle(
                                            color: isSelected
                                                ? const Color(0xFF00F0FF)
                                                : Colors.white,
                                            fontSize: 16,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isSelected)
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
                  ],
                ),
              ),
            ),
          ),

          // DOB DROPDOWN POPUP
          SlideUpMenu(
            menuHeight: 370,
            maxHeight: 500,
            isVisible: _dobDropdownOpen,
            onToggle: () {
              final willOpen = !_dobDropdownOpen;
              setState(() {
                _dobDropdownOpen = !_dobDropdownOpen;
              });

              // When opening, restore positions to show selected values
              if (willOpen) {
                _restoreScrollPositions();
              }
            },
            onClose: () {
              _saveScrollPositions();
              setState(() {
                _dobDropdownOpen = false;
              });
            },
            backgroundColor: const Color(0xFF0B1320),
            shadowColor: const Color(0xFF00F0FF),
            borderRadius: 20.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // DATE PICKER - Compact version
                  Container(
                    height: 280,
                    child: Stack(
                      children: [
                        // Center highlight
                        Positioned(
                          top: (286 / 2) - 24.5,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 49,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BEBF),
                              border: Border.all(
                                color: const Color(0xFF007BFF),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        // Month column
                        Row(
                          children: [
                            // Month column
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollEndNotification) {
                                    if (!_monthController.hasClients)
                                      return true;

                                    final itemHeight = 40.0;
                                    final scrollOffset =
                                        _monthController.offset;
                                    final currentIndex =
                                        (scrollOffset / itemHeight).round();
                                    final clampedIndex = currentIndex.clamp(
                                      0,
                                      _months.length - 1,
                                    );

                                    // Always snap to center when scrolling ends
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (_monthController.hasClients) {
                                            _snapToCenter(
                                              _monthController,
                                              clampedIndex,
                                            );
                                          }
                                        });
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  key: const PageStorageKey<String>(
                                    'month_list',
                                  ),
                                  shrinkWrap: true,
                                  itemCount: _months.length,
                                  controller: _monthController,
                                  physics: const ClampingScrollPhysics(),
                                  itemExtent: 40,
                                  padding: EdgeInsets.symmetric(
                                    vertical: (286 - 40) / 2,
                                  ),
                                  itemBuilder: (context, index) {
                                    final isSelected = index == _selectedMonth;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedMonth = index;
                                          _datePicked = true;
                                          _updateDaysList();
                                          _validateDob();
                                        });
                                        onDobPicked();
                                        _snapToCenter(_monthController, index);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          _months[index],
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Day column
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollEndNotification) {
                                    if (!_dayController.hasClients) return true;

                                    final itemHeight = 40.0;
                                    final scrollOffset = _dayController.offset;
                                    final currentIndex =
                                        (scrollOffset / itemHeight).round();
                                    final clampedIndex = currentIndex.clamp(
                                      0,
                                      _days.length - 1,
                                    );

                                    // Always snap to center when scrolling ends
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (_dayController.hasClients) {
                                            _snapToCenter(
                                              _dayController,
                                              clampedIndex,
                                            );
                                          }
                                        });
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  key: const PageStorageKey<String>('day_list'),
                                  shrinkWrap: true,
                                  itemCount: _days.length,
                                  padding: EdgeInsets.symmetric(
                                    vertical: (286 - 40) / 2,
                                  ),
                                  itemExtent: 40,
                                  physics: const ClampingScrollPhysics(),
                                  controller: _dayController,
                                  itemBuilder: (context, index) {
                                    final isSelected = index == _selectedDay;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedDay = index;
                                          _datePicked = true;
                                          _validateDob();
                                        });
                                        onDobPicked();
                                        _snapToCenter(_dayController, index);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          _days[index].toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),

                            // Year column
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (notification) {
                                  if (notification is ScrollEndNotification) {
                                    if (!_yearController.hasClients)
                                      return true;

                                    final itemHeight = 40.0;
                                    final scrollOffset = _yearController.offset;
                                    final currentIndex =
                                        (scrollOffset / itemHeight).round();
                                    final clampedIndex = currentIndex.clamp(
                                      0,
                                      _years.length - 1,
                                    );

                                    // Always snap to center when scrolling ends
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                          if (_yearController.hasClients) {
                                            _snapToCenter(
                                              _yearController,
                                              clampedIndex,
                                            );
                                          }
                                        });
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  key: const PageStorageKey<String>(
                                    'year_list',
                                  ),
                                  shrinkWrap: true,
                                  itemCount: _years.length,
                                  padding: EdgeInsets.symmetric(
                                    vertical: (286 - 40) / 2,
                                  ),
                                  itemExtent: 40,
                                  physics: const ClampingScrollPhysics(),
                                  controller: _yearController,
                                  itemBuilder: (context, index) {
                                    final isSelected = index == _selectedYear;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedYear = index;
                                          _datePicked = true;
                                          _updateDaysList();
                                          _validateDob();
                                        });
                                        onDobPicked();
                                        _snapToCenter(_yearController, index);
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          _years[index].toString(),
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? Colors.black
                                                : Colors.white,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Add white space under the Set button
                  const SizedBox(height: 20),
                  // Close button
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 20),
                    child: GestureDetector(
                      onTap: () {
                        // Save scroll positions before closing
                        _saveScrollPositions();
                        setState(() {
                          _dobDropdownOpen = false;
                          // Ensure date is marked as picked
                          _datePicked = true;
                        });
                        onDobPicked();
                      },
                      child: Container(
                        width: 120,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 1,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'Set',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildStep(String label, {bool filled = false, Color? filledColor}) {
    final fontProvider = Provider.of<FontSizeProvider>(context);
    return SizedBox(
      height: 83,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: filled
                ? (filledColor ?? const Color(0xFF00F0FF))
                : Colors.white,
            child: filled
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: fontProvider.getScaledSize(15),
              height: 1.0,
              letterSpacing: 0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Tablet version with same validation logic
class TabletProtectAccess extends StatefulWidget {
  const TabletProtectAccess({super.key});

  @override
  State<TabletProtectAccess> createState() => _TabletProtectAccessState();
}

class _TabletProtectAccessState extends State<TabletProtectAccess> {
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();

  // Button hover states
  bool _isBackHovered = false;
  bool _isNextHovered = false;
  bool _isGetCodeHovered = false;
  bool _isGetCodeClicked = false;

  // Dropdown states
  bool _countryDropdownOpen = false;
  bool _dobDropdownOpen = false;

  // Selected values
  String _selectedCountry = '';
  String _selectedCountryId = '';
  bool _datePicked = false;

  // Validation states
  bool _countryValid = false;
  bool _dobValid = false;
  bool _emailValid = false;
  bool _codeValid = false;
  String? _emailError;

  // Controllers
  final TextEditingController _countryFieldController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();

  // Code input controllers
  final List<TextEditingController> _codeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  List<String> _code = ["", "", "", "", "", ""];

  // Focus nodes
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;

  // Date picker controllers
  late final ScrollController _monthController;
  late final ScrollController _dayController;
  late final ScrollController _yearController;

  // Date values
  int _selectedMonth = 0;
  int _selectedDay = 0;
  int _selectedYear = 0;

  // Email verification states
  String _serverCode = "";
  int _attempts = 0;
  bool _showCodeSent = false;
  bool _codeDisabled = false;
  bool? _isCodeVerified;

  // Timer and cooldown
  Timer? _timer;
  int _cooldownSeconds = 0;

  // Country list
  List<Map<String, String>> get countries => CountriesService.getCountries();
  List<Map<String, String>> _filteredCountries = [];

  // Date lists
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  final List<int> _days = List.generate(31, (i) => i + 1);
  final List<int> _years = List.generate(56, (i) => 1970 + i);

  // Get if any sheet is open
  bool get _anySheetOpen => _countryDropdownOpen || _dobDropdownOpen;

  @override
  void initState() {
    super.initState();

    // Initialize controllers
    _monthController = ScrollController();
    _dayController = ScrollController();
    _yearController = ScrollController();

    // Initialize countries
    _filteredCountries = List.from(countries);

    // Add focus listener for email validation
    _emailFocusNode.addListener(_validateEmailOnUnfocus);

    // Add search listener
    _countrySearchController.addListener(
      () => _filterCountries(_countrySearchController.text),
    );

    // Initialize date picker after widgets are built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDatePickerListeners();
      _initializeDatePickerPositions();
    });
  }

  void _initializeDatePickerPositions() {
    // Only snap to center if we have pre-filled data
    if (_datePicked) {
      _snapToCenter(_monthController, _selectedMonth);
      _snapToCenter(_dayController, _selectedDay);
      _snapToCenter(_yearController, _selectedYear);
    } else {
      // Initialize with current date
      final now = DateTime.now();
      _selectedYear = _years.indexOf(now.year);
      _selectedMonth = now.month - 1;
      _selectedDay = now.day - 1;
      _datePicked = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _snapToCenter(_monthController, _selectedMonth);
        _snapToCenter(_dayController, _selectedDay);
        _snapToCenter(_yearController, _selectedYear);
      });
    }
  }

  void _setupDatePickerListeners() {
    void _updateDobController() {
      _dobController.text = _dobDisplayText;
      onDobPicked();
    }

    _monthController.addListener(() {
      if (!_monthController.hasClients) return;
      final itemHeight = 40.0;
      final containerHeight = 286.0;
      final centerOffset = (containerHeight / 2) - (itemHeight / 2);
      final scrollOffset = _monthController.offset + centerOffset;
      final newIndex = (scrollOffset / itemHeight).round();
      final clampedIndex = newIndex.clamp(0, _months.length - 1);
      if (clampedIndex != _selectedMonth) {
        setState(() {
          _selectedMonth = clampedIndex;
          _datePicked = true;
          _updateDobController();
          _validateDob();
        });
      }
    });

    _dayController.addListener(() {
      if (!_dayController.hasClients) return;
      final itemHeight = 40.0;
      final containerHeight = 286.0;
      final centerOffset = (containerHeight / 2) - (itemHeight / 2);
      final scrollOffset = _dayController.offset + centerOffset;
      final newIndex = (scrollOffset / itemHeight).round();
      final clampedIndex = newIndex.clamp(0, _days.length - 1);
      if (clampedIndex != _selectedDay) {
        setState(() {
          _selectedDay = clampedIndex;
          _datePicked = true;
          _updateDobController();
          _validateDob();
        });
      }
    });

    _yearController.addListener(() {
      if (!_yearController.hasClients) return;
      final itemHeight = 40.0;
      final containerHeight = 286.0;
      final centerOffset = (containerHeight / 2) - (itemHeight / 2);
      final scrollOffset = _yearController.offset + centerOffset;
      final newIndex = (scrollOffset / itemHeight).round();
      final clampedIndex = newIndex.clamp(0, _years.length - 1);
      if (clampedIndex != _selectedYear) {
        setState(() {
          _selectedYear = clampedIndex;
          _datePicked = true;
          _updateDobController();
          _validateDob();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userProvider = context.read<UserProvider>();

    // Prefill country
    if (userProvider.country.isNotEmpty && _selectedCountry.isEmpty) {
      _selectedCountry = userProvider.country;
      _selectedCountryId = userProvider.countryId;
      _countryFieldController.text = userProvider.country;
      _countryValid = true;
    }

    // Prefill email
    if (_emailController.text.isEmpty) {
      _emailController.text = userProvider.email;
      _validateEmail();
    }

    // Prefill date of birth
    if (_dobController.text.isEmpty && userProvider.dob.isNotEmpty) {
      final parts = userProvider.dob.split('-');
      final year = parts[0];
      final monthIndex = int.parse(parts[1]) - 1;
      final day = int.parse(parts[2]);
      _selectedYear = _years.indexOf(int.parse(year));
      _selectedMonth = monthIndex;
      _selectedDay = day - 1;
      _datePicked = true;
      _dobController.text = "${_months[monthIndex]} $day $year";
      _dobValid = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_monthController.hasClients &&
            _dayController.hasClients &&
            _yearController.hasClients) {
          _snapToCenter(_monthController, _selectedMonth);
          _snapToCenter(_dayController, _selectedDay);
          _snapToCenter(_yearController, _selectedYear);
        }
      });
    }

    // Prefill code if already verified
    if (userProvider.emailCode.isNotEmpty && _code.every((c) => c.isEmpty)) {
      final saved = userProvider.emailCode;
      for (int i = 0; i < saved.length; i++) {
        _codeControllers[i].text = saved[i];
        _code[i] = saved[i];
      }
      setState(() {
        _codeValid = true;
        _isCodeVerified = true;
      });
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    _timer?.cancel();
    _emailFocusNode.removeListener(_validateEmailOnUnfocus);
    for (var f in _focusNodes) f.dispose();
    for (var c in _codeControllers) c.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // Validation methods (same as mobile)
  void _validateEmailOnUnfocus() {
    if (!_emailFocusNode.hasFocus && _emailController.text.isNotEmpty) {
      _validateEmailAndShowError();
    }
  }

  void _validateEmail() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailValid = false;
        _emailError = null;
      });
      return;
    }

    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      setState(() {
        _emailValid = false;
        _emailError = "Please enter a valid email address.";
      });
      return;
    }

    setState(() {
      _emailValid = true;
      _emailError = null;
    });
  }

  void _validateEmailAndShowError() {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _emailValid = false;
        _emailError = null;
      });
      return;
    }

    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      setState(() {
        _emailValid = false;
        _emailError = "Please enter a valid email address.";
      });
      errorStackKey.currentState?.showError(_emailError!);
      return;
    }

    setState(() {
      _emailValid = true;
      _emailError = null;
    });
  }

  void _validateCountry() {
    setState(() {
      _countryValid = _selectedCountry.isNotEmpty;
    });
  }

  void _validateDob() {
    setState(() {
      _dobValid = _datePicked;
    });
  }

  void _validateCode() {
    final allFilled = _code.every((c) => c.isNotEmpty);
    setState(() {
      _codeValid = allFilled && (_isCodeVerified == true);
    });
  }

  // Check if all fields are valid
  bool get _allFieldsValid =>
      _countryValid && _dobValid && _emailValid && _codeValid;

  // Validate all fields and show errors
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate country
    _validateCountry();
    if (!_countryValid) {
      errorStackKey.currentState?.showError("Please select your country.");
      hasError = true;
    }

    // Validate date of birth
    _validateDob();
    if (!_dobValid) {
      errorStackKey.currentState?.showError(
        "Please select your date of birth.",
      );
      hasError = true;
    }

    // Validate email
    _validateEmail();
    if (!_emailValid && _emailError != null) {
      errorStackKey.currentState?.showError(_emailError!);
      hasError = true;
    } else if (!_emailValid) {
      errorStackKey.currentState?.showError("Please enter your email address.");
      hasError = true;
    }

    // Validate code
    _validateCode();
    if (!_codeValid && _code.any((c) => c.isNotEmpty)) {
      errorStackKey.currentState?.showError("Verification code is incorrect.");
      hasError = true;
    } else if (!_codeValid) {
      errorStackKey.currentState?.showError(
        "Please enter the verification code.",
      );
      hasError = true;
    }
  }

  // Fixed Date picker helper method
  void _snapToCenter(ScrollController controller, int selectedIndex) {
    if (!controller.hasClients) return;

    // Determine item height based on which controller it is
    double itemHeight;
    if (controller == _monthController) {
      itemHeight = 40.0; // FIXED: Changed from 20.0 to 40.0
    } else {
      itemHeight = 40.0;
    }

    final containerHeight = 286.0;
    final centerOffset = (containerHeight / 2) - (itemHeight / 2);
    final targetOffset = selectedIndex * itemHeight;
    final scrollPosition = targetOffset - centerOffset;
    final maxScroll = controller.position.maxScrollExtent;
    final clampedPosition = scrollPosition.clamp(0.0, maxScroll);

    controller.animateTo(
      clampedPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _filterCountries(String value) {
    setState(() {
      _filteredCountries = countries
          .where((c) => c['name']!.toLowerCase().contains(value.toLowerCase()))
          .toList();
    });
  }

  void _selectCountry(Map<String, String> country) {
    setState(() {
      _selectedCountry = country['name']!;
      _selectedCountryId = country['name']!;
      _countryFieldController.text = country['name']!;
      _countryDropdownOpen = false;
      _validateCountry();
    });
    final userProvider = context.read<UserProvider>();
    userProvider.setCountry(_selectedCountry, _selectedCountryId);
  }

  String get _dobForApi {
    final month = (_selectedMonth + 1).toString().padLeft(2, '0');
    final day = _days[_selectedDay].toString().padLeft(2, '0');
    final year = _years[_selectedYear].toString();
    return "$year-$month-$day";
  }

  String get _dobDisplayText {
    if (!_datePicked) return "";
    final day = _days[_selectedDay].toString();
    final month = _months[_selectedMonth];
    final year = _years[_selectedYear].toString();
    return "$month $day $year";
  }

  void onDobPicked() {
    final userProvider = context.read<UserProvider>();
    userProvider.setDob(_dobForApi);
  }

  // Helper method to close all dropdowns
  void _closeAllSheets() {
    setState(() {
      _countryDropdownOpen = false;
      _dobDropdownOpen = false;
    });
  }

  // Code input handler
  void _onCodeChanged(String value, int index) async {
    if (value.length > 1) {
      _codeControllers[index].text = value[0];
    }

    setState(() {
      _code[index] = _codeControllers[index].text;
    });

    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();

    if (_code.every((c) => c.isNotEmpty)) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        errorStackKey.currentState?.showError("Email is required.");
        return;
      }

      final userProvider = context.read<UserProvider>();
      bool valid = await _verifyCode(email, _code.join());

      if (valid) {
        userProvider.setEmailCode(_code.join());
        setState(() {
          _isCodeVerified = true;
          _codeValid = true;
        });
      } else {
        setState(() {
          _isCodeVerified = false;
        });

        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            for (var c in _codeControllers) c.clear();
            _code = ["", "", "", "", "", ""];
          });
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  // API methods
  Future<void> _fetchCodeFromGo() async {
    final email = _emailController.text.trim();
    final userProvider = context.read<UserProvider>();

    if (email.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your email first.");
      return;
    }

    if (!_emailValid) {
      _validateEmailAndShowError();
      return;
    }

    // Show click animation
    setState(() {
      _isGetCodeClicked = true;
    });

    // Cancel existing timer
    _timer?.cancel();

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/get-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    // Reset animation after short delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isGetCodeClicked = false;
        });
      }
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _serverCode = data['code'];
      _attempts = data['attempts'] ?? 0;
      _cooldownSeconds = data['cooldown'] ?? 0;

      setState(() {
        _showCodeSent = true;
        _codeDisabled = _cooldownSeconds > 0;
      });

      if (_cooldownSeconds > 0) {
        _startCooldownTimer();
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showCodeSent = false);
      });
    } else {
      final data = jsonDecode(response.body);
      errorStackKey.currentState?.showError(
        data['error'] ?? "Failed to send code. Please try again.",
      );
    }
  }

  Future<bool> _verifyCode(String email, String code) async {
    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email.trim(), "code": code.trim()}),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return result['valid'] == true;
    }
    return false;
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() {
          _cooldownSeconds--;
        });
      } else {
        timer.cancel();
        setState(() {
          _codeDisabled = false;
        });
      }
    });
  }

  String _formatCooldown(int seconds) {
    if (seconds >= 3600) {
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      return "${hours}h ${minutes}m";
    } else {
      int minutes = seconds ~/ 60;
      int secs = seconds % 60;
      return "${minutes}m ${secs}s";
    }
  }

  void _handleNextTap() {
    if (_allFieldsValid) {
      _navigateToNext();
    } else {
      _validateAllFieldsAndShowErrors();
    }
  }

  void _navigateToNext() {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => ResponsivePasswordPage(),
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  // Build country dropdown sheet
  Widget _buildCountrySheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        color: const Color(0xFF0B1320),
        child: Column(
          children: [
            const SizedBox(height: 18),

            // HANDLE
            GestureDetector(
              onTap: () => setState(() => _countryDropdownOpen = false),
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
                controller: _countrySearchController,
                onChanged: _filterCountries,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Search Country',
                  hintStyle: TextStyle(color: Colors.white54, fontSize: 22),
                  border: InputBorder.none,
                ),
              ),
            ),

            const Divider(color: Colors.white24),

            if (_selectedCountry.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: const Color(0xFF00F0FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Selected: $_selectedCountry',
                      style: const TextStyle(
                        color: Color(0xFF00F0FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

            // COUNTRIES GRID
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 60,
                  vertical: 20,
                ),
                itemCount: _filteredCountries.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 15,
                ),
                itemBuilder: (context, i) {
                  final country = _filteredCountries[i];
                  final isSelected = country['name'] == _selectedCountry;
                  return GestureDetector(
                    onTap: () => _selectCountry(country),
                    child: Row(
                      children: [
                        SvgPicture.asset(
                          country['flag']!,
                          width: 35,
                          height: 35,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Text(
                            country['name']!,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF00F0FF)
                                  : Colors.white,
                              fontSize: 18,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: const Color(0xFF00F0FF),
                            size: 20,
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

  // Build DOB dropdown sheet
  Widget _buildDobSheet() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: Container(
        color: const Color(0xFF0B1320),
        child: Column(
          children: [
            const SizedBox(height: 18),

            // HANDLE
            GestureDetector(
              onTap: () => setState(() => _dobDropdownOpen = false),
              child: CustomPaint(
                size: const Size(120, 20),
                painter: VLinePainter(),
              ),
            ),

            const SizedBox(height: 20),

            // DATE PICKER
            SizedBox(
              height: 286,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      width: double.infinity,
                      height: 286,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0B1320),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: double.infinity,
                      height: 49,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BEBF),
                        border: Border.all(
                          color: const Color(0xFF007BFF),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            if (!_monthController.hasClients) return true;
                            final itemHeight = 40.0;
                            final containerHeight = 286.0;
                            final centerOffset =
                                (containerHeight / 2) - (itemHeight / 2);
                            final scrollOffset =
                                _monthController.offset + centerOffset;
                            final index = (scrollOffset / itemHeight).round();
                            final clampedIndex = index.clamp(
                              0,
                              _months.length - 1,
                            );
                            _snapToCenter(_monthController, clampedIndex);
                            return true;
                          },
                          child: ListView.builder(
                            itemCount: _months.length,
                            controller: _monthController,
                            physics: const ClampingScrollPhysics(),
                            itemExtent: 40,
                            padding: EdgeInsets.symmetric(
                              vertical: (286 - 40) / 2,
                            ),
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedMonth;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedMonth = index;
                                    _datePicked = true;
                                    _validateDob();
                                  });
                                  onDobPicked();
                                  _snapToCenter(_monthController, index);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _months[index],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            if (!_dayController.hasClients) return true;
                            final itemHeight = 40.0;
                            final containerHeight = 286.0;
                            final centerOffset =
                                (containerHeight / 2) - (itemHeight / 2);
                            final scrollOffset =
                                _dayController.offset + centerOffset;
                            final index = (scrollOffset / itemHeight).round();
                            final clampedIndex = index.clamp(
                              0,
                              _days.length - 1,
                            );
                            _snapToCenter(_dayController, clampedIndex);
                            return true;
                          },
                          child: ListView.builder(
                            itemCount: _days.length,
                            padding: EdgeInsets.symmetric(
                              vertical: (286 - 40) / 2,
                            ),
                            itemExtent: 40,
                            physics: const ClampingScrollPhysics(),
                            controller: _dayController,
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedDay;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedDay = index;
                                    _datePicked = true;
                                    _validateDob();
                                  });
                                  onDobPicked();
                                  _snapToCenter(_dayController, index);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _days[index].toString(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      Expanded(
                        child: NotificationListener<ScrollEndNotification>(
                          onNotification: (notification) {
                            if (!_yearController.hasClients) return true;
                            final itemHeight = 40.0;
                            final containerHeight = 286.0;
                            final centerOffset =
                                (containerHeight / 2) - (itemHeight / 2);
                            final scrollOffset =
                                _yearController.offset + centerOffset;
                            final index = (scrollOffset / itemHeight).round();
                            final clampedIndex = index.clamp(
                              0,
                              _years.length - 1,
                            );
                            _snapToCenter(_yearController, clampedIndex);
                            return true;
                          },
                          child: ListView.builder(
                            itemCount: _years.length,
                            padding: EdgeInsets.symmetric(
                              vertical: (286 - 40) / 2,
                            ),
                            itemExtent: 40,
                            physics: const ClampingScrollPhysics(),
                            controller: _yearController,
                            itemBuilder: (context, index) {
                              final isSelected = index == _selectedYear;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedYear = index;
                                    _datePicked = true;
                                    _validateDob();
                                  });
                                  onDobPicked();
                                  _snapToCenter(_yearController, index);
                                },
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Text(
                                    _years[index].toString(),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;
    final double sheetHeight = 650;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Error Stack
          Positioned(
            top: 20,
            left: 0,
            right: 0,
            child: ErrorStack(key: errorStackKey),
          ),

          // Main content
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.07,
                      vertical: screenHeight * 0.03,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isLandscape ? 600 : 500,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B1320),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F0FF),
                                blurRadius: 7,
                                spreadRadius: 0,
                              ),
                            ],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF00F0FF),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Sign Up / Sign In buttons
                              SizedBox(
                                width: 230,
                                height: 40,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 126,
                                      child: CustomButton(
                                        text: 'Sign Up',
                                        width: 104,
                                        height: 40,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        onTap: () {},
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF00F0FF),
                                            Color(0xFF0177B3),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00F0FF,
                                            ).withOpacity(0.5),
                                            blurRadius: 10,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      child: GestureDetector(
                                        child: Container(
                                          width: 106,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              width: 1,
                                              color: const Color(0xFF00F0FF),
                                            ),
                                          ),
                                          child: CustomButton(
                                            text: 'Sign In',
                                            width: 106,
                                            height: 40,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            onTap: () {},
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Title
                              const Text(
                                "Your Digital Pass Into Egety",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 32,
                                  height: 1.0,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Progress Steps
                              SizedBox(
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      top: 9.5,
                                      left: 32,
                                      right: 32,
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          const totalSteps = 5;
                                          const completedSteps = 2;
                                          final segmentCount = totalSteps - 1;
                                          final filledSegments =
                                              completedSteps - 1;
                                          final totalWidth =
                                              constraints.maxWidth;
                                          final filledWidth =
                                              totalWidth *
                                              (filledSegments / segmentCount);
                                          final remainingWidth =
                                              totalWidth - filledWidth;

                                          return Row(
                                            children: [
                                              Container(
                                                width: filledWidth,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        topLeft:
                                                            Radius.circular(
                                                              100,
                                                            ),
                                                        bottomLeft:
                                                            Radius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Color(0xFF00F0FF),
                                                      Color(0xFF0EA0BB),
                                                    ],
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                width: remainingWidth,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.only(
                                                        topRight:
                                                            Radius.circular(
                                                              100,
                                                            ),
                                                        bottomRight:
                                                            Radius.circular(
                                                              100,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        for (var i = 0; i < 5; i++)
                                          Expanded(
                                            child: _buildStep(
                                              i == 1
                                                  ? "Contact\nand Verify"
                                                  : "",
                                              filled: i <= 1,
                                              filledColor: i == 1
                                                  ? const Color(0xFF0EA0BB)
                                                  : null,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Form Fields
                              SizedBox(
                                width: 450,
                                child: Column(
                                  children: [
                                    // Country Input
                                    _buildTabletInputSection(
                                      title:
                                          "What Is Your Country Of Residence?",
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _countryDropdownOpen =
                                              !_countryDropdownOpen,
                                        ),
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 400,
                                              height: 50,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0B1320),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4.0,
                                                        ),
                                                    child: SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: SvgPicture.asset(
                                                        'assets/images/iconFlag.svg',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 18),
                                                  Expanded(
                                                    child: TextField(
                                                      controller:
                                                          _countryFieldController,
                                                      readOnly: true,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Inter',
                                                      ),
                                                      decoration:
                                                          const InputDecoration(
                                                            hintText: "Country",
                                                            hintStyle:
                                                                TextStyle(
                                                                  color: Color(
                                                                    0xFFA5A6A8,
                                                                  ),
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontFamily:
                                                                      'Inter',
                                                                  height: 1.0,
                                                                ),
                                                            border: InputBorder
                                                                .none,
                                                            isDense: true,
                                                          ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Positioned(
                                              top: 16,
                                              right: 16,
                                              child: SizedBox(
                                                width: 18,
                                                height: 18,
                                                child: Image.asset(
                                                  'assets/images/Blacksun-icon-chevron-down.png',
                                                  width: 18,
                                                  height: 18,
                                                  fit: BoxFit.contain,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    // Date of Birth Input
                                    _buildTabletInputSection(
                                      title: "When Were You Born?",
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _dobDropdownOpen =
                                              !_dobDropdownOpen,
                                        ),
                                        child: Container(
                                          width: 400,
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0B1320),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF00F0FF),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Image.asset(
                                                'assets/images/DOB.png',
                                                width: 16,
                                                height: 18,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: Text(
                                                  _datePicked
                                                      ? _dobDisplayText
                                                      : "Date Of Birth",
                                                  style: TextStyle(
                                                    color: _datePicked
                                                        ? Colors.white
                                                        : const Color(
                                                            0xFFA5A6A8,
                                                          ),
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'Inter',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    // Email Input
                                    _buildTabletInputSection(
                                      title: "Where Can We Reach You?",
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 400,
                                            height: 50,
                                            padding: const EdgeInsets.only(
                                              left: 12,
                                              right: 70,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0B1320),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF00F0FF),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                  child: Image.asset(
                                                    'assets/images/SVGRepo_iconCarrier.png',
                                                    width: 16,
                                                    height: 18,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Focus(
                                                    onFocusChange: (hasFocus) =>
                                                        setState(
                                                          () =>
                                                              _isEmailFocused =
                                                                  hasFocus,
                                                        ),
                                                    child: TextField(
                                                      controller:
                                                          _emailController,
                                                      focusNode:
                                                          _emailFocusNode,
                                                      decoration:
                                                          const InputDecoration(
                                                            border: InputBorder
                                                                .none,
                                                            isCollapsed: true,
                                                            contentPadding:
                                                                EdgeInsets.only(
                                                                  top: 0,
                                                                ),
                                                          ),
                                                      onChanged: (value) {
                                                        final userProvider =
                                                            context
                                                                .read<
                                                                  UserProvider
                                                                >();
                                                        userProvider.setEmail(
                                                          value.trim(),
                                                        );
                                                        _validateEmail();
                                                      },
                                                      onEditingComplete: () {
                                                        _validateEmailAndShowError();
                                                        FocusScope.of(
                                                          context,
                                                        ).unfocus();
                                                      },
                                                      style: const TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontFamily: 'Inter',
                                                        color: Color(
                                                          0xFF00F0FF,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          AnimatedPositioned(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            left: 40,
                                            top:
                                                (_emailController
                                                        .text
                                                        .isNotEmpty ||
                                                    _isEmailFocused)
                                                ? -10
                                                : 15,
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              style: TextStyle(
                                                color: const Color(0xFFA5A6A8),
                                                fontSize:
                                                    (_emailController
                                                            .text
                                                            .isNotEmpty ||
                                                        _isEmailFocused)
                                                    ? 13
                                                    : 15,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Inter',
                                                backgroundColor:
                                                    (_emailController
                                                            .text
                                                            .isNotEmpty ||
                                                        _isEmailFocused)
                                                    ? const Color(0xFF0B1320)
                                                    : Colors.transparent,
                                              ),
                                              child: const Text("Email"),
                                            ),
                                          ),
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () async {
                                                  final userProvider = context
                                                      .read<UserProvider>();
                                                  if (_emailController
                                                      .text
                                                      .isEmpty) {
                                                    ClipboardData?
                                                    clipboardData =
                                                        await Clipboard.getData(
                                                          Clipboard.kTextPlain,
                                                        );
                                                    if (clipboardData?.text !=
                                                        null) {
                                                      setState(() {
                                                        _emailController.text =
                                                            clipboardData!
                                                                .text!;
                                                        userProvider.setEmail(
                                                          _emailController.text,
                                                        );
                                                        _validateEmail();
                                                      });
                                                    }
                                                  } else {
                                                    setState(() {
                                                      _emailController.clear();
                                                      userProvider.setEmail("");
                                                      _validateEmail();
                                                    });
                                                  }
                                                },
                                                child: Container(
                                                  width: 55,
                                                  height: 30,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          7,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF00F0FF,
                                                      ),
                                                    ),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      _emailController
                                                              .text
                                                              .isEmpty
                                                          ? "Paste"
                                                          : "Clear",
                                                      style: const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 15,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    // Email Verification
                                    _buildEmailVerificationSection(),

                                    const SizedBox(height: 40),

                                    // Navigation Buttons
                                    _buildNavigationButtons(),

                                    const SizedBox(height: 25),

                                    // Verification Message
                                    const Text(
                                      "Your ID is now verified\nYour vault is a step closer to being yours",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                        height: 1.3,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 20),
                                    const FooterWidget(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Bottom right image
          Positioned(
            bottom: 20,
            right: 20,
            child: Image.asset(
              'assets/images/Rectangle2.png',
              width: isLandscape ? 120 : 100,
              height: isLandscape ? 120 : 100,
              fit: BoxFit.contain,
            ),
          ),

          // 🔥 OVERLAY FADE WHEN SHEET IS OPEN
          if (_anySheetOpen)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: 1,
              child: GestureDetector(
                onTap: _closeAllSheets,
                child: Container(color: Colors.black.withOpacity(0.45)),
              ),
            ),

          // COUNTRY DROPDOWN SHEET
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _countryDropdownOpen ? 0 : -sheetHeight,
            height: sheetHeight,
            child: _buildCountrySheet(),
          ),

          // DOB DROPDOWN SHEET
          AnimatedPositioned(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _dobDropdownOpen ? 0 : -350,
            height: 350,
            child: _buildDobSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletInputSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            height: 1.0,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildEmailVerificationSection() {
    return SizedBox(
      width: 400,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Email Verification",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 1.0,
              color: Colors.white,
              letterSpacing: -0.08,
            ),
          ),
          const SizedBox(height: 15),

          if (_showCodeSent)
            Center(
              child: Opacity(
                opacity: 1,
                child: Transform.rotate(
                  angle: 0,
                  child: Container(
                    width: 88,
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
                        height: 1.0,
                        letterSpacing: -1.6,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Code input fields
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      return GestureDetector(
                        onTap: () => _focusNodes[index].requestFocus(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            children: [
                              SizedBox(
                                width: 35,
                                height: 25,
                                child: TextField(
                                  enabled: !_codeDisabled,
                                  readOnly: _codeDisabled,
                                  showCursor: !_codeDisabled,
                                  controller: _codeControllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: _codeDisabled
                                        ? Colors.grey
                                        : (_isCodeVerified == true
                                              ? const Color(0xFF00F0FF)
                                              : (_isCodeVerified == false
                                                    ? Colors.red
                                                    : Colors.white)),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  cursorColor: Colors.white,
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                  ),
                                  onChanged: _codeDisabled
                                      ? null
                                      : (value) => _onCodeChanged(value, index),
                                ),
                              ),
                              Container(
                                width: 35,
                                height: 2,
                                color: _codeDisabled
                                    ? Colors.grey
                                    : (_code[index].isEmpty
                                          ? Colors.white
                                          : Colors.transparent),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                if (_isCodeVerified != null)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _isCodeVerified == true
                          ? const Color(0xFF00F0FF)
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isCodeVerified == true ? Icons.check : Icons.close,
                      color: _isCodeVerified == true
                          ? Colors.black
                          : Colors.white,
                      size: 16,
                    ),
                  ),
                const SizedBox(width: 15),
                MouseRegion(
                  onEnter: (_cooldownSeconds == 0 && _emailValid)
                      ? (_) => setState(() => _isGetCodeHovered = true)
                      : null,
                  onExit: (_) => setState(() => _isGetCodeHovered = false),
                  cursor: (_cooldownSeconds == 0 && _emailValid)
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.forbidden,
                  child: GestureDetector(
                    onTap: (_cooldownSeconds == 0 && _emailValid)
                        ? _fetchCodeFromGo
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      width: 100,
                      height: 27,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        boxShadow: _isGetCodeClicked
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00F0FF,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 0),
                                ),
                              ]
                            : (_isGetCodeHovered
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00F0FF,
                                        ).withOpacity(0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00F0FF,
                                        ).withOpacity(0.8),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 0),
                                      ),
                                    ]),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: _cooldownSeconds > 0
                            ? Text(
                                _formatCooldown(_cooldownSeconds),
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              )
                            : Text(
                                "Get Code",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return SizedBox(
      width: 400,
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
            onEnter: (_) => setState(() => _isBackHovered = true),
            onExit: (_) => setState(() => _isBackHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 106,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                ),
                child: Center(
                  child: Text(
                    "Back",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: _isBackHovered
                          ? const Color(0xFF00F0FF)
                          : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          MouseRegion(
            onEnter: (_) =>
                _allFieldsValid ? setState(() => _isNextHovered = true) : null,
            onExit: (_) => setState(() => _isNextHovered = false),
            cursor: _allFieldsValid
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: _handleNextTap,
              child: Container(
                width: 105,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _allFieldsValid
                        ? const Color(0xFF00F0FF)
                        : const Color(0xFF4A5568),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: _allFieldsValid
                          ? (_isNextHovered
                                ? const Color(0xFF00F0FF)
                                : Colors.white)
                          : const Color(0xFF718096),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 64,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              gradient: LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: const [Color(0xFF0B1320), Color(0xFF00F0FF)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String label, {bool filled = false, Color? filledColor}) {
    return SizedBox(
      height: 77,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: filled
                ? (filledColor ?? const Color(0xFF00F0FF))
                : Colors.white,
            child: filled
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.0,
              letterSpacing: 0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

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
