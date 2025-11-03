import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/footer_widgets.dart';
import "../services/auth_service.dart";

import 'dart:async';

class RegisterPatternScreen extends StatefulWidget {
  const RegisterPatternScreen({super.key});

  @override
  State<RegisterPatternScreen> createState() => _RegisterPatternScreenState();
}

class _RegisterPatternScreenState extends State<RegisterPatternScreen> {
  final int gridSize = 3;
  List<int> selectedDots = [];
  List<int> registeredPattern = []; // Store the first pattern
  bool patternCompleted = false;
  bool isConfirmMode = false; // Track if we're in confirm mode
  bool patternsMatched = false; // Track if patterns matched

  final double dotSize = 17;
  final GlobalKey _gridKey = GlobalKey();

  bool showPatternLines = true;
  bool isEyeVisible = true;

  int currentLockingFrame = 0;
  bool showLockingAnimation = false;
  List<String> lockingFrames = [
    'assets/images/locking1.png',
    'assets/images/locking2.png',
    'assets/images/locking3.png',
    'assets/images/locking5.png',
  ];

  Future<void> _logout() async {
    try {
      await AuthService.deleteToken();
      Navigator.pushNamedAndRemoveUntil(context, '/sign-in', (route) => false);
    } catch (e) {
      print("Logout failed: $e");
    }
  }

