import 'package:flutter/material.dart';
import 'package:flutter_project/screens/congrats.dart';
import 'package:flutter_project/screens/protect_access.dart';
import 'package:flutter_project/widgets/error_widgets.dart';
import 'package:flutter_project/widgets/footer_widgets.dart';
import 'package:gradient_borders/gradient_borders.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:flutter_project/providers/font_size_provider.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import 'package:flutter_project/routes/routes.dart';

class PasswordPageApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ResponsivePasswordPage(),
    );
  }
}

class ResponsivePasswordPage extends StatelessWidget {
  const ResponsivePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const TabletPasswordPage();
        } else {
          return const MobilePasswordPage();
        }
      },
    );
  }
}

class MobilePasswordPage extends StatefulWidget {
  const MobilePasswordPage({super.key});

  @override
  State<MobilePasswordPage> createState() => _MobilePasswordPageState();
}

class _MobilePasswordPageState extends State<MobilePasswordPage> {
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // Button hover states
  bool _isBackHovered = false;
  bool _isBackPressed = false;
  bool _isNextHovered = false;

  bool _isNextPressed = false;
  bool _isGenerateHovered = false;

  // Password validation states
  bool _has2Caps = false;
  bool _has2Lower = false;
  bool _has2Numbers = false;
  bool _has2Special = false;
  bool _hasMin10 = false;
  bool _passwordsMatch = false;
  bool _termsAccepted = false;

  // Password error states
  String? _passwordError;
  String? _confirmPasswordError;

  // Controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // UI states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Track if password field has text for paste/clear button
  bool _hasTextInPassword = false;

  // Check if all fields are valid
  bool get _allFieldsValid =>
      _has2Caps &&
      _has2Lower &&
      _has2Numbers &&
      _has2Special &&
      _hasMin10 &&
      _passwordsMatch &&
      _termsAccepted;

  @override
  void initState() {
    super.initState();

    // Add focus listeners for validation
    _passwordFocusNode.addListener(_validatePasswordOnUnfocus);
    _confirmPasswordFocusNode.addListener(_validateConfirmPasswordOnUnfocus);

    // Add text change listeners
    _passwordController.addListener(() {
      _validatePassword();
      setState(() {
        _hasTextInPassword = _passwordController.text.isNotEmpty;
      });
    });

    _confirmPasswordController.addListener(() {
      _validatePasswordsMatch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Validate initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validatePassword();
      _validatePasswordsMatch();
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_validatePasswordOnUnfocus);
    _confirmPasswordFocusNode.removeListener(_validateConfirmPasswordOnUnfocus);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // Validation methods
  void _validatePasswordOnUnfocus() {
    if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
      _validatePasswordAndShowError();
    }
  }

  void _validateConfirmPasswordOnUnfocus() {
    if (!_confirmPasswordFocusNode.hasFocus &&
        _confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPasswordAndShowError();
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _has2Caps = false;
        _has2Lower = false;
        _has2Numbers = false;
        _has2Special = false;
        _hasMin10 = false;
        _passwordError = null;
      });
      return;
    }

