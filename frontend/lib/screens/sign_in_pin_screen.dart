import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../widgets/footer_widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter_project/providers/font_size_provider.dart';

import '../widgets/error_widgets.dart';

class SignInPinScreen extends StatefulWidget {
  const SignInPinScreen({super.key});

  @override
  State<SignInPinScreen> createState() => _SignInPinScreenState();
}

class _SignInPinScreenState extends State<SignInPinScreen> {
  bool showPatternLines = false;
  bool isEyeVisible = true;
  bool _obscurePin = true;
  List<String> _pin = [];
  bool _isPinValid = false; // Track if PIN is valid (backend validated)
  bool _isValidating = false; // Track if validation is in progress
  bool _hasValidationError = false; // Track if we have a validation error
  Timer? _validationTimer; // Timer for debouncing validation
  Timer? _clearPinTimer; // Timer to clear PIN after error

  // Button hover and press states
  bool _isBackHovered = false;
  bool _isBackPressed = false;
  bool _isLogoutHovered = false;
  bool _isLogoutPressed = false;
  bool _isKeypadNextHovered = false;
  bool _isKeypadNextPressed = false;

  // Reference to the ErrorStackState to show errors
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // Generate numbers 0–9 and shuffle
  List<String> _numbers = List.generate(10, (i) => i.toString())
    ..shuffle(Random());

  void _onKeyTap(String key) async {
    // 1) Handle NEXT (Navigate after validation)
    if (key == 'Next') {
      if (!_isPinValid) {
        return; // Button should be disabled, but just in case
      }

      // SUCCESS - Navigate to settings
      debugPrint('✅ Correct PIN entered! Navigating to settings...');
      Navigator.pushNamed(context, '/settings');
      return;
    }

    // 2) For BACKSPACE
    if (key == 'Back') {
      // Cancel any pending clear timer
      _clearPinTimer?.cancel();

      // Reset error state when user starts editing again
      if (_hasValidationError) {
        setState(() {
          _hasValidationError = false;
          _pin.clear();
        });
      } else {
        setState(() {
          if (_pin.isNotEmpty) {
            _pin.removeLast();
            _isPinValid = false; // Reset validation when PIN changes
            _hasValidationError = false; // Reset error state
            if (_pin.length == 4) {
              // If we still have 4 digits after backspace, re-validate
              _schedulePinValidation();
            }
          }
        });
      }
      return;
    }

    // 3) For number keys (0–9)
    if (_pin.length < 4) {
      // Cancel any pending clear timer
      _clearPinTimer?.cancel();

      // Clear error state when user starts typing again
      if (_hasValidationError) {
        setState(() {
          _hasValidationError = false;
          _pin.clear();
          _pin.add(key);
        });
      } else {
        setState(() {
          _pin.add(key);
          if (_pin.length == 4) {
            // When we have 4 digits, schedule validation
            _schedulePinValidation();
          } else {
            // If less than 4 digits, reset validation
            _isPinValid = false;
            _hasValidationError = false;
          }
        });
      }
    }
  }

  // Schedule PIN validation with debounce
  void _schedulePinValidation() {
    // Cancel any pending validation
    _validationTimer?.cancel();

    // Schedule new validation after a short delay (debounce)
    _validationTimer = Timer(Duration(milliseconds: 500), () {
      _validatePinWithBackend();
    });
  }

