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
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  Timer? _timer;
  int _remainingSeconds = 0;
  List<String> code = List.generate(6, (_) => "");
  bool isCodeCorrect = false;
  bool _isCodeValid = true;
  bool _codeSent = false;
  int cooldown = 0;
  int attempts = 0;
  Timer? _cooldownTimer;
  // New state variables for color management
  Color _otpTextColor = Colors.white;
  Timer? _colorResetTimer;

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
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    _colorResetTimer?.cancel();
    _slideController.dispose();
    super.dispose();
  }

  Future<bool> verifyCode(String email, String code) async {
    if (email.isEmpty || code.length != 6) return false;
    try {
      return await AuthService.verifyEidCode(email: email, code: code);
    } catch (e) {
      _errorStackKey.currentState?.showError('Failed to verify code: $e');
      return false;
    }
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
    final email = _controller.text.trim();

    if (email.isEmpty) {
      _errorStackKey.currentState?.showError('Please enter your Email');
      return;
    }

    try {
      final data = await AuthService.sendEidCode(email);

      final int backendCooldown =
          data["cooldown"] ?? 0; // cooldown from backend
      attempts = data["attempts"] ?? 0;

      setState(() {
        _codeSent = true;
        _remainingSeconds = backendCooldown; // start UI timer
      });

      // Start countdown timer
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          t.cancel();
        }
      });
    } catch (e) {
      _errorStackKey.currentState?.showError('Email not registered');
    }
  }

  // void _handleSendCode() async {

  //   final email = _controller.text.trim();

  //   if (email.isEmpty) {
  //     _errorStackKey.currentState?.showError('Please enter your Email');
  //     return;
  //   }

  //   try {
  //     final data = await AuthService.sendEidCode(email);

  //     setState(() {
  //       _codeSent = true;

  //       attempts = data["attempts"] ?? 0;
  //       cooldown = data["cooldown"] ?? 0;

  //       // UI timer cooldown
  //       _remainingSeconds = cooldown;
  //     });

  //     // Start cooldown timer
  //     _timer?.cancel();
  //     _timer = Timer.periodic(const Duration(seconds: 1), (t) {
  //       if (_remainingSeconds > 0) {
  //         setState(() => _remainingSeconds--);
  //       } else {
  //         t.cancel();
  //       }
  //     });
  //   } catch (e) {
  //     _errorStackKey.currentState?.showError('Email not registered');
  //   }
  // }

  // void _handleSendCode() async {
  //   if (cooldown > 0) return;
  //   final email = _controller.text.trim();
  //   if (email.isEmpty) {
  //     _errorStackKey.currentState?.showError('Please enter your Email');
  //     return;
  //   }
  //   try {
  //     final data = await AuthService.sendEidCode(email);
  //     final int cooldown = data['cooldown'] ?? 0;
  //     attempts = data['attempts'] ?? 0;
  //     if (!mounted) return;
  //     setState(() {
  //       _codeSent = true;
  //       _startTimer();
  //     });
  //   } catch (e) {
  //     _errorStackKey.currentState?.showError('Email not registered');
  //   }
  // }

  void _openOverlay() {
    setState(() => _showOverlay = true);
    _slideController.forward();
  }

  void _closeOverlay() async {
    await _slideController.reverse();
    setState(() => _showOverlay = false);
  }

  // New method to handle code verification with color changes
  Future<void> _handleCodeVerification() async {
    if (!_codeSent) {
      _errorStackKey.currentState?.showError('Please click "Send Code" first.');
      return;
    }

    final email = _controller.text.trim();
    final code = _otpControllers.map((c) => c.text).join();

    if (code.length != 6) {
      _errorStackKey.currentState?.showError(
        'Please enter the complete 6-digit code.',
      );
      return;
    }

    bool valid = await AuthService.verifyEidCode(email: email, code: code);

    if (valid) {
      // Code is correct - set color to #00F0FF
      setState(() {
        _otpTextColor = const Color(0xFF00F0FF);
        isCodeCorrect = true;
        _isCodeValid = true;
      });

      try {
        await AuthService.sendEidEmail(email);
        _openOverlay();
      } catch (e) {
        _errorStackKey.currentState?.showError('Failed to send EID: $e');
      }
    } else {
      // Code is incorrect or expired - set color to #F42222
      setState(() {
        _otpTextColor = const Color(0xFFF42222);
        isCodeCorrect = false;
        _isCodeValid = false;
      });

      _errorStackKey.currentState?.showError("Invalid or expired code.");

      // Clear input fields after 2 seconds
      _colorResetTimer?.cancel();
      _colorResetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            for (var controller in _otpControllers) {
              controller.clear();
            }
            // Clear the code list properly
            for (int i = 0; i < this.code.length; i++) {
              this.code[i] = "";
            }
            _otpTextColor = Colors.white;
            _isCodeValid = true;
          });
          _otpFocusNodes[0].requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return MobileForgotEidPage(
            controller: _controller,
            otpControllers: _otpControllers,
            otpFocusNodes: _otpFocusNodes,
            errorStackKey: _errorStackKey,
            timer: _timer,
            remainingSeconds: _remainingSeconds,
            code: code,
            isCodeCorrect: isCodeCorrect,
            isCodeValid: _isCodeValid,
            codeSent: _codeSent,
            isEmailNotEmpty: _isEmailNotEmpty,
            isTimerRunning: _isTimerRunning,
            showOverlay: _showOverlay,
            slideController: _slideController,
            slideAnimation: _slideAnimation,
            otpTextColor: _otpTextColor,
            onVerifyCode: verifyCode,
            onStartTimer: _startTimer,
            onFormatTime: _formatTime,
            onHandleSendCode: _handleSendCode,
            onOpenOverlay: _openOverlay,
            onCloseOverlay: _closeOverlay,
            onHandleCodeVerification: _handleCodeVerification,
          );
        },
      ),
    );
  }
}

