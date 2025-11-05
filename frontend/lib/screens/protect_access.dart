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
  bool isCodeCorrect = false;
  int secondsRemaining = 119;
  double _dropdownAge = 400;
  bool _isTyping = false;

  String verifiedCode = "";

  late final ScrollController _monthController;
  late final ScrollController _dayController;
  late final ScrollController _yearController;

  String _selectedCountry = '';
  String _selectedCountryId = '';

  List<Map<String, String>> countries = [];
  List<Map<String, String>> _filteredCountries = [];
  final TextEditingController _countryFieldController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _selectController = TextEditingController();

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

    if (_attempts >= 3) {
      setState(() => _tooManyAttempts = true);
      errorStackKey.currentState?.showError(
        "Too many failed attempts. Please try again later.",
      );
      return;
    }

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/get-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    print("⬅ Response: ${response.statusCode} ${response.body}");

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

      print("✅ Code sent successfully: $serverCode");
    } else {
      errorStackKey.currentState?.showError(
        "Failed to send code. Please try again.",
      );
    }
  }

  Future<bool> verifyCode(String email, String code) async {
    final body = {"email": email.trim(), "code": code.trim()};

    print("➡ Sending verify request: $body");

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/verify-code"),
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
          isCodeCorrect = true;
        });

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
    fetchCountries();
  }

  Future<void> fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/countries'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          countries = data.map<Map<String, String>>((item) {
            return {
              'id': item['ID'],
              'name': item['Name'],
              'flag': item['Flag'],
            };
          }).toList();
          _filteredCountries = List.from(countries);
        });
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      print("Error fetching countries: $e");
    }
  }

  void _filterCountries(String value) {
    setState(() {
      _filteredCountries = countries
          .where(
            (c) => c['name']!.toLowerCase().startsWith(value.toLowerCase()),
          )
          .toList();
    });
  }

  void _selectCountry(Map<String, String> country) {
    setState(() {
      _selectedCountry = country['name']!;
      _selectedCountryId = country['id']!;
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

      if (valid) {
        setState(() {
          isCodeCorrect = true;
          _isCodeValid = true;
          _tooManyAttempts = false;
        });
        _timer?.cancel();
      } else {
        _attempts++;

        setState(() {
          isCodeCorrect = false;
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
      isCodeCorrect = userProvider.emailCodeVerified;
    }

    if (userProvider.emailCodeSecondsLeft > 0 && !isCodeCorrect) {
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
                  left: 0,
                  right: 5,
                  child: SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 9.5,
                          left: 32,
                          right: 40,
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
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStep("Profile\nStart", filled: true),
                            _buildStep(
                              "Contact\nand Verify",
                              filled: true,
                              filledColor: const Color(0xFF0EA0BB),
                            ),
                            _buildStep("Security\nBase"),
                            _buildStep("Register\nLive"),
                            _buildStep("Register\nPattern"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Country Input
                Positioned(
                  top: 285,
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
                  top: 388,
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
                  top: 490,
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
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          Container(
                            width: 374,
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                  child: Image.asset(
                                    'assets/images/SVGRepo_iconCarrier.png',
                                    width: 16,
                                    height: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _emailController,
                                    decoration: const InputDecoration(
                                      hintText: "Email",
                                      hintStyle: TextStyle(
                                        color: Color(0xFFA5A6A8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'Inter',
                                        height: 1.0,
                                      ),
                                      border: InputBorder.none,
                                      isCollapsed: true,
                                    ),
                                    onChanged: (value) {
                                      final userProvider =
                                          Provider.of<UserProvider>(
                                            context,
                                            listen: false,
                                          );
                                      userProvider.setEmail(value.trim());
                                    },
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: 'Inter',
                                      color: Color(0xFF00F0FF),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                  top: 604,
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

                        if (_hideInputFields)
                          Positioned(
                            top: 30,
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
                            child: _tooManyAttempts
                                ? SizedBox(
                                    width: 270,
                                    height: 26,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0B1320),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.0,
                                                ),
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.61,
                                                ),
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.61,
                                                ),
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.0,
                                                ),
                                              ],
                                              stops: [0.0, 0.101, 0.9038, 1.0],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            "Too many attempts. Try again later.",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : Row(
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
                                                  child: TextField(
                                                    controller:
                                                        _codecontrollers[index],
                                                    focusNode:
                                                        _focusNodes[index],
                                                    showCursor: !(code.every(
                                                      (c) => c.isNotEmpty,
                                                    )),
                                                    textAlign: TextAlign.center,
                                                    maxLength: 1,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    style: TextStyle(
                                                      color: isCodeCorrect
                                                          ? const Color(
                                                              0xFF00F0FF,
                                                            )
                                                          : (_isCodeValid ==
                                                                    false
                                                                ? Colors.red
                                                                : Colors.white),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    cursorColor: isCodeCorrect
                                                        ? const Color(
                                                            0xFF00F0FF,
                                                          )
                                                        : (_isCodeValid == false
                                                              ? Colors.red
                                                              : Colors.white),
                                                    decoration:
                                                        const InputDecoration(
                                                          counterText: "",
                                                          border:
                                                              InputBorder.none,
                                                        ),
                                                    onChanged: (value) =>
                                                        _onChanged(
                                                          value,
                                                          index,
                                                        ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 30,
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

                                      if (isCodeCorrect ||
                                          _isCodeValid == false) ...[
                                        const SizedBox(width: 10),
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isCodeCorrect
                                                ? const Color(0xFF00F0FF)
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCodeCorrect
                                                ? Icons.check
                                                : Icons.close,
                                            color: isCodeCorrect
                                                ? Colors.black
                                                : Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),

                        Positioned(
                          top: 21,
                          left: 280,
                          child: GestureDetector(
                            onTap:
                                (_secondsLeft == 0 &&
                                    !_tooManyAttempts &&
                                    !_isTyping)
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
                  top: 703,
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
                  top: 811,
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

                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: FooterWidget(),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ), // space from footer
                    child: ErrorStack(key: errorStackKey),
                  ),
                ),
                // ErrorStack(key: errorStackKey),

                // Dropdowns (Country and DOB) - same as original
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  bottom: _countryDropdownOpen ? 0 : -_dropdownHeight,
                  left: 0,
                  right: 0,
                  height: _dropdownHeight,
                  child: ClipRect(
                    child: Container(
                      color: const Color(0xFF0B1320),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () {
                              setState(() => _countryDropdownOpen = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: CustomPaint(
                                size: const Size(120, 20),
                                painter: VLinePainter(),
                              ),
                            ),
                          ),
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
                              decoration: InputDecoration(
                                hintText: 'Search Country',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white24, thickness: 0.5),
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
                                              Image.network(
                                                '${ApiConstants.baseUrl}${country['flag']}',
                                                width: 30,
                                                height: 30,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Container(
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

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                  bottom: _dobDropdownOpen ? 0 : -_dropdownAge,
                  left: 0,
                  right: 0,
                  height: _dropdownAge,
                  child: Container(
                    width: 394,
                    height: 286,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B1320),
                      borderRadius: BorderRadius.circular(8),
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
                              Positioned(
                                top: 0,
                                left: 10,
                                width: 144,
                                height: 286,
                                child:
                                    NotificationListener<ScrollEndNotification>(
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
                                        physics: const BouncingScrollPhysics(),
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
        pageBuilder: (_, __, ___) => PasswordPage(),
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

  Column _buildStep(String label, {bool filled = false, Color? filledColor}) {
    return Column(
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
    );
  }
}

class TabletProtectAccess extends StatefulWidget {
  const TabletProtectAccess({super.key});

  @override
  State<TabletProtectAccess> createState() => _TabletProtectAccessState();
}

class _TabletProtectAccessState extends State<TabletProtectAccess> {
  // All the same state variables and methods as _MobileProtectAccessState
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();

  bool _signUpGlow = false;
  bool _countryDropdownOpen = false;
  double _dropdownHeight = 400;
  bool _isBtnHovered = false;
  bool _isHovered = false;
  String verificationCode = "";
  bool isCodeCorrect = false;
  int secondsRemaining = 119;
  double _dropdownAge = 400;
  bool _isTyping = false;

  String verifiedCode = "";

  late final ScrollController _monthController;
  late final ScrollController _dayController;
  late final ScrollController _yearController;

  String _selectedCountry = '';
  String _selectedCountryId = '';

  List<Map<String, String>> countries = [];
  List<Map<String, String>> _filteredCountries = [];
  final TextEditingController _countryFieldController = TextEditingController();
  final TextEditingController _countrySearchController =
      TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _selectController = TextEditingController();

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

  // All the same methods as mobile version...
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

    if (_attempts >= 3) {
      setState(() => _tooManyAttempts = true);
      errorStackKey.currentState?.showError(
        "Too many failed attempts. Please try again later.",
      );
      return;
    }

    final response = await http.post(
      Uri.parse("http://10.0.2.2:8080/get-code"),
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
      Uri.parse("http://10.0.2.2:8080/verify-code"),
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
          isCodeCorrect = true;
        });
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

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
    fetchCountries();
  }

  Future<void> fetchCountries() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/countries'),
      );
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          countries = data.map<Map<String, String>>((item) {
            return {
              'id': item['ID'],
              'name': item['Name'],
              'flag': item['Flag'],
            };
          }).toList();
          _filteredCountries = List.from(countries);
        });
      } else {
        throw Exception('Failed to load countries');
      }
    } catch (e) {
      print("Error fetching countries: $e");
    }
  }

  void _filterCountries(String value) {
    setState(() {
      _filteredCountries = countries
          .where(
            (c) => c['name']!.toLowerCase().startsWith(value.toLowerCase()),
          )
          .toList();
    });
  }

  void _selectCountry(Map<String, String> country) {
    setState(() {
      _selectedCountry = country['name']!;
      _selectedCountryId = country['id']!;
      _countryFieldController.text = country['name']!;
      _countryDropdownOpen = false;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    userProvider.setCountry(_selectedCountry, _selectedCountryId);
  }

  @override
  void dispose() {
    _monthController.dispose();
    _timer?.cancel();
    _focusNodes.forEach((f) => f.dispose());
    _codecontrollers.forEach((c) => c.dispose());
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

      if (valid) {
        setState(() {
          isCodeCorrect = true;
          _isCodeValid = true;
          _tooManyAttempts = false;
        });
        _timer?.cancel();
      } else {
        _attempts++;

        setState(() {
          isCodeCorrect = false;
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
      isCodeCorrect = userProvider.emailCodeVerified;
    }

    if (userProvider.emailCodeSecondsLeft > 0 && !isCodeCorrect) {
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
          // Tablet layout with SingleChildScrollView and Column
          Positioned.fill(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.05,
                ),
                child: Column(
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
                                colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
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

                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      "Your Digital Pass Into Egety",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Progress Steps
                    Center(
                      child: SizedBox(
                        width: 394,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              top: 9.5,
                              left: 32,
                              right: 40,
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  const totalSteps = 5;
                                  const completedSteps = 2;
                                  final segmentCount = totalSteps - 1;
                                  final filledSegments = completedSteps - 1;

                                  final totalWidth = constraints.maxWidth;
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStep("Profile\nStart", filled: true),
                                _buildStep(
                                  "Contact\nand Verify",
                                  filled: true,
                                  filledColor: const Color(0xFF0EA0BB),
                                ),
                                _buildStep("Security\nBase"),
                                _buildStep("Register\nLive"),
                                _buildStep("Register\nPattern"),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form Fields
                    SizedBox(
                      width: 500, // Fixed width for tablet form
                      child: Column(
                        children: [
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
                                    _countryDropdownOpen =
                                        !_countryDropdownOpen;
                                  });
                                },
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 400,
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
                                            padding: const EdgeInsets.only(
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
                                                fontSize: 20,
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
                              ),
                            ],
                          ),

                          const SizedBox(height: 25),

                          // Date of Birth Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "When Were You Born?",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  height: 1.0,
                                  color: Colors.white,
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
                                  width: 400,
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

                          const SizedBox(height: 25),

                          // Email Input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Where Can We Reach You?",
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  height: 1.0,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Stack(
                                children: [
                                  Container(
                                    width: 400,
                                    height: 50,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
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
                                          padding: const EdgeInsets.only(
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
                                          child: TextField(
                                            controller: _emailController,
                                            decoration: const InputDecoration(
                                              hintText: "Email",
                                              hintStyle: TextStyle(
                                                color: Color(0xFFA5A6A8),
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                fontFamily: 'Inter',
                                                height: 1.0,
                                              ),
                                              border: InputBorder.none,
                                              isCollapsed: true,
                                            ),
                                            onChanged: (value) {
                                              final userProvider =
                                                  Provider.of<UserProvider>(
                                                    context,
                                                    listen: false,
                                                  );
                                              userProvider.setEmail(
                                                value.trim(),
                                              );
                                            },
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w500,
                                              fontFamily: 'Inter',
                                              color: Color(0xFF00F0FF),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
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

                          const SizedBox(height: 25),

                          // Email Verification
                          SizedBox(
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
                                const SizedBox(height: 12),

                                if (_hideInputFields)
                                  Opacity(
                                    opacity: 1,
                                    child: Transform.rotate(
                                      angle: 0,
                                      child: Container(
                                        width: 88,
                                        height: 24,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Color(0xFF00F0FF),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                                  )
                                else if (_tooManyAttempts)
                                  SizedBox(
                                    width: 270,
                                    height: 26,
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Color(0xFF0B1320),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.0,
                                                ),
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.61,
                                                ),
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.61,
                                                ),
                                                Color.fromRGBO(
                                                  175,
                                                  34,
                                                  34,
                                                  0.0,
                                                ),
                                              ],
                                              stops: [0.0, 0.101, 0.9038, 1.0],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                        ),
                                        Center(
                                          child: Text(
                                            "Too many attempts. Try again later.",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Row(
                                    children: [
                                      // Code input fields
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
                                                  width: 40,
                                                  child: TextField(
                                                    controller:
                                                        _codecontrollers[index],
                                                    focusNode:
                                                        _focusNodes[index],
                                                    showCursor: !(code.every(
                                                      (c) => c.isNotEmpty,
                                                    )),
                                                    textAlign: TextAlign.center,
                                                    maxLength: 1,
                                                    keyboardType:
                                                        TextInputType.number,
                                                    style: TextStyle(
                                                      color: isCodeCorrect
                                                          ? const Color(
                                                              0xFF00F0FF,
                                                            )
                                                          : (_isCodeValid ==
                                                                    false
                                                                ? Colors.red
                                                                : Colors.white),
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    cursorColor: isCodeCorrect
                                                        ? const Color(
                                                            0xFF00F0FF,
                                                          )
                                                        : (_isCodeValid == false
                                                              ? Colors.red
                                                              : Colors.white),
                                                    decoration:
                                                        const InputDecoration(
                                                          counterText: "",
                                                          border:
                                                              InputBorder.none,
                                                        ),
                                                    onChanged: (value) =>
                                                        _onChanged(
                                                          value,
                                                          index,
                                                        ),
                                                  ),
                                                ),
                                                Container(
                                                  width: 40,
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

                                      const SizedBox(width: 15),

                                      // Success/Error icon
                                      if (isCodeCorrect ||
                                          _isCodeValid == false) ...[
                                        AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: isCodeCorrect
                                                ? const Color(0xFF00F0FF)
                                                : Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            isCodeCorrect
                                                ? Icons.check
                                                : Icons.close,
                                            color: isCodeCorrect
                                                ? Colors.black
                                                : Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 15),
                                      ],

                                      // Get Code button
                                      GestureDetector(
                                        onTap:
                                            (_secondsLeft == 0 &&
                                                !_tooManyAttempts &&
                                                !_isTyping)
                                            ? fetchCodeFromGo
                                            : null,
                                        child: Container(
                                          width: 85,
                                          height: 23,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Center(
                                            child: _secondsLeft > 0
                                                ? Text(
                                                    "${_secondsLeft ~/ 60}m ${_secondsLeft % 60}s",
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 20,
                                                      color: Colors.black,
                                                    ),
                                                  )
                                                : const Text(
                                                    "Get Code",
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 18,
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
                          ),

                          const SizedBox(height: 40),

                          // Navigation Buttons
                          SizedBox(
                            width: 500,
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
                                      width: 120,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF00F0FF),
                                          width: 1,
                                        ),
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
                                    onTap: () {
                                      _validateAndNavigate(context);
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

                          const SizedBox(height: 30),

                          // Verification Message
                          const Text(
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

                          const SizedBox(height: 40),

                          // Footer
                          FooterWidget(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Error Stack
          ErrorStack(key: errorStackKey),

          // Dropdowns (same as mobile)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _countryDropdownOpen ? 0 : -_dropdownHeight,
            left: 0,
            right: 0,
            height: _dropdownHeight,
            child: ClipRect(
              child: Container(
                color: const Color(0xFF0B1320),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() => _countryDropdownOpen = false);
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: CustomPaint(
                          size: const Size(120, 20),
                          painter: VLinePainter(),
                        ),
                      ),
                    ),
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
                        decoration: InputDecoration(
                          hintText: 'Search Country',
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white24, thickness: 0.5),
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
                                        Image.network(
                                          '${ApiConstants.baseUrl}${country['flag']}',
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

          AnimatedPositioned(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            bottom: _dobDropdownOpen ? 0 : -_dropdownAge,
            left: 0,
            right: 0,
            height: _dropdownAge,
            child: Container(
              width: double.infinity,
              height: 286,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1320),
                borderRadius: BorderRadius.circular(8),
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
                        Positioned(
                          top: 0,
                          left: MediaQuery.of(context).size.width * 0.2,
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
                        Positioned(
                          top: 0,
                          left: MediaQuery.of(context).size.width * 0.2 + 154,
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
                        Positioned(
                          top: 0,
                          left: MediaQuery.of(context).size.width * 0.2 + 308,
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
        pageBuilder: (_, __, ___) => PasswordPage(),
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

  Column _buildStep(String label, {bool filled = false, Color? filledColor}) {
    return Column(
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
