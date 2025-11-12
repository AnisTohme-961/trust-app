import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../widgets/error_widgets.dart';
import 'dart:convert'; // Added for jsonDecode
import 'package:flutter/services.dart';
import '../widgets/footer_widgets.dart';

class SignInSecondTimeScreen extends StatefulWidget {
  const SignInSecondTimeScreen({super.key});

  @override
  State<SignInSecondTimeScreen> createState() => _SignInSecondTimeScreenState();
}

class _SignInSecondTimeScreenState extends State<SignInSecondTimeScreen> {
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _rememberMe = false;

  bool get _isEmailNotEmpty => _controller.text.isNotEmpty;
  bool get _isPasswordNotEmpty => _passwordController.text.isNotEmpty;

  bool _hideInputFields = false;
  bool _tooManyAttempts = false;
  bool isCodeCorrect = false;
  bool? _isCodeValid;

  List<TextEditingController> _codecontrollers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  List<String> code = List.generate(6, (_) => "");
  int _secondsLeft = 0;

  int _getCodeAttempts = 0;

  List<TextEditingController> _authCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _authFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> authCode = List.generate(6, (_) => "");
  bool _hideAuthenticatorInput = false;
  bool _tooManyAuthenticatorAttempts = false;
  bool isAuthenticatorCodeCorrect = false;
  bool? _isAuthenticatorCodeValid;
  int _authSecondsLeft = 0;

  //for the SMS verification
  // SMS Verification front-end only
  List<TextEditingController> _smsCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _smsFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _smsCode = List.generate(6, (_) => "");
  bool _hideSMSInputFields = false;
  bool isSMSCodeCorrect = false; // just for UI simulation
  int _smsSecondsLeft = 0;

  void _onSMSChanged(String value, int index) {
    setState(() {
      _smsCode[index] = value;

      if (value.isNotEmpty && index < 5) {
        _smsFocusNodes[index + 1].requestFocus();
      } else if (value.isEmpty && index > 0) {
        _smsFocusNodes[index - 1].requestFocus();
      }

      // Simulate code validation when all fields are filled
      if (_smsCode.every((c) => c.isNotEmpty)) {
        isSMSCodeCorrect = true; // just for demo, mark as correct
      } else {
        isSMSCodeCorrect = false;
      }
    });
  }

