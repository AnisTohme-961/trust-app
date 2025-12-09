import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../widgets/error_widgets.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../widgets/footer_widgets.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isClicked = false; // Added for button animation


  bool get _isEmailNotEmpty => _controller.text.isNotEmpty;
  bool get _isPasswordNotEmpty => _passwordController.text.isNotEmpty;

  String serverCode = "";
  bool _hideInputFields = false;
  bool _tooManyAttempts = false;
  bool isCodeCorrect = false;
  bool? _isCodeValid;
  bool _codeDisabled = false;
  bool _showCodeSent = false;

  @override
  void initState() {
    super.initState();
    //  _restoreCooldown();
    _controller.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));

    Future.delayed(const Duration(milliseconds: 200), () {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (_controller.text.isEmpty && userProvider.eid.isNotEmpty) {
        _controller.text = userProvider.eid;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _codecontrollers.forEach((c) => c.dispose());
    _focusNodes.forEach((f) => f.dispose());
    _timer?.cancel();
    super.dispose();
  }

  List<TextEditingController> _codecontrollers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  List<String> code = List.generate(6, (_) => "");
  int _secondsLeft = 0;
  int _getCodeAttempts = 0;

  final _storage = const FlutterSecureStorage();
  Timer? _timer;
  int _attempts = 0;

  Future<void> fetchCodeFromGo() async {
    final identifier = _controller.text.trim();
    final password = _passwordController.text.trim();
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (identifier.isEmpty || password.isEmpty) {
      errorStackKey.currentState?.showError(
        'Please enter your eid/email and password first',
        duration: const Duration(seconds: 5),
      );
      return;
    }

    final credentialsValid = await AuthService.validateCredentials(
      identifier: identifier,
      password: password,
    );

    if (!credentialsValid) {
      errorStackKey.currentState?.showError(
        "Incorrect password. Please try again.",
        duration: const Duration(seconds: 5),
      );
      return;
    }

    try {
      _timer?.cancel();
      final data = await AuthService.sendCode(identifier: identifier);

        setState(() {
      code = List.generate(6, (_) => "");
      _codecontrollers.forEach((c) => c.clear());
      _isCodeValid = null;
      isCodeCorrect = false;
      _codeDisabled = true;
    });

    Future.delayed(Duration(milliseconds: 150), () {
      if (mounted) _focusNodes[0].requestFocus();
    });

      serverCode = data['code'];
      _attempts = data['attempts'] ?? 0;
      int cooldown = data['cooldown'] ?? 0;

      setState(() {
        _showCodeSent = true;
        _codeDisabled = true; // grey input fields
        _secondsLeft = cooldown;
      });

      // hide "Code Sent" after 2s
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showCodeSent = false);
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsLeft > 0) {
          setState(() => _secondsLeft--);
        } else {
          timer.cancel();
          if (mounted) setState(() => _codeDisabled = false); // enable fields
             Future.delayed(const Duration(milliseconds: 20), () {
        if (mounted) _focusNodes[0].requestFocus();
      });
        }
      });
    } catch (e) {
      errorStackKey.currentState?.showError(
        'Failed to send code. Please try again.',
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
          _secondsLeft = 0;
        } else {
          errorStackKey.currentState?.showError(
            'Incorrect or expired code. Please request a new one',
            duration: const Duration(seconds: 5),
          );

          // Clear input fields and hide red container after 2 seconds
          Timer(const Duration(seconds: 2), () {
            setState(() {
              code = List.generate(6, (_) => "");
              _codecontrollers.forEach((c) => c.clear());
              _isCodeValid = null; // hide red container
                isCodeCorrect = false;     // reset “correct” status
                _focusNodes.forEach((f) => f.unfocus());
            });
          });
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

        // Clear input fields and hide red container after 2 seconds
        Timer(const Duration(seconds: 2), () {
          setState(() {
            code = List.generate(6, (_) => "");
            _codecontrollers.forEach((c) => c.clear());
            _isCodeValid = null; // hide red container
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return TabletSignInPage(
              controller: _controller,
              passwordController: _passwordController,
              showPassword: _showPassword,
              rememberMe: _rememberMe,
              isEmailNotEmpty: _isEmailNotEmpty,
              isPasswordNotEmpty: _isPasswordNotEmpty,
              hideInputFields: _hideInputFields,
              isCodeCorrect: isCodeCorrect,
              isCodeValid: _isCodeValid,
              codecontrollers: _codecontrollers,
              focusNodes: _focusNodes,
              code: code,
              secondsLeft: _secondsLeft,
              errorStackKey: errorStackKey,
              onShowPasswordChanged: (value) =>
                  setState(() => _showPassword = value),
              onRememberMeChanged: (value) =>
                  setState(() => _rememberMe = value),
              onFetchCode: fetchCodeFromGo,
              onCodeChanged: _onChanged,
            );
          } else {
            return MobileSignInPage(
              controller: _controller,
              passwordController: _passwordController,
              showPassword: _showPassword,
              rememberMe: _rememberMe,
              isEmailNotEmpty: _isEmailNotEmpty,
              isPasswordNotEmpty: _isPasswordNotEmpty,
              hideInputFields: _hideInputFields,
              isCodeCorrect: isCodeCorrect,
              isCodeValid: _isCodeValid,
              codecontrollers: _codecontrollers,
              focusNodes: _focusNodes,
              code: code,
              secondsLeft: _secondsLeft,
              errorStackKey: errorStackKey,
              onShowPasswordChanged: (value) =>
                  setState(() => _showPassword = value),
              onRememberMeChanged: (value) =>
                  setState(() => _rememberMe = value),
              onFetchCode: fetchCodeFromGo,
              onCodeChanged: _onChanged,
              emailFocus: _emailFocus,
              passwordFocus: _passwordFocus,
              tooManyAttempts: _tooManyAttempts,
              codeDisabled: _codeDisabled,
              showCodeSent: _showCodeSent,
              isClicked: _isClicked,
              onButtonClick: () {
                // Show visual feedback
                setState(() {
                  _isClicked = true;
                });

                // Call your function
                fetchCodeFromGo();

                // Reset after short delay (200ms is good for visual feedback)
                Future.delayed(Duration(milliseconds: 200), () {
                  if (mounted) {
                    setState(() {
                      _isClicked = false;
                    });
                  }
                });
              },
            );
          }
        },
      ),
    );
  }
}