    setState(() {
      _has2Caps = RegExp(r'[A-Z]').allMatches(password).length >= 2;
      _has2Lower = RegExp(r'[a-z]').allMatches(password).length >= 2;
      _has2Numbers = RegExp(r'\d').allMatches(password).length >= 2;
      _has2Special = RegExp(r'[!@#\$&*~]').allMatches(password).length >= 2;
      _hasMin10 = password.length >= 10;
      _passwordError = null;
    });
  }

  void _validatePasswordsMatch() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword.isEmpty) {
      setState(() {
        _passwordsMatch = false;
        _confirmPasswordError = null;
      });
      return;
    }

    setState(() {
      _passwordsMatch = password == confirmPassword;
      _confirmPasswordError = null;
    });
  }

  void _validatePasswordAndShowError() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _has2Caps = false;
        _has2Lower = false;
        _has2Numbers = false;
        _has2Special = false;
        _hasMin10 = false;
        _passwordError = null;
      });
      return;
    }

    if (password.length < 10) {
      setState(() {
        _hasMin10 = false;
        _passwordError = "Password must be at least 10 characters.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'[A-Z]').allMatches(password).length < 2) {
      setState(() {
        _has2Caps = false;
        _passwordError = "Password must contain at least 2 capital letters.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'[a-z]').allMatches(password).length < 2) {
      setState(() {
        _has2Lower = false;
        _passwordError = "Password must contain at least 2 lowercase letters.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'\d').allMatches(password).length < 2) {
      setState(() {
        _has2Numbers = false;
        _passwordError = "Password must contain at least 2 numbers.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'[!@#\$&*~]').allMatches(password).length < 2) {
      setState(() {
        _has2Special = false;
        _passwordError =
            "Password must contain at least 2 special characters (!@#\$&*~).";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    setState(() {
      _has2Caps = true;
      _has2Lower = true;
      _has2Numbers = true;
      _has2Special = true;
      _hasMin10 = true;
      _passwordError = null;
    });
  }

  void _validateConfirmPasswordAndShowError() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword.isEmpty) {
      setState(() {
        _passwordsMatch = false;
        _confirmPasswordError = null;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _passwordsMatch = false;
        _confirmPasswordError = "Passwords do not match.";
      });
      _errorStackKey.currentState?.showError(_confirmPasswordError!);
      return;
    }

    setState(() {
      _passwordsMatch = true;
      _confirmPasswordError = null;
    });
  }

  // Check if all fields are valid
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate password
    _validatePassword();
    if (!_hasMin10) {
      _errorStackKey.currentState?.showError(
        "Password must be at least 10 characters.",
      );
      hasError = true;
    } else if (!_has2Caps) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 capital letters.",
      );
      hasError = true;
    } else if (!_has2Lower) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 lowercase letters.",
      );
      hasError = true;
    } else if (!_has2Numbers) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 numbers.",
      );
      hasError = true;
    } else if (!_has2Special) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 special characters (!@#\$&*~).",
      );
      hasError = true;
    }

    // Validate confirm password
    _validatePasswordsMatch();
    if (!_passwordsMatch && _confirmPasswordController.text.isNotEmpty) {
      _errorStackKey.currentState?.showError("Passwords do not match.");
      hasError = true;
    } else if (!_passwordsMatch) {
      _errorStackKey.currentState?.showError("Please confirm your password.");
      hasError = true;
    }

    // Validate terms
    if (!_termsAccepted) {
      _errorStackKey.currentState?.showError(
        "You must agree to the terms and conditions.",
      );
      hasError = true;
    }
  }

  void _handleNextTap() {
    if (_allFieldsValid) {
      _proceedWithSubmission();
    } else {
      _validateAllFieldsAndShowErrors();
    }
  }

  void _proceedWithSubmission() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() => _isLoading = true);

    String? eid = await ApiService.createUser(
      firstName: userProvider.firstName,
      lastName: userProvider.lastName,
      email: userProvider.email,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      emailCode: userProvider.emailCode!.trim(),
      sponsorCode: userProvider.sponsorCode,
      gender: userProvider.gender,
      country: {"name": userProvider.country, "code": userProvider.countryId},
      language: {
        "name": userProvider.selectedLanguage,
        "code": userProvider.selectedLanguageId,
      },
      dob: userProvider.dob,
    );

    setState(() => _isLoading = false);

    if (eid != null) {
      await userProvider.registerUser(
        firstName: userProvider.firstName,
        lastName: userProvider.lastName,
        eid: eid,
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ResponsiveRegisterLivePage()));
    } else {
      _errorStackKey.currentState?.showError(
        "Failed to create user. Please try again.",
      );
    }
  }

  String generatePassword() {
    final rand = Random.secure();

    final upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final lower = 'abcdefghijklmnopqrstuvwxyz';
    final numbers = '0123456789';
    final specialChars = '!@#\$&*~';

    List<String> passwordChars = [];

    // Step 1: Add exactly 2 special characters
    passwordChars.addAll(
      List.generate(2, (_) => specialChars[rand.nextInt(specialChars.length)]),
    );

    // Step 2: Add 2 uppercase, 2 lowercase, 2 numbers
    passwordChars.addAll(
      List.generate(2, (_) => upper[rand.nextInt(upper.length)]),
    );
    passwordChars.addAll(
      List.generate(2, (_) => lower[rand.nextInt(lower.length)]),
    );
    passwordChars.addAll(
      List.generate(2, (_) => numbers[rand.nextInt(numbers.length)]),
    );

    // Step 3: Fill remaining to reach minimum length 10 with letters and numbers only
    final lettersAndNumbers = upper + lower + numbers;
    while (passwordChars.length < 10) {
      passwordChars.add(
        lettersAndNumbers[rand.nextInt(lettersAndNumbers.length)],
      );
    }

    // Step 4: Shuffle
    passwordChars.shuffle(rand);

    return passwordChars.join();
  }

  void _handleGeneratePassword() {
    final newPassword = generatePassword();
    setState(() {
      _passwordController.text = newPassword;
      _confirmPasswordController.text = newPassword;
      _hasTextInPassword = true;
      _validatePassword();
      _validatePasswordsMatch();
    });
  }

  Color _getValidationColor(bool isValid) {
    return isValid ? const Color(0xFF00F0FF) : const Color(0xFFFF0000);
  }

  Color _getValidationTextColor(bool isValid) {
    return isValid ? const Color(0xFF00F0FF) : const Color(0xFFFF0000);
  }

  // Helper method to handle paste/clear for both password fields
  void _handlePasswordPasteClear() async {
    if (_hasTextInPassword) {
      // Clear both password fields
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _hasTextInPassword = false;
      });
    } else {
      // Paste from clipboard into both fields
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null) {
        final text = clipboardData.text ?? '';
        _passwordController.text = text;
        _confirmPasswordController.text = text;
        setState(() {
          _hasTextInPassword = text.isNotEmpty;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    ErrorStack(key: _errorStackKey),
                    // Sign In/Sign Up Buttons
                    SizedBox(
                      width: 230,
                      height: 40,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 126,
                            child: Container(
                              width: 104,
                              height: 40,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
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
                              child: const Center(
                                child: Text(
                                  'Sign Up',
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
                          Positioned(
                            left: 0,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).pop();
                              },
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
                                child: Center(
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(
                                        context,
                                      ).pushNamed('/sign-in');
                                    },
                                    child: const Text(
                                      'Sign In',
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
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Title
                    Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Protect Your Access',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          height: 1.0,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress Section
                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress Line
                          Positioned(
                            top: 9.5,
                            left: 20,
                            right: 20,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                const totalSteps = 5;
                                const completedSteps = 2;
                                const segmentCount = totalSteps - 1;

                                final totalWidth = constraints.maxWidth;
                                final filledWidth =
                                    totalWidth *
                                    (completedSteps / segmentCount);
                                final remainingWidth = totalWidth - filledWidth;

                                return Row(
                                  children: [
                                    // Filled part (two steps)
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
                                            Color(0xFF13D2C7),
                                            Color(0xFF00259E),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                    // Remaining part
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

                          // Progress Steps
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStep("", filled: true),
                              _buildStep(
                                "",
                                filled: true,
                                filledColor: const Color(0xFF0EA0BB),
                              ),
                              _buildStep(
                                "Security\nBase",
                                filled: true,
                                filledColor: const Color(0xFF0764AD),
                              ),
                              _buildStep(""),
                              _buildStep(""),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Password Section
                    Column(
                      children: [
                        const Text(
                          "Got a Strong Password?",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Password Input Field
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 70,
                              child: TextField(
                                controller: _passwordController,
                                focusNode: _passwordFocusNode,
                                obscureText: _obscurePassword,
                                onEditingComplete: () {
                                  _validatePasswordAndShowError();
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_confirmPasswordFocusNode);
                                },
                                style: TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: fontProvider.getScaledSize(15),
                                ),
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  labelStyle: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontProvider.getScaledSize(15),
                                  ),
                                  floatingLabelStyle: TextStyle(
                                    color: Color(0xFF00F0FF),
                                    fontSize: fontProvider.getScaledSize(15),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 10,
                                      right: 8,
                                    ),
                                    child: Image.asset(
                                      'assets/images/Icon.png',
                                      width: 20,
                                      height: 20,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 35,
                                    minHeight: 20,
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Eye Icon
                                      GestureDetector(
                                        onTap: () => setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        }),
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Image.asset(
                                            _obscurePassword
                                                ? 'assets/images/eyeSlash.png'
                                                : 'assets/images/eye1.png',
                                            width: 22,
                                            height: 22,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),

                                      // Paste/Clear Button - works for both fields
                                      Container(
                                        width: 65,
                                        height: 32,
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            7,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFF00F0FF),
                                            width: 1,
                                          ),
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              7,
                                            ),
                                            onTap: _handlePasswordPasteClear,
                                            child: Center(
                                              child: Text(
                                                _hasTextInPassword
                                                    ? "Clear"
                                                    : "Paste",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: fontProvider
                                                      .getScaledSize(15),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7.64),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(7.64),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F0FF),
                                      width: 1.5,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 0),

                        // Confirm Password and Generate Row
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    height: 52,
                                    child: TextField(
                                      controller: _confirmPasswordController,
                                      focusNode: _confirmPasswordFocusNode,
                                      obscureText: _obscureConfirmPassword,
                                      onEditingComplete: () {
                                        _validateConfirmPasswordAndShowError();
                                        FocusScope.of(context).unfocus();
                                      },
                                      style: TextStyle(
                                        color: const Color(0xFF00F0FF),
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: fontProvider.getScaledSize(
                                          15,
                                        ),
                                      ),
                                      decoration: InputDecoration(
                                        labelText: "Confirm Password",
                                        labelStyle: TextStyle(
                                          color: Colors.white70,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: fontProvider.getScaledSize(
                                            15,
                                          ),
                                        ),
                                        floatingLabelStyle: TextStyle(
                                          color: const Color(0xFF00F0FF),
                                          fontSize: fontProvider.getScaledSize(
                                            15,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                            right: 8,
                                          ),
                                          child: Image.asset(
                                            'assets/images/Icon.png',
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                        prefixIconConstraints:
                                            const BoxConstraints(
                                              minWidth: 35,
                                              minHeight: 20,
                                            ),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Eye Icon for confirm password only
                                            GestureDetector(
                                              onTap: () => setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              }),
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                child: Image.asset(
                                                  _obscureConfirmPassword
                                                      ? 'assets/images/eyeSlash.png'
                                                      : 'assets/images/eye1.png',
                                                  width: 22,
                                                  height: 22,
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            7.64,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF00F0FF),
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            7.64,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF00F0FF),
                                            width: 1.5,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 16,
                                              horizontal: 0,
                                            ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Generate Button
                            MouseRegion(
                              onEnter: (_) =>
                                  setState(() => _isGenerateHovered = true),
                              onExit: (_) =>
                                  setState(() => _isGenerateHovered = false),
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _handleGeneratePassword,
                                child: Container(
                                  width: 126,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: GradientBoxBorder(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF00F0FF),
                                          Color(0xFFFFFFFF),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      width: 1.5,
                                    ),
                                    color: Colors.transparent,
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {
                                      final newPassword = generatePassword();
                                      setState(() {
                                        _passwordController.text = newPassword;
                                        _confirmPasswordController.text =
                                            newPassword;
                                        _hasTextInPassword = true;
                                        _validatePassword(); // Validate immediately after generating
                                      });
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 38,
                                          height: 38,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4.0,
                                            ),
                                            child: Image.asset(
                                              'assets/images/stars.png',
                                              width: 38,
                                              height: 38,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Generate",
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: fontProvider
                                                .getScaledSize(15),
                                            color: Colors.white,
                                            letterSpacing: -0.08 * 20,
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
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Password Requirements
                    Container(
                      width: double.infinity,
                      height: 146,
                      child: Column(
                        children: [
                          Text(
                            "Your password should contain at least",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: fontProvider.getScaledSize(15),
                              height: 1.0,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Requirements in two columns
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRequirement(
                                      "2 Capital Letters",
                                      _has2Caps,
                                    ),
                                    const SizedBox(height: 5),
                                    _buildRequirement(
                                      "2 Lowercase Letters",
                                      _has2Lower,
                                    ),
                                    const SizedBox(height: 5),
                                    _buildRequirement(
                                      "2 Numbers",
                                      _has2Numbers,
                                    ),
                                  ],
                                ),
                              ),

                              // Right Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildRequirement(
                                      "2 Special Characters",
                                      _has2Special,
                                    ),
                                    const SizedBox(height: 5),
                                    _buildRequirement(
                                      "Minimum 10 Characters",
                                      _hasMin10,
                                    ),
                                    const SizedBox(height: 5),
                                    _buildRequirement(
                                      "Passwords Match",
                                      _passwordsMatch,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 0),

                    // Terms and Conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _termsAccepted = !_termsAccepted;
                              });
                            },
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _termsAccepted
                                    ? const Color(0xFF00F0FF)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: const Color(0xFF00F0FF),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: _termsAccepted
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.black,
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: fontProvider.getScaledSize(15),
                                height: 1,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      "When pressing the signup button I agree to Egety ",
                                ),
                                TextSpan(
                                  text: "Terms & Conditions",
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.solid,
                                    decorationThickness: 1,
                                  ),
                                ),
                                const TextSpan(text: " and "),
                                TextSpan(
                                  text: "Privacy Policy",
                                  style: const TextStyle(
                                    color: Color(0xFF00F0FF),
                                    decoration: TextDecoration.underline,
                                    decorationStyle: TextDecorationStyle.solid,
                                    decorationThickness: 1,
                                  ),
                                ),
                                const TextSpan(
                                  text: " set by Egety Technology",
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Navigation Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(
                                right: 8,
                              ), // Space from Back button
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: const [
                                    Color(0xFF0B1320),
                                    Color(0xFF00F0FF),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          MouseRegion(
                            onEnter: (_) =>
                                setState(() => _isBackHovered = true),
                            onExit: (_) =>
                                setState(() => _isBackHovered = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTapDown: (_) {
                                setState(() => _isBackPressed = true);
                              },
                              onTapUp: (_) {
                                setState(() => _isBackPressed = false);
                                Navigator.of(context).pop();
                              },
                              onTapCancel: () {
                                setState(() => _isBackPressed = false);
                              },
                              onTap: () => Navigator.of(context).pop(),
                              child: Transform.scale(
                                scale: _isBackPressed ? 0.95 : 1.0,
                                child: Container(
                                  width: 106,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                    color: _isBackHovered
                                        ? const Color(
                                            0xFF00F0FF,
                                          ).withOpacity(0.15)
                                        : (_isBackPressed
                                              ? const Color(
                                                  0xFF00F0FF,
                                                ).withOpacity(0.25)
                                              : const Color(0xFF0B1320)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Back",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        height: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Spacer between buttons
                          const SizedBox(width: 8),

                          MouseRegion(
                            onEnter: (_) => _allFieldsValid
                                ? setState(() => _isNextHovered = true)
                                : null,
                            onExit: (_) =>
                                setState(() => _isNextHovered = false),
                            cursor: _allFieldsValid
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.forbidden,
                            child: GestureDetector(
                              onTapDown: _allFieldsValid
                                  ? (_) {
                                      setState(() => _isNextPressed = true);
                                    }
                                  : null,
                              onTapUp: _allFieldsValid
                                  ? (_) {
                                      setState(() => _isNextPressed = false);
                                    }
                                  : null,
                              onTapCancel: _allFieldsValid
                                  ? () {
                                      setState(() => _isNextPressed = false);
                                    }
                                  : null,
                              onTap: () {
                                if (_allFieldsValid) {
                                  _handleNextTap();
                                } else {
                                  _validateAllFieldsAndShowErrors();
                                }
                              },
                              child: Transform.scale(
                                scale: _allFieldsValid && _isNextPressed
                                    ? 0.95
                                    : 1.0,
                                child: Container(
                                  width: 106,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _allFieldsValid
                                          ? const Color(0xFF00F0FF)
                                          : const Color(0xFF4A5568),
                                      width: 1,
                                    ),
                                    color: _allFieldsValid
                                        ? (_isNextHovered
                                              ? const Color(
                                                  0xFF00F0FF,
                                                ).withOpacity(0.15)
                                              : _isNextPressed
                                              ? const Color(
                                                  0xFF00F0FF,
                                                ).withOpacity(0.25)
                                              : const Color(0xFF0B1320))
                                        : const Color(0xFF0B1320),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Next",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        height: 1.0,
                                        color: _allFieldsValid
                                            ? Colors.white
                                            : const Color(0xFF718096),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Right divider
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8),
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

                    // Bottom Text
                    const SizedBox(
                      width: 291,
                      child: Text(
                        "The gate is now built. Only you can open it",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 20,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                    const FooterWidget(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    final fontProvider = Provider.of<FontSizeProvider>(context);
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: _getValidationColor(isValid)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: fontProvider.getScaledSize(15),
            color: _getValidationTextColor(isValid),
            letterSpacing: -0.03 * 20,
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String label, {bool filled = false, Color? filledColor}) {
    final fontProvider = Provider.of<FontSizeProvider>(context);
    return SizedBox(
      height: 66,
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
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class TabletPasswordPage extends StatefulWidget {
  const TabletPasswordPage({super.key});

  @override
  State<TabletPasswordPage> createState() => _TabletPasswordPageState();
}

class _TabletPasswordPageState extends State<TabletPasswordPage> {
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // Button hover states
  bool _isBackHovered = false;
  bool _isNextHovered = false;
  bool _isGenerateHovered = false;

  // Password validation states
  bool _has2Caps = false;
  bool _has2Lower = false;
  bool _has2Numbers = false;
  bool _has2Special = false;
  bool _hasMin10 = false;
  bool _passwordsMatch = false;
  bool _termsAccepted = false;

  // Password error states
  String? _passwordError;
  String? _confirmPasswordError;

  // Controllers
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Focus nodes
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  // UI states
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Track if password field has text for paste/clear button
  bool _hasTextInPassword = false;

  // Check if all fields are valid
  bool get _allFieldsValid =>
      _has2Caps &&
      _has2Lower &&
      _has2Numbers &&
      _has2Special &&
      _hasMin10 &&
      _passwordsMatch &&
      _termsAccepted;

  @override
  void initState() {
    super.initState();

    // Add focus listeners for validation
    _passwordFocusNode.addListener(_validatePasswordOnUnfocus);
    _confirmPasswordFocusNode.addListener(_validateConfirmPasswordOnUnfocus);

    // Add text change listeners
    _passwordController.addListener(() {
      _validatePassword();
      setState(() {
        _hasTextInPassword = _passwordController.text.isNotEmpty;
      });
    });

    _confirmPasswordController.addListener(() {
      _validatePasswordsMatch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Validate initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validatePassword();
      _validatePasswordsMatch();
    });
  }

  @override
  void dispose() {
    _passwordFocusNode.removeListener(_validatePasswordOnUnfocus);
    _confirmPasswordFocusNode.removeListener(_validateConfirmPasswordOnUnfocus);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // Validation methods (same as mobile)
  void _validatePasswordOnUnfocus() {
    if (!_passwordFocusNode.hasFocus && _passwordController.text.isNotEmpty) {
      _validatePasswordAndShowError();
    }
  }

  void _validateConfirmPasswordOnUnfocus() {
    if (!_confirmPasswordFocusNode.hasFocus &&
        _confirmPasswordController.text.isNotEmpty) {
      _validateConfirmPasswordAndShowError();
    }
  }

  void _validatePassword() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _has2Caps = false;
        _has2Lower = false;
        _has2Numbers = false;
        _has2Special = false;
        _hasMin10 = false;
        _passwordError = null;
      });
      return;
    }

    setState(() {
      _has2Caps = RegExp(r'[A-Z]').allMatches(password).length >= 2;
      _has2Lower = RegExp(r'[a-z]').allMatches(password).length >= 2;
      _has2Numbers = RegExp(r'\d').allMatches(password).length >= 2;
      _has2Special = RegExp(r'[!@#\$&*~]').allMatches(password).length >= 2;
      _hasMin10 = password.length >= 10;
      _passwordError = null;
    });
  }

  void _validatePasswordsMatch() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword.isEmpty) {
      setState(() {
        _passwordsMatch = false;
        _confirmPasswordError = null;
      });
      return;
    }

    setState(() {
      _passwordsMatch = password == confirmPassword;
      _confirmPasswordError = null;
    });
  }

  void _validatePasswordAndShowError() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() {
        _has2Caps = false;
        _has2Lower = false;
        _has2Numbers = false;
        _has2Special = false;
        _hasMin10 = false;
        _passwordError = null;
      });
      return;
    }

    if (password.length < 10) {
      setState(() {
        _hasMin10 = false;
        _passwordError = "Password must be at least 10 characters.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'[A-Z]').allMatches(password).length < 2) {
      setState(() {
        _has2Caps = false;
        _passwordError = "Password must contain at least 2 capital letters.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'[a-z]').allMatches(password).length < 2) {
      setState(() {
        _has2Lower = false;
        _passwordError = "Password must contain at least 2 lowercase letters.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'\d').allMatches(password).length < 2) {
      setState(() {
        _has2Numbers = false;
        _passwordError = "Password must contain at least 2 numbers.";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    if (RegExp(r'[!@#\$&*~]').allMatches(password).length < 2) {
      setState(() {
        _has2Special = false;
        _passwordError =
            "Password must contain at least 2 special characters (!@#\$&*~).";
      });
      _errorStackKey.currentState?.showError(_passwordError!);
      return;
    }

    setState(() {
      _has2Caps = true;
      _has2Lower = true;
      _has2Numbers = true;
      _has2Special = true;
      _hasMin10 = true;
      _passwordError = null;
    });
  }

  void _validateConfirmPasswordAndShowError() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (confirmPassword.isEmpty) {
      setState(() {
        _passwordsMatch = false;
        _confirmPasswordError = null;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _passwordsMatch = false;
        _confirmPasswordError = "Passwords do not match.";
      });
      _errorStackKey.currentState?.showError(_confirmPasswordError!);
      return;
    }

    setState(() {
      _passwordsMatch = true;
      _confirmPasswordError = null;
    });
  }

  // Check if all fields are valid
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate password
    _validatePassword();
    if (!_hasMin10) {
      _errorStackKey.currentState?.showError(
        "Password must be at least 10 characters.",
      );
      hasError = true;
    } else if (!_has2Caps) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 capital letters.",
      );
      hasError = true;
    } else if (!_has2Lower) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 lowercase letters.",
      );
      hasError = true;
    } else if (!_has2Numbers) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 numbers.",
      );
      hasError = true;
    } else if (!_has2Special) {
      _errorStackKey.currentState?.showError(
        "Password must contain at least 2 special characters (!@#\$&*~).",
      );
      hasError = true;
    }

    // Validate confirm password
    _validatePasswordsMatch();
    if (!_passwordsMatch && _confirmPasswordController.text.isNotEmpty) {
      _errorStackKey.currentState?.showError("Passwords do not match.");
      hasError = true;
    } else if (!_passwordsMatch) {
      _errorStackKey.currentState?.showError("Please confirm your password.");
      hasError = true;
    }

    // Validate terms
    if (!_termsAccepted) {
      _errorStackKey.currentState?.showError(
        "You must agree to the terms and conditions.",
      );
      hasError = true;
    }
  }

  void _handleNextTap() {
    if (_allFieldsValid) {
      _proceedWithSubmission();
    } else {
      _validateAllFieldsAndShowErrors();
    }
  }

  void _proceedWithSubmission() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() => _isLoading = true);

    String? eid = await ApiService.createUser(
      firstName: userProvider.firstName,
      lastName: userProvider.lastName,
      email: userProvider.email,
      password: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
      emailCode: userProvider.emailCode!.trim(),
      sponsorCode: userProvider.sponsorCode,
      gender: userProvider.gender,
      country: {"name": userProvider.country, "code": userProvider.countryId},
      language: {
        "name": userProvider.selectedLanguage,
        "code": userProvider.selectedLanguageId,
      },
      dob: userProvider.dob,
    );

    setState(() => _isLoading = false);

    if (eid != null) {
      await userProvider.registerUser(
        firstName: userProvider.firstName,
        lastName: userProvider.lastName,
        eid: eid,
      );
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ResponsiveRegisterLivePage()));
    } else {
      _errorStackKey.currentState?.showError(
        "Failed to create user. Please try again.",
      );
    }
  }

  String generatePassword() {
    final rand = Random.secure();

    final upper = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final lower = 'abcdefghijklmnopqrstuvwxyz';
    final numbers = '0123456789';
    final specialChars = '!@#\$&*~';

    List<String> passwordChars = [];

    // Step 1: Add exactly 2 special characters
    passwordChars.addAll(
      List.generate(2, (_) => specialChars[rand.nextInt(specialChars.length)]),
    );

    // Step 2: Add 2 uppercase, 2 lowercase, 2 numbers
    passwordChars.addAll(
      List.generate(2, (_) => upper[rand.nextInt(upper.length)]),
    );
    passwordChars.addAll(
      List.generate(2, (_) => lower[rand.nextInt(lower.length)]),
    );
    passwordChars.addAll(
      List.generate(2, (_) => numbers[rand.nextInt(numbers.length)]),
    );

    // Step 3: Fill remaining to reach minimum length 10 with letters and numbers only
    final lettersAndNumbers = upper + lower + numbers;
    while (passwordChars.length < 10) {
      passwordChars.add(
        lettersAndNumbers[rand.nextInt(lettersAndNumbers.length)],
      );
    }

    // Step 4: Shuffle
    passwordChars.shuffle(rand);

    return passwordChars.join();
  }

  void _handleGeneratePassword() {
    final newPassword = generatePassword();
    setState(() {
      _passwordController.text = newPassword;
      _confirmPasswordController.text = newPassword;
      _hasTextInPassword = true;
      _validatePassword();
      _validatePasswordsMatch();
    });
  }

  Color _getValidationColor(bool isValid) {
    return isValid ? const Color(0xFF00F0FF) : const Color(0xFFFF0000);
  }

  Color _getValidationTextColor(bool isValid) {
    return isValid ? const Color(0xFF00F0FF) : const Color(0xFFFF0000);
  }

  // Helper method to handle paste/clear for both password fields
  void _handlePasswordPasteClear() async {
    if (_hasTextInPassword) {
      // Clear both password fields
      _passwordController.clear();
      _confirmPasswordController.clear();
      setState(() {
        _hasTextInPassword = false;
      });
    } else {
      // Paste from clipboard into both fields
      final clipboardData = await Clipboard.getData('text/plain');
      if (clipboardData != null) {
        final text = clipboardData.text ?? '';
        _passwordController.text = text;
        _confirmPasswordController.text = text;
        setState(() {
          _hasTextInPassword = text.isNotEmpty;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
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
                              // Error Stack
                              ErrorStack(key: _errorStackKey),
                              const SizedBox(height: 20),

                              // Sign In/Sign Up Buttons
                              SizedBox(
                                width: 230,
                                height: 40,
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: 126,
                                      child: Container(
                                        width: 104,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                                        child: const Center(
                                          child: Text(
                                            'Sign Up',
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
                                    Positioned(
                                      left: 0,
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
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
                                          child: const Center(
                                            child: Text(
                                              'Sign In',
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
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // Title
                              const Text(
                                'Protect Your Access',
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

                              // Progress Section
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
                                          const completedSteps = 3;
                                          const segmentCount = totalSteps - 1;

                                          final totalWidth =
                                              constraints.maxWidth;
                                          final filledWidth =
                                              totalWidth *
                                              (completedSteps / segmentCount);
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
                                                      Color(0xFF13D2C7),
                                                      Color(0xFF00259E),
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
                                        _buildStep("", filled: true),
                                        _buildStep(
                                          "",
                                          filled: true,
                                          filledColor: const Color(0xFF0EA0BB),
                                        ),
                                        _buildStep(
                                          "Security\nBase",
                                          filled: true,
                                          filledColor: const Color(0xFF0764AD),
                                        ),
                                        _buildStep("Register\nLive"),
                                        _buildStep("Register\nPattern"),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Password Section
                              SizedBox(
                                width: 450,
                                child: Column(
                                  children: [
                                    const Text(
                                      "Got a Strong Password?",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        height: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Password Input Field with Paste/Clear button
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 400,
                                          height: 50,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF00F0FF),
                                              width: 1,
                                            ),
                                            color: Colors.transparent,
                                          ),
                                          child: Row(
                                            children: [
                                              SizedBox(
                                                width: 14,
                                                height: 18,
                                                child: Image.asset(
                                                  'assets/images/Icon.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Expanded(
                                                child: TextField(
                                                  controller:
                                                      _passwordController,
                                                  focusNode: _passwordFocusNode,
                                                  obscureText: _obscurePassword,
                                                  onEditingComplete: () {
                                                    _validatePasswordAndShowError();
                                                    FocusScope.of(
                                                      context,
                                                    ).requestFocus(
                                                      _confirmPasswordFocusNode,
                                                    );
                                                  },
                                                  style: const TextStyle(
                                                    color: Color(0xFF00F0FF),
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                  ),
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: "Password",
                                                        hintStyle: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                          color: Colors.white54,
                                                        ),
                                                        border:
                                                            InputBorder.none,
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.zero,
                                                      ),
                                                ),
                                              ),
                                              // Paste/Clear Button - works for both fields
                                              Container(
                                                width: 65,
                                                height: 32,
                                                margin: const EdgeInsets.only(
                                                  right: 8,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  border: Border.all(
                                                    color: const Color(
                                                      0xFF00F0FF,
                                                    ),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          7,
                                                        ),
                                                    onTap:
                                                        _handlePasswordPasteClear,
                                                    child: Center(
                                                      child: Text(
                                                        _hasTextInPassword
                                                            ? "Clear"
                                                            : "Paste",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // Eye Icon
                                              GestureDetector(
                                                onTap: () => setState(
                                                  () => _obscurePassword =
                                                      !_obscurePassword,
                                                ),
                                                child: SizedBox(
                                                  width: 21,
                                                  height: 16,
                                                  child: Image.asset(
                                                    _obscurePassword
                                                        ? 'assets/images/eyeSlash.png'
                                                        : 'assets/images/eye1.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Floating label
                                        if (_passwordController.text.isNotEmpty)
                                          Positioned(
                                            left: 30,
                                            top: -8,
                                            child: Container(
                                              color: const Color(0xFF0B1320),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: const Text(
                                                "Password",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),

                                    const SizedBox(height: 15),

                                    // Confirm Password and Generate Row
                                    SizedBox(
                                      width: 400,
                                      child: Row(
                                        children: [
                                          // Confirm Password
                                          Expanded(
                                            flex: 2,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Container(
                                                  height: 50,
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF00F0FF,
                                                      ),
                                                      width: 1,
                                                    ),
                                                    color: Colors.transparent,
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 14,
                                                        height: 18,
                                                        child: Image.asset(
                                                          'assets/images/Icon.png',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        child: TextField(
                                                          controller:
                                                              _confirmPasswordController,
                                                          focusNode:
                                                              _confirmPasswordFocusNode,
                                                          obscureText:
                                                              _obscureConfirmPassword,
                                                          onEditingComplete: () {
                                                            _validateConfirmPasswordAndShowError();
                                                            FocusScope.of(
                                                              context,
                                                            ).unfocus();
                                                          },
                                                          style:
                                                              const TextStyle(
                                                                color: Color(
                                                                  0xFF00F0FF,
                                                                ),
                                                                fontFamily:
                                                                    'Inter',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 15,
                                                              ),
                                                          decoration: const InputDecoration(
                                                            hintText:
                                                                "Confirm Password",
                                                            hintStyle:
                                                                TextStyle(
                                                                  color: Colors
                                                                      .white54,
                                                                  fontFamily:
                                                                      'Inter',
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontSize: 15,
                                                                ),
                                                            border: InputBorder
                                                                .none,
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets.zero,
                                                          ),
                                                        ),
                                                      ),
                                                      // Eye Icon for confirm password only (no paste/clear button)
                                                      GestureDetector(
                                                        onTap: () => setState(
                                                          () => _obscureConfirmPassword =
                                                              !_obscureConfirmPassword,
                                                        ),
                                                        child: SizedBox(
                                                          width: 21,
                                                          height: 16,
                                                          child: Image.asset(
                                                            _obscureConfirmPassword
                                                                ? 'assets/images/eyeSlash.png'
                                                                : 'assets/images/eye1.png',
                                                            fit: BoxFit.contain,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                // Floating label for confirm password
                                                if (_confirmPasswordController
                                                    .text
                                                    .isNotEmpty)
                                                  Positioned(
                                                    left: 30,
                                                    top: -8,
                                                    child: Container(
                                                      color: const Color(
                                                        0xFF0B1320,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 4,
                                                          ),
                                                      child: const Text(
                                                        "Confirm Password",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 10),

                                          // Generate Button
                                          MouseRegion(
                                            onEnter: (_) => setState(
                                              () => _isGenerateHovered = true,
                                            ),
                                            onExit: (_) => setState(
                                              () => _isGenerateHovered = false,
                                            ),
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: _handleGeneratePassword,
                                              child: Container(
                                                width: 126,
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: GradientBoxBorder(
                                                    gradient:
                                                        const LinearGradient(
                                                          colors: [
                                                            Color(0xFF00F0FF),
                                                            Color(0xFFFFFFFF),
                                                          ],
                                                          begin: Alignment
                                                              .centerLeft,
                                                          end: Alignment
                                                              .centerRight,
                                                        ),
                                                    width: 1.5,
                                                  ),
                                                  color: _isGenerateHovered
                                                      ? const Color(
                                                          0xFF00F0FF,
                                                        ).withOpacity(0.1)
                                                      : Colors.transparent,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    SizedBox(
                                                      width: 28.5,
                                                      height: 24,
                                                      child: Image.asset(
                                                        'assets/images/stars.png',
                                                        fit: BoxFit.contain,
                                                        color:
                                                            _isGenerateHovered
                                                            ? Colors.black
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Generate",
                                                      style: TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 15,
                                                        color:
                                                            _isGenerateHovered
                                                            ? Colors.black
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 30),

                                    // Password Requirements
                                    const Text(
                                      "Your password should contain at least",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize: 15,
                                        height: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    // Requirements Grid
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildRequirementRow(
                                              "2 Capital Letters",
                                              _has2Caps,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildRequirementRow(
                                              "2 Lowercase Letters",
                                              _has2Lower,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildRequirementRow(
                                              "2 Numbers",
                                              _has2Numbers,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 20),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildRequirementRow(
                                              "2 Special Characters",
                                              _has2Special,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildRequirementRow(
                                              "Minimum 10 Characters",
                                              _hasMin10,
                                            ),
                                            const SizedBox(height: 12),
                                            _buildRequirementRow(
                                              "Passwords Match",
                                              _passwordsMatch,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Terms and Conditions
                              SizedBox(
                                width: 400,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _termsAccepted = !_termsAccepted;
                                          });
                                        },
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: _termsAccepted
                                                ? const Color(0xFF00F0FF)
                                                : Colors.transparent,
                                            border: Border.all(
                                              color: const Color(0xFF00F0FF),
                                              width: 1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              5,
                                            ),
                                          ),
                                          child: _termsAccepted
                                              ? const Icon(
                                                  Icons.check,
                                                  size: 18,
                                                  color: Colors.black,
                                                )
                                              : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                            height: 1.3,
                                            color: Colors.white,
                                          ),
                                          children: [
                                            const TextSpan(
                                              text:
                                                  "When pressing the signup button I agree to Egety ",
                                            ),
                                            TextSpan(
                                              text: "Terms & Conditions",
                                              style: const TextStyle(
                                                color: Color(0xFF00F0FF),
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationStyle:
                                                    TextDecorationStyle.solid,
                                                decorationThickness: 1,
                                              ),
                                            ),
                                            const TextSpan(text: " and "),
                                            TextSpan(
                                              text: "Privacy Policy",
                                              style: const TextStyle(
                                                color: Color(0xFF00F0FF),
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationStyle:
                                                    TextDecorationStyle.solid,
                                                decorationThickness: 1,
                                              ),
                                            ),
                                            const TextSpan(
                                              text: " set by Egety Technology",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Navigation Buttons
                              SizedBox(
                                width: 400,
                                height: 40,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(11),
                                        gradient: LinearGradient(
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: _allFieldsValid
                                              ? const [
                                                  Color(0xFF0B1320),
                                                  Color(0xFF00F0FF),
                                                ]
                                              : const [
                                                  Color(0xFF0B1320),
                                                  Color(0xFF4A5568),
                                                ],
                                        ),
                                      ),
                                    ),
                                    MouseRegion(
                                      onEnter: (_) =>
                                          setState(() => _isBackHovered = true),
                                      onExit: (_) => setState(
                                        () => _isBackHovered = false,
                                      ),
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () =>
                                            Navigator.of(context).pop(),
                                        child: Container(
                                          width: 106,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.transparent,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFF00F0FF),
                                              width: 1,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              "Back",
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 20,
                                                height: 1.0,
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
                                      onEnter: (_) => _allFieldsValid
                                          ? setState(
                                              () => _isNextHovered = true,
                                            )
                                          : null,
                                      onExit: (_) => setState(
                                        () => _isNextHovered = false,
                                      ),
                                      cursor: _allFieldsValid
                                          ? SystemMouseCursors.click
                                          : SystemMouseCursors.forbidden,
                                      child: GestureDetector(
                                        onTap: _handleNextTap,
                                        child: Container(
                                          width: 105,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            border: Border.all(
                                              color: _allFieldsValid
                                                  ? const Color(0xFF00F0FF)
                                                  : const Color(0xFF4A5568),
                                              width: 1,
                                            ),
                                            color: _allFieldsValid
                                                ? (_isNextHovered
                                                      ? const Color(
                                                          0xFF00F0FF,
                                                        ).withOpacity(0.15)
                                                      : Colors.transparent)
                                                : Colors.transparent,
                                          ),
                                          child: Center(
                                            child: _isLoading
                                                ? const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  )
                                                : Text(
                                                    "Next",
                                                    style: TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 20,
                                                      height: 1.0,
                                                      color: _allFieldsValid
                                                          ? (_isNextHovered
                                                                ? const Color(
                                                                    0xFF00F0FF,
                                                                  )
                                                                : Colors.white)
                                                          : const Color(
                                                              0xFF718096,
                                                            ),
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
                                          colors: _allFieldsValid
                                              ? const [
                                                  Color(0xFF0B1320),
                                                  Color(0xFF00F0FF),
                                                ]
                                              : const [
                                                  Color(0xFF0B1320),
                                                  Color(0xFF4A5568),
                                                ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Footer Text
                              const Text(
                                "The gate is now built. Only you can open it",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 20,
                                  height: 1.0,
                                  letterSpacing: 0,
                                  color: Colors.white,
                                ),
                              ),

                              const SizedBox(height: 20),
                              const FooterWidget(),
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
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: _getValidationColor(isValid)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: _getValidationTextColor(isValid),
            height: 1.0,
          ),
        ),
      ],
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