  void fetchSMSCode() {
    setState(() {
      _hideSMSInputFields = true; // show "Code Sent"
      _smsCodeControllers.forEach((c) => c.clear());
      _smsCode = List.generate(6, (_) => "");
      isSMSCodeCorrect = false;
      _smsSecondsLeft = 120; // start countdown immediately
    });

    // Countdown timer
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_smsSecondsLeft <= 0) {
        timer.cancel();
      } else {
        setState(() => _smsSecondsLeft--);
      }
    });

    // Show input fields again after 2 seconds
    Timer(const Duration(seconds: 2), () {
      setState(() {
        _hideSMSInputFields = false;
      });
    });
  }

  String getEnteredSMSCode() =>
      _smsCodeControllers.map((c) => c.text.trim()).join();

  void fetchCodeFromGo() async {
    final identifier = _controller.text.trim();

    // ✅ Show an error if the field is empty
    if (identifier.isEmpty) {
      errorStackKey.currentState?.showError(
        'Please enter your eid/email first',
        duration: const Duration(seconds: 5),
      );
      return;
    }

    try {
      if (_getCodeAttempts >= 4) {
        errorStackKey.currentState?.showError(
          "Too many attempts. Please try again in 10 minutes.",
          duration: const Duration(seconds: 5),
        );

        // reset after 10 minutes
        Timer(const Duration(minutes: 10), () {
          setState(() => _getCodeAttempts = 0);
        });
        return;
      }

      await AuthService.sendCode(identifier: identifier);
      setState(() {
        _getCodeAttempts++;
        _hideInputFields = true;
        isCodeCorrect = false;
        _isCodeValid = null;
        code = List.generate(6, (_) => "");
        _codecontrollers.forEach((c) => c.clear());
      });

      Timer(const Duration(seconds: 2), () {
        setState(() {
          _hideInputFields = false;
        });
      });

      _secondsLeft = 120; // 2 minutes
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft <= 0) {
          timer.cancel();
        } else {
          setState(() {
            _secondsLeft--;
          });
        }
      });
    } catch (e) {
      errorStackKey.currentState?.showError(
        'Failed to send code',
        duration: const Duration(seconds: 5),
      );
    }
  }

  String getEnteredCode() => _codecontrollers.map((c) => c.text.trim()).join();

  void _onChanged(String value, int index) async {
    setState(() {
      code[index] = value;
      if (value.isNotEmpty && index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else if (value.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    });

    // Verify code automatically when all 6 digits are filled
    if (getEnteredCode().length == 6 &&
        getEnteredCode().split('').every((d) => d.isNotEmpty)) {
      try {
        final res = await AuthService.verifyCode(
          identifier: _controller.text.trim(),
          code: getEnteredCode(),
        );

        setState(() {
          isCodeCorrect = res;
          _isCodeValid = res;
        });

        if (res) {
          // Stop timer when code is correct
          _secondsLeft = 0;
        } else {
          errorStackKey.currentState?.showError(
            'Incorrect or expired code. Please request a new one',
            duration: const Duration(seconds: 5),
          );
        }
      } catch (e) {
        setState(() {
          isCodeCorrect = false;
          _isCodeValid = false;
        });
        final msg = e.toString().contains('expired')
            ? 'Code expired. Please request a new one'
            : 'Incorrect code. Try again';
        errorStackKey.currentState?.showError(
          msg,
          duration: const Duration(seconds: 5),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    _codecontrollers.forEach((c) => c.dispose());
    _focusNodes.forEach((f) => f.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const SizedBox(height: 75),
                Image.asset(
                  'egetyPerfectStar.png',
                  width: 111,
                  height: 126,
                  fit: BoxFit.contain,
                ),
                const Text(
                  'Egety Trust',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 50,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                signInAndSignUpButtons(),
                const SizedBox(height: 10),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Text(
                  'Please enter your credentials to continue',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 15),
                buildEmailInput(),
                const SizedBox(height: 15),
                buildPasswordInput(),
                buildForgotRow(),
                buildRememberMe(),
                const SizedBox(height: 10),
                buildEmailVerification(),

                const SizedBox(height: 15),
                buildSMSVerification(),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                  ), // optional left/right spacing
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 160,
                      height: 26,
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
                      child: const Center(
                        child: Text(
                          "Call me instead",
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                buildAuthenticatorApp(),

                buildSignInButton(),
                const SizedBox(height: 20),
                const Text(
                  'You built your vault Now unlock it',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                FooterWidget(),
              ],
            ),
          ),
          ErrorStack(key: errorStackKey),
        ],
      ),
    );
  }

  Widget buildEmailInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                    'SVGRepo_iconCarrier.png',
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
                    if (_isEmailNotEmpty) {
                      _controller.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        _controller.text = clipboardData!.text!;
                      }
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

  Widget buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
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
                Image.asset(
                  'Icon.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Password',
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
                GestureDetector(
                  onTap: () => setState(() => _showPassword = !_showPassword),
                  child: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF00F0FF),
                  ),
                ),
                const SizedBox(width: 10),
                CustomButton(
                  text: _isPasswordNotEmpty ? 'Clear' : 'Paste',
                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (_isPasswordNotEmpty) {
                      _passwordController.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        _passwordController.text = clipboardData!.text!;
                      }
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (_passwordController.text.isNotEmpty)
            Positioned(
              left: 15,
              top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                color: const Color(0xFF0B1320),
                child: const Text(
                  'Password',
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

  Widget buildForgotRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Forgot EID?',
            style: TextStyle(
              color: Color(0xFF00F0FF),
              fontSize: 15,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/forgot-password');
            },
            child: const Text(
              'Forgot Password?',
              style: TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRememberMe() {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: _rememberMe,
              onChanged: (value) =>
                  setState(() => _rememberMe = value ?? false),
              side: const BorderSide(color: Color(0xFF00F0FF)),
              checkColor: Colors.black,
              activeColor: const Color(0xFF00F0FF),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const Expanded(
            child: Text(
              'Remember Me On This Device',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildEmailVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -4,
              left: -1,
              child: Text(
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
            ),
            if (_hideInputFields)
              Positioned(
                top: 21,
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
                      height: 1.0,
                      letterSpacing: -1.6,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            if (!_hideInputFields)
              Positioned(
                top: 25,
                left: 0,
                child: Row(
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 24,
                            child: TextField(
                              controller: _codecontrollers[index],
                              focusNode: _focusNodes[index],
                              showCursor: !(code.every((c) => c.isNotEmpty)),
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isCodeCorrect
                                    ? const Color(0xFF00F0FF)
                                    : (_isCodeValid == false
                                          ? Colors.red
                                          : Colors.white),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              cursorColor: isCodeCorrect
                                  ? const Color(0xFF00F0FF)
                                  : (_isCodeValid == false
                                        ? Colors.red
                                        : Colors.white),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => _onChanged(value, index),
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
                    );
                  }),
                ),
              ),
            if (isCodeCorrect)
              const Positioned(
                top: 25,
                left: 240,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF00F0FF),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            Positioned(
              top: 21,
              left: 270,
              child: GestureDetector(
                onTap: (_secondsLeft == 0 && !_tooManyAttempts)
                    ? fetchCodeFromGo
                    : null,
                child: Container(
                  width: 100,
                  height: 26,
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
                              fontSize: 15,
                              color: Colors.black,
                            ),
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

  Widget buildSignInButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 30),
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
          text: 'Sign In',
          width: 120,
          height: 45,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          textColor: Colors.white,
          borderColor: const Color(0xFF00F0FF),
          backgroundColor: const Color(0xFF0B1320),
          onTap: () async {
            final identifier = _controller.text.trim();
            final password = _passwordController.text.trim();
            final code = getEnteredCode();

            // Basic validations
            if (identifier.isEmpty) {
              errorStackKey.currentState?.showError(
                'Please enter your eid/email',
                duration: const Duration(seconds: 5),
              );
              return;
            }
            if (password.isEmpty) {
              errorStackKey.currentState?.showError(
                'Please enter your password',
                duration: const Duration(seconds: 5),
              );
              return;
            }
            if (code.length != 6) {
              errorStackKey.currentState?.showError(
                'Enter the 6-digit code sent to your email address',
                duration: const Duration(seconds: 5),
              );
              return;
            }
            if (!isCodeCorrect) {
              errorStackKey.currentState?.showError(
                'Please wait for code verification',
                duration: const Duration(seconds: 5),
              );
              return;
            }

            try {
              final success = await AuthService.signIn(
                identifier: identifier,
                password: password,
                code: code,
                rememberMe: _rememberMe,
              );

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sign in successful!')),
                );
                Navigator.pushReplacementNamed(context, '/register-pin');
              }
            } catch (e) {
              print('Sign in error: $e');
              String message = 'Invalid login credentials';
              final s = e.toString();

              try {
                // Remove "Exception: " prefix if present
                final jsonStr = s.startsWith('Exception: ')
                    ? s.substring(11)
                    : s;
                final map = jsonDecode(jsonStr) as Map<String, dynamic>;

                if (map.containsKey('remainingSeconds')) {
                  final secs = (map['remainingSeconds'] as num).toInt();
                  final h = secs ~/ 3600;
                  final m = (secs % 3600) ~/ 60;
                  final sec = secs % 60;
                  message =
                      'Your account is locked. It will be unlocked in\n${h}h ${m}m ${sec}s';
                } else if (map.containsKey('error') &&
                    map['error'].toString().toLowerCase().contains('expired')) {
                  message = 'Code expired. Please request a new one';
                } else if (map.containsKey('error')) {
                  message = map['error'];
                }
              } catch (_) {
                // Fallback: keep generic message
              }

              errorStackKey.currentState?.showError(
                message,
                duration: const Duration(seconds: 5),
              );
            }
          },
        ),

        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 30),
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

  Row signInAndSignUpButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          text: 'Sign In',
          width: 120,
          height: 45,
          fontSize: 22,
          textColor: Colors.black,
          backgroundColor: const Color(0xFF00F0FF),
          borderColor: const Color(0xFF00F0FF),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          onTap: () {},
        ),
        const SizedBox(width: 20),
        CustomButton(
          text: 'Sign Up',
          width: 120,
          height: 45,
          fontSize: 22,
          textColor: Colors.white,
          backgroundColor: const Color(0xFF0B1320),
          borderColor: const Color(0xFF00F0FF),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          onTap: () {},
        ),
      ],
    );
  }

  Widget buildAuthenticatorApp() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -4,
              left: -1,
              child: Text(
                "Authenticator App",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.0,
                  color: Colors.white,
                  letterSpacing: -0.08,
                ),
              ),
            ),
            // "Code Sent" container
            if (_hideAuthenticatorInput)
              Positioned(
                top: 21,
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
                      fontSize: 20,
                      height: 1.0,
                      letterSpacing: -1.6,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            // 6 input fields
            if (!_hideAuthenticatorInput)
              Positioned(
                top: 25,
                left: 0,
                child: Row(
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 24,
                            child: TextField(
                              controller: _authCodeControllers[index],
                              focusNode: _authFocusNodes[index],
                              showCursor: !authCode.every((c) => c.isNotEmpty),
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isAuthenticatorCodeCorrect
                                    ? const Color(0xFF00F0FF)
                                    : (_isAuthenticatorCodeValid == false
                                          ? Colors.red
                                          : Colors.white),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              cursorColor: isAuthenticatorCodeCorrect
                                  ? const Color(0xFF00F0FF)
                                  : (_isAuthenticatorCodeValid == false
                                        ? Colors.red
                                        : Colors.white),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  authCode[index] = value;
                                  if (value.isNotEmpty && index < 5) {
                                    _authFocusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _authFocusNodes[index - 1].requestFocus();
                                  }
                                });
                              },
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 2,
                            color: authCode[index].isEmpty
                                ? Colors.white
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            if (isAuthenticatorCodeCorrect)
              const Positioned(
                top: 25,
                left: 240,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF00F0FF),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            // Get Code button
            Positioned(
              top: 21,
              left: 270,
              child: GestureDetector(
                onTap: (_authSecondsLeft == 0 && !_tooManyAuthenticatorAttempts)
                    ? () {
                        setState(() {
                          _hideAuthenticatorInput = true; // show "Code Sent"
                          _authSecondsLeft = 120; // 2 min countdown
                        });

                        // Show "Code Sent" for 2 seconds, then show input fields again
                        Timer(const Duration(seconds: 2), () {
                          setState(() {
                            _hideAuthenticatorInput = false; // show inputs
                            _authCodeControllers.forEach((c) => c.clear());
                            authCode = List.generate(6, (_) => "");
                          });
                        });

                        // Countdown timer (like email verification)
                        Timer.periodic(const Duration(seconds: 1), (timer) {
                          if (_authSecondsLeft <= 0) {
                            timer.cancel();
                          } else {
                            setState(() {
                              _authSecondsLeft--;
                            });
                          }
                        });
                      }
                    : null,
                child: Container(
                  width: 100,
                  height: 26,
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
                    child: _authSecondsLeft > 0
                        ? Text(
                            "${_authSecondsLeft ~/ 60}m ${_authSecondsLeft % 60}s",
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
                              fontSize: 15,
                              color: Colors.black,
                            ),
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

  Widget buildSMSVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: SizedBox(
        height: 70,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -4,
              left: -1,
              child: Text(
                "SMS Verification",
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
            // Show "Code Sent" only if inputs are hidden
            if (_hideSMSInputFields)
              Positioned(
                top: 21,
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
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            // 6 SMS input fields
            if (!_hideSMSInputFields)
              Positioned(
                top: 25,
                left: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 30,
                            height: 24,
                            child: TextField(
                              controller: _smsCodeControllers[index],
                              focusNode: _smsFocusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isSMSCodeCorrect
                                    ? const Color(0xFF00F0FF)
                                    : Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              cursorColor: Colors.white,
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => _onSMSChanged(value, index),
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 2,
                            color: _smsCode[index].isEmpty
                                ? Colors.white
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            if (isSMSCodeCorrect)
              const Positioned(
                top: 25,
                left: 240,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF00F0FF),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            // Get Code button
            Positioned(
              top: 21,
              left: 270,
              child: GestureDetector(
                onTap: _smsSecondsLeft == 0 ? fetchSMSCode : null,
                child: Container(
                  width: 100,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: _smsSecondsLeft > 0
                        ? Text(
                            "${_smsSecondsLeft ~/ 60}m ${_smsSecondsLeft % 60}s",
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
                              fontSize: 15,
                              color: Colors.black,
                            ),
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
}
