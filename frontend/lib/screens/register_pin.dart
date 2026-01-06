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

  // State for Next button
  bool _isNextHovered = false;
  bool _isNextPressed = false;

  // State for Back button
  bool _isBackHovered = false;
  bool _isBackPressed = false;

  // State for the other Next button
  bool _isSecondNextHovered = false;
  bool _isSecondNextPressed = false;

  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // Validation states
  bool _pinValid = false;
  bool _pinMatching = false;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _numbers = List.generate(10, (i) => i.toString())..shuffle();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _pin.clear();
        _validatePin();
      } else if (value == 'Logout') {
        _logout();
      } else {
        if (_pin.length < 4) {
          _pin.add(value);
          if (_pin.length == 4) {
            // Validate automatically when 4 digits are entered
            _validatePinAutomatically();
          } else {
            // Clear validation state if not 4 digits
            _pinMatching = false;
            _pinValid = false;
          }
        }
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

  // Validation methods
  void _validatePin() {
    final enteredPin = _pin.join();

    if (enteredPin.isEmpty) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = null;
      });
      return;
    }

    if (enteredPin.length < 4) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "Please enter 4 digits";
      });
      return;
    }

    // Validate all digits are numbers (should always be true with keypad, but just in case)
    final pinRegex = RegExp(r"^[0-9]{4}$");
    if (!pinRegex.hasMatch(enteredPin)) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "PIN must contain exactly 4 digits";
      });
      return;
    }

    setState(() {
      _pinValid = true;
      _pinError = null;
    });
  }

  // Special validation for confirm PIN screen - checks if PIN matches original
  void _validatePinAutomatically() {
    final enteredPin = _pin.join();

    // Basic validation
    if (enteredPin.isEmpty || enteredPin.length < 4) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = null;
      });
      return;
    }

    final pinRegex = RegExp(r"^[0-9]{4}$");
    if (!pinRegex.hasMatch(enteredPin)) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "PIN must contain exactly 4 digits";
      });
      return;
    }

    setState(() {
      _pinValid = true;

      // Check if we're in confirm PIN mode and validate match
      if (widget.originalPin != null) {
        if (enteredPin == widget.originalPin) {
          _pinMatching = true;
          _pinError = null;
          // When PIN matches, we don't need to clear errors since they auto-remove
        } else {
          _pinMatching = false;
          _pinError = "PIN does not match";
          // Show error immediately when 4 digits are entered and don't match
          _errorStackKey.currentState?.showError(_pinError!);

          // Automatically clear the PIN field when it doesn't match
          Future.delayed(const Duration(milliseconds: 500), () {
            // Clear after a short delay so user can see the wrong PIN
            if (mounted) {
              setState(() {
                _pin.clear();
                _pinValid = false;
                _pinMatching = false;
              });
            }
          });
        }
      } else {
        // For first PIN entry, just mark as valid
        _pinMatching = true; // Enable Next button for first PIN entry
        _pinError = null;
      }
    });
  }

  void _validatePinAndShowError() {
    final enteredPin = _pin.join();

    if (enteredPin.isEmpty) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = null;
      });
      return;
    }

    if (enteredPin.length < 4) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "Please enter 4 digits";
      });
      _errorStackKey.currentState?.showError(_pinError!);
      return;
    }

    final pinRegex = RegExp(r"^[0-9]{4}$");
    if (!pinRegex.hasMatch(enteredPin)) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "PIN must contain exactly 4 digits";
      });
      _errorStackKey.currentState?.showError(_pinError!);
      return;
    }

    setState(() {
      _pinValid = true;

      if (widget.originalPin != null) {
        if (enteredPin == widget.originalPin) {
          _pinMatching = true;
          _pinError = null;
          // No need to clear errors - they auto-remove after duration
        } else {
          _pinMatching = false;
          _pinError = "PIN does not match";
          _errorStackKey.currentState?.showError(_pinError!);

          _pin.clear();
          _pinValid = false;
          _pinMatching = false;
        }
      } else {
        _pinMatching = true;
        _pinError = null;
      }
    });
  }

  // Function to validate all fields and show errors if any
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate PIN
    _validatePin();
    if (widget.originalPin != null) {
      // For confirm PIN screen, check if PIN matches
      if (_pin.isNotEmpty && _pin.length == 4) {
        if (_pin.join() != widget.originalPin) {
          _errorStackKey.currentState?.showError(
            "PIN does not match. Try again.",
          );
          hasError = true;
        }
      }
    }

    if (_pinError != null && !_pinValid) {
      _errorStackKey.currentState?.showError(_pinError!);
      hasError = true;
    }

    if (_pin.isEmpty || _pin.length < 4) {
      _errorStackKey.currentState?.showError("Please enter 4 digits");
      hasError = true;
    }
  }

  void _onNext() async {
    final enteredPin = _pin.join();

    // Check if all fields are valid
    if (!_pinValid || !_pinMatching) {
      // Validate all fields and show errors if any
      _validateAllFieldsAndShowErrors();
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

  // Check if all required fields are valid
  bool get _allFieldsValid {
    if (widget.originalPin != null) {
      // For confirm PIN screen, need both valid AND matching
      return _pinValid && _pinMatching;
    } else {
      // For first PIN entry, just need valid
      return _pinValid && _pin.length == 4;
    }
  }

  // Helper method to build interactive buttons
  Widget _buildInteractiveButton({
    required String text,
    required VoidCallback onTap,
    required bool isEnabled,
    required bool isHovered,
    required bool isPressed,
    required VoidCallback onHoverEnter,
    required VoidCallback onHoverExit,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
    double width = 106,
    double height = 40,
    bool useCustomButton = false,
  }) {
    return MouseRegion(
      onEnter: (_) => isEnabled ? onHoverEnter() : null,
      onExit: (_) => onHoverExit(),
      cursor: isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => onTapDown() : null,
        onTapUp: isEnabled ? (_) => onTapUp() : null,
        onTapCancel: isEnabled ? onTapCancel : null,
        onTap: onTap,
        child: Transform.scale(
          scale: isEnabled && isPressed ? 0.95 : 1.0,
          child: useCustomButton
              ? _buildCustomButton(
                  text: text,
                  width: width,
                  height: height,
                  isEnabled: isEnabled,
                  isHovered: isHovered,
                  isPressed: isPressed,
                  onTap: onTap,
                )
              : _buildContainerButton(
                  text: text,
                  width: width,
                  height: height,
                  isEnabled: isEnabled,
                  isHovered: isHovered,
                  isPressed: isPressed,
                  onTap: onTap,
                ),
        ),
      ),
    );
  }

  Widget _buildCustomButton({
    required String text,
    required double width,
    required double height,
    required bool isEnabled,
    required bool isHovered,
    required bool isPressed,
    required VoidCallback onTap,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? const Color(0xFF00F0FF) : const Color(0xFF4A5568),
          width: 1,
        ),
        color: isEnabled
            ? (isHovered
                  ? const Color(0xFF00F0FF).withOpacity(0.15)
                  : isPressed
                  ? const Color(0xFF00F0FF).withOpacity(0.25)
                  : Colors.transparent)
            : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: isEnabled ? Colors.white : const Color(0xFF718096),
        ),
      ),
    );
  }

  Widget _buildContainerButton({
    required String text,
    required double width,
    required double height,
    required bool isEnabled,
    required bool isHovered,
    required bool isPressed,
    required VoidCallback onTap,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? const Color(0xFF00F0FF) : const Color(0xFF4A5568),
          width: 1,
        ),
        color: isEnabled
            ? (isHovered
                  ? const Color(0xFF00F0FF).withOpacity(0.15)
                  : isPressed
                  ? const Color(0xFF00F0FF).withOpacity(0.25)
                  : Colors.transparent)
            : Colors.transparent,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          fontSize: 20,
          color: isEnabled ? Colors.white : const Color(0xFF718096),
        ),
      ),
    );
  }

  // Wrapper for NavButton to add interaction
  Widget _wrapNavButtonWithInteraction() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isBackHovered = true),
      onExit: (_) => setState(() => _isBackHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isBackPressed = true),
        onTapUp: (_) => setState(() => _isBackPressed = false),
        onTapCancel: () => setState(() => _isBackPressed = false),
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
        child: Transform.scale(
          scale: _isBackPressed ? 0.95 : 1.0,
          child: Container(
            width: 106,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1),
              color: _isBackHovered
                  ? const Color(0xFF00F0FF).withOpacity(0.15)
                  : _isBackPressed
                  ? const Color(0xFF00F0FF).withOpacity(0.25)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: const Text(
              "Back",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
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
                            completedSteps: widget.originalPin != null ? 4 : 4,
                          ),
                        ),
                        _ProgressSteps(originalPin: widget.originalPin),
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
                                  color: filled
                                      ? (_allFieldsValid
                                            ? const Color(0xFF00F0FF)
                                            : const Color(0xFFFF6B6B))
                                      : Colors.white.withOpacity(0.9),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                filled
                                    ? _pin[index]
                                    : '', // Always show actual digit
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 24,
                                  color: filled
                                      ? (_allFieldsValid
                                            ? Colors.white
                                            : const Color(0xFFFF6B6B))
                                      : Colors.white,
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
                        // Back button with interaction
                        _wrapNavButtonWithInteraction(),
                        // Next button with interaction
                        _buildInteractiveButton(
                          text: "Next",
                          onTap: () {
                            if (_allFieldsValid) {
                              _onNext();
                            } else {
                              _validateAllFieldsAndShowErrors();
                            }
                          },
                          isEnabled: _allFieldsValid,
                          isHovered: _isNextHovered,
                          isPressed: _isNextPressed,
                          onHoverEnter: () =>
                              setState(() => _isNextHovered = true),
                          onHoverExit: () =>
                              setState(() => _isNextHovered = false),
                          onTapDown: () =>
                              setState(() => _isNextPressed = true),
                          onTapUp: () => setState(() => _isNextPressed = false),
                          onTapCancel: () =>
                              setState(() => _isNextPressed = false),
                          useCustomButton: false,
                        ),
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

  // State for Next button
  bool _isNextHovered = false;
  bool _isNextPressed = false;

  // State for Back button
  bool _isBackHovered = false;
  bool _isBackPressed = false;

  // State for the other Next button
  bool _isSecondNextHovered = false;
  bool _isSecondNextPressed = false;

  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // Validation states
  bool _pinValid = false;
  bool _pinMatching = false;
  String? _pinError;

  @override
  void initState() {
    super.initState();
    _numbers = List.generate(10, (i) => i.toString())..shuffle();
  }

  void _onKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _pin.clear();
        _validatePin();
      } else if (value == 'Logout') {
        _logout();
      } else {
        if (_pin.length < 4) {
          _pin.add(value);
          if (_pin.length == 4) {
            // Validate automatically when 4 digits are entered
            _validatePinAutomatically();
          } else {
            // Clear validation state if not 4 digits
            _pinMatching = false;
            _pinValid = false;
          }
        }
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

  // Validation methods
  void _validatePin() {
    final enteredPin = _pin.join();

    if (enteredPin.isEmpty) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = null;
      });
      return;
    }

    if (enteredPin.length < 4) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "Please enter 4 digits";
      });
      return;
    }

    // Validate all digits are numbers
    final pinRegex = RegExp(r"^[0-9]{4}$");
    if (!pinRegex.hasMatch(enteredPin)) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "PIN must contain exactly 4 digits";
      });
      return;
    }

    setState(() {
      _pinValid = true;
      _pinError = null;
    });
  }

  // Special validation for confirm PIN screen - checks if PIN matches original
  void _validatePinAutomatically() {
    final enteredPin = _pin.join();

    // Basic validation
    if (enteredPin.isEmpty || enteredPin.length < 4) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = null;
      });
      return;
    }

    final pinRegex = RegExp(r"^[0-9]{4}$");
    if (!pinRegex.hasMatch(enteredPin)) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "PIN must contain exactly 4 digits";
      });
      return;
    }

    setState(() {
      _pinValid = true;

      // Check if we're in confirm PIN mode and validate match
      if (widget.originalPin != null) {
        if (enteredPin == widget.originalPin) {
          _pinMatching = true;
          _pinError = null;
          // When PIN matches, we don't need to clear errors since they auto-remove
        } else {
          _pinMatching = false;
          _pinError = "PIN does not match";
          // Show error immediately when 4 digits are entered and don't match
          _errorStackKey.currentState?.showError(_pinError!);
        }
      } else {
        // For first PIN entry, just mark as valid
        _pinMatching = true; // Enable Next button for first PIN entry
        _pinError = null;
      }
    });
  }

  void _validatePinAndShowError() {
    final enteredPin = _pin.join();

    if (enteredPin.isEmpty) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = null;
      });
      return;
    }

    if (enteredPin.length < 4) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "Please enter 4 digits";
      });
      _errorStackKey.currentState?.showError(_pinError!);
      return;
    }

    final pinRegex = RegExp(r"^[0-9]{4}$");
    if (!pinRegex.hasMatch(enteredPin)) {
      setState(() {
        _pinValid = false;
        _pinMatching = false;
        _pinError = "PIN must contain exactly 4 digits";
      });
      _errorStackKey.currentState?.showError(_pinError!);
      return;
    }

    setState(() {
      _pinValid = true;

      if (widget.originalPin != null) {
        if (enteredPin == widget.originalPin) {
          _pinMatching = true;
          _pinError = null;
          // No need to clear errors - they auto-remove after duration
        } else {
          _pinMatching = false;
          _pinError = "PIN does not match";
          _errorStackKey.currentState?.showError(_pinError!);
        }
      } else {
        _pinMatching = true;
        _pinError = null;
      }
    });
  }

  // Function to validate all fields and show errors if any
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate PIN
    _validatePin();
    if (widget.originalPin != null) {
      // For confirm PIN screen, check if PIN matches
      if (_pin.isNotEmpty && _pin.length == 4) {
        if (_pin.join() != widget.originalPin) {
          _errorStackKey.currentState?.showError(
            "PIN does not match. Try again.",
          );
          hasError = true;
        }
      }
    }

    if (_pinError != null && !_pinValid) {
      _errorStackKey.currentState?.showError(_pinError!);
      hasError = true;
    }

    if (_pin.isEmpty || _pin.length < 4) {
      _errorStackKey.currentState?.showError("Please enter 4 digits");
      hasError = true;
    }
  }

  void _onNext() async {
    final enteredPin = _pin.join();

    // Check if all fields are valid
    if (!_pinValid || !_pinMatching) {
      // Validate all fields and show errors if any
      _validateAllFieldsAndShowErrors();
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

  // Check if all required fields are valid
  bool get _allFieldsValid {
    if (widget.originalPin != null) {
      // For confirm PIN screen, need both valid AND matching
      return _pinValid && _pinMatching;
    } else {
      // For first PIN entry, just need valid
      return _pinValid && _pin.length == 4;
    }
  }

  // Helper method to build interactive buttons for tablet
  Widget _buildInteractiveButton({
    required String text,
    required VoidCallback onTap,
    required bool isEnabled,
    required bool isHovered,
    required bool isPressed,
    required VoidCallback onHoverEnter,
    required VoidCallback onHoverExit,
    required VoidCallback onTapDown,
    required VoidCallback onTapUp,
    required VoidCallback onTapCancel,
    double width = 106,
    double height = 40,
    bool useCustomButton = false,
  }) {
    return MouseRegion(
      onEnter: (_) => isEnabled ? onHoverEnter() : null,
      onExit: (_) => onHoverExit(),
      cursor: isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: isEnabled ? (_) => onTapDown() : null,
        onTapUp: isEnabled ? (_) => onTapUp() : null,
        onTapCancel: isEnabled ? onTapCancel : null,
        onTap: onTap,
        child: Transform.scale(
          scale: isEnabled && isPressed ? 0.95 : 1.0,
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isEnabled
                    ? const Color(0xFF00F0FF)
                    : const Color(0xFF4A5568),
                width: 1,
              ),
              color: isEnabled
                  ? (isHovered
                        ? const Color(0xFF00F0FF).withOpacity(0.15)
                        : isPressed
                        ? const Color(0xFF00F0FF).withOpacity(0.25)
                        : Colors.transparent)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 20,
                color: isEnabled ? Colors.white : const Color(0xFF718096),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Wrapper for NavButton to add interaction for tablet
  Widget _wrapNavButtonWithInteraction() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isBackHovered = true),
      onExit: (_) => setState(() => _isBackHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isBackPressed = true),
        onTapUp: (_) => setState(() => _isBackPressed = false),
        onTapCancel: () => setState(() => _isBackPressed = false),
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
        child: Transform.scale(
          scale: _isBackPressed ? 0.95 : 1.0,
          child: Container(
            width: 106,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF00F0FF), width: 1),
              color: _isBackHovered
                  ? const Color(0xFF00F0FF).withOpacity(0.15)
                  : _isBackPressed
                  ? const Color(0xFF00F0FF).withOpacity(0.25)
                  : Colors.transparent,
            ),
            alignment: Alignment.center,
            child: const Text(
              "Back",
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
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
          _errorStackKey.currentState?.showError(
            "Please complete PIN confirmation first",
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
                                              completedSteps:
                                                  widget.originalPin != null
                                                  ? 4
                                                  : 3,
                                            ),
                                          ),
                                          _ProgressSteps(
                                            originalPin: widget.originalPin,
                                          ),
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
                                                  color: filled
                                                      ? (_allFieldsValid
                                                            ? const Color(
                                                                0xFF00F0FF,
                                                              )
                                                            : const Color(
                                                                0xFFFF6B6B,
                                                              ))
                                                      : Colors.white
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
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 32,
                                                  color: filled
                                                      ? (_allFieldsValid
                                                            ? Colors.white
                                                            : const Color(
                                                                0xFFFF6B6B,
                                                              ))
                                                      : Colors.white,
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
                                      width: isLandscape ? 450 : 380,
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          _GradientLine(isLeft: true),
                                          // Back button with interaction
                                          _wrapNavButtonWithInteraction(),
                                          // Next button with interaction
                                          _buildInteractiveButton(
                                            text: "Next",
                                            onTap: () {
                                              if (_allFieldsValid) {
                                                _onNext();
                                              } else {
                                                _validateAllFieldsAndShowErrors();
                                              }
                                            },
                                            isEnabled: _allFieldsValid,
                                            isHovered: _isNextHovered,
                                            isPressed: _isNextPressed,
                                            onHoverEnter: () => setState(
                                              () => _isNextHovered = true,
                                            ),
                                            onHoverExit: () => setState(
                                              () => _isNextHovered = false,
                                            ),
                                            onTapDown: () => setState(
                                              () => _isNextPressed = true,
                                            ),
                                            onTapUp: () => setState(
                                              () => _isNextPressed = false,
                                            ),
                                            onTapCancel: () => setState(
                                              () => _isNextPressed = false,
                                            ),
                                          ),
                                          _GradientLine(isLeft: false),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 40),

                                    // ===== Footer =====
                                    FooterWidget(),

                                    // Add bottom spacing for landscape
                                    if (isLandscape)
                                      SizedBox(height: screenHeight * 0.1),
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

            // ErrorStack widget (it uses Overlay so it renders separately)
            ErrorStack(key: _errorStackKey),
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

           final gradientColors = [
            Color(0xFF00F0FF), 
            Color(0xFF0EA0BB), 
            Color(0xFF0764AD),
            Color(0xFF01259E), 
          ];

            final stops = List.generate(
            gradientColors.length,
            (i) => i / (gradientColors.length - 1),
          );


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
                    gradient: LinearGradient(
                    colors: gradientColors,
                  stops: stops,
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
  final String? originalPin;

  const _ProgressSteps({super.key, this.originalPin});

  @override
@override
Widget build(BuildContext context) {
  final steps = [
    {"label": "", "color": Color(0xFF00F0FF)},
    {"label": "", "color": Color(0xFF0EA0BB)},
    {"label": "", "color": Color(0xFF0764AD)},
    {"label": "Register Live", "color": Color(0xFF01259E)},
    {"label": "", "color": Colors.white},
  ];

  return SizedBox(
    width: double.infinity,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(
        steps.length,
        (index) {
          final step = steps[index];
          final filled = index <= 3; // mark first 4 as filled (adjust dynamically)
          return _buildStep(
            step["label"] as String,
            filled: filled,
            filledColor: step["color"] as Color,
          );
        },
      ),
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
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 8),
          if (label.isNotEmpty)
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: 14, // slightly smaller for multi-line
                height: 1.2, // better line spacing
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
