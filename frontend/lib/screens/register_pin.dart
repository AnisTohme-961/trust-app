import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import "../services/auth_service.dart";
import 'package:flutter_project/widgets/footer_widgets.dart';
import '../widgets/error_widgets.dart';

class ResponsiveRegisterPinScreen extends StatelessWidget {
  final String title;
  final String? originalPin;

  const ResponsiveRegisterPinScreen({
    super.key,
    required this.title,
    this.originalPin,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return TabletRegisterPinScreen(
            title: title,
            originalPin: originalPin,
          );
        } else {
          return MobileRegisterPinScreen(
            title: title,
            originalPin: originalPin,
          );
        }
      },
    );
  }
}

class MobileRegisterPinScreen extends StatefulWidget {
  final String title;
  final String? originalPin;

  const MobileRegisterPinScreen({
    super.key,
    required this.title,
    this.originalPin,
  });

  @override
  State<MobileRegisterPinScreen> createState() =>
      _MobileRegisterPinScreenState();
}

class _MobileRegisterPinScreenState extends State<MobileRegisterPinScreen> {
  final List<String> _pin = [];
  late final List<String> _numbers;

  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  @override
  void initState() {
    super.initState();
    _numbers = List.generate(10, (i) => i.toString())..shuffle();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _pin.clear();
      } else if (value == 'Logout') {
        _logout();
      } else {
        if (_pin.length < 4) _pin.add(value);
      }
    });
  }

  Future<void> _logout() async {
    try {
      await AuthService.deleteToken();
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    } catch (e) {
      print("Logout failed: $e");
    }
  }

  void _onNext() async {
    final enteredPin = _pin.join();

    // Check PIN length first
    if (enteredPin.length < 4) {
      _errorStackKey.currentState?.showError("Please enter 4 digits");
      return;
    }

    // If confirming PIN
    if (widget.originalPin != null) {
      if (enteredPin == widget.originalPin) {
        try {
          await AuthService.registerPin(enteredPin);
          _pin.clear();
          setState(() {});
          Navigator.pushReplacementNamed(context, '/register-pattern');
        } catch (e) {
          _pin.clear();
          setState(() {});
          _errorStackKey.currentState?.showError("Error: $e");
        }
      } else {
        _pin.clear();
        setState(() {});
        _errorStackKey.currentState?.showError(
          "PIN does not match. Try again.",
        );
      }
    } else {
      // Enter original PIN - UPDATED WITH SLIDE ANIMATION
      if (_pin.length == 4) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResponsiveRegisterPinScreen(
                  title: "Confirm PIN",
                  originalPin: enteredPin,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        _pin.clear();
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent going back when in confirm PIN mode
      onWillPop: () async {
        if (widget.originalPin != null) {
          // Show error when trying to go back from confirm PIN screen
          _errorStackKey.currentState?.showError(
            "Please complete PIN confirmation first",
          );
          return false; // Prevent going back
        }
        return true; // Allow going back when not in confirm PIN mode
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // ===== Top Section =====
              Column(
                children: [
                  const SizedBox(height: 20),

                  // ===== Top Buttons =====
                  SizedBox(
                    width: 230,
                    height: 40,
                    child: Row(
                      children: [
                        Expanded(
                          child: _OutlinedButton(
                            text: 'Sign In',
                            onTap: () =>
                                Navigator.pushNamed(context, '/sign-in'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _GradientButton(
                            text: 'Sign Up',
                            onTap: () =>
                                Navigator.pushNamed(context, '/sign-up'),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ===== Subtitle =====
                  const Text(
                    "Protect Your Access",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 5),

                  // ===== Progress Steps =====
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 9.5,
                          left: 32,
                          right: 40,
                          child: _ProgressLine(
                            totalSteps: 5,
                            completedSteps: 4,
                          ),
                        ),
                        const _ProgressSteps(),
                      ],
                    ),
                  ),
                ],
              ),

              // ===== PIN Input Section =====
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Title only - eye icon removed
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // PIN Boxes - always show actual digits
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final filled = index < _pin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 18,
                              ),
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.9),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                filled
                                    ? _pin[index]
                                    : '', // Always show actual digit
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 40),

                        // Keypad
                        _Keypad(onKeyTap: _onKeyTap, numbers: _numbers),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),

              // ===== Bottom Navigation =====
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GradientLine(isLeft: true),
                        _NavButton(
                          text: "Back",
                          onTap: () {
                            if (widget.originalPin != null) {
                              // Prevent manual back button when in confirm PIN mode
                              _errorStackKey.currentState?.showError(
                                "Please complete PIN confirmation first",
                              );
                            } else {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        _NavButton(text: "Next", onTap: _onNext),
                        _GradientLine(isLeft: false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ===== Footer =====
                  FooterWidget(),

                  const SizedBox(height: 10),
                ],
              ),

              // ===== Error Stack =====
              ErrorStack(key: _errorStackKey),
            ],
          ),
        ),
      ),
    );
  }
}