class MobileSignInPage extends StatelessWidget {
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

  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool showPassword;
  final bool rememberMe;
  final bool isEmailNotEmpty;
  final bool isPasswordNotEmpty;
  final bool hideInputFields;
  final bool isCodeCorrect;
  final bool? isCodeValid;
  final List<TextEditingController> codecontrollers;
  final List<FocusNode> focusNodes;
  final List<String> code;
  final int secondsLeft;
  final GlobalKey<ErrorStackState> errorStackKey;
  final ValueChanged<bool> onShowPasswordChanged;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onFetchCode;
  final void Function(String, int) onCodeChanged;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool tooManyAttempts;
  final bool codeDisabled;
  final bool showCodeSent;
  final bool isClicked;
  final VoidCallback onButtonClick;

  const MobileSignInPage({
    super.key,
    required this.controller,
    required this.passwordController,
    required this.showPassword,
    required this.rememberMe,
    required this.isEmailNotEmpty,
    required this.isPasswordNotEmpty,
    required this.hideInputFields,
    required this.isCodeCorrect,
    required this.isCodeValid,
    required this.codecontrollers,
    required this.focusNodes,
    required this.code,
    required this.secondsLeft,
    required this.errorStackKey,
    required this.onShowPasswordChanged,
    required this.onRememberMeChanged,
    required this.onFetchCode,
    required this.onCodeChanged,
    required this.emailFocus,
    required this.passwordFocus,
    required this.tooManyAttempts,
    required this.codeDisabled,
    required this.showCodeSent,
    required this.isClicked,
    required this.onButtonClick,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/egetyPerfectStar.png',
                width: 111,
                height: 126,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 0),
              const Text(
                'Egety Trust',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildSignInAndSignUpButtons(context),
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
              _buildEmailInput(),
              const SizedBox(height: 15),
              _buildPasswordInput(),
              _buildForgotRow(context),
              _buildRememberMe(),
              const SizedBox(height: 10),
              _buildEmailVerification(),
              _buildSignInButton(context),
              const SizedBox(height: 20),
              const Text(
                'You built your vault \nNow unlock it',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              FooterWidget(),
            ],
          ),
        ),
        ErrorStack(key: errorStackKey),
      ],
    );
  }

  Widget _buildEmailInput() {
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
                  'assets/images/SVGRepo_iconCarrier.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: emailFocus,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 15,
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
                  ),
                ),
                const SizedBox(width: 10),
                CustomButton(
                  text: isEmailNotEmpty ? 'Clear' : 'Paste',
                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (isEmailNotEmpty) {
                      controller.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        controller.text = clipboardData!.text!;
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          if (controller.text.isNotEmpty)
            Positioned(
              left: 15,
              top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                color: const Color(0xFF0B1320),
                child: const Text(
                  'Identifier',
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

  Widget _buildPasswordInput() {
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
                  'assets/images/Icon.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    focusNode: passwordFocus,
                    obscureText: !showPassword,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 15,
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
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => onShowPasswordChanged(!showPassword),
                  child: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF00F0FF),
                  ),
                ),
                const SizedBox(width: 10),
                CustomButton(
                  text: isPasswordNotEmpty ? 'Clear' : 'Paste',
                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (isPasswordNotEmpty) {
                      passwordController.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        passwordController.text = clipboardData!.text!;
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          if (passwordController.text.isNotEmpty)
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

  Widget _buildForgotRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/forgot-eid');
            },
            child: const Text(
              'Forgot EID?',
              style: TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 15,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
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

  Widget _buildRememberMe() {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: rememberMe,
              onChanged: (value) => onRememberMeChanged(value ?? false),
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

  Widget _buildEmailVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: SizedBox(
        height: 120,
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
            if (showCodeSent)
              Positioned(
                top: 21,
                left: 50,
                child: Container(
                  width: 95,
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
            if (!showCodeSent)
              Positioned(
                top: 22,
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
                              controller: codecontrollers[index],
                              focusNode: focusNodes[index],
                              enabled: !codeDisabled,
                              readOnly: codeDisabled,
                              showCursor: !codeDisabled,
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
                                fontSize: 20,
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
                              ),
                              onChanged: (value) => onCodeChanged(value, index),
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 2,
                            color: codeDisabled
                                ? Colors.grey
                                : code[index].isEmpty
                                ? Colors.white
                                : Colors.transparent,
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),

            if (isCodeCorrect || isCodeValid == false)
              Positioned(
                top: 25,
                left: 240,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isCodeCorrect ? const Color(0xFF00F0FF) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCodeCorrect ? Icons.check : Icons.close,
                    color: isCodeCorrect ? Colors.black : Colors.white,
                    size: 16,
                  ),
                ),
              ),

            Positioned(
              top: 21,
              left: 270,
              child: GestureDetector(
                onTap: (secondsLeft == 0 && !tooManyAttempts)
                    ? onButtonClick
                    : null,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 100),
                  width: 100,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: isClicked
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
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: secondsLeft > 0
                        ? Text(
                            formatCooldown(secondsLeft),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            tooManyAttempts ? "Locked" : "Get Code",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              color: tooManyAttempts
                                  ? Colors.black
                                  : Colors.white,
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

  Widget _buildSignInButton(BuildContext context) {
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
            final identifier = controller.text.trim();
            final password = passwordController.text.trim();
            final enteredCode = codecontrollers
                .map((c) => c.text.trim())
                .join();

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
            if (enteredCode.length != 6) {
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
                code: enteredCode,
                rememberMe: rememberMe,
              );

              if (success) {
                // 🟢 Give storage time to write values
                await Future.delayed(const Duration(milliseconds: 100));

                final pinRegistered =
                    (await AuthService.storage.read(key: 'pinRegistered')) ==
                    'true';

                final patternRegistered =
                    (await AuthService.storage.read(
                      key: 'patternRegistered',
                    )) ==
                    'true';

                print("PIN: $pinRegistered, PATTERN: $patternRegistered");

                if (!pinRegistered && !patternRegistered) {
                  Navigator.pushReplacementNamed(context, '/register-pin');
                } else if (pinRegistered && !patternRegistered) {
                  Navigator.pushReplacementNamed(context, '/register-pattern');
                } else {
                  Navigator.pushReplacementNamed(context, '/sign-in-pin');
                }
              }
            } catch (e) {
              print('Sign in error: $e');
              String message = 'Invalid login credentials';
              final s = e.toString();

              try {
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

  Row _buildSignInAndSignUpButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          text: 'Sign In',
          width: 120,
          height: 45,
          fontSize: 20,
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
          fontSize: 20,
          textColor: Colors.white,
          backgroundColor: const Color(0xFF0B1320),
          borderColor: const Color(0xFF00F0FF),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          onTap: () {
            Navigator.pushNamed(context, '/register');
          },
        ),
      ],
    );
  }
}

class TabletSignInPage extends StatelessWidget {
  final TextEditingController controller;
  final TextEditingController passwordController;
  final bool showPassword;
  final bool rememberMe;
  final bool isEmailNotEmpty;
  final bool isPasswordNotEmpty;
  final bool hideInputFields;
  final bool isCodeCorrect;
  final bool? isCodeValid;
  final List<TextEditingController> codecontrollers;
  final List<FocusNode> focusNodes;
  final List<String> code;
  final int secondsLeft;
  final GlobalKey<ErrorStackState> errorStackKey;
  final ValueChanged<bool> onShowPasswordChanged;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onFetchCode;
  final void Function(String, int) onCodeChanged; // Fixed type

  const TabletSignInPage({
    super.key,
    required this.controller,
    required this.passwordController,
    required this.showPassword,
    required this.rememberMe,
    required this.isEmailNotEmpty,
    required this.isPasswordNotEmpty,
    required this.hideInputFields,
    required this.isCodeCorrect,
    required this.isCodeValid,
    required this.codecontrollers,
    required this.focusNodes,
    required this.code,
    required this.secondsLeft,
    required this.errorStackKey,
    required this.onShowPasswordChanged,
    required this.onRememberMeChanged,
    required this.onFetchCode,
    required this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(height: screenHeight * 0.02),
                                  Image.asset(
                                    'assets/images/egetyPerfectStar.png',
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
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildSignInAndSignUpButtons(context),
                                  const SizedBox(height: 0),
                                  const Text(
                                    'Welcome back!',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 0),
                                  const Text(
                                    'Please enter your credentials to continue',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildEmailInput(),
                                  const SizedBox(height: 10),
                                  _buildPasswordInput(),
                                  _buildForgotRow(context),
                                  _buildRememberMe(),
                                  const SizedBox(height: 20),
                                  _buildEmailVerification(),
                                  const SizedBox(height: 20),
                                  _buildSignInButton(context),
                                  const SizedBox(height: 40),
                                  const Text(
                                    'You built your vault\nNow unlock it',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FooterWidget(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: -10,
                      child: Image.asset(
                        'assets/images/Rectangle2.png',
                        width: screenWidth > 600
                            ? 120
                            : 450, // Larger on tablets
                        height: screenWidth > 600
                            ? 120
                            : 450, // Larger on tablets
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ErrorStack(key: errorStackKey),
        ],
      ),
    );
  }

  Widget _buildEmailInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 394,
            height: 50,
            padding: const EdgeInsets.only(left: 5, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1320),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00F0FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/SVGRepo_iconCarrier.png',
                  width: 16,
                  height: 14,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 15),
                // ✅ Align TextField vertically with icon
                Expanded(
                  child: TextField(
                    controller: controller,
                    textAlignVertical:
                        TextAlignVertical.center, // ✅ centers text vertically
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true, // ✅ removes extra vertical padding
                      contentPadding: EdgeInsets.only(
                        bottom: 2,
                      ), // fine tune alignment
                      hintText: 'EID / Email',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                CustomButton(
                  text: isEmailNotEmpty ? 'Clear' : 'Paste',
                  width: 60,
                  height: 30,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (isEmailNotEmpty) {
                      controller.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        controller.text = clipboardData!.text!;
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          if (controller.text.isNotEmpty)
            Positioned(
              left: 20,
              top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFF0B1320),
                child: const Text(
                  'E-mail',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
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

  Widget _buildPasswordInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 394, // ✅ fixed width
            height: 50, // ✅ fixed height
            padding: const EdgeInsets.only(left: 5, right: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1320),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF00F0FF)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/Icon.png',
                  width: 14,
                  height: 18,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: passwordController,
                    obscureText: !showPassword,
                    textAlignVertical:
                        TextAlignVertical.center, // ✅ aligns text with icon
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 18,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      isCollapsed: true, // ✅ removes internal padding
                      contentPadding: EdgeInsets.only(bottom: 2),
                      hintText: 'Password',
                      hintStyle: TextStyle(
                        color: Colors.white54,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                GestureDetector(
                  onTap: () => onShowPasswordChanged(!showPassword),
                  child: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: const Color(0xFF00F0FF),
                    size: 21,
                  ),
                ),
                const SizedBox(width: 15),
                CustomButton(
                  text: isPasswordNotEmpty ? 'Clear' : 'Paste',
                  width: 60,
                  height: 30,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (isPasswordNotEmpty) {
                      passwordController.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        passwordController.text = clipboardData!.text!;
                      }
                    }
                  },
                ),
              ],
            ),
          ),

          if (passwordController.text.isNotEmpty)
            Positioned(
              left: 20,
              top: -12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xFF0B1320),
                child: const Text(
                  'Password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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

  Widget _buildForgotRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
      child: Container(
        width: 394, // ✅ set fixed width
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/forgot-eid');
              },
              child: const Text(
                'Forgot EID?',
                style: TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
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
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRememberMe() {
    return Center(
      child: Container(
        width: 394,
        child: Row(
          children: [
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: rememberMe,
                onChanged: (value) => onRememberMeChanged(value ?? false),
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
      ),
    );
  }

  Widget _buildEmailVerification() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width: 394,
        height: 140,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: -4,
              left: -2,
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
            if (hideInputFields)
              Positioned(
                top: 20,
                left: 80,
                child: Container(
                  width: 94,
                  height: 23,
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
            if (!hideInputFields)
              Positioned(
                top: 10,
                left: -5,
                child: Row(
                  children: List.generate(6, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        children: [
                          SizedBox(
                            width: 40,
                            height: 30,
                            child: TextField(
                              controller: codecontrollers[index],
                              focusNode: focusNodes[index],
                              showCursor: !(code.every((c) => c.isNotEmpty)),
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              keyboardType: TextInputType.number,
                              style: TextStyle(
                                color: isCodeCorrect
                                    ? const Color(0xFF00F0FF)
                                    : (isCodeValid == false
                                          ? Colors.red
                                          : Colors.white),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                              cursorColor: isCodeCorrect
                                  ? const Color(0xFF00F0FF)
                                  : (isCodeValid == false
                                        ? Colors.red
                                        : Colors.white),
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (value) =>
                                  onCodeChanged(value, index), // Fixed
                            ),
                          ),
                          Container(
                            width: 35,
                            height: 3,
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
                top: 20,
                left: 257,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: Color(0xFF00F0FF),
                  child: Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
            Positioned(
              top: 20,
              left: 285,
              child: GestureDetector(
                onTap: (secondsLeft == 0) ? onFetchCode : null,
                child: Container(
                  width: 94,
                  height: 23,
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
                    child: secondsLeft > 0
                        ? Text(
                            "${secondsLeft ~/ 60}m ${secondsLeft % 60}s",
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignInButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: Center(
        child: Container(
          width: 394, // ✅ fixed width
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
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
              const SizedBox(width: 20),
              CustomButton(
                text: 'Sign In',
                width: 106,
                height: 40,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                borderColor: const Color(0xFF00F0FF),
                backgroundColor: const Color(0xFF0B1320),
                onTap: () async {
                  final identifier = controller.text.trim();
                  final password = passwordController.text.trim();
                  final enteredCode = codecontrollers
                      .map((c) => c.text.trim())
                      .join();

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
                  if (enteredCode.length != 6) {
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
                      code: enteredCode,
                      rememberMe: rememberMe,
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
                          map['error'].toString().toLowerCase().contains(
                            'expired',
                          )) {
                        message = 'Code expired. Please request a new one';
                      } else if (map.containsKey('error')) {
                        message = map['error'];
                      }
                    } catch (_) {
                      // Fallback generic message
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
            ],
          ),
        ),
      ),
    );
  }

  Row _buildSignInAndSignUpButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CustomButton(
          text: 'Sign In',
          width: 106,
          height: 40,
          fontSize: 20,
          textColor: Colors.black,
          backgroundColor: const Color(0xFF00F0FF),
          borderColor: const Color(0xFF00F0FF),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          onTap: () {},
        ),
        const SizedBox(width: 15),
        CustomButton(
          text: 'Sign Up',
          width: 106,
          height: 40,
          fontSize: 20,
          textColor: Colors.white,
          backgroundColor: const Color(0xFF0B1320),
          borderColor: const Color(0xFF00F0FF),
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          onTap: () {
            Navigator.pushNamed(context, '/register');
          },
        ),
      ],
    );
  }
}
