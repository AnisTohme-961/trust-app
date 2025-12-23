import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async' show Timer;
import '../widgets/custom_button.dart';
import 'package:gradient_borders/box_borders/gradient_box_border.dart';
import '../widgets/footer_widgets.dart';
import '../widgets/error_widgets.dart';
import "../services/auth_service.dart";

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasTextInPassword = false;

  bool get _isEmailNotEmpty => _controller.text.isNotEmpty;

  // Verification state variables
  bool _showEmailCodeSent = false;
  List<TextEditingController> _emailCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _emailCode = List.generate(6, (_) => '');

  bool _showSMSCodeSent = false;
  List<TextEditingController> _smsCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _smsFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _smsCode = List.generate(6, (_) => '');

  bool _showAuthCodeSent = false;
  List<TextEditingController> _authCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _authFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _authCode = List.generate(6, (_) => '');

  // Password rule checks
  bool _has2Caps = false;
  bool _has2Lower = false;
  bool _has2Numbers = false;
  bool _has2Special = false;
  bool _hasMin10 = false;
  bool _passwordsMatch = false;

  bool _validationPerformed = false;
  String? _activeCodeType;
  bool codeDisabled = false;

  Timer? _timer;
  int _remainingSeconds = 0;

  List<String> code = List.generate(6, (_) => "");
  Map<String, bool> isCodeCorrectMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  Map<String, bool> isCodeValidMap = {'email': true, 'sms': true, 'auth': true};
  Map<String, bool> _hasCodeBeenSentBeforeMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  bool _codeSent = false;

  bool _showPasswordChangedOverlay = false;

  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // New state variables for button animation effect
  Map<String, bool> _buttonClickedMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  // Timer for button animation reset
  Map<String, Timer?> _buttonAnimationTimers = {
    'email': null,
    'sms': null,
    'auth': null,
  };

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _emailCodeControllers) c.dispose();
    for (var f in _emailFocusNodes) f.dispose();
    for (var c in _smsCodeControllers) c.dispose();
    for (var f in _smsFocusNodes) f.dispose();
    for (var c in _authCodeControllers) c.dispose();
    for (var f in _authFocusNodes) f.dispose();

    // Cancel all timers
    _timer?.cancel();
    for (var timer in _timers.values) {
      timer?.cancel();
    }
    for (var timer in _buttonAnimationTimers.values) {
      timer?.cancel();
    }
    super.dispose();
  }

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

  void _handleBackspace(
    int index,
    List<TextEditingController> controllers,
    List<String> codeList,
    List<FocusNode> focusNodes,
  ) {
    if (codeList[index].isEmpty && index > 0) {
      controllers[index - 1].clear();
      codeList[index - 1] = '';
      focusNodes[index - 1].requestFocus();
      setState(() {});
    }
  }

  void _onChanged(
    String value,
    int index,
    List<TextEditingController> controllers,
    List<String> codeList,
    List<FocusNode> focusNodes,
  ) async {
    // 1️⃣ Keep digits only
    final digits = value.replaceAll(RegExp(r'\D'), '');

    // User deleted input
    if (digits.isEmpty) {
      codeList[index] = '';
      setState(() {});
      return;
    }

    // 2️⃣ Distribute pasted digits starting from current index
    for (int i = 0; i < codeList.length; i++) {
      if (i >= index && (i - index) < digits.length) {
        controllers[i].text = digits[i - index];
        codeList[i] = digits[i - index];
      }
    }

    // 3️⃣ Move focus to next empty field
    final nextIndex = codeList.indexWhere((c) => c.isEmpty);
    if (nextIndex != -1) {
      focusNodes[nextIndex].requestFocus();
    } else {
      focusNodes.last.unfocus(); // all filled
    }

    setState(() {});
  }

  // Timer management variables
  Map<String, int> _countdowns = {'email': 0, 'sms': 0, 'auth': 0};
  Map<String, Timer?> _timers = {'email': null, 'sms': null, 'auth': null};

  void _resetOtpFields(String type) {
    List<TextEditingController> controllers;
    List<FocusNode> focusNodes;
    List<String> codeList;

    // Choose which type to reset
    switch (type) {
      case 'email':
        controllers = _emailCodeControllers;
        focusNodes = _emailFocusNodes;
        codeList = _emailCode;
        break;
      case 'sms':
        controllers = _smsCodeControllers;
        focusNodes = _smsFocusNodes;
        codeList = _smsCode;
        break;
      case 'auth':
        controllers = _authCodeControllers;
        focusNodes = _authFocusNodes;
        codeList = _authCode;
        break;
      default:
        return;
    }

    // Clear all digits
    for (var controller in controllers) {
      controller.clear();
    }

    // Clear internal code list
    for (int i = 0; i < codeList.length; i++) {
      codeList[i] = '';
    }

    // Unfocus everything first
    for (var node in focusNodes) {
      node.unfocus();
    }
  }

  // Updated _fetchCode to handle timer with animation effect
  void _fetchCode(String type) async {
    _resetOtpFields(type);
    // Cancel any existing button animation timer for this type
    _buttonAnimationTimers[type]?.cancel();

    // Show visual feedback
    setState(() {
      _buttonClickedMap[type] = true;
    });

    // Disable if ANY type is active
    if (_activeCodeType != null && _activeCodeType != type) {
      // Reset animation after delay
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _buttonClickedMap[type] = false;
          });
        }
      });
      return;
    }

    if (_countdowns[type]! > 0) {
      // Reset animation after delay
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _buttonClickedMap[type] = false;
          });
        }
      });
      return;
    }

    if (_controller.text.isEmpty) {
      _errorStackKey.currentState?.showError("Please enter your EID / Email");
      // Reset animation after delay
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _buttonClickedMap[type] = false;
          });
        }
      });
      return;
    }

    final identifier = _controller.text.trim();

    try {
      Map<String, dynamic> data;

      if (type == "auth") {
        data = await AuthService.generateTOTP(identifier);
      } else {
        data = await AuthService.sendResetCode(identifier);
      }

      final int cooldown = data["cooldown"] ?? 60;

      // 🔵 Show "Code Sent"
      _setCodeSentFlag(type, true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _setCodeSentFlag(type, false);
      });

      // 🔵 Start cooldown + disable ALL buttons
      setState(() {
        _activeCodeType = type; // 🔥 lock all buttons except this one
        _countdowns[type] = cooldown;
        codeDisabled = true; // disable all buttons
        _hasCodeBeenSentBeforeMap[type] = true;
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
            codeDisabled = false;
          }
        });
      });
    } catch (e) {
      _errorStackKey.currentState?.showError(
        "Failed to send code. Please try again.",
      );
    } finally {
      // Reset animation after short delay
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _buttonClickedMap[type] = false;
          });
        }
      });
    }
  }

  void _setCodeSentFlag(String type, bool value) {
    setState(() {
      if (type == 'email') _showEmailCodeSent = value;
      if (type == 'sms') _showSMSCodeSent = value;
      if (type == 'auth') _showAuthCodeSent = value;
    });
  }

  String generatePassword() {
    // Define character sets
    const capitalLetters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const lowercaseLetters = 'abcdefghijklmnopqrstuvwxyz';
    const numbers = '0123456789';
    const specialCharacters = '!@#\$%^&*()';

    // Ensure we have at least 2 of each required type
    final random = Random();

    // Generate required characters
    final caps = List.generate(
      2,
      (_) => capitalLetters[random.nextInt(capitalLetters.length)],
    ).join();
    final lowers = List.generate(
      2,
      (_) => lowercaseLetters[random.nextInt(lowercaseLetters.length)],
    ).join();
    final nums = List.generate(
      2,
      (_) => numbers[random.nextInt(numbers.length)],
    ).join();
    final specials = List.generate(
      2,
      (_) => specialCharacters[random.nextInt(specialCharacters.length)],
    ).join();

    // Combine all required characters
    String basePassword = caps + lowers + nums + specials;

    // If we need more characters to reach minimum 10, fill with random characters from all sets
    const allChars =
        capitalLetters + lowercaseLetters + numbers + specialCharacters;
    final remainingLength = 10 - basePassword.length;

    if (remainingLength > 0) {
      final extraChars = List.generate(
        remainingLength,
        (_) => allChars[random.nextInt(allChars.length)],
      ).join();
      basePassword += extraChars;
    }

    // Shuffle the password to mix the characters
    final shuffledPassword = basePassword.split('')..shuffle(random);
    return shuffledPassword.join();
  }

  Color bulletColor(bool condition) {
    // Always show validation status based on current password state
    return condition
        ? const Color(0xFF00F0FF) // Change to #00F0FF when valid
        : const Color(0xFFFF0000); // Keep red if invalid
  }

  void _updatePasswordRules() {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    setState(() {
      _has2Caps = RegExp(r'[A-Z]').allMatches(password).length >= 2;
      _has2Lower = RegExp(r'[a-z]').allMatches(password).length >= 2;
      _has2Numbers = RegExp(r'\d').allMatches(password).length >= 2;
      _has2Special = RegExp(r'[!@#\$%^&*()]').allMatches(password).length >= 2;
      _hasMin10 = password.length >= 10;
      _passwordsMatch = password == confirm;
    });
  }

  void _validatePassword() {
    setState(() {
      _validationPerformed = true;
      _updatePasswordRules();
    });
  }

  @override
  void initState() {
    super.initState();

    // Listen to password input changes for automatic validation
    _passwordController.addListener(() {
      setState(() {
        _hasTextInPassword = _passwordController.text.isNotEmpty;
        _updatePasswordRules(); // Validate automatically on every change
      });
    });

    // Listen to confirm password input changes for automatic validation
    _confirmPasswordController.addListener(() {
      setState(() {
        _updatePasswordRules(); // Validate automatically on every change
      });
    });
  }

  void _handleInvalidCode(
    String type,
    List<TextEditingController> controllers,
    List<String> codeList,
    List<FocusNode> focusNodes,
  ) {
    setState(() {
      isCodeValidMap[type] = false;
      isCodeCorrectMap[type] = false;
    });

    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;

      setState(() {
        for (int i = 0; i < controllers.length; i++) {
          controllers[i].clear();
          codeList[i] = '';
        }
        isCodeValidMap[type] = true;
        isCodeCorrectMap[type] = false;
      });

      focusNodes[0].requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 60),
            child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Forgot Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Please enter your email address or EID \n to reset your password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(child: buildEmailInput()),
                  const SizedBox(height: 30),
                  buildVerificationSection(
                    title: 'Email Verification',
                    showCodeSent: _showEmailCodeSent,
                    codeControllers: _emailCodeControllers,
                    focusNodes: _emailFocusNodes,
                    codeList: _emailCode,
                    type: 'email',
                    codeDisabled: codeDisabled,
                    isClicked: _buttonClickedMap['email'] ?? false,
                  ),
                  const SizedBox(height: 10),
                  // buildVerificationSection(
                  //   title: 'SMS Verification',
                  //   showCodeSent: _showSMSCodeSent,
                  //   codeControllers: _smsCodeControllers,
                  //   focusNodes: _smsFocusNodes,
                  //   codeList: _smsCode,
                  //   type: 'sms',
                  //   codeDisabled: codeDisabled,
                  //   isClicked: _buttonClickedMap['sms'] ?? false,
                  // ),
                  // const SizedBox(height: 10),
                  // buildVerificationSection(
                  //   title: 'Authenticator App',
                  //   showCodeSent: _showAuthCodeSent,
                  //   codeControllers: _authCodeControllers,
                  //   focusNodes: _authFocusNodes,
                  //   codeList: _authCode,
                  //   type: 'auth',
                  //   codeDisabled: codeDisabled,
                  //   isClicked: _buttonClickedMap['auth'] ?? false,
                  // ),
                  const SizedBox(height: 0),
                  buildPasswordRow(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    toggleObscure: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    hasTextInPassword: _hasTextInPassword,
                    clearOrPaste: () async {
                      if (_hasTextInPassword) {
                        // Clear both password fields
                        _passwordController.clear();
                        _confirmPasswordController.clear();
                        setState(() => _hasTextInPassword = false);
                      } else {
                        final clipboardData = await Clipboard.getData(
                          'text/plain',
                        );
                        if (clipboardData != null) {
                          final text = clipboardData.text ?? '';
                          _passwordController.text = text;
                          _confirmPasswordController.text = text;
                          setState(() => _hasTextInPassword = text.isNotEmpty);
                        }
                      }
                    },
                    hint: "New Password",
                  ),
                  const SizedBox(height: 15),
                  buildConfirmAndGenerateRow(),
                  buildPasswordRules(),
                  buildBackAndChangeButtons(),

                  const SizedBox(height: 40),
                  const Text(
                    'Your system is safe again \n Welcome Back',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  FooterWidget(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          ErrorStack(key: _errorStackKey),

          // ✅ Success overlay (on top of everything)
          if (_showPasswordChangedOverlay)
            Container(
              color: Colors.black.withOpacity(0.7),
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/blueCircleCheck.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Password changed\nsuccessfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget buildPasswordRow({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleObscure,
    required bool hasTextInPassword,
    required VoidCallback clearOrPaste,
    String hint = "Password",
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7.64),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1),
              color: Colors.transparent,
            ),
            child: Row(
              children: [
                Image.asset('assets/images/Icon.png', width: 18, height: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    controller: controller,
                    obscureText: obscureText,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: const TextStyle(
                        color: Colors.white54,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      setState(() {
                        // Update the hasTextInPassword state for floating label
                        // _hasTextInPassword = value.isNotEmpty;
                        _updatePasswordRules();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: toggleObscure,
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Image.asset(
                      obscureText
                          ? 'assets/images/eyeSlash.png'
                          : 'assets/images/eye1.png',
                      width: 22,
                      height: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () async {
                    if (_hasTextInPassword) {
                      // Clear both password and confirm password fields
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      setState(() => _hasTextInPassword = false);
                    } else {
                      // Paste from clipboard into both fields
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData != null) {
                        final text = clipboardData.text ?? '';
                        _passwordController.text = text;
                        _confirmPasswordController.text = text;
                        setState(() => _hasTextInPassword = text.isNotEmpty);
                      }
                    }
                  },
                  child: Container(
                    width: 65,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      hasTextInPassword ? "Clear" : "Paste",
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Floating label
          if (controller.text.isNotEmpty)
            Positioned(
              left: 10,
              top: -10,
              child: Container(
                color: const Color(0xFF0B1320),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  hint, // Display 'Password'
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget buildConfirmAndGenerateRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        children: [
          // Confirm Password field with floating label
          Expanded(
            flex: 2,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF00F0FF),
                      width: 1,
                    ),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/images/Icon.png',
                        width: 18,
                        height: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(
                            color: Color(0xFF00F0FF),
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
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
                          onChanged: (value) {
                            setState(() {
                              _passwordsMatch =
                                  _passwordController.text == value;
                              _hasTextInPassword =
                                  _passwordController.text.isNotEmpty ||
                                  _confirmPasswordController.text.isNotEmpty;
                              _updatePasswordRules(); // Auto validate on change
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.asset(
                            _obscureConfirmPassword
                                ? 'assets/images/eyeSlash.png'
                                : 'assets/images/eye1.png',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Floating label for Confirm Password
                if (_confirmPasswordController.text.isNotEmpty)
                  Positioned(
                    left: 12,
                    top: -10,
                    child: Container(
                      color: const Color(0xFF0B1320),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: const Text(
                        "Confirm Password",
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
          ),
          const SizedBox(width: 8),
          // Generate Password button
          Flexible(
            flex: 1,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: const GradientBoxBorder(
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
                    _hasTextInPassword = true;
                    _updatePasswordRules();
                    _passwordsMatch = true;
                  });
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/stars.png',
                      width: 32,
                      height: 32,
                    ),
                    const SizedBox(width: 4),
                    const Flexible(
                      child: Text(
                        'Generate',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                          color: Colors.white,
                        ),
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

  Widget buildPasswordRules() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 20),
      child: Container(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 50.0),
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
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBullet("2 Capital Letters", _has2Caps),
                      const SizedBox(height: 5),
                      buildBullet("2 Lowercase Letters", _has2Lower),
                      const SizedBox(height: 5),
                      buildBullet("2 Numbers", _has2Numbers),
                    ],
                  ),
                ),
                const Spacer(), 
                IntrinsicWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildBullet("2 Special Characters", _has2Special),
                      const SizedBox(height: 5),
                      buildBullet("Minimum 10 Characters", _hasMin10),
                      const SizedBox(height: 5),
                      buildBullet("Passwords Match", _passwordsMatch),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildBullet(String text, bool condition) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start, // Align top of icon with first line
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 8.0,
          ), // optional: small vertical adjustment
          child: Icon(Icons.circle, size: 8, color: bulletColor(condition)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: bulletColor(condition),
              letterSpacing: -0.03 * 20,
              height: 1.2, // adjust spacing for multi-line
            ),
          ),
        ),
      ],
    );
  }

  Widget buildEmailInput() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.92;

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
                    controller: _controller,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'EID / Email ',
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
                  text: _isEmailNotEmpty ? 'Clear' : 'Paste',
                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    final clipboardData = await Clipboard.getData('text/plain');
                    final text = clipboardData?.text;
                    if (_isEmailNotEmpty) {
                      _controller.clear();
                    } else if (text != null) {
                      _controller.text = text;
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (_controller.text.isNotEmpty)
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

  Widget buildVerificationSection({
    required String title,
    required bool showCodeSent,
    required List<TextEditingController> codeControllers,
    required List<FocusNode> focusNodes,
    required List<String> codeList,
    required String type,
    required bool codeDisabled,
    required bool isClicked,
  }) {
    bool isCodeCorrect = isCodeCorrectMap[type] ?? false;
    bool isCodeValid = isCodeValidMap[type] ?? true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 0),
      child: SizedBox(
        height: 85,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 🟦 Title
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

            // 🟦 "Code Sent" indicator
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

            // 🔢 OTP Fields
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
                              child: RawKeyboardListener(
                                focusNode:
                                    FocusNode(), // separate node for listener
                                onKey: (event) {
                                  if (event is RawKeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.backspace) {
                                    _handleBackspace(
                                      index,
                                      codeControllers,
                                      codeList,
                                      focusNodes,
                                    );
                                  }
                                },
                                child: TextField(
                                  controller: codeControllers[index],
                                  focusNode: focusNodes[index],
                                  showCursor: !codeDisabled,
                                  enabled: !codeDisabled,
                                  readOnly: codeDisabled,
                                  textAlign: TextAlign.center,
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
                                  onChanged: (value) async {
                                    // 1️⃣ Handle typing + paste + focus correctly
                                    _onChanged(
                                      value,
                                      index,
                                      codeControllers,
                                      codeList,
                                      focusNodes,
                                    );

                                    // 2️⃣ Reset validity while typing
                                    setState(() {
                                      isCodeValidMap[type] = true;
                                      isCodeCorrectMap[type] = false;
                                    });

                                    // 3️⃣ Verify only when ALL digits are filled
                                    if (codeList.every((c) => c.isNotEmpty)) {
                                      final email = _controller.text.trim();
                                      bool valid = false;

                                      try {
                                        if (type == 'auth') {
                                          valid = await AuthService.verifyTOTP(
                                            email: email,
                                            code: codeList.join(),
                                          );
                                        } else {
                                          valid =
                                              await AuthService.verifyResetCode(
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
                                          _handleInvalidCode(
                                            type,
                                            codeControllers,
                                            codeList,
                                            focusNodes,
                                          );
                                        }
                                      } catch (_) {
                                        _handleInvalidCode(
                                          type,
                                          codeControllers,
                                          codeList,
                                          focusNodes,
                                        );
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),

                            // 🔹 Underline (vanishes when correct)
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

            // 📩 Get Code button WITH ANIMATION EFFECT
            Positioned(
              top: 21,
              left: 280,
              child: GestureDetector(
                onTap: (_activeCodeType == null || _activeCodeType == type)
                    ? () {
                        // Show visual feedback immediately
                        setState(() {
                          _buttonClickedMap[type] = true;
                        });

                        if (_controller.text.isEmpty) {
                          _errorStackKey.currentState?.showError(
                            "Please enter your EID / Email",
                          );
                          // Reset animation after delay
                          Future.delayed(Duration(milliseconds: 200), () {
                            if (mounted) {
                              setState(() {
                                _buttonClickedMap[type] = false;
                              });
                            }
                          });
                          return;
                        }
                        _fetchCode(type);
                      }
                    : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  width: 94,
                  height: 23,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: _buttonClickedMap[type]!
                        ? [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: const Offset(0, 0),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: const Color(0xFF00F0FF).withOpacity(0.8),
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
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: _countdowns[type]! > 0
                                ? const Color(0xFF0B1320)
                                : (_buttonClickedMap[type]!
                                      ? Colors.white
                                      : Colors.black),
                          ),
                        )
                      : Text(
                          _hasCodeBeenSentBeforeMap[type]!
                              ? "Send Again"
                              : "Get Code",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: _buttonClickedMap[type]!
                                ? Colors.white
                                : Colors.black,
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

  Widget buildBackAndChangeButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        CustomButton(
          text: 'Back',
          width: 100,
          height: 45,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          textColor: Colors.white,
          borderColor: const Color(0xFF00F0FF),
          backgroundColor: const Color(0xFF0B1320),
          onTap: () {
            Navigator.pop(context); // Go back to the previous screen
          },
        ),

        const SizedBox(width: 20),
        CustomButton(
          text: 'Change',
          width: 100,
          height: 45,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          textColor: Colors.white,
          borderColor: const Color(0xFF00F0FF),
          backgroundColor: const Color(0xFF0B1320),
          onTap: () async {
            // Only proceed if password is valid
            if (_has2Caps &&
                _has2Lower &&
                _has2Numbers &&
                _has2Special &&
                _hasMin10 &&
                _passwordsMatch) {
              // Determine which code type to use
              String type = '';
              List<String> codeList = [];
              if (_emailCode.every((c) => c.isNotEmpty)) {
                type = 'email';
                codeList = _emailCode;
              } else if (_smsCode.every((c) => c.isNotEmpty)) {
                type = 'sms';
                codeList = _smsCode;
              } else if (_authCode.every((c) => c.isNotEmpty)) {
                type = 'auth';
                codeList = _authCode;
              } else {
                _errorStackKey.currentState?.showError(
                  "Please enter verification code",
                );
                return;
              }

              try {
                // Verify the code depending on type
                bool verified = false;
                if (type == 'auth') {
                  verified = await AuthService.verifyTOTP(
                    email: _controller.text.trim(),
                    code: codeList.join(),
                  );
                } else {
                  verified = await AuthService.verifyResetCode(
                    identifier: _controller.text.trim(),
                    code: codeList.join(),
                  );
                }

                if (!verified) {
                  _errorStackKey.currentState?.showError(
                    "Invalid or expired code",
                  );
                  return;
                }

                // Reset password
                await AuthService.resetPassword(
                  identifier: _controller.text.trim(),
                  code: codeList.join(),
                  newPassword: _passwordController.text,
                  confirmPassword: _confirmPasswordController.text,
                  method: type,
                );

                // Show overlay after successful verification and reset
                setState(() => _showPasswordChangedOverlay = true);
                Timer(const Duration(seconds: 3), () {
                  setState(() => _showPasswordChangedOverlay = false);
                  Navigator.pushReplacementNamed(context, '/sign-in');
                });
              } catch (e) {
                _errorStackKey.currentState?.showError(e.toString());
              }
            } else {
              _errorStackKey.currentState?.showError(
                "Please follow password requirements",
              );
            }
          },
        ),

        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF0B1320)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
