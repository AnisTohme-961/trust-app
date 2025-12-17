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
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  bool _isClicked = false; // Added for button animation
  bool _hasCodeBeenSentBefore = false;

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
    _slideController.dispose();
    super.dispose();
  }

  void _handleGetEid() async {
    // Show visual feedback
    setState(() {
      _isClicked = true;
    });

    final email = _controller.text.trim();

    if (email.isEmpty) {
      _errorStackKey.currentState?.showError('Please enter your Email');
      // Reset animation
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isClicked = false;
          });
        }
      });
      return;
    }

    // Basic email validation
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _errorStackKey.currentState?.showError(
        'Please enter a valid email address',
      );
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isClicked = false;
          });
        }
      });
      return;
    }

    try {
      // Call the service to send EID directly to email
      await AuthService.sendEidEmail(email);

      setState(() {
        _hasCodeBeenSentBefore = true;
      });

      _openOverlay();
    } catch (e) {
      _errorStackKey.currentState?.showError('Failed to send EID: $e');
    } finally {
      // Reset animation after short delay
      Future.delayed(Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {
            _isClicked = false;
          });
        }
      });
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return MobileForgotEidPage(
            controller: _controller,
            errorStackKey: _errorStackKey,
            hasCodeBeenSentBefore: _hasCodeBeenSentBefore,
            showOverlay: _showOverlay,
            slideController: _slideController,
            slideAnimation: _slideAnimation,
            isClicked: _isClicked,
            onHandleGetEid: _handleGetEid,
            onOpenOverlay: _openOverlay,
            onCloseOverlay: _closeOverlay,
          );
        },
      ),
    );
  }
}

class MobileForgotEidPage extends StatefulWidget {
  final TextEditingController controller;
  final GlobalKey<ErrorStackState> errorStackKey;
  final bool hasCodeBeenSentBefore;
  final bool showOverlay;
  final AnimationController slideController;
  final Animation<Offset> slideAnimation;
  final bool isClicked;
  final VoidCallback onHandleGetEid;
  final VoidCallback onOpenOverlay;
  final VoidCallback onCloseOverlay;

  const MobileForgotEidPage({
    super.key,
    required this.controller,
    required this.errorStackKey,
    required this.hasCodeBeenSentBefore,
    required this.showOverlay,
    required this.slideController,
    required this.slideAnimation,
    required this.isClicked,
    required this.onHandleGetEid,
    required this.onOpenOverlay,
    required this.onCloseOverlay,
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
                const SizedBox(height: 30),
                _buildGetEidButton(),
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
                          'If an email is linked to your credentials and \nregistered in EGETY, your EID has been sent to it.',
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
          onTap: () {
            Navigator.of(context).pushNamed('/sign-in');
          },
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
            Navigator.of(context).pushNamed('/sign-up');
          },
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

  Widget _buildGetEidButton() {
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
          onTap: widget.onHandleGetEid,
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
  final bool isClicked;
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
    required this.isClicked,
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
                    // maxLength: 1,
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
          onTap: () {
            Navigator.of(context).pushNamed('/sign-in');
          },
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
            Navigator.of(context).pushNamed('/sign-up');
          },
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
                boxShadow: widget.isClicked
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
                          spreadRadius: 0,
                          offset: const Offset(0, 0),
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: Text(
                widget.isTimerRunning
                    ? widget.onFormatTime(widget.remainingSeconds)
                    : 'Send Code',
                style: TextStyle(
                  color: widget.isTimerRunning
                      ? const Color(0xFF0B1320)
                      : (widget.isClicked ? Colors.white : Colors.black),
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
