import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/footer_widgets.dart';
import "../services/auth_service.dart";
import 'dart:async';
import '../widgets/error_widgets.dart';

class ResponsiveRegisterPatternScreen extends StatelessWidget {
  const ResponsiveRegisterPatternScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const TabletRegisterPatternScreen();
        } else {
          return const MobileRegisterPatternScreen();
        }
      },
    );
  }
}

class MobileRegisterPatternScreen extends StatefulWidget {
  const MobileRegisterPatternScreen({super.key});

  @override
  State<MobileRegisterPatternScreen> createState() =>
      _MobileRegisterPatternScreenState();
}

class _MobileRegisterPatternScreenState
    extends State<MobileRegisterPatternScreen> {
  final int gridSize = 3;
  List<int> selectedDots = [];
  List<int> registeredPattern = [];
  bool patternCompleted = false;
  bool isConfirmMode = false;
  bool patternsMatched = false;
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  final double dotSize = 17;
  final GlobalKey _gridKey = GlobalKey();

  bool showPatternLines = true;
  bool isEyeVisible = true;

  int currentLockingFrame = 0;
  bool showLockingAnimation = false;
  List<String> lockingFrames = [
    'locking1.png',
    'locking2.png',
    'locking3.png',
    'locking5.png',
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
      if (selectedDots.length < 4) {
        _errorStackKey.currentState?.showError("Minimum 4 dots");
        setState(() {
          selectedDots = [];
          patternCompleted = false;
        });
        return;
      }

      setState(() {
        registeredPattern = List.from(selectedDots);
        isConfirmMode = true;
        patternCompleted = false;
        selectedDots = [];
      });
    } else {
      if (_patternsMatch(registeredPattern, selectedDots)) {
        setState(() {
          patternCompleted = true;
          patternsMatched = true;
          showLockingAnimation = true;
          currentLockingFrame = 0;
        });

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
          Navigator.pushNamed(context, '/coming-soon');
        } catch (e) {
          print("Error registering pattern: $e");
        }
      } else {
        _errorStackKey.currentState?.showError(
          "Pattern does not match. \n Try again.",
        );
        setState(() {
          patternCompleted = false;
          patternsMatched = false;
          showLockingAnimation = false;
          selectedDots = [];
        });
      }
    }
  }

  bool _patternsMatch(List<int> pattern1, List<int> pattern2) {
    if (pattern1.length != pattern2.length) return false;
    for (int i = 0; i < pattern1.length; i++) {
      if (pattern1[i] != pattern2[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Sign In / Sign Up Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          child: _OutlinedButton(
                            text: 'Sign In',
                            onTap: () =>
                                Navigator.pushNamed(context, '/sign-in'),
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 110,
                          child: _GradientButton(
                            text: 'Sign Up',
                            onTap: () =>
                                Navigator.pushNamed(context, '/sign-up'),
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
                    // Progress Line + Steps
                    SizedBox(
                      width: double.infinity,
                      child: Stack(
                        children: [
                          Positioned(
                            top: 12,
                            left: 32,
                            right: 38,
                            child: _ProgressLine(
                              totalSteps: 5,
                              completedSteps: 2,
                            ),
                          ),
                          const _ProgressSteps(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Pattern Header
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isConfirmMode
                              ? 'Confirm Pattern'
                              : 'Register Pattern',
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
                                ? 'whiteEye.png'
                                : 'whiteEyeSlash.png',
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
                    // Pattern Grid
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
                                Future.delayed(
                                  const Duration(milliseconds: 500),
                                  () => _onPatternComplete(),
                                );
                              } else {
                                _errorStackKey.currentState?.showError(
                                  "Minimum 4 dots",
                                );
                                setState(() {
                                  selectedDots = [];
                                  patternCompleted = false;
                                });
                              }
                            },
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double cellSize =
                                    constraints.maxWidth / gridSize;
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
                                    if (patternsMatched && isConfirmMode)
                                      Center(
                                        child: Image.asset(
                                          'lockBackground.png',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    if (patternsMatched && showLockingAnimation)
                                      Center(
                                        child: Image.asset(
                                          lockingFrames[currentLockingFrame],
                                          width: 60,
                                          height: 60,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
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
                                              left:
                                                  dotCenters[i].dx -
                                                  dotSize / 2,
                                              top:
                                                  dotCenters[i].dy -
                                                  dotSize / 2,
                                              child: Container(
                                                width: dotSize,
                                                height: dotSize,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: showPatternLines
                                                      ? (selectedDots.contains(
                                                              i,
                                                            )
                                                            ? const Color(
                                                                0xFF00F0FF,
                                                              )
                                                            : Colors.white)
                                                      : Colors.white,
                                                  boxShadow:
                                                      (showPatternLines &&
                                                          selectedDots.contains(
                                                            i,
                                                          ))
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
                    // Back & Logout Buttons
                    buildBackAndLogoutButtons(context),
                    const SizedBox(height: 30),
                    const FooterWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
        // ErrorStack always at the bottom
        ErrorStack(key: _errorStackKey),
      ],
    );
  }
}

class TabletRegisterPatternScreen extends StatefulWidget {
  const TabletRegisterPatternScreen({super.key});

  @override
  State<TabletRegisterPatternScreen> createState() =>
      _TabletRegisterPatternScreenState();
}

class _TabletRegisterPatternScreenState
    extends State<TabletRegisterPatternScreen> {
  final int gridSize = 3;
  List<int> selectedDots = [];
  List<int> registeredPattern = [];
  bool patternCompleted = false;
  bool isConfirmMode = false;
  bool patternsMatched = false;

  final double dotSize = 16; // Larger dots for tablet
  final GlobalKey _gridKey = GlobalKey();

  bool showPatternLines = true;
  bool isEyeVisible = true;

  int currentLockingFrame = 0;
  bool showLockingAnimation = false;
  List<String> lockingFrames = [
    'locking1.png',
    'locking2.png',
    'locking3.png',
    'locking5.png',
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
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: Center(
        child: SizedBox(
          width: 460, // fixed width
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
                width: 106,
                height: 40,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                textColor: Colors.white,
                borderColor: const Color(0xFF00F0FF),
                backgroundColor: const Color(0xFF0B1320),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(width: 15),

              CustomButton(
                text: 'Logout',
                width: 106,
                height: 40,
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
        ),
      ),
    );
  }

  void _onPatternComplete() async {
    if (!isConfirmMode) {
      setState(() {
        registeredPattern = List.from(selectedDots);
        isConfirmMode = true;
        patternCompleted = false;
        selectedDots = [];
      });
    } else {
      if (_patternsMatch(registeredPattern, selectedDots)) {
        setState(() {
          patternCompleted = true;
          patternsMatched = true;
          showLockingAnimation = true;
          currentLockingFrame = 0;
        });

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
          Navigator.pushNamed(context, '/coming-soon');
        } catch (e) {
          print("Error registering pattern: $e");
        }
      } else {
        setState(() {
          patternCompleted = false;
          patternsMatched = false;
          showLockingAnimation = false;
          selectedDots = [];
        });
      }
    }
  }

  bool _patternsMatch(List<int> pattern1, List<int> pattern2) {
    if (pattern1.length != pattern2.length) return false;
    for (int i = 0; i < pattern1.length; i++) {
      if (pattern1[i] != pattern2[i]) return false;
    }
    return true;
  }

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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 50),
                                  // Sign In / Sign Up Buttons - Centered for tablet
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                      const SizedBox(width: 10),
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
                                  const SizedBox(height: 10),

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
                                  const SizedBox(height: 10),

                                  // Progress Line + Steps - Wider for tablet
                                  SizedBox(
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 10,
                                          left: 42,
                                          right: 49,
                                          child: _ProgressLine(
                                            totalSteps: 5,
                                            completedSteps: 2,
                                          ),
                                        ),
                                        const _ProgressSteps(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Pattern Header
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isConfirmMode
                                            ? 'Confirm Pattern'
                                            : 'Register Pattern',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 30,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            showPatternLines =
                                                !showPatternLines;
                                            isEyeVisible = !isEyeVisible;
                                          });
                                        },
                                        child: Image.asset(
                                          isEyeVisible
                                              ? 'whiteEye.png'
                                              : 'whiteEyeSlash.png',
                                          width: 16,
                                          height: 15,
                                        ),
                                      ),
                                    ],
                                  ),

                                  Text(
                                    isConfirmMode
                                        ? 'Redraw your pattern to confirm'
                                        : 'Draw a secure pattern (minimum 4 dots) \n to protect your account',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 0),

                                  // Pattern Grid - Larger for tablet
                                  Center(
                                    child: SizedBox(
                                      key: _gridKey,
                                      width: 350, // Larger grid for tablet
                                      height: 300,
                                      child: GestureDetector(
                                        onPanStart: (_) {
                                          setState(() {
                                            selectedDots = [];
                                            patternCompleted = false;
                                          });
                                        },
                                        onPanUpdate: (details) {
                                          RenderBox box =
                                              _gridKey.currentContext!
                                                      .findRenderObject()
                                                  as RenderBox;
                                          Offset localPos = box.globalToLocal(
                                            details.globalPosition,
                                          );

                                          double cellSize =
                                              box.size.width / gridSize;
                                          int row = (localPos.dy / cellSize)
                                              .floor();
                                          int col = (localPos.dx / cellSize)
                                              .floor();
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
                                            double cellSize =
                                                constraints.maxWidth / gridSize;

                                            List<Offset> dotCenters = [];
                                            for (
                                              int row = 0;
                                              row < gridSize;
                                              row++
                                            ) {
                                              for (
                                                int col = 0;
                                                col < gridSize;
                                                col++
                                              ) {
                                                double x =
                                                    (col + 0.5) * cellSize;
                                                double y =
                                                    (row + 0.5) * cellSize;
                                                dotCenters.add(Offset(x, y));
                                              }
                                            }

                                            return Stack(
                                              children: [
                                                if (patternsMatched &&
                                                    isConfirmMode)
                                                  Center(
                                                    child: Image.asset(
                                                      'lockBackground.png',
                                                      width: 120,
                                                      height: 120,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),

                                                if (patternsMatched &&
                                                    showLockingAnimation)
                                                  Center(
                                                    child: Image.asset(
                                                      lockingFrames[currentLockingFrame],
                                                      width: 80,
                                                      height: 80,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),

                                                Opacity(
                                                  opacity: patternCompleted
                                                      ? 0.7
                                                      : 1.0,
                                                  child: Stack(
                                                    children: [
                                                      if (showPatternLines)
                                                        CustomPaint(
                                                          size: Size.infinite,
                                                          painter:
                                                              _PatternPainter(
                                                                selectedDots:
                                                                    selectedDots,
                                                                dotCenters:
                                                                    dotCenters,
                                                              ),
                                                        ),
                                                      for (
                                                        int i = 0;
                                                        i < dotCenters.length;
                                                        i++
                                                      )
                                                        Positioned(
                                                          left:
                                                              dotCenters[i].dx -
                                                              dotSize / 2,
                                                          top:
                                                              dotCenters[i].dy -
                                                              dotSize / 2,
                                                          child: Container(
                                                            width: dotSize,
                                                            height: dotSize,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              color:
                                                                  showPatternLines
                                                                  ? (selectedDots
                                                                            .contains(
                                                                              i,
                                                                            )
                                                                        ? const Color(
                                                                            0xFF00F0FF,
                                                                          )
                                                                        : Colors
                                                                              .white)
                                                                  : Colors
                                                                        .white,
                                                              boxShadow:
                                                                  (showPatternLines &&
                                                                      selectedDots
                                                                          .contains(
                                                                            i,
                                                                          ))
                                                                  ? [
                                                                      BoxShadow(
                                                                        color: const Color(
                                                                          0xFF00F0FF,
                                                                        ).withOpacity(0.7),
                                                                        blurRadius:
                                                                            8,
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
                                  const SizedBox(height: 40),

                                  // Back & Logout Buttons
                                  buildBackAndLogoutButtons(context),
                                  const SizedBox(height: 110),

                                  const FooterWidget(),
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
                        'Rectangle2.png',
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
        ],
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
    return SizedBox(
      width: 343,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final segmentWidth = totalWidth / (totalSteps - 1);
          final gradients = [
            const LinearGradient(
              colors: [Color(0xFF00F0FF), Color(0xFF0EA0BB)],
            ),
            const LinearGradient(
              colors: [Color(0xFF13D2C7), Color(0xFF01259E)],
            ),
            const LinearGradient(
              colors: [Color(0xFF01259E), Color(0xFF01259E)],
            ),
            const LinearGradient(
              colors: [Color(0xFF01259E), Color(0xFF00259E)],
            ),
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
      ),
    );
  }
}

// ===== Progress Steps =====
class _ProgressSteps extends StatelessWidget {
  const _ProgressSteps();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 410,
    child: Row(
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
    ),
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
