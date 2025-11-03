import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import "../services/auth_service.dart";
import 'package:flutter_project/widgets/footer_widgets.dart';

class RegisterPinScreen extends StatefulWidget {
  final String title;
  final String? originalPin; // optional: for confirmation step

  const RegisterPinScreen({super.key, required this.title, this.originalPin});

  @override
  State<RegisterPinScreen> createState() => _RegisterPinScreenState();
}

class _RegisterPinScreenState extends State<RegisterPinScreen> {
  final List<String> _pin = [];
  bool _obscurePin = true;

  late final List<String> _numbers;

  @override
  void initState() {
    super.initState();
    // Shuffle numbers only once when the page is created
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
      // Confirm PIN step - send to backend
      if (enteredPin == widget.originalPin) {
        try {
          await AuthService.registerPin(enteredPin); // Backend call

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PIN registered successfully!")),
          );

          // Navigate to next page (replace '/home' with your route)
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
      // First PIN entry - navigate to Confirm PIN
      if (_pin.length == 4) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterPinScreen(
              title: "Confirm PIN",
              originalPin: enteredPin,
            ),
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: 430,
          height: 932,
          child: Stack(
            children: [
              // ===== Top Buttons =====
              Positioned(
                top: 100,
                left: 99,
                width: 230,
                height: 40,
                child: Row(
                  children: [
                    Expanded(
                      child: _OutlinedButton(
                        text: 'Sign In',
                        onTap: () => Navigator.pushNamed(context, '/sign-in'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: _GradientButton(
                        text: 'Sign Up',
                        onTap: () => Navigator.pushNamed(context, '/sign-up'),
                      ),
                    ),
                  ],
                ),
              ),

              // ===== Subtitle =====
              const Positioned(
                top: 152,
                left: 65,
                child: Center(
                  child: Text(
                    "Protect Your Access",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // ===== Progress Steps =====
              Positioned(
                top: 200,
                left: 10,
                right: 0,
                child: SizedBox(
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 9.5,
                        left: 32,
                        right: 40,
                        child: _ProgressLine(totalSteps: 5, completedSteps: 2),
                      ),
                      const _ProgressSteps(),
                    ],
                  ),
                ),
              ),

              // ===== PIN Input Section =====
              Positioned(
                top: 240,
                left: 6,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 30,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w700,
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                setState(() => _obscurePin = !_obscurePin),
                            icon: Icon(
                              _obscurePin
                                  ? Ionicons.eye_off_outline
                                  : Ionicons.eye_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

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
                      const SizedBox(height: 25),

                      // Keypad
                      _Keypad(onKeyTap: _onKeyTap, numbers: _numbers),
                    ],
                  ),
                ),
              ),

              // ===== Bottom Navigation =====
              Positioned(
                top: 775,
                left: 15.5,
                child: SizedBox(
                  width: 399,
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _GradientLine(isLeft: true),
                      _NavButton(
                        text: "Back",
                        onTap: () => Navigator.pop(context),
                      ),
                      _NavButton(text: "Next", onTap: _onNext),
                      _GradientLine(isLeft: false),
                    ],
                  ),
                ),
              ),

              // ===== Footer =====
              Positioned(bottom: 20, left: 0, right: 0, child: FooterWidget()),
            ],
          ),
        ),
      ),
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
      _buildStep("Register\nPattern"),
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

// ===== Keypad =====
class _Keypad extends StatelessWidget {
  final void Function(String) onKeyTap;
  final List<String> numbers; // shuffled list from parent

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      fontSize: isLogout || isClear
                          ? 20
                          : 30, // smaller for Logout/Clear
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
      width: 105,
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