  Widget buildBackAndLogoutButtons(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 20),
      child: Row(
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
              _logout(); // ✅ Use your existing logout logic
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
      ),
    );
  }

  void _onPatternComplete() async {
    if (!isConfirmMode) {
      // First pattern registered
      setState(() {
        registeredPattern = List.from(selectedDots);
        isConfirmMode = true;
        patternCompleted = false;
        selectedDots = [];
      });
    } else {
      // Confirming pattern
      if (_patternsMatch(registeredPattern, selectedDots)) {
        // Pattern confirmed - show lock background and animation
        setState(() {
          patternCompleted = true;
          patternsMatched = true;
          showLockingAnimation = true;
          currentLockingFrame = 0;
        });

        // Animate frames 1 → 5
        for (int i = 0; i < lockingFrames.length; i++) {
          await Future.delayed(const Duration(milliseconds: 300), () {
            setState(() {
              currentLockingFrame = i;
            });
          });
        }

        try {
          await AuthService.registerPattern(selectedDots);
          print("Pattern registered successfully");
          Navigator.pushNamed(context, '/sign-in');
        } catch (e) {
          print("Error registering pattern: $e");
        }
      } else {
        // Pattern not confirmed - reset
        setState(() {
          patternCompleted = false;
          patternsMatched = false;
          showLockingAnimation = false;
          selectedDots = [];
        });
      }
    }
  }

  // void _onPatternComplete() async {
  //   if (!isConfirmMode) {
  //     // First pattern registered
  //     setState(() {
  //       registeredPattern = List.from(selectedDots);
  //       isConfirmMode = true;
  //       patternCompleted = false;
  //       selectedDots = [];
  //     });
  //   } else {
  //     // Confirming pattern
  //     if (_patternsMatch(registeredPattern, selectedDots)) {
  //       // Pattern confirmed - show both lock background and animation
  //       setState(() {
  //         patternCompleted = true;
  //         patternsMatched = true; // Set match flag
  //         showLockingAnimation = true;
  //         currentLockingFrame = 0; // Start with locking1.png
  //       });

  //       // Animate frames 1 → 5
  //       Timer.periodic(const Duration(milliseconds: 300), (timer) {
  //         if (currentLockingFrame < lockingFrames.length - 1) {
  //           setState(() {
  //             currentLockingFrame++;
  //           });
  //         } else {
  //           timer.cancel(); // Stop timer at last frame
  //           setState(() {
  //             currentLockingFrame =
  //                 lockingFrames.length - 1; // Keep locking5.png
  //           });
  //         }
  //       });
  //       try {
  //         await AuthService.registerPattern(selectedDots); // <-- your method
  //         print("Pattern registered successfully");
  //         // Optionally navigate to the next screen here
  //         Navigator.pushNamed(context, '/next-screen');
  //       } catch (e) {
  //         print("Error registering pattern: $e");
  //         // Show error dialog/snackbar to user if needed
  //       }
  //     } else {
  //       // Pattern not confirmed - don't show anything
  //       setState(() {
  //         patternCompleted = false;
  //         patternsMatched = false; // Reset match flag
  //         showLockingAnimation = false;
  //         selectedDots = []; // Reset for retry
  //       });
  //     }
  //   }
  // }

  bool _patternsMatch(List<int> pattern1, List<int> pattern2) {
    if (pattern1.length != pattern2.length) return false;
    for (int i = 0; i < pattern1.length; i++) {
      if (pattern1[i] != pattern2[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ===== Sign In / Sign Up Buttons =====
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 110,
                      child: _OutlinedButton(
                        text: 'Sign In',
                        onTap: () => Navigator.pushNamed(context, '/sign-in'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    SizedBox(
                      width: 110,
                      child: _GradientButton(
                        text: 'Sign Up',
                        onTap: () => Navigator.pushNamed(context, '/sign-up'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Protect Your Access',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),
                // ===== Progress Line + Steps =====
                SizedBox(
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 12,
                        left: 32,
                        right: 38,
                        child: _ProgressLine(totalSteps: 5, completedSteps: 2),
                      ),
                      const _ProgressSteps(),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // ===== Pattern Header (Dynamic based on mode) =====
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isConfirmMode ? 'Confirm Pattern' : 'Register Pattern',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          showPatternLines = !showPatternLines;
                          isEyeVisible = !isEyeVisible;
                        });
                      },
                      child: Image.asset(
                        isEyeVisible
                            ? 'assets/images/whiteEye.png'
                            : 'assets/images/whiteEyeSlash.png',
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isConfirmMode
                      ? 'Redraw your pattern to confirm'
                      : 'Draw a secure pattern (min. 4 dots) \n to protect your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                // ===== Pattern Grid =====
                Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      key: _gridKey,
                      width: 280,
                      height: 280,
                      child: GestureDetector(
                        onPanStart: (_) {
                          setState(() {
                            selectedDots = [];
                            patternCompleted = false;
                          });
                        },
                        onPanUpdate: (details) {
                          RenderBox box =
                              _gridKey.currentContext!.findRenderObject()
                                  as RenderBox;
                          Offset localPos = box.globalToLocal(
                            details.globalPosition,
                          );

                          double cellSize = box.size.width / gridSize;
                          int row = (localPos.dy / cellSize).floor();
                          int col = (localPos.dx / cellSize).floor();
                          int idx = row * gridSize + col;

                          if (row >= 0 &&
                              row < gridSize &&
                              col >= 0 &&
                              col < gridSize &&
                              !selectedDots.contains(idx)) {
                            setState(() {
                              selectedDots.add(idx);
                            });
                          }
                        },
                        onPanEnd: (_) {
                          if (selectedDots.length >= 4) {
                            setState(() {
                              patternCompleted = true;
                            });
                            // Automatically process pattern completion
                            Future.delayed(
                              const Duration(milliseconds: 500),
                              () => _onPatternComplete(),
                            );
                          } else {
                            setState(() {
                              selectedDots = [];
                              patternCompleted = false;
                            });
                          }
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            double cellSize = constraints.maxWidth / gridSize;

                            List<Offset> dotCenters = [];
                            for (int row = 0; row < gridSize; row++) {
                              for (int col = 0; col < gridSize; col++) {
                                double x = (col + 0.5) * cellSize;
                                double y = (row + 0.5) * cellSize;
                                dotCenters.add(Offset(x, y));
                              }
                            }

                            return Stack(
                              children: [
                                // Lock background - only show when patterns matched
                                if (patternsMatched && isConfirmMode)
                                  Center(
                                    child: Image.asset(
                                      'assets/images/lockBackground.png',
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                // Locking animation frames on top - only show when patterns matched
                                if (patternsMatched && showLockingAnimation)
                                  Center(
                                    child: Image.asset(
                                      lockingFrames[currentLockingFrame],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.contain,
                                    ),
                                  ),

                                // Dots and lines
                                Opacity(
                                  opacity: patternCompleted ? 0.7 : 1.0,
                                  child: Stack(
                                    children: [
                                      if (showPatternLines)
                                        CustomPaint(
                                          size: Size.infinite,
                                          painter: _PatternPainter(
                                            selectedDots: selectedDots,
                                            dotCenters: dotCenters,
                                          ),
                                        ),
                                      for (
                                        int i = 0;
                                        i < dotCenters.length;
                                        i++
                                      )
                                        Positioned(
                                          left: dotCenters[i].dx - dotSize / 2,
                                          top: dotCenters[i].dy - dotSize / 2,
                                          child: Container(
                                            width: dotSize,
                                            height: dotSize,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: showPatternLines
                                                  ? (selectedDots.contains(i)
                                                        ? const Color(
                                                            0xFF00F0FF,
                                                          )
                                                        : Colors.white)
                                                  : Colors.white,
                                              boxShadow:
                                                  (showPatternLines &&
                                                      selectedDots.contains(i))
                                                  ? [
                                                      BoxShadow(
                                                        color: const Color(
                                                          0xFF00F0FF,
                                                        ).withOpacity(0.7),
                                                        blurRadius: 7,
                                                      ),
                                                    ]
                                                  : [],
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // ===== Back & Logout Buttons =====
                buildBackAndLogoutButtons(context),
                const SizedBox(height: 30),
                const FooterWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===== Custom Outlined Button =====
class _OutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _OutlinedButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
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

// ===== Custom Gradient Button =====
class _GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _GradientButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
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

// ===== Pattern Painter =====
class _PatternPainter extends CustomPainter {
  final List<int> selectedDots;
  final List<Offset> dotCenters;

  _PatternPainter({required this.selectedDots, required this.dotCenters});

  @override
  void paint(Canvas canvas, Size size) {
    if (selectedDots.length < 2) return;

    Paint paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (int i = 0; i < selectedDots.length - 1; i++) {
      int first = selectedDots[i];
      int second = selectedDots[i + 1];
      canvas.drawLine(dotCenters[first], dotCenters[second], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ===== Progress Line =====
class _ProgressLine extends StatelessWidget {
  final int totalSteps;
  final int completedSteps;
  const _ProgressLine({required this.totalSteps, required this.completedSteps});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final segmentWidth = totalWidth / (totalSteps - 1);
        final gradients = [
          const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF0EA0BB)]),
          const LinearGradient(colors: [Color(0xFF13D2C7), Color(0xFF01259E)]),
          const LinearGradient(colors: [Color(0xFF01259E), Color(0xFF01259E)]),
          const LinearGradient(colors: [Color(0xFF01259E), Color(0xFF00259E)]),
        ];
        return Row(
          children: List.generate(
            totalSteps - 1,
            (i) => Container(
              width: segmentWidth,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: i == 0 ? const Radius.circular(100) : Radius.zero,
                  right: i == totalSteps - 2
                      ? const Radius.circular(100)
                      : Radius.zero,
                ),
                gradient: i < gradients.length ? gradients[i] : null,
                color: i >= gradients.length ? Colors.white : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ===== Progress Steps =====
class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps();

  @override
  Widget build(BuildContext context) => Row(
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
      _buildStep(
        "Register\nLive",
        filled: true,
        filledColor: const Color(0xFF01259E),
      ),
      _buildStep(
        "Register\nPattern",
        filled: true,
        filledColor: const Color(0xFF01259E),
      ),
    ],
  );

  static Widget _buildStep(
    String label, {
    bool filled = false,
    Color? filledColor,
  }) => Column(
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
          color: Colors.white,
        ),
      ),
    ],
  );
}