class MobileForgotEidPage extends StatefulWidget {
  final TextEditingController controller;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final GlobalKey<ErrorStackState> errorStackKey;
  final Timer? timer;
  final int remainingSeconds;
  final List<String> code;
  final bool isCodeCorrect;
  final bool isCodeValid;
  final bool codeSent;
  final bool isEmailNotEmpty;
  final bool isTimerRunning;
  final bool showOverlay;
  final AnimationController slideController;
  final Animation<Offset> slideAnimation;
  final Color otpTextColor;
  final Future<bool> Function(String, String) onVerifyCode;
  final VoidCallback onStartTimer;
  final String Function(int) onFormatTime;
  final VoidCallback onHandleSendCode;
  final VoidCallback onOpenOverlay;
  final VoidCallback onCloseOverlay;
  final VoidCallback onHandleCodeVerification;

  const MobileForgotEidPage({
    super.key,
    required this.controller,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.errorStackKey,
    required this.timer,
    required this.remainingSeconds,
    required this.code,
    required this.isCodeCorrect,
    required this.isCodeValid,
    required this.codeSent,
    required this.isEmailNotEmpty,
    required this.isTimerRunning,
    required this.showOverlay,
    required this.slideController,
    required this.slideAnimation,
    required this.otpTextColor,
    required this.onVerifyCode,
    required this.onStartTimer,
    required this.onFormatTime,
    required this.onHandleSendCode,
    required this.onOpenOverlay,
    required this.onCloseOverlay,
    required this.onHandleCodeVerification,
  });

  @override
  State<MobileForgotEidPage> createState() => _MobileForgotEidPageState();
}

class _MobileForgotEidPageState extends State<MobileForgotEidPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
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
                _buildSignInAndSignUpButtons(),
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
                _buildEmailInput(),
                const SizedBox(height: 22),
                _buildSendCodeSection(),
                const SizedBox(height: 30),
                _buildSendEidButton(),
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
        if (widget.showOverlay) ...[
          GestureDetector(
            onTap: widget.onCloseOverlay,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SlideTransition(
            position: widget.slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B1320),
                    border: Border(
                      top: BorderSide(color: Color(0xFF00F0FF), width: 2.0),
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
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
                            onTap: widget.onCloseOverlay,
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
                      _buildOkButton(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        ErrorStack(key: widget.errorStackKey),
      ],
    );
  }

  Widget _buildOtpInput() {
    bool isCooldown = widget.remainingSeconds > 0;
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
                    height: 25,
                    child: TextField(
                      controller: widget.otpControllers[index],
                      focusNode: widget.otpFocusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      showCursor: !widget.isCodeCorrect && !isCooldown,
                      enabled: !widget.isCodeCorrect && !isCooldown,
                      readOnly: widget.isCodeCorrect || isCooldown,
                      style: TextStyle(
                        color: isCooldown ? Colors.grey : widget.otpTextColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      cursorColor: widget.isCodeCorrect || isCooldown
                          ? Colors.transparent
                          : widget.otpTextColor,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) async {
                        if (widget.isCodeCorrect) return;

                        if (value.length > 1) {
                          widget.otpControllers[index].text = value[0];
                        }

                        if (value.isNotEmpty && index < 5) {
                          widget.otpFocusNodes[index + 1].requestFocus();
                        }

                        if (value.isEmpty && index > 0) {
                          widget.otpFocusNodes[index - 1].requestFocus();
                        }

                        setState(() {
                          widget.code[index] =
                              widget.otpControllers[index].text;
                        });

                        // Auto-verify when all fields are filled
                        if (widget.code.every((c) => c.isNotEmpty)) {
                          widget.onHandleCodeVerification();
                        }
                      },
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 35,
                    height: widget.isCodeCorrect ? 0 : 2,
                    color: isCooldown ? Colors.grey : widget.otpTextColor,
                  ),
                ],
              ),
            );
          }),
          if (widget.isCodeCorrect || !widget.isCodeValid) ...[
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.isCodeCorrect
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFFF42222),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isCodeCorrect ? Icons.check : Icons.close,
                color: widget.isCodeCorrect ? Colors.black : Colors.white,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Row _buildSignInAndSignUpButtons() {
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
                    controller: widget.controller,
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
                  text: widget.controller.text.isNotEmpty ? 'Clear' : 'Paste',

                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (widget.controller.text.isNotEmpty) {
                      // CLEAR
                      widget.controller.clear();
                    } else {
                      // PASTE
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );

                      if (clipboardData?.text != null) {
                        widget.controller.text = clipboardData!.text!;
                      }
                    }

                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (widget.controller.text.isNotEmpty)
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

  Widget _buildSendCodeSection() {
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 17),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: _buildOtpInput()),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: widget.isTimerRunning ? null : widget.onHandleSendCode,
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
                widget.isTimerRunning
                    ?  formatCooldown(widget.remainingSeconds) 
                    : 'Send Code',
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

  Widget _buildSendEidButton() {
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
          onTap: widget.onHandleCodeVerification,
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

  Widget _buildOkButton() {
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
        onTap: () {
          Navigator.pushReplacementNamed(context, '/sign-in');
        },
      ),
    );
  }
}

