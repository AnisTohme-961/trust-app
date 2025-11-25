import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_project/screens/password.dart';
import 'package:flutter_project/services/api_service.dart';
import 'package:flutter_project/screens/signup.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_project/widgets/footer_widgets.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:flutter_project/widgets/error_widgets.dart';
import 'package:provider/provider.dart';
import '../constants/api_constants.dart';
import '../widgets/custom_button.dart';
import '../services/country_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  bool _signUpGlow = false;
  bool _countryDropdownOpen = false;
  double _dropdownHeight = 400;
  bool _isBtnHovered = false;
  bool _isHovered = false;
  String verificationCode = "";
  // bool isCodeCorrect = false;
  int secondsRemaining = 119;
  double _dropdownAge = 400;
  bool _isTyping = false;
  bool _codeDisabled = false;

  String verifiedCode = "";

  late final ScrollController _monthController;
  late final ScrollController _dayController;
  late final ScrollController _yearController;

  String _selectedCountry = '';
  String _selectedCountryId = '';

  List<Map<String, String>> _filteredCountries = [];
  final TextEditingController _countryFieldController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _selectController = TextEditingController();

  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;

  bool _dobDropdownOpen = false;
  bool isCodeValid = false;

  int _selectedMonth = 0;
  int _selectedDay = 0;
  int _selectedYear = 0;
  final TextEditingController _dobController = TextEditingController();
  List<String> code = ["", "", "", "", "", ""];
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  List<TextEditingController> _codecontrollers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  bool _datePicked = false;

  bool get _isAnyDropdownOpen => _countryDropdownOpen || _dobDropdownOpen;

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

  // Hardcoded list of countries with flags in country_service.dart
  List<Map<String, String>> get countries => CountriesService.getCountries();

  List<String> generate6DigitCode() {
    final rnd = Random.secure();
    return List.generate(6, (_) => rnd.nextInt(10).toString());
  }

  String serverCode = "";

  int _attempts = 0;
  bool _tooManyAttempts = false;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _showCodeSent = false;
  bool _hideInputFields = false;
  bool? _isCodeValid;

 Future<void> fetchCodeFromGo() async {
  final email = _emailController.text.trim();

  if (email.isEmpty) {
    errorStackKey.currentState?.showError("Please enter your email first.");
    return;
  }

  final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
  if (!RegExp(emailPattern).hasMatch(email)) {
    errorStackKey.currentState?.showError(
      "Please enter a valid email address.",
    );
    return;
  }

  final response = await http.post(
    Uri.parse("${ApiConstants.baseUrl}/get-code"),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"email": email}),
  );

  final data = jsonDecode(response.body);
  _timer?.cancel(); // stop any previous timer

  if (response.statusCode == 200) {
    serverCode = data['code'];
    _attempts = data['attempts'] ?? 0;
    _secondsLeft = data['cooldown'] ?? 0;

    final storage = FlutterSecureStorage();
    final cooldownEnd = DateTime.now().add(Duration(seconds: _secondsLeft));
    await storage.write(
      key: "emailCooldownEnd",
      value: cooldownEnd.toIso8601String(),
    );

    // 1️⃣ Show "Code Sent" immediately
    setState(() {
      _showCodeSent = true;
      _hideInputFields = false; // initially keep input visible
      _codeDisabled = _secondsLeft > 0;
    });

    // 2️⃣ Start cooldown timer
    if (_secondsLeft > 0) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          timer.cancel();
          setState(() {
            _codeDisabled = false;       // re-enable typing
            _hideInputFields = true;     // enable input fields when cooldown ends
          });
        }
      });
    } else {
      // no cooldown → show input fields immediately
      setState(() => _hideInputFields = true);
    }

    // 3️⃣ Hide "Code Sent" after 2 seconds
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showCodeSent = false;
        });
      }
    });
  } else {
    errorStackKey.currentState?.showError(
      data['error'] ?? "Failed to send code. Please try again.",
    );
  }
}


  Future<bool> verifyCode(String email, String code) async {
    final body = {"email": email.trim(), "code": code.trim()};

    print("➡ Sending verify request: $body");

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    print("⬅ Response: ${response.body}");

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['valid'] == true) {
        _timer?.cancel();
        print("✅ Code verified on server!");

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setEmailCode(code.trim());

        setState(() {
          verifiedCode = code.trim();
          // isCodeCorrect = true;
        });
        userProvider.setCodeCorrect(true);
        print("➡ Stored verifiedCode in provider: ${userProvider.emailCode}");
        return true;
      } else {
        print("❌ Code invalid or expired");
        return false;
      }
    } else {
      print("❌ Server error: ${response.body}");
      return false;
    }
  }

  final List<int> _days = List.generate(31, (i) => i + 1);
  final List<int> _years = List.generate(56, (i) => 1970 + i);

  String get _dobText =>
      "${_days[_selectedDay].toString().padLeft(2, '0')} ${_months[_selectedMonth]} ${_years[_selectedYear]}";

  void _snapToItem(ScrollController controller, int selectedIndex) {
    final targetOffset = selectedIndex * 40.0 - (286 / 2 - 20);
    controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    
    restoreCooldown();
    _monthController = ScrollController(initialScrollOffset: 0.0);
    _dayController = ScrollController(initialScrollOffset: 0.0);
    _yearController = ScrollController(initialScrollOffset: 0.0);

    void _updateDobController() {
      _dobController.text = _dobDisplayText;
      onDobPicked();
    }

    _monthController.addListener(() {
      final newIndex = (_monthController.offset / 40).round();
      if (newIndex != _selectedMonth &&
          newIndex >= 0 &&
          newIndex < _months.length) {
        setState(() {
          _selectedMonth = newIndex;
          _datePicked = true;
          _updateDobController();
        });
      }
    });

    _dayController.addListener(() {
      final newIndex = (_dayController.offset / 40).round();
      if (newIndex != _selectedDay &&
          newIndex >= 0 &&
          newIndex < _days.length) {
        setState(() {
          _selectedDay = newIndex;
          _datePicked = true;
          _updateDobController();
        });
      }
    });

    _yearController.addListener(() {
      final newIndex = (_yearController.offset / 40).round();
      if (newIndex != _selectedYear &&
          newIndex >= 0 &&
          newIndex < _years.length) {
        setState(() {
          _selectedYear = newIndex;
          _datePicked = true;
          _updateDobController();
        });
      }
    });

    _countrySearchController.addListener(
      () => _filterCountries(_countrySearchController.text),
    );

    // Initialize countries list instead of fetching from API
    _initializeCountries();
  }

  void _initializeCountries() {
    setState(() {
      _filteredCountries = List.from(countries);
    });
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
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setCountry(_selectedCountry, _selectedCountryId);
    print("Selected country: $_selectedCountry");
  }

  void _flickSignUpGlow() {
    setState(() => _signUpGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _signUpGlow = false);
    });
  }

  @override
  void dispose() {
    _monthController.dispose();
    _timer?.cancel();
    _focusNodes.forEach((f) => f.dispose());
    _codecontrollers.forEach((c) => c.dispose());
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) async {
    if (value.length > 1) {
      _codecontrollers[index].text = value[0];
    }
    
    setState(() {
      code[index] = _codecontrollers[index].text;
      _isTyping = code.any((c) => c.isNotEmpty);
      _isCodeValid = true;
    });

    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();

    if (code.every((c) => c.isNotEmpty)) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        errorStackKey.currentState?.showError("Email is required.");
        return;
      }

      bool valid = await verifyCode(email, code.join());
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      if (valid) {
        userProvider.setCodeCorrect(true);
        userProvider.setCodeValid(true);
        setState(() {
          // isCodeCorrect = true;
          // _isCodeValid = true;
          _tooManyAttempts = false;
        });
        _timer?.cancel();
      } else {
        _attempts++;
        userProvider.setCodeCorrect(false);
        setState(() {
          // isCodeCorrect = false;
          _isCodeValid = false;
        });

        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;

          setState(() {
            for (var c in _codecontrollers) c.clear();
            code = ["", "", "", "", "", ""];
            _isCodeValid = true;
          });
          _focusNodes[0].requestFocus();
        });
      }
    }
  }

  void _selectDob(int dayIndex, int monthIndex, int yearIndex) {
    setState(() {
      _selectedDay = dayIndex;
      _selectedMonth = monthIndex;
      _selectedYear = yearIndex;
      _datePicked = true;
    });
    onDobPicked();
  }

  void onDobPicked() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setDob(_dobForApi);
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
void restoreCooldown() async {
  final storage = FlutterSecureStorage();
  final saved = await storage.read(key: "emailCooldownEnd");
  if (saved == null) return;

    final end = DateTime.parse(saved);
    final now = DateTime.now();
    int remaining = end.difference(now).inSeconds;

  if (remaining > 0) {
    setState(() {
      _secondsLeft = remaining;
      _codeDisabled = true;
      _hideInputFields = false; // hide input fields while cooldown
    });

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
        setState(() {
          _codeDisabled = false;
          _hideInputFields = true; // show input fields when cooldown ends
        });
      }
    });
  } else {
    // cooldown expired → show input fields
    setState(() => _hideInputFields = true);
  }
}


  @override
  Widget build(BuildContext context) {
    const double dropdownHeight = 650;

    final userProvider = Provider.of<UserProvider>(context);

    // Prefill logic remains the same...
    if (userProvider.country.isNotEmpty && _selectedCountry.isEmpty) {
      _selectedCountry = userProvider.country;
      _selectedCountryId = userProvider.countryId;
      _countryFieldController.text = userProvider.country;
    }

    if (_emailController.text.isEmpty) {
      _emailController.text = userProvider.email;
    }

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
    }

    if (userProvider.emailCode.isNotEmpty && code.every((c) => c.isEmpty)) {
      final emailCode = userProvider.emailCode;
      for (int i = 0; i < emailCode.length; i++) {
        _codecontrollers[i].text = emailCode[i];
        code[i] = emailCode[i];
      }
      userProvider.setCodeCorrect(userProvider.emailCodeVerified);
    }

    if (userProvider.emailCodeSecondsLeft > 0 && !userProvider.isCodeCorrect) {
      _secondsLeft = userProvider.emailCodeSecondsLeft;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() {
            _secondsLeft--;
          });
          userProvider.setEmailCodeTimer(_secondsLeft);
        } else {
          timer.cancel();
          errorStackKey.currentState?.showError(
            "Code expired. Please request a new one.",
          );
          userProvider.setEmailCodeTimer(0);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Main content - Mobile layout with absolute positioning
          Positioned(
            width: 430,
            height: 932,
            child: Stack(
              children: [
                // ErrorStack at the top of the screen
                ErrorStack(key: errorStackKey),
                // Your existing mobile layout code here...
                // This is the original Stack with all the Positioned widgets
                // I'm keeping it the same as your original code for mobile
                Positioned(
                  top: 100,
                  left: 99,
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
                              onTap: () {},
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Title
                Positioned(
                  top: 152,
                  left: 14,
                  width: 402,
                  height: 36,
                  child: const Center(
                    child: Text(
                      "Your Digital Pass Into Egety",
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 29,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Progress Steps
                Positioned(
                  top: 200,
                  left: 25,
                  right: 45,
                  child: SizedBox(
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
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(100),
                                        bottomLeft: Radius.circular(100),
                                      ),
                                      gradient: const LinearGradient(
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
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: const BorderRadius.only(
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
                                  i == 1 ? "Contact\nand Verify" : "",
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
                ),

                // Country Input
                Positioned(
                  top: 290,
                  left: 18,
                  child: Column(
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
                              width: 374,
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
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: "Country",
                                        hintStyle: TextStyle(
                                          color: Color(0xFFA5A6A8),
                                          fontSize: 15,
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
                              left: 341,
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
                ),

                // Date of Birth Input
                Positioned(
                  top: 393,
                  left: 18,
                  child: Column(
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
                          setState(() {
                            _dobDropdownOpen = !_dobDropdownOpen;
                          });
                        },
                        child: Container(
                          width: 374,
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
                    ],
                  ),
                ),

                // Email Input
                Positioned(
                  top: 495,
                  left: 18,
                  child: Column(
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
                          // Main Input Container
                          Container(
                            width: 374,
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
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        isCollapsed: true,
                                        contentPadding: EdgeInsets.only(top: 0),
                                      ),
                                      onChanged: (value) {
                                        final userProvider =
                                            Provider.of<UserProvider>(
                                              context,
                                              listen: false,
                                            );
                                        userProvider.setEmail(value.trim());
                                        setState(
                                          () {},
                                        ); // Update label position
                                      },
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                        color: Color(0xFF00F0FF),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Floating Label
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 200),
                            left: 40,
                            top:
                                (_emailController.text.isNotEmpty ||
                                    _isEmailFocused)
                                ? -10
                                : 15,
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                color: const Color(0xFFA5A6A8),
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
                              ),
                              child: const Text("Email"),
                            ),
                          ),

                          // Paste / Clear Button
                          Positioned(
                            top: 10,
                            right: 10,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () async {
                                  final userProvider =
                                      Provider.of<UserProvider>(
                                        context,
                                        listen: false,
                                      );
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
                                      });
                                    }
                                  } else {
                                    setState(() {
                                      _emailController.clear();
                                      userProvider.setEmail("");
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
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
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
                    ],
                  ),
                ),

                // Email Verification
                Positioned(
                  top: 609,
                  left: 19,
                  child: Container(
                    width: 393,
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
                                    color: Color(0xFF00F0FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    "Code Sent",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 20,
                                      height: 1.0,
                                      letterSpacing: -0.08 * 20,
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
                              padding: const EdgeInsets.only(top: 25.0),
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
                                            SizedBox(
                                              width: 30,
                                              height: 20,
                                              child: TextField(
                                                enabled: !_codeDisabled,
                                                readOnly: _codeDisabled,
                                                showCursor: !_codeDisabled,

                                                controller:
                                                    _codecontrollers[index],
                                                focusNode: _focusNodes[index],

                                                textAlign: TextAlign.center,
                                                maxLength: 1,
                                                keyboardType:
                                                    TextInputType.number,

                                                      style: TextStyle(
                                                        color: _codeDisabled
                                                            ? Colors
                                                                  .grey // disabled text
                                                            : (userProvider.isCodeCorrect
                                                                  ? Color(
                                                                      0xFF00F0FF,
                                                                    )
                                                                  : (_isCodeValid ==
                                                                            false
                                                                        ? Colors
                                                                              .red
                                                                        : Colors
                                                                              .white)),
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),

                                                cursorColor: Colors.white,
                                                decoration:
                                                    const InputDecoration(
                                                      counterText: "",
                                                      border: InputBorder.none,
                                                    ),

                                                onChanged: _codeDisabled
                                                    ? null
                                                    : (value) => _onChanged(
                                                        value,
                                                        index,
                                                      ),
                                              ),
                                            ),

                                            // Dash under input
                                            Container(
                                              width: 30,
                                              height: 2,
                                              color: _codeDisabled
                                                  ? Colors.grey
                                                  : (code[index].isEmpty
                                                        ? Colors.white
                                                        : Colors.transparent),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),

                                        if (userProvider.isCodeCorrect ||
                                            _isCodeValid == false) ...[
                                          const SizedBox(width: 10),
                                          AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: userProvider.isCodeCorrect
                                                  ? const Color(0xFF00F0FF)
                                                  : Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              userProvider.isCodeCorrect
                                                  ? Icons.check
                                                  : Icons.close,
                                              color: userProvider.isCodeCorrect
                                                  ? Colors.black
                                                  : Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                          ),

                        Positioned(
                          top: 21,
                          left: 280,
                          child: GestureDetector(
                            onTap: (_secondsLeft == 0 && !_isTyping)
                                ? fetchCodeFromGo
                                : null,
                            child: Container(
                              width: 100,
                              height: 27,
                              decoration: BoxDecoration(
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
                                    ).withOpacity(0.8),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: _secondsLeft > 0
                                    ? Text(
                                        "${_secondsLeft ~/ 60}m ${_secondsLeft % 60}s",
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 18,
                                          color: Colors.black,
                                        ),
                                      )
                                    : const Text(
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
                  ),
                ),

                // Navigation Buttons
                Positioned(
                  top: 708,
                  left: 15.5,
                  child: SizedBox(
                    width: 399,
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
                            onTap: () {
                              _validateAndNavigate(context);
                            },
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(right: 15.0),
                          child: Container(
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
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 816,
                  left: 17,
                  child: SizedBox(
                    child: const Center(
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
                  ),
                ),

                if (_isAnyDropdownOpen)
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black.withOpacity(0.6),
                  ),

                // Dropdowns (Country and DOB) - same as original
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  bottom: _countryDropdownOpen ? 0 : -_dropdownHeight,
                  left: 0,
                  right: 0,
                  height: _dropdownHeight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF0B1320),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFF00F0FF), // top border color
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 12),

                            // CLOSE HANDLE
                            GestureDetector(
                              onTap: () {
                                setState(() => _countryDropdownOpen = false);
                              },
                              child: Padding(
                                padding: EdgeInsets.only(left: 20),
                                child: CustomPaint(
                                  size: Size(120, 20),
                                  painter: VLinePainter(),
                                ),
                              ),
                            ),

                            // SEARCH FIELD
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 50),
                              child: TextField(
                                controller: _countrySearchController,
                                onChanged: _filterCountries,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search Country',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),

                            Divider(color: Colors.white24, thickness: 0.5),

                            // LIST - Updated to use emoji flags
                            Expanded(
                              child: _filteredCountries.isEmpty
                                  ? Center(
                                      child: Text(
                                        "No countries found",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    )
                                  : ListView.builder(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 50,
                                        vertical: 16,
                                      ),
                                      itemCount: _filteredCountries.length,
                                      itemBuilder: (context, index) {
                                        final country =
                                            _filteredCountries[index];

                                        return GestureDetector(
                                          onTap: () => _selectCountry(country),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 8.0,
                                            ),
                                            child: Row(
                                              children: [
                                                // Using emoji flags instead of network images
                                                // In your ListView.builder, update the flag display to:
                                                SvgPicture.asset(
                                                  country['flag']!,
                                                  width: 30,
                                                  height: 30,
                                                  fit: BoxFit.contain,
                                                ),
                                                SizedBox(width: 10),
                                                Text(
                                                  country['name'] ?? '',
                                                  style: TextStyle(
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
                ),

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  bottom: _dobDropdownOpen ? 0 : -_dropdownAge,
                  left: 0,
                  right: 0,
                  height: _dropdownAge,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20.0),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(
                          20,
                        ), // top-left and top-right rounded
                      ),
                      child: Container(
                        width: 394,
                        height: 286,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B1320),
                          border: const Border(
                            top: BorderSide(
                              color: Color(0xFF00F0FF), // top border color
                              width: 2.0,
                            ),
                          ),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _dobDropdownOpen = false),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                child: CustomPaint(
                                  size: const Size(120, 20),
                                  painter: VLinePainter(),
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 286,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      width: 430,
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
                                      width: 432,
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
                                  // Month List
                                  Positioned(
                                    top: 0,
                                    left: 10,
                                    width: 144,
                                    height: 286,
                                    child:
                                        NotificationListener<
                                          ScrollEndNotification
                                        >(
                                          onNotification: (notification) {
                                            _snapToItem(
                                              _monthController,
                                              _selectedMonth,
                                            );
                                            return true;
                                          },
                                          child: ListView.builder(
                                            itemCount: _months.length,
                                            controller: _monthController,
                                            physics:
                                                const BouncingScrollPhysics(),
                                            itemExtent: 40,
                                            padding: EdgeInsets.symmetric(
                                              vertical: (286 - 40) / 2,
                                            ),
                                            itemBuilder: (context, index) {
                                              final isSelected =
                                                  index == _selectedMonth;
                                              return GestureDetector(
                                                onTap: () {
                                                  setState(() {
                                                    _selectedMonth = index;
                                                    _datePicked = true;
                                                  });
                                                  onDobPicked();
                                                  _snapToItem(
                                                    _monthController,
                                                    _selectedMonth,
                                                  );
                                                },
                                                child: Container(
                                                  alignment: Alignment.center,
                                                  child: Text(
                                                    _months[index],
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.w500,
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
                                  // Day List
                                  Positioned(
                                    top: 0,
                                    left: 154,
                                    width: 144,
                                    height: 286,
                                    child: ListView.builder(
                                      itemCount: _days.length,
                                      padding: EdgeInsets.symmetric(
                                        vertical: (286 - 40) / 2,
                                      ),
                                      itemExtent: 40,
                                      physics: const BouncingScrollPhysics(),
                                      controller: _dayController,
                                      itemBuilder: (context, index) {
                                        final isSelected =
                                            index == _selectedDay;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedDay = index;
                                              _datePicked = true;
                                            });
                                            onDobPicked();
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
                                  // Year List
                                  Positioned(
                                    top: 0,
                                    left: 298,
                                    width: 144,
                                    height: 286,
                                    child: ListView.builder(
                                      itemCount: _years.length,
                                      padding: EdgeInsets.symmetric(
                                        vertical: (286 - 40) / 2,
                                      ),
                                      itemExtent: 40,
                                      physics: const BouncingScrollPhysics(),
                                      controller: _yearController,
                                      itemBuilder: (context, index) {
                                        final isSelected =
                                            index == _selectedYear;
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedYear = index;
                                              _datePicked = true;
                                            });
                                            onDobPicked();
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndNavigate(BuildContext context) {
    final country = _selectedCountry;
    final dob = _dobDisplayText;
    final email = _emailController.text.trim();
    final code = _codecontrollers.map((c) => c.text).join();

    if (country.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your country.");
      return;
    }
    if (dob.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your date of birth.");
      return;
    } else {
      try {
        final dobParts = dob.split(' ');
        final month = _months.indexOf(dobParts[0]) + 1;
        final day = int.parse(dobParts[1]);
        final year = int.parse(dobParts[2]);
        final date = DateTime(year, month, day);

        if (date.day != day || date.month != month || date.year != year) {
          throw FormatException();
        }
      } catch (_) {
        errorStackKey.currentState?.showError(
          "Please enter a valid date of birth.",
        );
        return;
      }
    }

    if (email.isEmpty) {
      errorStackKey.currentState?.showError("Email is required.");
      return;
    }
    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    final emailRegex = RegExp(emailPattern);
    if (!emailRegex.hasMatch(email)) {
      errorStackKey.currentState?.showError(
        "Please enter a valid email address.",
      );
      return;
    }

    if (code.isEmpty) {
      errorStackKey.currentState?.showError(
        "Please enter the verification code.",
      );
      return;
    } else if (code.length != 6) {
      errorStackKey.currentState?.showError(
        "Verification code must be 6 digits.",
      );
      return;
    }

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

class TabletProtectAccess extends StatefulWidget {
  const TabletProtectAccess({super.key});

  @override
  State<TabletProtectAccess> createState() => _TabletProtectAccessState();
}

class _TabletProtectAccessState extends State<TabletProtectAccess> {
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();

  bool _signUpGlow = false;
  bool _countryDropdownOpen = false;
  double _dropdownHeight = 400;
  bool _isBtnHovered = false;
  bool _isHovered = false;
  String verificationCode = "";
  int secondsRemaining = 119;
  double _dropdownAge = 400;
  bool _isTyping = false;

  String verifiedCode = "";

  late final ScrollController _monthController;
  late final ScrollController _dayController;
  late final ScrollController _yearController;

  String _selectedCountry = '';
  String _selectedCountryId = '';

  // Hardcoded list of countries with flags in country_service.dart
  List<Map<String, String>> get countries => CountriesService.getCountries();

  List<Map<String, String>> _filteredCountries = [];
  final TextEditingController _countryFieldController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;

  bool _dobDropdownOpen = false;
  bool isCodeValid = false;

  int _selectedMonth = 0;
  int _selectedDay = 0;
  int _selectedYear = 0;
  final TextEditingController _dobController = TextEditingController();
  List<String> code = ["", "", "", "", "", ""];
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  List<TextEditingController> _codecontrollers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  bool _datePicked = false;

  bool get _isAnyDropdownOpen => _countryDropdownOpen || _dobDropdownOpen;

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

  List<String> generate6DigitCode() {
    final rnd = Random.secure();
    return List.generate(6, (_) => rnd.nextInt(10).toString());
  }

  String serverCode = "";

  int _attempts = 0;
  bool _tooManyAttempts = false;
  int _secondsLeft = 0;
  Timer? _timer;
  bool _showCodeSent = false;
  bool _hideInputFields = false;
  bool? _isCodeValid;

  final List<int> _days = List.generate(31, (i) => i + 1);
  final List<int> _years = List.generate(56, (i) => 1970 + i);

  String get _dobText =>
      "${_days[_selectedDay].toString().padLeft(2, '0')} ${_months[_selectedMonth]} ${_years[_selectedYear]}";

  void _snapToItem(ScrollController controller, int selectedIndex) {
    final targetOffset = selectedIndex * 40.0 - (286 / 2 - 20);
    controller.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();
    
    _monthController = ScrollController(initialScrollOffset: 0.0);
    _dayController = ScrollController(initialScrollOffset: 0.0);
    _yearController = ScrollController(initialScrollOffset: 0.0);

    void _updateDobController() {
      _dobController.text = _dobDisplayText;
      onDobPicked();
    }

    _monthController.addListener(() {
      final newIndex = (_monthController.offset / 40).round();
      if (newIndex != _selectedMonth &&
          newIndex >= 0 &&
          newIndex < _months.length) {
        setState(() {
          _selectedMonth = newIndex;
          _datePicked = true;
          _updateDobController();
        });
      }
    });

    _dayController.addListener(() {
      final newIndex = (_dayController.offset / 40).round();
      if (newIndex != _selectedDay &&
          newIndex >= 0 &&
          newIndex < _days.length) {
        setState(() {
          _selectedDay = newIndex;
          _datePicked = true;
          _updateDobController();
        });
      }
    });

    _yearController.addListener(() {
      final newIndex = (_yearController.offset / 40).round();
      if (newIndex != _selectedYear &&
          newIndex >= 0 &&
          newIndex < _years.length) {
        setState(() {
          _selectedYear = newIndex;
          _datePicked = true;
          _updateDobController();
        });
      }
    });

    _countrySearchController.addListener(
      () => _filterCountries(_countrySearchController.text),
    );

    // Initialize countries like mobile version
    _initializeCountries();
  }

  void _initializeCountries() {
    setState(() {
      _filteredCountries = List.from(countries);
    });
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
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setCountry(_selectedCountry, _selectedCountryId);
  }

  Future<void> fetchCodeFromGo() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your email first.");
      return;
    }

    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    if (!RegExp(emailPattern).hasMatch(email)) {
      errorStackKey.currentState?.showError(
        "Please enter a valid email address.",
      );
      return;
    }

    final code = generate6DigitCode().join();
    serverCode = code;

    // if (_attempts >= 3) {
    //   setState(() => _tooManyAttempts = true);
    //   errorStackKey.currentState?.showError(
    //     "Too many failed attempts. Please try again later.",
    //   );
    //   return;
    // }

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/get-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 400) {
      final data = jsonDecode(response.body);
      errorStackKey.currentState?.showError(data['error']);
      return;
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      serverCode = data['code'];

      setState(() {
        _attempts++;
        _tooManyAttempts = false;
        _secondsLeft = 119;
        _showCodeSent = true;
        _hideInputFields = true;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _hideInputFields = false);
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
          userProvider.setEmailCodeTimer(_secondsLeft);
        } else {
          timer.cancel();
          userProvider.setEmailCodeTimer(0);
          errorStackKey.currentState?.showError(
            "Code expired. Please request a new one.",
          );
        }
      });
    } else {
      errorStackKey.currentState?.showError(
        "Failed to send code. Please try again.",
      );
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    final body = {"email": email.trim(), "code": code.trim()};

    final response = await http.post(
      Uri.parse("${ApiConstants.baseUrl}/verify-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['valid'] == true) {
        _timer?.cancel();

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        userProvider.setEmailCode(code.trim());

        setState(() {
          verifiedCode = code.trim();
          // isCodeCorrect = true;
        });
        userProvider.setCodeCorrect(true);
        
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _dayController.dispose();
    _yearController.dispose();
    _timer?.cancel();
    _focusNodes.forEach((f) => f.dispose());
    _codecontrollers.forEach((c) => c.dispose());
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value, int index) async {
    if (value.length > 1) {
      _codecontrollers[index].text = value[0];
    }

    setState(() {
      code[index] = _codecontrollers[index].text;
      _isTyping = code.any((c) => c.isNotEmpty);
      _isCodeValid = true;
    });

    if (value.isNotEmpty && index < 5) _focusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0) _focusNodes[index - 1].requestFocus();

    if (code.every((c) => c.isNotEmpty)) {
      final email = _emailController.text.trim();
      if (email.isEmpty) {
        errorStackKey.currentState?.showError("Email is required.");
        return;
      }

      bool valid = await verifyCode(email, code.join());
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (valid) {
        
        userProvider.setCodeCorrect(true);
        setState(() {
          // isCodeCorrect = true;
          _isCodeValid = true;
          _tooManyAttempts = false;
        });
        _timer?.cancel();
      } else {
        _attempts++;

        userProvider.setCodeCorrect(false);
        setState(() {
          // isCodeCorrect = false;
          _isCodeValid = false;
        });

        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;

          setState(() {
            for (var c in _codecontrollers) c.clear();
            code = ["", "", "", "", "", ""];
            _isCodeValid = true;
          });
          _focusNodes[0].requestFocus();
        });

        if (_attempts >= 3) {
          setState(() {
            _tooManyAttempts = true;
          });
          _timer?.cancel();
        }
      }
    }
  }

  void onDobPicked() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setDob(_dobForApi);
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    final userProvider = Provider.of<UserProvider>(context);

    // Prefill logic (same as mobile)
    if (userProvider.country.isNotEmpty && _selectedCountry.isEmpty) {
      _selectedCountry = userProvider.country;
      _selectedCountryId = userProvider.countryId;
      _countryFieldController.text = userProvider.country;
    }

    if (_emailController.text.isEmpty) {
      _emailController.text = userProvider.email;
    }

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
    }

    if (userProvider.emailCode.isNotEmpty && code.every((c) => c.isEmpty)) {
      final emailCode = userProvider.emailCode;
      for (int i = 0; i < emailCode.length; i++) {
        _codecontrollers[i].text = emailCode[i];
        code[i] = emailCode[i];
      }
      userProvider.setCodeCorrect(userProvider.emailCodeVerified);

    }

    if (userProvider.emailCodeSecondsLeft > 0 && !userProvider.isCodeCorrect) {
      _secondsLeft = userProvider.emailCodeSecondsLeft;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() {
            _secondsLeft--;
          });
          userProvider.setEmailCodeTimer(_secondsLeft);
        } else {
          timer.cancel();
          errorStackKey.currentState?.showError(
            "Code expired. Please request a new one.",
          );
          userProvider.setEmailCodeTimer(0);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          ErrorStack(key: errorStackKey),
          // Main content
          Column(
            children: [
              // Error Stack at the top
              Expanded(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.08,
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

                              // Progress Steps - Updated to match mobile layout
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

                              // Form Fields - Centered and properly spaced for tablet
                              SizedBox(
                                width: 450,
                                child: Column(
                                  children: [
                                    // Country Input
                                    _buildTabletInputSection(
                                      title:
                                          "What Is Your Country Of Residence?",
                                      child: _buildCountryField(),
                                    ),

                                    const SizedBox(height: 25),

                                    // Date of Birth Input
                                    _buildTabletInputSection(
                                      title: "When Were You Born?",
                                      child: _buildDobField(),
                                    ),

                                    const SizedBox(height: 25),

                                    // Email Input
                                    _buildTabletInputSection(
                                      title: "Where Can We Reach You?",
                                      child: _buildEmailField(),
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

                                    const SizedBox(height: 30),

                                    // Footer
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

          // Dropdown Overlays
          if (_isAnyDropdownOpen)
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withOpacity(0.6),
            ),

          // Country Dropdown
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _countryDropdownOpen ? 0 : -_dropdownHeight,
            left: 0,
            right: 0,
            height: _dropdownHeight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1320),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(
                      top: BorderSide(color: Color(0xFF00F0FF), width: 2.0),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // Close handle
                      GestureDetector(
                        onTap: () =>
                            setState(() => _countryDropdownOpen = false),
                        child: Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: CustomPaint(
                            size: Size(120, 20),
                            painter: VLinePainter(), // not const
                          ),
                        ),
                      ),

                      // Search field
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _countrySearchController,
                          onChanged: _filterCountries,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search Country',
                            hintStyle: TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const Divider(color: Colors.white24, thickness: 0.5),
                      // Country list
                      Expanded(
                        child: _filteredCountries.isEmpty
                            ? const Center(
                                child: Text(
                                  "No countries found",
                                  style: TextStyle(color: Colors.white),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 16,
                                ),
                                itemCount: _filteredCountries.length,
                                itemBuilder: (context, index) {
                                  final country = _filteredCountries[index];
                                  return GestureDetector(
                                    onTap: () => _selectCountry(country),
                                    child: Padding(
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
                                          Text(
                                            country['name']!,
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
          ),

          // DOB Dropdown
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _dobDropdownOpen ? 0 : -_dropdownAge,
            left: 0,
            right: 0,
            height: _dropdownAge,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Container(
                width: double.infinity,
                height: 286,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B1320),
                  border: Border(
                    top: BorderSide(color: Color(0xFF00F0FF), width: 2.0),
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _dobDropdownOpen = false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Align(
                          alignment: Alignment.center,
                          child: CustomPaint(
                            size: const Size(120, 20),
                            painter: VLinePainter(),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      height: 286,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF0B1320),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),

                          /// ----- CENTER HIGHLIGHT BOX -----
                          Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: double.infinity,
                              height: 49,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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

                          /// ----- MONTH PICKER -----
                          Positioned(
                            top: 0,
                            left: 90,
                            width: 144,
                            height: 286,
                            child: NotificationListener<ScrollEndNotification>(
                              onNotification: (notification) {
                                _snapToItem(_monthController, _selectedMonth);
                                return true;
                              },
                              child: ListView.builder(
                                itemCount: _months.length,
                                controller: _monthController,
                                physics: const BouncingScrollPhysics(),
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
                                      });
                                      onDobPicked();
                                      _snapToItem(
                                        _monthController,
                                        _selectedMonth,
                                      );
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

                          /// ----- DAY PICKER -----
                          Positioned(
                            top: 0,
                            left: 224,
                            width: 144,
                            height: 286,
                            child: ListView.builder(
                              itemCount: _days.length,
                              padding: EdgeInsets.symmetric(
                                vertical: (286 - 40) / 2,
                              ),
                              itemExtent: 40,
                              physics: const BouncingScrollPhysics(),
                              controller: _dayController,
                              itemBuilder: (context, index) {
                                final isSelected = index == _selectedDay;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDay = index;
                                      _datePicked = true;
                                    });
                                    onDobPicked();
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

                          /// ----- YEAR PICKER -----
                          Positioned(
                            top: 0,
                            left: 368,
                            width: 144,
                            height: 286,
                            child: ListView.builder(
                              itemCount: _years.length,
                              padding: EdgeInsets.symmetric(
                                vertical: (286 - 40) / 2,
                              ),
                              itemExtent: 40,
                              physics: const BouncingScrollPhysics(),
                              controller: _yearController,
                              itemBuilder: (context, index) {
                                final isSelected = index == _selectedYear;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedYear = index;
                                      _datePicked = true;
                                    });
                                    onDobPicked();
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
                        ],
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

  Widget _buildCountryField() {
    return GestureDetector(
      onTap: () => setState(() => _countryDropdownOpen = !_countryDropdownOpen),
      child: Stack(
        children: [
          Container(
            width: 400,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1320),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                    ),
                    decoration: const InputDecoration(
                      hintText: "Country",
                      hintStyle: TextStyle(
                        color: Color(0xFFA5A6A8),
                        fontSize: 15,
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
    );
  }

  Widget _buildDobField() {
    return GestureDetector(
      onTap: () => setState(() => _dobDropdownOpen = !_dobDropdownOpen),
      child: Container(
        width: 400,
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1320),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00F0FF), width: 1),
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
                _datePicked ? _dobDisplayText : "Date Of Birth",
                style: TextStyle(
                  color: _datePicked ? Colors.white : const Color(0xFFA5A6A8),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 400,
          height: 50,
          padding: const EdgeInsets.only(left: 12, right: 70),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1320),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF00F0FF), width: 1.2),
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
                  onFocusChange: (hasFocus) =>
                      setState(() => _isEmailFocused = hasFocus),
                  child: TextField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: EdgeInsets.only(top: 0),
                    ),
                    onChanged: (value) {
                      final userProvider = Provider.of<UserProvider>(
                        context,
                        listen: false,
                      );
                      userProvider.setEmail(value.trim());
                    },
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Inter',
                      color: Color(0xFF00F0FF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating Label
        AnimatedPositioned(
          duration: const Duration(milliseconds: 200),
          left: 40,
          top: (_emailController.text.isNotEmpty || _isEmailFocused) ? -10 : 15,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              color: const Color(0xFFA5A6A8),
              fontSize: (_emailController.text.isNotEmpty || _isEmailFocused)
                  ? 13
                  : 15,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
              backgroundColor:
                  (_emailController.text.isNotEmpty || _isEmailFocused)
                  ? const Color(0xFF0B1320)
                  : Colors.transparent,
            ),
            child: const Text("Email"),
          ),
        ),
        // Paste/Clear Button
        Positioned(
          top: 10,
          right: 10,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                if (_emailController.text.isEmpty) {
                  ClipboardData? clipboardData = await Clipboard.getData(
                    Clipboard.kTextPlain,
                  );
                  if (clipboardData?.text != null) {
                    setState(() {
                      _emailController.text = clipboardData!.text!;
                      userProvider.setEmail(_emailController.text);
                    });
                  }
                } else {
                  setState(() {
                    _emailController.clear();
                    userProvider.setEmail("");
                  });
                }
              },
              child: Container(
                width: 55,
                height: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFF00F0FF)),
                  color: Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    _emailController.text.isEmpty ? "Paste" : "Clear",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildEmailVerificationSection() {
    final userProvider = Provider.of<UserProvider>(context);
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

          if (_hideInputFields)
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
                        fontSize: 20,
                        height: 1.0,
                        letterSpacing: -0.08 * 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            )
          else if (_tooManyAttempts)
            SizedBox(
              width: 270,
              height: 26,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1320),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromRGBO(175, 34, 34, 0.0),
                          Color.fromRGBO(175, 34, 34, 0.61),
                          Color.fromRGBO(175, 34, 34, 0.61),
                          Color.fromRGBO(175, 34, 34, 0.0),
                        ],
                        stops: [0.0, 0.101, 0.9038, 1.0],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const Center(
                    child: Text(
                      "Too many attempts. Try again later.",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
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
                                  controller: _codecontrollers[index],
                                  focusNode: _focusNodes[index],
                                  showCursor: !(code.every(
                                    (c) => c.isNotEmpty,
                                  )),
                                  textAlign: TextAlign.center,
                                  maxLength: 1,
                                  keyboardType: TextInputType.number,
                                  style: TextStyle(
                                    color: userProvider.isCodeCorrect
                                        ? const Color(0xFF00F0FF)
                                        : (_isCodeValid == false
                                              ? Colors.red
                                              : Colors.white),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  cursorColor: userProvider.isCodeCorrect
                                      ? const Color(0xFF00F0FF)
                                      : (_isCodeValid == false
                                            ? Colors.red
                                            : Colors.white),
                                  decoration: const InputDecoration(
                                    counterText: "",
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) =>
                                      _onChanged(value, index),
                                ),
                              ),
                              Container(
                                width: 35,
                                height: 2,
                                color: code[index].isEmpty
                                    ? Colors.white
                                    : Colors.transparent,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(width: 10),

                // Success/Error icon
                if (userProvider.isCodeCorrect || _isCodeValid == false)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: userProvider.isCodeCorrect
                          ? const Color(0xFF00F0FF)
                          : Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      userProvider.isCodeCorrect ? Icons.check : Icons.close,
                      color: userProvider.isCodeCorrect ? Colors.black : Colors.white,
                      size: 16,
                    ),
                  ),

                const SizedBox(width: 15),

                // Get Code button
                GestureDetector(
                  onTap: (_secondsLeft == 0 && !_tooManyAttempts && !_isTyping)
                      ? fetchCodeFromGo
                      : null,
                  child: Container(
                    width: 100,
                    height: 27,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00F0FF).withOpacity(0.8),
                          blurRadius: 15,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: _secondsLeft > 0
                          ? Text(
                              "${_secondsLeft ~/ 60}m ${_secondsLeft % 60}s",
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 18,
                                color: Colors.black,
                              ),
                            )
                          : const Text(
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
                child: const Center(
                  child: Text(
                    "Back",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _validateAndNavigate(context),
              child: Container(
                width: 105,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00F0FF), width: 1),
                ),
                child: const Center(
                  child: Text(
                    "Next",
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white,
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
              gradient: const LinearGradient(
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
                colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _validateAndNavigate(BuildContext context) {
    final country = _selectedCountry;
    final dob = _dobDisplayText;
    final email = _emailController.text.trim();
    final code = _codecontrollers.map((c) => c.text).join();

    if (country.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your country.");
      return;
    }
    if (dob.isEmpty) {
      errorStackKey.currentState?.showError("Please enter your date of birth.");
      return;
    } else {
      try {
        final dobParts = dob.split(' ');
        final month = _months.indexOf(dobParts[0]) + 1;
        final day = int.parse(dobParts[1]);
        final year = int.parse(dobParts[2]);
        final date = DateTime(year, month, day);

        if (date.day != day || date.month != month || date.year != year) {
          throw FormatException();
        }
      } catch (_) {
        errorStackKey.currentState?.showError(
          "Please enter a valid date of birth.",
        );
        return;
      }
    }

    if (email.isEmpty) {
      errorStackKey.currentState?.showError("Email is required.");
      return;
    }
    final emailPattern = r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$';
    final emailRegex = RegExp(emailPattern);
    if (!emailRegex.hasMatch(email)) {
      errorStackKey.currentState?.showError(
        "Please enter a valid email address.",
      );
      return;
    }

    if (code.isEmpty) {
      errorStackKey.currentState?.showError(
        "Please enter the verification code.",
      );
      return;
    } else if (code.length != 6) {
      errorStackKey.currentState?.showError(
        "Verification code must be 6 digits.",
      );
      return;
    }

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
