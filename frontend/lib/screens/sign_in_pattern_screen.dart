import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../widgets/footer_widgets.dart';
import '../widgets/error_widgets.dart';

class SignInPatternScreen extends StatefulWidget {
  const SignInPatternScreen({super.key});

  @override
  State<SignInPatternScreen> createState() => _SignInPatternScreenState();
}

class _SignInPatternScreenState extends State<SignInPatternScreen> {
  bool isEyeVisible = true;
  static const int gridCount = 3;
  static const double dotSize = 18.0;
  final GlobalKey _gridKey = GlobalKey();
  List<int> selectedDots = [];

  Timer? _clearTimer;

  Future<void> _logout() async {
    try {
      await AuthService.deleteToken();
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    } catch (e) {
      print("Logout failed: $e");
    }
  }

  @override
  void dispose() {
    _clearTimer?.cancel();
    super.dispose();
  }

  void _handleDotSelection(int index) {
    if (!selectedDots.contains(index)) {
      setState(() => selectedDots.add(index));
    }
  }

  void _clearPatternDelayed([int millis = 800]) {
    _clearTimer?.cancel();
    _clearTimer = Timer(Duration(milliseconds: millis), () {
      setState(() {
        selectedDots = [];
      });
    });
  }

  // void _showError(String message) {
  //   final overlay = Overlay.of(context);
  //   if (overlay == null) return;

  //   final overlayEntry = OverlayEntry(
  //     builder: (context) => Positioned(
  //       top: 0,
  //       left: 0,
  //       right: 0,
  //       child: Material(
  //         color: Colors.transparent,
  //         child: ErrorBanner(message: message),
  //       ),
  //     ),
  //   );

  //   overlay.insert(overlayEntry);

  //   Future.delayed(const Duration(milliseconds: 3000), () {
  //     overlayEntry.remove();
  //   });
  // }
  // void _validatePattern() async {
  //   if (selectedDots.length < 4) {
  //     _showError("Please draw a pattern of at least 4 dots.");
  //     _clearPatternDelayed(1000);
  //     return;
  //   }

  //   try {
  //     bool isValid = await AuthService.validatePattern(selectedDots);

  //     if (!isValid) {
  //       _showError("Incorrect Pattern. Try Again.");
  //       _clearPatternDelayed(1200);
  //       return;
  //     }

  //     // SUCCESS
  //     debugPrint("✅ Correct Pattern!");
  //     Navigator.pushNamed(context, '/settings');
  //   } catch (e) {
  //     _showError("Error validating pattern.");
  //   }

  //   _clearPatternDelayed(800);
  // }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final gridSize = min(screenWidth * 0.85, 320.0);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 60, 20, 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/egetyPerfectStar.png',
                width: 111,
                height: 126,
                fit: BoxFit.contain,
              ),
              const Text(
                'Egety Trust',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 50,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),

              // Title row with eye toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        "Enter Pattern To Continue",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: Colors.white,
                        ),
                        softWrap: false, // 👈 disables wrapping
                        overflow: TextOverflow
                            .visible, // or TextOverflow.ellipsis if needed
                        maxLines: 1, // 👈 force single line
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isEyeVisible = !isEyeVisible;
                          });
                        },
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Image.asset(
                            isEyeVisible
                                ? 'assets/images/whiteEye.png'
                                : 'assets/images/whiteEyeSlash.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Pattern grid area
              Center(
                child: Container(
                  key: _gridKey,
                  width: gridSize,
                  height: gridSize,
                  child: GestureDetector(
                    onPanStart: (_) {
                      setState(() {
                        selectedDots = [];
                      });
                    },
                    onPanUpdate: (details) {
                      final renderBox =
                          _gridKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      if (renderBox == null) return;
                      final local = renderBox.globalToLocal(
                        details.globalPosition,
                      );
                      final cellSize = gridSize / gridCount;

                      for (int r = 0; r < gridCount; r++) {
                        for (int c = 0; c < gridCount; c++) {
                          final idx = r * gridCount + c;
                          final center = Offset(
                            c * cellSize + cellSize / 2,
                            r * cellSize + cellSize / 2,
                          );
                          if ((local - center).distance <= cellSize * 0.45) {
                            _handleDotSelection(idx);
                          }
                        }
                      }
                    },
                    // onPanEnd: (_) {
                    //   if (selectedDots.length >= 4) {
                    //     _validatePattern();
                    //   } else {
                    //     _showError("Pattern too short (min 4 dots).");
                    //   }
                    //   _clearPatternDelayed(900);
                    // },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = min(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final cellSize = size / gridCount;
                        final dotCenters = <Offset>[];
                        for (int r = 0; r < gridCount; r++) {
                          for (int c = 0; c < gridCount; c++) {
                            dotCenters.add(
                              Offset(
                                c * cellSize + cellSize / 2,
                                r * cellSize + cellSize / 2,
                              ),
                            );
                          }
                        }

                        return Stack(
                          children: [
                            // Pattern connecting lines (only if eye visible)
                            if (isEyeVisible)
                              CustomPaint(
                                size: Size(size, size),
                                painter: _PatternPainter(
                                  selectedDots: selectedDots,
                                  dotCenters: dotCenters,
                                ),
                              ),

                            // Dots (always visible)
                            for (int i = 0; i < dotCenters.length; i++)
                              Positioned(
                                left: dotCenters[i].dx - dotSize / 2,
                                top: dotCenters[i].dy - dotSize / 2,
                                child: Container(
                                  width: dotSize,
                                  height: dotSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color:
                                        (isEyeVisible &&
                                            selectedDots.contains(i))
                                        ? const Color(0xFF00F0FF)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),

              buildBackAndLogoutButtons(context),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      debugPrint('Forgot Pattern tapped');
                    },
                    child: const Text(
                      'Forgot Pattern?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/sign-in-pin');
                    },
                    child: const Text(
                      'Use Pin Instead',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF00F0FF),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBackAndLogoutButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 0),
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
            width: 90,
            height: 45,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            textColor: Colors.white,
            borderColor: const Color(0xFF00F0FF),
            backgroundColor: const Color(0xFF0B1320),
            onTap: () {
              Navigator.pop(context);
            },
          ),

          const SizedBox(width: 20),

          // 🚪 LOGOUT BUTTON
          CustomButton(
            text: 'Logout',
            width: 110,
            height: 45,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            textColor: Colors.white,
            borderColor: const Color(0xFF00F0FF),
            backgroundColor: const Color(0xFF0B1320),
            onTap: () async {
              _logout();
            },
          ),

          const SizedBox(width: 20),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 0),
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
      ),
    );
  }
}

// Painter for connecting lines with glow
class _PatternPainter extends CustomPainter {
  final List<int> selectedDots;
  final List<Offset> dotCenters;

  _PatternPainter({required this.selectedDots, required this.dotCenters});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedDots.length < 2) return;

    // Glow effect paint
    final glowPaint = Paint()
      ..color = const Color(0xFF00F0FF).withOpacity(0.6)
      ..strokeWidth = 8.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    // Solid line paint
    final linePaint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < selectedDots.length - 1; i++) {
      final a = selectedDots[i];
      final b = selectedDots[i + 1];
      if (a >= 0 && a < dotCenters.length && b >= 0 && b < dotCenters.length) {
        canvas.drawLine(dotCenters[a], dotCenters[b], glowPaint);
        canvas.drawLine(dotCenters[a], dotCenters[b], linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) {
    return old.selectedDots != selectedDots || old.dotCenters != dotCenters;
  }
}
