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
import 'package:provider/provider.dart';
import 'dart:math';

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
  bool _signUpGlow = false;
  bool _nextClicked = false;

  bool _has2Caps = false;
  bool _has2Lower = false;
  bool _has2Numbers = false;
  bool _has2Special = false;
  bool _hasMin10 = false;
  bool _passwordsMatch = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasTextInPassword = false;
  bool isChecked = false;
  bool isLoading = false;

  void _validatePassword() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _has2Caps = RegExp(r'[A-Z]').allMatches(password).length >= 2;
      _has2Lower = RegExp(r'[a-z]').allMatches(password).length >= 2;
      _has2Numbers = RegExp(r'\d').allMatches(password).length >= 2;
      _has2Special = RegExp(r'[!@#\$&*~]').allMatches(password).length >= 2;
      _hasMin10 = password.length >= 10;
      _passwordsMatch = password == confirmPassword && password.isNotEmpty;
    });
  }

  void _validateAndSubmit() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Always validate before submission
    _validatePassword();

    if (password.isEmpty) {
      _errorStackKey.currentState?.showError("Please enter your password.");
      return;
    }

    if (confirmPassword.isEmpty) {
      _errorStackKey.currentState?.showError("Please confirm your password.");
      return;
    }

    if (!_has2Caps ||
        !_has2Lower ||
        !_has2Numbers ||
        !_has2Special ||
        !_hasMin10 ||
        !_passwordsMatch) {
      _errorStackKey.currentState?.showError(
        "Please follow password requirements.",
      );
      return;
    }

    if (!isChecked) {
      _errorStackKey.currentState?.showError(
        "You must agree to the terms before continuing.",
      );
      return;
    }

    // If all validations pass, proceed with submission
    _proceedWithSubmission();
  }

  void _proceedWithSubmission() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    setState(() => isLoading = true);

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

    setState(() => isLoading = false);

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to create user")));
    }
  }

  void _flickSignUpGlow() {
    setState(() => _signUpGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _signUpGlow = false);
    });
  }

  Color bulletColor(bool isValid) {
    // Always show validation status based on current password state
    return isValid
        ? const Color(0xFF00F0FF) // Change to #00F0FF when valid
        : const Color(0xFFFF0000); // Keep red if invalid
  }

  Color requirementTextColor(bool isValid) {
    // Always show validation status based on current password state
    return isValid
        ? const Color(0xFF00F0FF) // Change to #00F0FF when valid
        : const Color(0xFFFF0000); // Keep red if invalid
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

  @override
  void initState() {
    super.initState();

    // Listen to password input changes for automatic validation
    _passwordController.addListener(() {
      setState(() {
        _hasTextInPassword = _passwordController.text.isNotEmpty;
        _validatePassword(); // Validate automatically on every change
      });
    });

    // Listen to confirm password input changes for automatic validation
    _confirmPasswordController.addListener(() {
      setState(() {
        _validatePassword(); // Validate automatically on every change
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Buttons container
                SizedBox(
                  width: 240,
                  height: 40,
                  child: Stack(
                    children: [
                      // Sign In Button
                      Positioned(
                        left: 0,
                        top: 0,
                        child: GestureDetector(
                          onTap: _validateAndSubmit,
                          child: Container(
                            width: 106,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B1320),
                              borderRadius: BorderRadius.circular(10),
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
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Sign Up Button
                      Positioned(
                        left: 126,
                        top: 0,
                        child: GestureDetector(
                          onTap: _flickSignUpGlow,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 106,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                width: 1,
                                color: const Color(0xFF00F0FF),
                              ),
                              gradient: _signUpGlow
                                  ? LinearGradient(
                                      colors: [
                                        const Color(
                                          0xFF00F0FF,
                                        ).withOpacity(0.7),
                                        const Color(
                                          0xFF0177B3,
                                        ).withOpacity(0.7),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF00F0FF),
                                        Color(0xFF0177B3),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                              boxShadow: _signUpGlow
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF00F0FF,
                                        ).withOpacity(0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                            child: const Center(
                              child: Text(
                                'Sign Up',
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
                            final segmentCount = totalSteps - 1;

                            final totalWidth = constraints.maxWidth;
                            final filledWidth =
                                totalWidth * (completedSteps / segmentCount);
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
                    // Title: "Got a Strong Password?"
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
                    Container(
                      width: double.infinity,
                      height: 70,
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: Color(0xFF00F0FF),
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          labelText: "Password",
                          labelStyle: const TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                          floatingLabelStyle: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 8),
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
                              GestureDetector(
                                onTap: () => setState(() {
                                  _obscurePassword = !_obscurePassword;
                                }),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
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

                    const SizedBox(height: 0),

                    // Confirm Password and Generate Row
                    Row(
                      children: [
                        // Confirm Password
                        Expanded(
                          flex: 2,
                          child: Container(
                            height: 52,
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(
                                color: Color(0xFF00F0FF),
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                labelStyle: const TextStyle(
                                  color: Colors.white70,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontSize: 15,
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
                        ),

                        const SizedBox(width: 8),

                        // Generate Button
                        Container(
                          width: 126,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: GradientBoxBorder(
                              gradient: LinearGradient(
                                colors: [Color(0xFF00F0FF), Color(0xFFFFFFFF)],
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
                                _confirmPasswordController.text = newPassword;
                                _validatePassword(); // Validate immediately after generating
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Image.asset(
                                      'assets/images/stars.png',
                                      width: 38,
                                      height: 38,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  "Generate",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.white,
                                    letterSpacing: -0.08 * 20,
                                  ),
                                ),
                              ],
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
                                _buildRequirement("2 Numbers", _has2Numbers),
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
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isChecked = !isChecked;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isChecked
                              ? const Color(0xFF00F0FF)
                              : Colors.transparent,
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: isChecked
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.black,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
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
                            const TextSpan(text: " set by Egety Technology"),
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

                      // Back Button
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
                            child: const Center(
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

                      // Next Button
                      MouseRegion(
                        cursor: isChecked
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: GestureDetector(
                          onTap: _validateAndSubmit,
                          child: Container(
                            width: 105,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF00F0FF),
                                width: 1,
                              ),
                            ),
                            child: Center(
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    )
                                  : const Text(
                                      "Next",
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

                const SizedBox(height: 30),

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

                const SizedBox(height: 30),

                // Footer
                FooterWidget(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequirement(String text, bool isValid) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: bulletColor(isValid)),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: requirementTextColor(isValid),
            letterSpacing: -0.03 * 20,
            height: 1.0,
          ),
        ),
      ],
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

class TabletPasswordPage extends StatefulWidget {
  const TabletPasswordPage({super.key});

  @override
  State<TabletPasswordPage> createState() => _TabletPasswordPageState();
}

class _TabletPasswordPageState extends State<TabletPasswordPage> {
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();
  bool _signUpGlow = false;
  bool _nextClicked = false;

  bool _has2Caps = false;
  bool _has2Lower = false;
  bool _has2Numbers = false;
  bool _has2Special = false;
  bool _hasMin10 = false;
  bool _passwordsMatch = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasTextInPassword = false;
  bool isChecked = false;
  bool isLoading = false;

  void _validateAndSubmit() {
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _has2Caps = RegExp(r'[A-Z]').allMatches(password).length >= 2;
      _has2Lower = RegExp(r'[a-z]').allMatches(password).length >= 2;
      _has2Numbers = RegExp(r'\d').allMatches(password).length >= 2;
      _has2Special = RegExp(r'[!@#\$&*~]').allMatches(password).length >= 2;
      _hasMin10 = password.length >= 10;
      _passwordsMatch = password == confirmPassword && password.isNotEmpty;
    });
    _nextClicked = true;

    if (password.isEmpty || confirmPassword.isEmpty) {
      _errorStackKey.currentState?.showError("Please enter your password.");
      return;
    }

    if (!_has2Caps ||
        !_has2Lower ||
        !_has2Numbers ||
        !_has2Special ||
        !_hasMin10 ||
        !_passwordsMatch) {
      _errorStackKey.currentState?.showError(
        "Please follow password requirements.",
      );
      return;
    }

    if (!isChecked) {
      _errorStackKey.currentState?.showError(
        "You must agree to the terms before continuing.",
      );
      return;
    }
  }

  void _flickSignUpGlow() {
    setState(() => _signUpGlow = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _signUpGlow = false);
    });
  }

  Color bulletColor(bool isValid) {
    if (!_nextClicked) return const Color(0xB300F0FF); // normal
    return isValid
        ? Colors.green
        : Colors.red; // green if valid, red if invalid
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

  @override
  void initState() {
    super.initState();

    // Listen to password input changes
    _passwordController.addListener(() {
      setState(() {
        _hasTextInPassword = _passwordController.text.isNotEmpty;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Main content with image at bottom right
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // Scrollable content
                    SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1,
                          vertical: screenHeight * 0.05,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isLandscape ? 450 : 420,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(20),
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
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Header Section
                                  const SizedBox(height: 40),

                                  // Sign In/Sign Up Buttons
                                  SizedBox(
                                    width: 233,
                                    height: 40,
                                    child: Stack(
                                      children: [
                                        // Sign In Button
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: _validateAndSubmit,
                                            child: Container(
                                              width: 106,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF0B1320),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  width: 1,
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ),
                                                ),
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Sign In',
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
                                        // Sign Up Button
                                        Positioned(
                                          left: 126,
                                          top: 0,
                                          child: GestureDetector(
                                            onTap: _flickSignUpGlow,
                                            child: AnimatedContainer(
                                              duration: const Duration(
                                                milliseconds: 200,
                                              ),
                                              width: 106,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  width: 1,
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ),
                                                ),
                                                gradient: _signUpGlow
                                                    ? LinearGradient(
                                                        colors: [
                                                          const Color(
                                                            0xFF00F0FF,
                                                          ).withOpacity(0.7),
                                                          const Color(
                                                            0xFF0177B3,
                                                          ).withOpacity(0.7),
                                                        ],
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                      )
                                                    : const LinearGradient(
                                                        colors: [
                                                          Color(0xFF00F0FF),
                                                          Color(0xFF0177B3),
                                                        ],
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                      ),
                                                boxShadow: _signUpGlow
                                                    ? [
                                                        BoxShadow(
                                                          color: const Color(
                                                            0xFF00F0FF,
                                                          ).withOpacity(0.5),
                                                          blurRadius: 10,
                                                          spreadRadius: 2,
                                                        ),
                                                      ]
                                                    : [],
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'Sign Up',
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

                                  const SizedBox(height: 15),

                                  // Title
                                  const Text(
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

                                  const SizedBox(height: 15),

                                  // Progress Section
                                  SizedBox(
                                    width: 398,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        // Progress Line
                                        Positioned(
                                          top: 12,
                                          left: 32,
                                          right: 40,
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              const totalSteps = 5;
                                              const completedSteps = 2;
                                              const segmentCount =
                                                  totalSteps - 1;

                                              final totalWidth =
                                                  constraints.maxWidth;
                                              final filledWidth =
                                                  totalWidth *
                                                  (completedSteps /
                                                      segmentCount);
                                              final remainingWidth =
                                                  totalWidth - filledWidth;

                                              return Row(
                                                children: [
                                                  Container(
                                                    width: filledWidth,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          const BorderRadius.only(
                                                            topLeft:
                                                                Radius.circular(
                                                                  100,
                                                                ),
                                                            bottomLeft:
                                                                Radius.circular(
                                                                  100,
                                                                ),
                                                          ),
                                                      gradient:
                                                          const LinearGradient(
                                                            colors: [
                                                              Color(0xFF13D2C7),
                                                              Color(0xFF00259E),
                                                            ],
                                                            begin: Alignment
                                                                .centerLeft,
                                                            end: Alignment
                                                                .centerRight,
                                                          ),
                                                    ),
                                                  ),
                                                  Container(
                                                    width: remainingWidth,
                                                    height: 6,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          const BorderRadius.only(
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

                                        // Progress Steps
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _buildStep(
                                              "Profile\nStart",
                                              filled: true,
                                            ),
                                            _buildStep(
                                              "Contact\nand Verify",
                                              filled: true,
                                              filledColor: const Color(
                                                0xFF0EA0BB,
                                              ),
                                            ),
                                            _buildStep(
                                              "Security\nBase",
                                              filled: true,
                                              filledColor: const Color(
                                                0xFF0764AD,
                                              ),
                                            ),
                                            _buildStep("Register\nLive"),
                                            _buildStep("Register\nPattern"),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 20),

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

                                      const SizedBox(height: 20),

                                      // Password Input Field
                                      Container(
                                        width: 375,
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
                                                controller: _passwordController,
                                                obscureText: _obscurePassword,
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
                                                      border: InputBorder.none,
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.zero,
                                                    ),
                                              ),
                                            ),
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
                                            const SizedBox(width: 12),
                                            GestureDetector(
                                              onTap: () async {
                                                if (_hasTextInPassword) {
                                                  _passwordController.clear();
                                                  _confirmPasswordController
                                                      .clear();
                                                  setState(() {
                                                    _hasTextInPassword = false;
                                                  });
                                                } else {
                                                  final clipboardData =
                                                      await Clipboard.getData(
                                                        'text/plain',
                                                      );
                                                  if (clipboardData != null) {
                                                    final text =
                                                        clipboardData.text ??
                                                        '';
                                                    _passwordController.text =
                                                        text;
                                                    _confirmPasswordController
                                                            .text =
                                                        text;
                                                    setState(() {
                                                      _hasTextInPassword =
                                                          text.isNotEmpty;
                                                    });
                                                  }
                                                }
                                              },
                                              child: Container(
                                                width: 60,
                                                height: 30,
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
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _hasTextInPassword
                                                      ? "Clear"
                                                      : "Paste",
                                                  style: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      const SizedBox(height: 15),

                                      // Confirm Password and Generate Row
                                      SizedBox(
                                        width: 375,
                                        child: Row(
                                          children: [
                                            // Confirm Password
                                            Expanded(
                                              flex: 2,
                                              child: Container(
                                                height: 50,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                    ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
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
                                                      CrossAxisAlignment.center,
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
                                                        obscureText:
                                                            _obscureConfirmPassword,
                                                        style: const TextStyle(
                                                          color: Color(
                                                            0xFF00F0FF,
                                                          ),
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                        ),
                                                        decoration:
                                                            const InputDecoration(
                                                              hintText:
                                                                  "Confirm Password",
                                                              hintStyle: TextStyle(
                                                                color: Colors
                                                                    .white54,
                                                                fontFamily:
                                                                    'Inter',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontSize: 15,
                                                              ),
                                                              border:
                                                                  InputBorder
                                                                      .none,
                                                              isDense: true,
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .zero,
                                                            ),
                                                      ),
                                                    ),
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
                                            ),

                                            const SizedBox(width: 10),

                                            // Generate Button
                                            Expanded(
                                              flex: 1,
                                              child: Container(
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
                                                  color: Colors.transparent,
                                                ),
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  onTap: () {
                                                    final newPassword =
                                                        generatePassword();
                                                    setState(() {
                                                      _passwordController.text =
                                                          newPassword;
                                                    });
                                                  },
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    children: [
                                                      SizedBox(
                                                        width: 28.5,
                                                        height: 24,
                                                        child: Image.asset(
                                                          'assets/images/stars.png',
                                                          fit: BoxFit.contain,
                                                        ),
                                                      ),
                                                      const Text(
                                                        "Generate",
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          fontSize: 15,
                                                          color: Colors.white,
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

                                      // Password Requirements Grid (Centered)
                                      Center(
                                        child: Row(
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
                                            const SizedBox(width: 7),
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
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  // Terms and Conditions
                                  Center(
                                    child: SizedBox(
                                      width: 370,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                isChecked = !isChecked;
                                              });
                                            },
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: isChecked
                                                    ? const Color(0xFF00F0FF)
                                                    : Colors.transparent,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ),
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: isChecked
                                                  ? const Icon(
                                                      Icons.check,
                                                      size: 18,
                                                      color: Colors.black,
                                                    )
                                                  : null,
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
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationStyle:
                                                          TextDecorationStyle
                                                              .solid,
                                                      decorationThickness: 1,
                                                    ),
                                                  ),
                                                  const TextSpan(text: " and "),
                                                  TextSpan(
                                                    text: "Privacy Policy",
                                                    style: const TextStyle(
                                                      color: Color(0xFF00F0FF),
                                                      decoration: TextDecoration
                                                          .underline,
                                                      decorationStyle:
                                                          TextDecorationStyle
                                                              .solid,
                                                      decorationThickness: 1,
                                                    ),
                                                  ),
                                                  const TextSpan(
                                                    text:
                                                        " set by Egety Technology",
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Navigation Buttons
                                  SizedBox(
                                    width: 375,
                                    height: 50,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          width: 64,
                                          height: 4,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
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

                                        // Back Button
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
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ),
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
                                                    height: 1.0,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // Next Button
                                        MouseRegion(
                                          cursor: isChecked
                                              ? SystemMouseCursors.click
                                              : SystemMouseCursors.basic,
                                          child: GestureDetector(
                                            onTap: () async {
                                              _validateAndSubmit();

                                              if (_has2Caps &&
                                                  _has2Lower &&
                                                  _has2Numbers &&
                                                  _has2Special &&
                                                  _hasMin10 &&
                                                  _passwordsMatch &&
                                                  isChecked) {
                                                setState(
                                                  () => isLoading = true,
                                                );

                                                String?
                                                eid = await ApiService.createUser(
                                                  firstName:
                                                      userProvider.firstName,
                                                  lastName:
                                                      userProvider.lastName,
                                                  email: userProvider.email,
                                                  password:
                                                      _passwordController.text,
                                                  confirmPassword:
                                                      _confirmPasswordController
                                                          .text,
                                                  emailCode: userProvider
                                                      .emailCode!
                                                      .trim(),
                                                  sponsorCode:
                                                      userProvider.sponsorCode,
                                                  gender: userProvider.gender,
                                                  country: {
                                                    "name":
                                                        userProvider.country,
                                                    "code":
                                                        userProvider.countryId,
                                                  },
                                                  language: {
                                                    "name": userProvider
                                                        .selectedLanguage,
                                                    "code": userProvider
                                                        .selectedLanguageId,
                                                  },
                                                  dob: userProvider.dob,
                                                );

                                                setState(
                                                  () => isLoading = false,
                                                );
                                                // final storage =
                                                //     FlutterSecureStorage();

                                                // if (eid != null) {
                                                //   await userProvider
                                                //       .registerUser(
                                                //         firstName: userProvider
                                                //             .firstName,
                                                //         lastName: userProvider
                                                //             .lastName,
                                                //         eid: eid,
                                                //         storage: storage,
                                                //       );

                                                //   Navigator.of(context).push(
                                                //     MaterialPageRoute(
                                                //       builder: (_) =>
                                                //           ResponsiveRegisterLivePage(),
                                                //     ),
                                                //   );
                                                // }
                                                if (eid != null) {
                                                  await userProvider
                                                      .registerUser(
                                                        firstName: userProvider
                                                            .firstName,
                                                        lastName: userProvider
                                                            .lastName,
                                                        eid: eid,
                                                      );
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ResponsiveRegisterLivePage(),
                                                    ),
                                                  );
                                                } else {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        "Failed to create user",
                                                      ),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: Container(
                                              width: 106,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF00F0FF,
                                                  ),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Center(
                                                child: isLoading
                                                    ? const CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2,
                                                      )
                                                    : const Text(
                                                        "Next",
                                                        style: TextStyle(
                                                          fontFamily: 'Inter',
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 20,
                                                          height: 1.0,
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
                                            borderRadius: BorderRadius.circular(
                                              11,
                                            ),
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

                                  const SizedBox(height: 45),

                                  // Footer Text
                                  const Text(
                                    "The gate is now built. Only \n you can open it",
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

                                  const SizedBox(height: 15),
                                  // Footer
                                  FooterWidget(),
                                ],
                              ),
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
          Positioned(
            bottom: 0, // Distance from bottom
            right: -10, // Distance from right
            child: Image.asset(
              'assets/images/Rectangle2.png',
              width: isLandscape
                  ? 150
                  : 120, // Adjust size based on orientation
              height: isLandscape ? 150 : 120,
              fit: BoxFit.contain,
            ),
          ),

          ErrorStack(key: _errorStackKey),
        ],
      ),
    );
  }

  Widget _buildRequirementRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: bulletColor(isValid)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            color: bulletColor(isValid),
            height: 1.0,
          ),
        ),
      ],
    );
  }

  Column _buildStep(String label, {bool filled = false, Color? filledColor}) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: filled
              ? (filledColor ?? const Color(0xFF00F0FF))
              : Colors.white,
          child: filled
              ? const Icon(Icons.check, color: Colors.white, size: 18)
              : null,
        ),
        const SizedBox(height: 10),
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
