import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../widgets/custom_button.dart';
import '../services/auth_service.dart';
import '../widgets/footer_widgets.dart';
import '../widgets/error_widgets.dart'; // Make sure you import your ErrorStack file path correctly

class SignInRegisterPinScreen extends StatefulWidget {
  const SignInRegisterPinScreen({super.key});

  @override
  State<SignInRegisterPinScreen> createState() =>
      _SignInRegisterPinScreenState();
}

class _SignInRegisterPinScreenState extends State<SignInRegisterPinScreen> {
  bool showPatternLines = false;
  bool isEyeVisible = true;
  bool _obscurePin = true;
  List<String> _pin = [];

  // Reference to the ErrorStackState to show errors
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();

  // Example of correct PIN (you can change this or fetch dynamically)
  final String correctPin = "1234";

  // Generate numbers 0–9 and shuffle
  List<String> _numbers = List.generate(10, (i) => i.toString())
    ..shuffle(Random());

  void _onKeyTap(String key) {
    setState(() {
      if (key == 'Next') {
        if (_pin.isEmpty) {
          _errorStackKey.currentState?.showError(
            'Please Enter Your Pin.',
            duration: const Duration(seconds: 3),
          );
        } else if (_pin.join() != correctPin) {
          _errorStackKey.currentState?.showError(
            'Incorrect Pin. Try Again.',
            duration: const Duration(seconds: 3),
          );
          _pin.clear();
        } else {
          debugPrint('✅ Correct PIN entered: ${_pin.join()}');
          // Continue to next step here...
        }
      } else if (key == 'Back') {
        if (_pin.isNotEmpty) {
          _pin.removeLast();
        }
      } else if (_pin.length < 4) {
        _pin.add(key);
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
          CustomButton(
            text: 'Back',
            width: 100,
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
            width: 120,
            height: 45,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            textColor: Colors.white,
            borderColor: const Color(0xFF00F0FF),
            backgroundColor: const Color(0xFF0B1320),
            onTap: () async {
              await _logout();
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 75.0),
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

                  // PIN Boxes
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final filled = index < _pin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 18),
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
                          filled ? (_obscurePin ? '*' : _pin[index]) : '',
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

                  const SizedBox(height: 10),

                  // Forgot Pin / Use Pattern row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          debugPrint('Forgot Pin tapped');
                        },
                        child: const Text(
                          'Forgot Pin?',
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
                          debugPrint('Use Pattern Instead tapped');
                        },
                        child: const Text(
                          'Use Pattern Instead',
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

  const _Keypad({required this.onKeyTap, required this.numbers});

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

              return GestureDetector(
                onTap: () => onKeyTap(text),
                child: Container(
                  width: 103,
                  height: 49,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isBack ? Colors.red : const Color(0xFF00F0FF),
                      width: isBack || isNext ? 3 : 1,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: isBack
                      ? Image.asset(
                          'assets/images/whiteBackArrow.png',
                          width: 25,
                          height: 25,
                          fit: BoxFit.contain,
                        )
                      : Text(
                          text,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: isNext
                                ? FontWeight.w500
                                : FontWeight.w800,
                            fontSize: isNext ? 20 : 30,
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