  // Validate PIN with backend
  Future<void> _validatePinWithBackend() async {
    if (_pin.length != 4) {
      return;
    }

    setState(() {
      _isValidating = true;
      _hasValidationError = false;
    });

    try {
      String enteredPin = _pin.join();
      bool isValid = await AuthService.validatePin(enteredPin);

      setState(() {
        if (isValid) {
          _isPinValid = true;
          _hasValidationError = false;
          _isValidating = false;
        } else {
          // PIN is invalid - show red borders briefly, then clear
          _hasValidationError = true;
          _isPinValid = false;
          _isValidating = false;

          // Show error message
          _errorStackKey.currentState?.showError(
            'Incorrect Pin. Try Again.',
            duration: Duration(seconds: 3),
          );

          // Schedule clearing of PIN after showing red borders briefly
          _clearPinTimer = Timer(Duration(milliseconds: 1500), () {
            if (mounted) {
              setState(() {
                _pin.clear(); // Clear the PIN digits
                _hasValidationError = false; // Reset error state after clearing
              });
            }
          });
        }
      });
    } catch (e) {
      setState(() {
        _isPinValid = false;
        _hasValidationError = true;
        _isValidating = false;
      });
      print("Validation error: $e");

      // Show error for network/backend issues
      _errorStackKey.currentState?.showError(
        'Validation failed. Please try again.',
        duration: Duration(seconds: 3),
      );

      // Schedule clearing of PIN after showing red borders briefly
      _clearPinTimer = Timer(Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _pin.clear(); // Clear the PIN digits
            _hasValidationError = false; // Reset error state after clearing
          });
        }
      });
    }
  }

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
    _validationTimer?.cancel();
    _clearPinTimer?.cancel();
    super.dispose();
  }

  Widget buildBackAndLogoutButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 0, bottom: 20),
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

          // Back Button with hover and click effects
          MouseRegion(
            onEnter: (_) => setState(() => _isBackHovered = true),
            onExit: (_) => setState(() => _isBackHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isBackPressed = true),
              onTapUp: (_) => setState(() => _isBackPressed = false),
              onTapCancel: () => setState(() => _isBackPressed = false),
              child: Transform.scale(
                scale: _isBackPressed ? 0.95 : 1.0,
                child: CustomButton(
                  text: 'Back',
                  width: 100,
                  height: 45,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  borderRadius: 10,
                  borderColor: const Color(0xFF00F0FF),
                  textColor: Colors.white,
                  backgroundColor: _isBackHovered
                      ? const Color(0xFF00F0FF).withOpacity(0.15)
                      : _isBackPressed
                      ? const Color(0xFF00F0FF).withOpacity(0.25)
                      : const Color(0xFF0B1320),
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Logout Button with hover and click effects
          MouseRegion(
            onEnter: (_) => setState(() => _isLogoutHovered = true),
            onExit: (_) => setState(() => _isLogoutHovered = false),
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTapDown: (_) => setState(() => _isLogoutPressed = true),
              onTapUp: (_) => setState(() => _isLogoutPressed = false),
              onTapCancel: () => setState(() => _isLogoutPressed = false),
              child: Transform.scale(
                scale: _isLogoutPressed ? 0.95 : 1.0,
                child: CustomButton(
                  text: 'Logout',
                  width: 120,
                  height: 45,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  borderRadius: 10,
                  borderColor: const Color(0xFF00F0FF),
                  textColor: Colors.white,
                  backgroundColor: _isLogoutHovered
                      ? const Color(0xFF00F0FF).withOpacity(0.15)
                      : _isLogoutPressed
                      ? const Color(0xFF00F0FF).withOpacity(0.25)
                      : const Color(0xFF0B1320),
                  onTap: () async {
                    await _logout();
                  },
                ),
              ),
            ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final fontProvider = Provider.of<FontSizeProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Image.asset(
                      'assets/images/egetyPerfectStar.png',
                      width: 111,
                      height: 126,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Text(
                    'Egety Trust',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Title row with eye icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Enter PIN To Continue",
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isEyeVisible = !isEyeVisible;
                            _obscurePin = !_obscurePin;
                          });
                        },
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Image.asset(
                            isEyeVisible
                                ? 'assets/images/whiteEyeSlash.png'
                                : 'assets/images/whiteEye.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // PIN Boxes with validation indicator
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          final filled = index < _pin.length;
                          Color borderColor;

                          // Determine border color based on validation state
                          if (_hasValidationError) {
                            borderColor = Color(0xFFFF0000); // Red for error
                          } else if (_isPinValid) {
                            borderColor = Color(0xFF00F0FF); // Blue for valid
                          } else if (filled) {
                            borderColor = Colors.white.withOpacity(
                              0.9,
                            ); // White for filled but not validated
                          } else {
                            borderColor = Colors.white.withOpacity(
                              0.9,
                            ); // White for empty
                          }

                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            width: 50,
                            height: 60,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: borderColor,
                                width: _hasValidationError || _isPinValid
                                    ? 2
                                    : 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              filled ? (_obscurePin ? '*' : _pin[index]) : '',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 24,
                                color: _hasValidationError
                                    ? Color(0xFFFF0000)
                                    : Colors.white,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      // Validation status indicator
                      if (_pin.length == 4 && _isValidating)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF00F0FF),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Validating...',
                              style: TextStyle(
                                color: Color(0xFF00F0FF),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      if (_hasValidationError && _pin.isEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Color(0xFFFF0000),
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Incorrect PIN - Please try again',
                              style: TextStyle(
                                color: Color(0xFFFF0000),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Keypad
                  _Keypad(
                    onKeyTap: _onKeyTap,
                    numbers: _numbers,
                    isPinValid: _isPinValid,
                    isPinComplete: _pin.length == 4,
                    isValidating: _isValidating,
                    hasValidationError: _hasValidationError,
                    isKeypadNextHovered: _isKeypadNextHovered,
                    isKeypadNextPressed: _isKeypadNextPressed,
                    onKeypadNextHoverChanged: (isHovered) {
                      setState(() => _isKeypadNextHovered = isHovered);
                    },
                    onKeypadNextPressChanged: (isPressed) {
                      setState(() => _isKeypadNextPressed = isPressed);
                    },
                  ),

                  const SizedBox(height: 10),

                  // Forgot Pin / Use Pattern row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          debugPrint('Forgot Pin tapped');
                        },
                        child: Text(
                          'Forgot Pin?',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: fontProvider.getScaledSize(15),
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/sign-in-pattern');
                        },
                        child: Text(
                          'Use Pattern Instead',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: fontProvider.getScaledSize(15),
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF00F0FF),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  buildBackAndLogoutButtons(),
                  const SizedBox(height: 30),
                  FooterWidget(),
                ],
              ),
            ),
          ),

          // 🧱 ErrorStack always on top
          ErrorStack(key: _errorStackKey),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final List<String> numbers;
  final bool isPinValid; // PIN is validated by backend
  final bool isPinComplete; // PIN has 4 digits (but may not be validated yet)
  final bool isValidating; // Validation in progress
  final bool hasValidationError; // PIN validation failed
  final bool isKeypadNextHovered;
  final bool isKeypadNextPressed;
  final Function(bool) onKeypadNextHoverChanged;
  final Function(bool) onKeypadNextPressChanged;

  const _Keypad({
    required this.onKeyTap,
    required this.numbers,
    required this.isPinValid,
    required this.isPinComplete,
    required this.isValidating,
    required this.hasValidationError,
    required this.isKeypadNextHovered,
    required this.isKeypadNextPressed,
    required this.onKeypadNextHoverChanged,
    required this.onKeypadNextPressChanged,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = [
      [numbers[0], numbers[1], numbers[2]],
      [numbers[3], numbers[4], numbers[5]],
      [numbers[6], numbers[7], numbers[8]],
      ['Back', numbers[9], 'Next'],
    ];

    return Column(
      children: List.generate(buttons.length, (rowIndex) {
        final row = buttons[rowIndex];
        final isLastRow = rowIndex == buttons.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastRow ? 0 : 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((text) {
              final isBack = text == 'Back';
              final isNext = text == 'Next';

              // Determine Next button border color - ALWAYS grey unless valid
              Color nextButtonBorderColor;
              Color nextButtonTextColor;
              Color nextButtonBackgroundColor;

              if (isPinValid) {
                nextButtonBorderColor = Color(0xFF00F0FF); // Blue when valid
                nextButtonTextColor = Colors.white; // White text when valid
                nextButtonBackgroundColor = isKeypadNextHovered
                    ? Color(0xFF00F0FF).withOpacity(0.15)
                    : isKeypadNextPressed
                    ? Color(0xFF00F0FF).withOpacity(0.25)
                    : Color(0xFF0B1320);
              } else {
                nextButtonBorderColor = Color(
                  0xFF4A5568,
                ); // Grey when not valid
                nextButtonTextColor = Color(
                  0xFF718096,
                ); // Grey text when not valid
                nextButtonBackgroundColor = Color(0xFF0B1320);
              }

              // For Next button, wrap it with MouseRegion and GestureDetector
              if (isNext) {
                return MouseRegion(
                  onEnter: (_) =>
                      isPinValid ? onKeypadNextHoverChanged(true) : null,
                  onExit: (_) => onKeypadNextHoverChanged(false),
                  cursor: isPinValid
                      ? SystemMouseCursors.click
                      : SystemMouseCursors.forbidden,
                  child: GestureDetector(
                    onTapDown: isPinValid
                        ? (_) => onKeypadNextPressChanged(true)
                        : null,
                    onTapUp: isPinValid
                        ? (_) {
                            onKeypadNextPressChanged(false);
                            onKeyTap(text);
                          }
                        : null,
                    onTapCancel: isPinValid
                        ? () => onKeypadNextPressChanged(false)
                        : null,
                    child: Transform.scale(
                      scale: isPinValid && isKeypadNextPressed ? 0.95 : 1.0,
                      child: Container(
                        width: 103,
                        height: 49,
                        decoration: BoxDecoration(
                          color: nextButtonBackgroundColor,
                          border: Border.all(
                            color: nextButtonBorderColor,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        alignment: Alignment.center,
                        child:
                            isPinComplete &&
                                !isPinValid &&
                                !hasValidationError &&
                                isValidating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              )
                            : Text(
                                text,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: nextButtonTextColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              }

              // For other buttons (numbers and Back), keep existing behavior
              return GestureDetector(
                onTap: () => onKeyTap(text),
                child: Container(
                  width: 103,
                  height: 49,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isBack
                          ? (hasValidationError
                                ? Color(0xFFFF0000)
                                : Color(0xFFFF0000)) // Red for back button
                          : Color(0xFF00F0FF), // Blue for number buttons
                      width: isBack ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: isBack
                      ? Image.asset(
                          'assets/images/whiteBackArrow.png',
                          width: 25,
                          height: 25,
                          color: hasValidationError
                              ? Color(0xFFFF0000)
                              : Colors.white,
                          fit: BoxFit.contain,
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            }).toList(),
          ),
        );
      }),
    );
  }
}
