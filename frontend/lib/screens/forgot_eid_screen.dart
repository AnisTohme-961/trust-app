import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../widgets/custom_button.dart';
import '../widgets/error_widgets.dart';
import '../widgets/footer_widgets.dart';
import "../services/auth_service.dart";
import "package:flutter_project/screens/protect_access.dart";

class ForgotEidPage extends StatefulWidget {
  const ForgotEidPage({super.key});

  @override
  State<ForgotEidPage> createState() => _ForgotEidPageState();
}

class _ForgotEidPageState extends State<ForgotEidPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  Timer? _timer;
  int _remainingSeconds = 0;

  List<String> code = List.generate(6, (_) => "");
  bool isCodeCorrect = false;
  bool _isCodeValid = true;
  bool _codeSent = false;

  bool get _isEmailNotEmpty => _controller.text.isNotEmpty;
  bool get _isTimerRunning => _remainingSeconds > 0;

  // Overlay and animation
  bool _showOverlay = false;
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // Start below screen
      end: const Offset(0, 0), // End at bottom
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  Future<bool> verifyCode(String email, String code) async {
    if (email.isEmpty) return false;
    if (code.length != 6) return false;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) return false;

    // TODO: Replace with real server verification
    return true;
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 120; // 2 minutes
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() => _remainingSeconds = 0);
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}m ${secs.toString().padLeft(2, '0')}s';
  }

  void _handleSendCode() async {
    if (_isTimerRunning) return;

    final email = _controller.text.trim();

    if (email.isEmpty) {
      _errorStackKey.currentState?.showError('Please enter your Email');
      return;
    }

    try {
      await AuthService.sendEidCode(email);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _startTimer();
      });

      _errorStackKey.currentState
          ?.showError('Verification code sent to your email.');
    } catch (e) {
      _errorStackKey.currentState?.showError('Error sending code: $e');
    }
  }

  void _openOverlay() {
    setState(() => _showOverlay = true);
    _slideController.forward();
  }

  void _closeOverlay() async {
    await _slideController.reverse();
    setState(() => _showOverlay = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 75),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Image.asset(
                      'assets/images/egetyPerfectStar.png',
                      width: 111,
                      height: 126,
                      fit: BoxFit.contain,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                  const Text(
                    'Egety Trust',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  signInAndSignUpButtons(),
                  const SizedBox(height: 10),
                  const Text(
                    'Enter Your Credentials',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'If any EID is connected to this email, username or \nmobile number, it will be emailed to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  buildEmailInput(),
                  const SizedBox(height: 22),
                  buildSendCodeSection(),
                  const SizedBox(height: 20),
                  buildSendEidButton(),
                  const SizedBox(height: 120),
                  const Text(
                    'You built your vault \n Now unlock it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const FooterWidget(),
                ],
              ),
            ),
          ),

          if (_showOverlay) ...[
            GestureDetector(
              onTap: _closeOverlay,
              child: Container(color: Colors.black.withOpacity(0.7)),
            ),
            SlideTransition(
              position: _slideAnimation,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1320),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 0),
                          child: GestureDetector(
                            onTap: _closeOverlay,
                            child: Image.asset(
                              'assets/images/closeWindow.png',
                              width: 110,
                              height: 50,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'If an email is linked to your credentials and \nregistered in EGETY, your EID is sent to it.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildOkButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],

          ErrorStack(key: _errorStackKey),
        ],
      ),
    );
  }
Widget buildOtpInput() {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const NeverScrollableScrollPhysics(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              children: [
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: _otpControllers[index],
                    focusNode: _otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    showCursor: !isCodeCorrect, // Hide caret when correct
                    enabled: !isCodeCorrect,    // Disable editing
                    readOnly: isCodeCorrect,    // Safety
                    style: TextStyle(
                      color: isCodeCorrect
                          ? const Color(0xFF00F0FF)
                          : (_isCodeValid == false ? Colors.red : Colors.white),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: isCodeCorrect
                        ? Colors.transparent
                        : (_isCodeValid == false ? Colors.red : Colors.white),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) async {
                      if (isCodeCorrect) return; // Stop editing once correct

                      if (value.length > 1) {
                        _otpControllers[index].text = value[0];
                      }

                      if (value.isNotEmpty && index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                      }

                      setState(() {
                        code[index] = _otpControllers[index].text;
                        _isCodeValid = true;
                      });

                      if (code.every((c) => c.isNotEmpty)) {
                        final email = _controller.text.trim();
                        bool valid = await verifyCode(email, code.join());

                        setState(() {
                          isCodeCorrect = valid;
                          _isCodeValid = valid;
                        });

                        if (!valid) {
                          Timer(const Duration(seconds: 3), () {
                            if (!mounted) return;
                            setState(() {
                              for (var c in _otpControllers) c.clear();
                              code = List.generate(6, (_) => "");
                              _isCodeValid = true;
                            });
                            _otpFocusNodes[0].requestFocus();
                          });
                        } else {
                          _timer?.cancel();
                        }
                      }
                    },
                  ),
                ),

                // ↓ Underline (hidden if code is correct)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 35,
                  height: isCodeCorrect ? 0 : 2, // Hide line when correct
                  color: isCodeCorrect
                      ? Colors.transparent
                      : (_isCodeValid == false ? Colors.red : Colors.white),
                ),
              ],
            ),
          );
        }),
        if (isCodeCorrect || _isCodeValid == false) ...[
          const SizedBox(width: 6),
          AnimatedContainer(
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
        ],
      ],
    ),
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
          onTap: () {},
        ),
      ],
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
                Image.asset(
                  'assets/images/SVGRepo_iconCarrier.png',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 15,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Email',
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
                      final clipboardData =
                          await Clipboard.getData('text/plain');
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

  Widget buildSendCodeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _codeSent ? buildOtpInput() : Container(height: 40),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isTimerRunning ? null : _handleSendCode,
            child: Container(
              width: 92,
              height: 25,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF00F0FF),
                    blurRadius: 11.5,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                _isTimerRunning ? _formatTime(_remainingSeconds) : 'Send Code',
                style: const TextStyle(
                  color: Color(0xFF0B1320),
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

  Widget buildSendEidButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 21),
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
          width: 120,
          height: 45,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          textColor: Colors.white,
          borderColor: const Color(0xFF00F0FF),
          backgroundColor: const Color(0xFF0B1320),
          text: 'Send EID',
          onTap: () async {
            if (!_codeSent) {
              _errorStackKey.currentState
                  ?.showError('Please click "Send Code" first.');
              return;
            }
            final email = _controller.text.trim();
            final code = _otpControllers.map((c) => c.text).join();

            if (!await AuthService.verifyEidCode(email: email, code: code)) {
              _errorStackKey.currentState
                  ?.showError("Invalid or expired code.");
              return;
            }

            _openOverlay();
          },
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 21),
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

  Widget buildOkButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: CustomButton(
        text: 'Ok',
        width: 120,
        height: 35,
        fontSize: 17,
        textColor: Colors.white,
        backgroundColor: const Color(0xFF0B1320),
        borderColor: const Color(0xFF00F0FF),
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        onTap: _closeOverlay,
      ),
    );
  }
}
