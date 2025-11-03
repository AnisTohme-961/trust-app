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
    return MaterialApp(debugShowCheckedModeBanner: false, home: PasswordPage());
  }
}

class PasswordPage extends StatefulWidget {
  const PasswordPage({super.key});

  @override
  State<PasswordPage> createState() => _PasswordPageState();
}

class _PasswordPageState extends State<PasswordPage> {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SizedBox(
        width: 430,
        height: 932,
        child: Stack(
          children: [
            // Buttons container
            Positioned(
              top: 100,
              left: 99,
              child: SizedBox(
                width: 230,
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
                                      const Color(0xFF00F0FF).withOpacity(0.7),
                                      const Color(0xFF0177B3).withOpacity(0.7),
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
            ),
            // Add this inside the Stack children, below the buttons Positioned
            Positioned(
              top: 152,
              left: 66,
              child: Container(
                width: 299,
                height: 36,
                alignment: Alignment.center, // center the text
                child: const Text(
                  'Protect Your Access',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700, // bold
                    fontSize: 30,
                    height: 1.0, // line-height 100%
                    color: Colors.white, // text color on white background
                  ),
                ),
              ),
            ),
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress Line
                    Positioned(
                      top: 9.5,
                      left: 32,
                      right: 40,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const totalSteps = 5;
                          const completedSteps = 2; // fill 2 steps
                          final segmentCount = totalSteps - 1;

                          final totalWidth = constraints.maxWidth;
                          final filledWidth =
                              totalWidth *
                              (completedSteps / segmentCount); // fill 2 steps
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
                                      Color(0xFF13D2C7), // your gradient start
                                      Color(0xFF00259E), // gradient end
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
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStep("Profile\nStart", filled: true),
                        _buildStep(
                          "Contact\nand Verify",
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
            ),
            Positioned(
              top: 287,
              left: 18,
              child: Container(
                width: 394,
                height: 192,
                child: Stack(
                  children: [
                    // Title: "Got a Strong Password?"
                    Positioned(
                      top: 0,
                      left: 82,
                      child: SizedBox(
                        child: const Text(
                          "Got a Strong Password?",
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

                    // Password Input Field Containerr
                    Positioned(
                      top: 36,
                      left: 0,
                      child: Container(
                        width: 374,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(7.64),
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 1,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            // Lock icon
                            Container(
                              width: 20,
                              height: 20,
                              child: Image.asset(
                                'assets/images/Icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // TextField
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
                                decoration: const InputDecoration(
                                  hintText: "Password",
                                  hintStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.white54,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            // Eye toggle
                            GestureDetector(
                              onTap: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: Image.asset(
                                  _obscurePassword
                                      ? 'assets/images/eyeSlash.png'
                                      : 'assets/images/eye1.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Paste button
                            GestureDetector(
                              onTap: () async {
                                if (_hasTextInPassword) {
                                  // Clear both fields
                                  _passwordController.clear();
                                  _confirmPasswordController.clear();
                                  setState(() {
                                    _hasTextInPassword = false;
                                  });
                                } else {
                                  // Paste from clipboard into both fields
                                  final clipboardData = await Clipboard.getData(
                                    'text/plain',
                                  );
                                  if (clipboardData != null) {
                                    final text = clipboardData.text ?? '';
                                    _passwordController.text = text;
                                    _confirmPasswordController.text = text;
                                    setState(() {
                                      _hasTextInPassword = text.isNotEmpty;
                                    });
                                  }
                                }
                              },
                              child: Container(
                                width: 60,
                                height: 30,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: const Color(0xFF00F0FF),
                                    width: 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  _hasTextInPassword ? "Clear" : "Paste",
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
                    ),

                    // Confirm Password
                    Positioned(
                      top: 100,
                      left: 0,
                      child: Container(
                        width: 240,
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00F0FF),
                            width: 1,
                          ),
                          color: Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Lock icon
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: Image.asset(
                                'assets/images/Icon.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(
                                  color: Color(0xFF00F0FF),
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                ),
                                decoration: const InputDecoration(
                                  hintText: "Confirm Password",
                                  hintStyle: TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                              child: SizedBox(
                                width: 22,
                                height: 22,
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

                    Positioned(
                      top: 100, // relative to container
                      left:
                          252, // adjust so button keeps same right padding as the page
                      child: Container(
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
                              _passwordController.text =
                                  newPassword; // your password TextEditingController
                            });
                          },
                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min, // shrink row to fit content
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Image inside the button
                              Container(
                                width: 38, // increased size
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
                              const SizedBox(width: 4), // small spacing to text
                              // Text
                              const Text(
                                "Generate",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.white,
                                  letterSpacing: -0.08 * 20, // -8%
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Add vertical space below Confirm Password and Generate fields
                    Positioned(
                      top: 160, // below the fields (100 + 52 + some space)
                      left: 0,
                      child: SizedBox(height: 44, width: 1),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 451,
              left: 10,
              child: Container(
                width: 409,
                height: 146,
                child: Stack(
                  children: [
                    // Title
                    Positioned(
                      top: 20,
                      left: 50,
                      child: SizedBox(
                        child: const Text(
                          "Your password should contain at least",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    // Left Column
                    Positioned(
                      top: 40,
                      left: 10,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2 Capital Letters
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: bulletColor(_has2Caps),
                              ), // bullet
                              SizedBox(width: 8),
                              Text(
                                "2 Capital Letters",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: bulletColor(_has2Caps),
                                  letterSpacing: -0.03 * 20,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // 2 Lowercase Letters
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: bulletColor(_has2Lower),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "2 Lowercase Letters",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: bulletColor(_has2Lower),
                                  letterSpacing: -0.03 * 20,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // 2 Numbers
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: bulletColor(_has2Numbers),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "2 Numbers",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: bulletColor(_has2Numbers),
                                  letterSpacing: -0.03 * 20,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right Column
                    Positioned(
                      top: 40,
                      left: 205,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 2 Special Characters
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: bulletColor(_has2Special),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "2 Special Characters",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: bulletColor(_has2Special),
                                  letterSpacing: -0.03 * 20,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Minimum 10 Characters
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: bulletColor(_hasMin10),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Minimum 10 Characters",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: bulletColor(_hasMin10),
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          // Passwords Match
                          Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: bulletColor(_passwordsMatch),
                              ),
                              SizedBox(width: 8),
                              Text(
                                "Passwords Match",
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: bulletColor(_passwordsMatch),
                                  letterSpacing: -0.03 * 20,
                                  height: 1.0,
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
            ),
            Positioned(
              top: 590, // adjust as needed
              left: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isChecked = !isChecked; // toggle
                      });
                    },
                    // Small square
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
                  const SizedBox(width: 10), // space between square and text
                  // Text column
                  SizedBox(
                    width: 330, // adjust width as needed
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
            ),

            Positioned(
              top: 690,
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
                          begin: Alignment.centerRight, // 270deg
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
                          Navigator.of(context).pop(); // <-- Just pop
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
                              Positioned(
                                top: 8,
                                left: 30,
                                child: Text(
                                  "Back",
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 20,
                                    height: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
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
                          _validateAndSubmit(); // validate bullets and show red if invalid

                          // Only proceed if all password rules pass
                          if (_has2Caps &&
                              _has2Lower &&
                              _has2Numbers &&
                              _has2Special &&
                              _hasMin10 &&
                              _passwordsMatch &&
                              isChecked) {
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
                              country: {
                                "name": userProvider.country,
                                "code": userProvider.countryId,
                              },
                              language: {
                                "name": userProvider.selectedLanguage,
                                "code": userProvider.selectedLanguageId,
                              },
                              dob: userProvider.dob,
                            );

                            setState(() => isLoading = false);

                            if (eid != null) {
                              userProvider.setEID(eid);
                              userProvider.markAsRegistered();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => RegisterLivePage(),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Failed to create user"),
                                ),
                              );
                            }
                          }
                        },
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

                    // Right Gradient Line Frame
                    Container(
                      width: 64,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: const LinearGradient(
                          begin: Alignment.centerRight, // 270deg
                          end: Alignment.centerLeft,
                          colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 785,
              left: 70,
              child: SizedBox(
                width: 291,
                height: 48,
                child: const Text(
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
            ),
            Positioned(bottom: 45, left: 0, right: 0, child: FooterWidget()),
            ErrorStack(key: _errorStackKey),
          ],
        ),
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