class TabletForgotEidPage extends StatefulWidget {
  final TextEditingController controller;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final GlobalKey<ErrorStackState> errorStackKey;
  final Timer? timer;
  final int remainingSeconds;
  final List<String> code;
  final bool isCodeCorrect;
  final bool isCodeValid;
  final bool codeSent;
  final bool isEmailNotEmpty;
  final bool isTimerRunning;
  final bool showOverlay;
  final AnimationController slideController;
  final Animation<Offset> slideAnimation;
  final Color otpTextColor;
  final Future<bool> Function(String, String) onVerifyCode;
  final VoidCallback onStartTimer;
  final String Function(int) onFormatTime;
  final VoidCallback onHandleSendCode;
  final VoidCallback onOpenOverlay;
  final VoidCallback onCloseOverlay;
  final VoidCallback onHandleCodeVerification;

  const TabletForgotEidPage({
    super.key,
    required this.controller,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.errorStackKey,
    required this.timer,
    required this.remainingSeconds,
    required this.code,
    required this.isCodeCorrect,
    required this.isCodeValid,
    required this.codeSent,
    required this.isEmailNotEmpty,
    required this.isTimerRunning,
    required this.showOverlay,
    required this.slideController,
    required this.slideAnimation,
    required this.otpTextColor,
    required this.onVerifyCode,
    required this.onStartTimer,
    required this.onFormatTime,
    required this.onHandleSendCode,
    required this.onOpenOverlay,
    required this.onCloseOverlay,
    required this.onHandleCodeVerification,
  });

  @override
  State<TabletForgotEidPage> createState() => _TabletForgotEidPageState();
}