class TabletRegisterPinScreen extends StatefulWidget {
  final String title;
  final String? originalPin;

  const TabletRegisterPinScreen({
    super.key,
    required this.title,
    this.originalPin,
  });

  @override
  State<TabletRegisterPinScreen> createState() =>
      _TabletRegisterPinScreenState();
}

class _TabletRegisterPinScreenState extends State<TabletRegisterPinScreen> {
  final List<String> _pin = [];
  late final List<String> _numbers;

  @override
  void initState() {
    super.initState();
    _numbers = List.generate(10, (i) => i.toString())..shuffle();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _pin.clear();
      } else if (value == 'Logout') {
        _logout();
      } else {
        if (_pin.length < 4) _pin.add(value);
      }
    });
  }

  Future<void> _logout() async {
    try {
      await AuthService.deleteToken();
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    } catch (e) {
      print("Logout failed: $e");
    }
  }

  void _onNext() async {
    final enteredPin = _pin.join();

    if (widget.originalPin != null) {
      if (enteredPin == widget.originalPin) {
        try {
          await AuthService.registerPin(enteredPin);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PIN registered successfully!")),
          );

          Navigator.pushReplacementNamed(context, '/register-pattern');
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
          _pin.clear();
          setState(() {});
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("PIN does not match. Try again.")),
        );
        _pin.clear();
        setState(() {});
      }
    } else {
      if (_pin.length == 4) {
        // UPDATED WITH SLIDE ANIMATION FOR TABLET
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ResponsiveRegisterPinScreen(
                  title: "Confirm PIN",
                  originalPin: enteredPin,
                ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;
                  var tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
        _pin.clear();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Enter 4 digits.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLandscape = screenWidth > screenHeight;

    return WillPopScope(
      // Prevent going back when in confirm PIN mode
      onWillPop: () async {
        if (widget.originalPin != null) {
          // Show error when trying to go back from confirm PIN screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete PIN confirmation first'),
              duration: Duration(seconds: 2),
            ),
          );
          return false; // Prevent going back
        }
        return true; // Allow going back when not in confirm PIN mode
      },
      child: Scaffold(
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
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0xFF00F0FF),
                                      blurRadius: 7,
                                      spreadRadius: 0,
                                    ),
                                  ],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 40),

                                    // ===== Top Buttons =====
                                    Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 106,
                                            height: 40,
                                            child: _OutlinedButton(
                                              text: 'Sign In',
                                              onTap: () => Navigator.pushNamed(
                                                context,
                                                '/sign-in',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
                                          SizedBox(
                                            width: 106,
                                            height: 40,
                                            child: _GradientButton(
                                              text: 'Sign Up',
                                              onTap: () => Navigator.pushNamed(
                                                context,
                                                '/sign-up',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // ===== Subtitle =====
                                    const Text(
                                      "Protect Your Access",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 30,
                                        color: Colors.white,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // ===== Progress Steps =====
                                    SizedBox(
                                      width: double.infinity,
                                      child: Stack(
                                        alignment: Alignment.topCenter,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 10,
                                            ),
                                            child: _ProgressLine(
                                              totalSteps: 5,
                                              completedSteps: 2,
                                            ),
                                          ),
                                          const _ProgressSteps(),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    // ===== PIN Input Section =====
                                    Column(
                                      children: [
                                        // Title only - eye icon removed
                                        Text(
                                          widget.title,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w700,
                                            fontSize: 30,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 25),

                                        // PIN Boxes - Larger for tablet, always show actual digits
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: List.generate(4, (index) {
                                            final filled = index < _pin.length;
                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 15,
                                                  ),
                                              width: 50,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.9),
                                                  width: 2,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                filled
                                                    ? _pin[index]
                                                    : '', // Always show actual digit
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 32,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                        const SizedBox(height: 30),

                                        // Keypad - Larger for tablet
                                        SizedBox(
                                          width: 400,
                                          height: 360,
                                          child: _TabletKeypad(
                                            onKeyTap: _onKeyTap,
                                            numbers: _numbers,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 20),

                                    // ===== Bottom Navigation =====
                                    SizedBox(
                                      width: 380,
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _GradientLine(isLeft: true),
                                          _NavButton(
                                            text: "Back",
                                            onTap: () {
                                              if (widget.originalPin != null) {
                                                // Prevent manual back button when in confirm PIN mode
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Please complete PIN confirmation first',
                                                    ),
                                                    duration: Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                Navigator.pop(context);
                                              }
                                            },
                                          ),
                                          _NavButton(
                                            text: "Next",
                                            onTap: _onNext,
                                          ),
                                          _GradientLine(isLeft: false),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // ===== Footer =====
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
              bottom: 0,
              right: -10,
              child: Image.asset(
                'assets/images/Rectangle2.png',
                width: screenWidth > 600 ? 120 : 450,
                height: screenWidth > 600 ? 120 : 450,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===== Tablet Keypad =====
class _TabletKeypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final List<String> numbers;

  const _TabletKeypad({required this.onKeyTap, required this.numbers});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      [numbers[0], numbers[1], numbers[2]],
      [numbers[3], numbers[4], numbers[5]],
      [numbers[6], numbers[7], numbers[8]],
      ['Logout', numbers[9], 'Clear'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((text) {
              final isLogout = text == 'Logout';
              final isClear = text == 'Clear';

              return GestureDetector(
                onTap: () => onKeyTap(text),
                child: Container(
                  width: 104,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLogout ? Colors.red : const Color(0xFF00F0FF),
                      width: isLogout || isClear ? 4 : 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: isLogout || isClear
                          ? FontWeight.w500
                          : FontWeight.w800,
                      fontSize: isLogout || isClear
                          ? 20
                          : 30, // 👈 only Logout & Clear = 20, others = 30
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ===== Custom Buttons =====
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _GradientButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 106,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F0FF).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _OutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _OutlinedButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 106,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1, color: const Color(0xFF00F0FF)),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    ),
  );
}

// ===== Progress Line =====
class _ProgressLine extends StatelessWidget {
  final int totalSteps;
  final int completedSteps;

  const _ProgressLine({
    required this.totalSteps,
    required this.completedSteps,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;

          final segmentCount = totalSteps - 1;
          final filledSegments = completedSteps - 1;

          final filledWidth = totalWidth * (filledSegments / segmentCount);
          final remainingWidth = totalWidth - filledWidth;

          return Row(
            children: [
              // -------- FILLED PART --------
              Container(
                width: filledWidth,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(100),
                    bottomLeft: Radius.circular(100),
                  ),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00F0FF), Color(0xFF0EA0BB)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),

              // -------- REMAINING PART --------
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
    );
  }
}

class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 66,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStep("", filled: true),
          _buildStep("", filled: true, filledColor: Color(0xFF0EA0BB)),
          _buildStep("", filled: true, filledColor: Color(0xFF0764AD)),
          _buildStep(
            "Register\nLive",
            filled: true,
            filledColor: Color(0xFF01259E),
          ),
          _buildStep(""),
        ],
      ),
    );
  }

  static Widget _buildStep(
    String label, {
    bool filled = false,
    Color? filledColor,
  }) {
    return SizedBox(
      width: 65,
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: filled
                ? (filledColor ?? Color(0xFF00F0FF))
                : Colors.white,
            child: filled
                ? Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              height: 1.0,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ===== Keypad =====
class _Keypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final List<String> numbers;

  const _Keypad({required this.onKeyTap, required this.numbers});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      [numbers[0], numbers[1], numbers[2]],
      [numbers[3], numbers[4], numbers[5]],
      [numbers[6], numbers[7], numbers[8]],
      ['Logout', numbers[9], 'Clear'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((text) {
              final isLogout = text == 'Logout';
              final isClear = text == 'Clear';

              return GestureDetector(
                onTap: () => onKeyTap(text),
                child: Container(
                  width: 103,
                  height: 49,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLogout ? Colors.red : const Color(0xFF00F0FF),
                      width: isLogout || isClear ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: isLogout || isClear
                          ? FontWeight.w500
                          : FontWeight.w800,
                      fontSize: isLogout || isClear ? 20 : 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _NavButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 106,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00F0FF), width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
    ),
  );
}

class _GradientLine extends StatelessWidget {
  final bool isLeft;
  const _GradientLine({required this.isLeft});

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 4,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(11),
      gradient: LinearGradient(
        begin: Alignment.centerRight,
        end: Alignment.centerLeft,
        colors: isLeft
            ? const [Color(0xFF00F0FF), Color(0xFF0B1320)]
            : const [Color(0xFF0B1320), Color(0xFF00F0FF)],
      ),
    ),
  );
}