class _TabletForgotEidPageState extends State<TabletForgotEidPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      setState(() {}); // rebuild when email changes
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.1,
                vertical: screenHeight * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo and Title Section
                  const SizedBox(height: 40),
                  Center(
                    child: Image.asset(
                      'assets/images/egetyPerfectStar.png',
                      width: 111,
                      height: 126,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Egety Trust',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Sign In/Sign Up Buttons
                  _buildTabletSignInSignUpButtons(),
                  const SizedBox(height: 30),

                  // Main Content
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
                  const SizedBox(height: 20),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 50),
                    child: Text(
                      'If any EID is connected to this email, username or mobile number, it will be emailed to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Email Input
                  _buildTabletEmailInput(),
                  const SizedBox(height: 30),

                  // OTP Section
                  _buildTabletSendCodeSection(),
                  const SizedBox(height: 30),

                  // Send EID Button
                  _buildTabletSendEidButton(),
                  const SizedBox(height: 60),

                  // Bottom Text
                  const Text(
                    'You built your vault\nNow unlock it',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Footer
                  const FooterWidget(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),

        // Overlay (same as mobile)
        if (widget.showOverlay) ...[
          GestureDetector(
            onTap: widget.onCloseOverlay,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          SlideTransition(
            position: widget.slideAnimation,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 250,
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
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: widget.onCloseOverlay,
                          child: Image.asset(
                            'assets/images/closeWindow.png',
                            width: 120,
                            height: 55,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'If an email is linked to your credentials and registered in EGETY, your EID is sent to it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildTabletOkButton(),
                  ],
                ),
              ),
            ),
          ),
        ],

        ErrorStack(key: widget.errorStackKey),
      ],
    );
  }

  Widget _buildTabletOtpInput() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: widget.otpControllers[index],
                    focusNode: widget.otpFocusNodes[index],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    showCursor: !widget.isCodeCorrect,
                    enabled: !widget.isCodeCorrect,
                    readOnly: widget.isCodeCorrect,
                    style: TextStyle(
                      color: widget.otpTextColor,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    cursorColor: widget.isCodeCorrect
                        ? Colors.transparent
                        : widget.otpTextColor,
                    decoration: const InputDecoration(
                      counterText: '',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) async {
                      if (widget.isCodeCorrect) return;

                      if (value.length > 1) {
                        widget.otpControllers[index].text = value[0];
                      }

                      if (value.isNotEmpty && index < 5) {
                        widget.otpFocusNodes[index + 1].requestFocus();
                      }
                      if (value.isEmpty && index > 0) {
                        widget.otpFocusNodes[index - 1].requestFocus();
                      }

                      setState(() {
                        widget.code[index] = widget.otpControllers[index].text;
                      });

                      if (widget.code.every((c) => c.isNotEmpty)) {
                        final email = widget.controller.text.trim();
                        bool valid = await widget.onVerifyCode(
                          email,
                          widget.code.join(),
                        );

                        if (valid) {
                          // Code is correct - trigger the verification flow
                          widget.onHandleCodeVerification();
                        } else {
                          // Code is incorrect - handled in the main method
                        }
                      }
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 50,
                  height: widget.isCodeCorrect ? 0 : 3,
                  color: widget.isCodeCorrect
                      ? Colors.transparent
                      : widget.otpTextColor,
                ),
              ],
            ),
          );
        }),
        if (widget.isCodeCorrect || !widget.isCodeValid) ...[
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: widget.isCodeCorrect
                  ? const Color(0xFF00F0FF)
                  : const Color(0xFFF42222),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isCodeCorrect ? Icons.check : Icons.close,
              color: widget.isCodeCorrect ? Colors.black : Colors.white,
              size: 18,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabletSignInSignUpButtons() {
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
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildTabletEmailInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Set width here
          Container(
            width: 394,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0B1320),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00F0FF), width: 2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 10),
                Image.asset(
                  'assets/images/SVGRepo_iconCarrier.png',
                  width: 14,
                  height: 12,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextField(
                    controller: widget.controller,
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
                      isDense: true, // removes extra vertical padding
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                      ), // centers vertically
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),

                const SizedBox(width: 15),
                CustomButton(
                  text: widget.isEmailNotEmpty ? 'Clear' : 'Paste',
                  width: 60,
                  height: 30,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (widget.controller.text.isNotEmpty) {
                      // CLEAR
                      widget.controller.clear();
                    } else {
                      // PASTE
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      if (clipboardData?.text != null) {
                        widget.controller.text = clipboardData!.text!;
                      }
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (widget.controller.text.isNotEmpty)
            Positioned(
              left: 25,
              top: -14,
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

  Widget _buildTabletSendCodeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 100),
      child: Column(
        children: [
          if (widget.codeSent) _buildTabletOtpInput(),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: widget.isTimerRunning ? null : widget.onHandleSendCode,
            child: Container(
              width: 94,
              height: 23,
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
                    blurRadius: 15,
                    spreadRadius: 0,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.isTimerRunning
                    ? widget.onFormatTime(widget.remainingSeconds)
                    : 'Send Code',
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

  Widget _buildTabletSendEidButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: SizedBox(
        width: 394,
        child: Row(
          children: [
            // Left gradient line
            Container(
              width:
                  (394 - 106 - 20) /
                  2, // total width minus button width minus spacers
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Button
            CustomButton(
              width: 106,
              height: 40,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              textColor: Colors.white,
              borderColor: const Color(0xFF00F0FF),
              backgroundColor: const Color(0xFF0B1320),
              text: 'Send EID',
              onTap: widget.onHandleCodeVerification,
            ),
            const SizedBox(width: 10),
            // Right gradient line
            Container(
              width: (394 - 106 - 20) / 2, // same as left
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF00F0FF), Color(0xFF0B1320)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletOkButton() {
    return CustomButton(
      text: 'Ok',
      width: 140,
      height: 45,
      fontSize: 20,
      textColor: Colors.white,
      backgroundColor: const Color(0xFF0B1320),
      borderColor: const Color(0xFF00F0FF),
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      onTap: () {
        Navigator.pushReplacementNamed(context, '/sign-in');
      },
    );
  }
}
