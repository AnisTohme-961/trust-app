import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_navigation_widget.dart';
import '../widgets/slide_up_menu_widget.dart';
import '../widgets/error_widgets.dart';
import '../providers/font_size_provider.dart';
import '../services/auth_service.dart';

// Custom painter for pattern lines
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

class FreezeAccount extends StatefulWidget {
  const FreezeAccount({super.key});

  @override
  State<FreezeAccount> createState() => _FreezeAccountState();
}

class _FreezeAccountState extends State<FreezeAccount> {
  // Menu visibility states
  bool _showUnfreezeMenu = false;
  bool _showPatternMenu = false;
  bool _showVerificationMenu = false;

  // PIN Input State for Unfreeze
  final List<String> _unfreezePin = [];
  bool _obscureUnfreezePin = true;
  bool _unfreezePinError = false;
  List<String> _unfreezeNumbers = List.generate(10, (i) => i.toString());

  // Pattern Grid State
  final int _patternGridSize = 3;
  List<int> _selectedPatternDots = [];
  bool _patternCompleted = false;
  final GlobalKey<ErrorStackState> _errorStackKey =
      GlobalKey<ErrorStackState>();
  final double _patternDotSize = 17;
  final GlobalKey _gridKey = GlobalKey();
  bool _showPatternLines = true;
  bool _isPatternEyeVisible = true;

  // Verification State
  final TextEditingController _verificationEmailController =
      TextEditingController();
  bool _showEmailCodeSent = false;
  bool _showSMSCodeSent = false;
  bool _showAuthCodeSent = false;

  final Map<String, bool> _isButtonClickedMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  final Map<String, bool> _hasCodeBeenSentMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  final List<TextEditingController> _emailCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _emailFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _emailCode = List.generate(6, (_) => '');

  final List<TextEditingController> _smsCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _smsFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _smsCode = List.generate(6, (_) => '');

  final List<TextEditingController> _authCodeControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _authFocusNodes = List.generate(6, (_) => FocusNode());
  List<String> _authCode = List.generate(6, (_) => '');

  Map<String, bool> isCodeCorrectMap = {
    'email': false,
    'sms': false,
    'auth': false,
  };

  Map<String, bool> isCodeValidMap = {'email': true, 'sms': true, 'auth': true};

  Map<String, int> _countdowns = {'email': 0, 'sms': 0, 'auth': 0};
  Map<String, Timer?> _timers = {'email': null, 'sms': null, 'auth': null};
  String? _activeCodeType;
  bool _codeDisabled = false;

  // Unfreeze text controller
  final TextEditingController _unfreezeTextController = TextEditingController();
  bool _showCheckImage = false;

  @override
  void initState() {
    super.initState();
    // Shuffle numbers for security
    _unfreezeNumbers.shuffle();

    // Listen to unfreeze text field changes
    _unfreezeTextController.addListener(_onUnfreezeTextChanged);
  }

  void _onUnfreezeTextChanged() {
    final text = _unfreezeTextController.text;
    setState(() {
      _showCheckImage = text == 'UNFREEZE ACCOUNT';
    });
  }

  bool _areUnfreezeConditionsMet() {
    return _unfreezeTextController.text == 'UNFREEZE ACCOUNT' &&
        _unfreezePin.length == 4 &&
        !_unfreezePinError;
  }

  bool _verifyUnfreezePin() {
    // This is a mock verification. Replace with your actual PIN verification logic
    const correctPin =
        '1234'; // Replace with actual PIN from your backend/secure storage

    if (_unfreezePin.join() == correctPin) {
      // PIN is correct
      setState(() {
        _unfreezePinError = false;
      });
      print("PIN verified successfully");
      return true;
    } else {
      // PIN is incorrect
      setState(() {
        _unfreezePinError = true;
      });

      _errorStackKey.currentState?.showError("Incorrect Pin. Try Again.");

      // Clear PIN fields after showing error
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _unfreezePin.clear();
          });
        }
      });
      return false;
    }
  }

  void _handleUnfreezeNextTap() {
    if (_areUnfreezeConditionsMet()) {
      // First check if PIN is 4 digits and correct
      if (_unfreezePin.length == 4 && !_unfreezePinError) {
        // PIN is valid, proceed to pattern menu
        _openPatternMenu();
      } else if (_unfreezePin.length < 4) {
        _errorStackKey.currentState?.showError('Enter 4 digits PIN first');
      } else if (_unfreezePinError) {
        _errorStackKey.currentState?.showError('Incorrect PIN. Try again.');
      }
    } else {
      // Show appropriate error message for incomplete conditions
      if (_unfreezeTextController.text != 'UNFREEZE ACCOUNT') {
        _errorStackKey.currentState?.showError(
          'Please enter "UNFREEZE ACCOUNT" first',
        );
      } else if (_unfreezePin.length < 4) {
        _errorStackKey.currentState?.showError('Enter 4 digits PIN first');
      }
    }
  }

  void _toggleUnfreezeMenu() {
    setState(() {
      _showUnfreezeMenu = !_showUnfreezeMenu;
      _showPatternMenu = false;
      _showVerificationMenu = false;

      if (_showUnfreezeMenu) {
        _unfreezePin.clear();
        _unfreezeNumbers.shuffle();
        _unfreezeTextController.clear();
        _showCheckImage = false;
        _unfreezePinError = false;
      }
    });
  }

  void _togglePatternMenu() {
    setState(() {
      _showPatternMenu = !_showPatternMenu;
      _showUnfreezeMenu = false;
      _showVerificationMenu = false;

      if (_showPatternMenu) {
        _selectedPatternDots = [];
        _patternCompleted = false;
        _showPatternLines = true;
        _isPatternEyeVisible = true;
      }
    });
  }

  void _toggleVerificationMenu() {
    setState(() {
      _showVerificationMenu = !_showVerificationMenu;
      _showUnfreezeMenu = false;
      _showPatternMenu = false;

      if (_showVerificationMenu) {
        // Reset all verification states
        _verificationEmailController.clear();
        _showEmailCodeSent = false;
        _showSMSCodeSent = false;
        _showAuthCodeSent = false;
        for (var c in _emailCodeControllers) c.clear();
        for (var c in _smsCodeControllers) c.clear();
        for (var c in _authCodeControllers) c.clear();
        _emailCode = List.generate(6, (_) => '');
        _smsCode = List.generate(6, (_) => '');
        _authCode = List.generate(6, (_) => '');
        isCodeCorrectMap = {'email': false, 'sms': false, 'auth': false};
        isCodeValidMap = {'email': true, 'sms': true, 'auth': true};
        _countdowns = {'email': 0, 'sms': 0, 'auth': 0};
        _activeCodeType = null;
        _codeDisabled = false;
      }
    });
  }

  void _openPatternMenu() {
    setState(() {
      _showUnfreezeMenu = false;
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _showPatternMenu = true;
        });
      });
    });
  }

  void _openVerificationMenuFromPattern() {
    setState(() {
      _showPatternMenu = false;
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          _showVerificationMenu = true;
        });
      });
    });
  }

  void _closeAllMenus() {
    setState(() {
      _showUnfreezeMenu = false;
      _showPatternMenu = false;
      _showVerificationMenu = false;
    });
  }

  // Pattern Grid Methods
  void _onPatternPanStart(DragStartDetails details) {
    setState(() {
      _selectedPatternDots = [];
      _patternCompleted = false;
    });
  }

  void _onPatternPanUpdate(DragUpdateDetails details) {
    RenderBox? box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;

    Offset localPos = box.globalToLocal(details.globalPosition);
    double cellSize = box.size.width / _patternGridSize;
    int row = (localPos.dy / cellSize).floor();
    int col = (localPos.dx / cellSize).floor();
    int idx = row * _patternGridSize + col;

    if (row >= 0 &&
        row < _patternGridSize &&
        col >= 0 &&
        col < _patternGridSize &&
        !_selectedPatternDots.contains(idx)) {
      setState(() {
        _selectedPatternDots.add(idx);
      });
    }
  }

  void _onPatternPanEnd(DragEndDetails details) {
    if (_selectedPatternDots.length >= 4) {
      setState(() {
        _patternCompleted = true;
      });
      print("Pattern entered: $_selectedPatternDots");
    } else {
      _errorStackKey.currentState?.showError("Minimum 4 dots required");
      setState(() {
        _selectedPatternDots = [];
        _patternCompleted = false;
      });
    }
  }

  // PIN Input Methods
  void _onUnfreezeKeyTap(String value) {
    setState(() {
      if (value == 'Clear') {
        _unfreezePin.clear();
        _unfreezePinError = false;
      } else if (value == 'leftArrow') {
        if (_unfreezePin.isNotEmpty) {
          _unfreezePin.removeLast();
        }
        _unfreezePinError = false;
      } else {
        if (_unfreezePin.length < 4) {
          _unfreezePin.add(value);
          _unfreezePinError = false;

          // Automatically validate when PIN reaches 4 digits
          if (_unfreezePin.length == 4) {
            _verifyUnfreezePin();
          }
        }
      }
    });
  }

  void _handlePatternNextTap() {
    if (_selectedPatternDots.length >= 4) {
      print("Pattern entered: $_selectedPatternDots");

      // Clear the pattern lines before opening verification menu
      setState(() {
        _selectedPatternDots = [];
        _patternCompleted = false;
      });

      _openVerificationMenuFromPattern();
    } else {
      _errorStackKey.currentState?.showError("Minimum 4 dots required");
      // Clear the pattern so user has to start fresh
      setState(() {
        _selectedPatternDots = [];
        _patternCompleted = false;
      });
    }
  }

  // Verification Methods
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

  void _fetchCode(String type) async {
    if (_activeCodeType != null && _activeCodeType != type) return;
    if (_countdowns[type]! > 0) return;

    if (_verificationEmailController.text.isEmpty) {
      _errorStackKey.currentState?.showError("Please enter your EID / Email");
      return;
    }

    final identifier = _verificationEmailController.text.trim();

    try {
      Map<String, dynamic> data;

      if (type == "auth") {
        data = await AuthService.generateTOTP(identifier);
      } else {
        data = await AuthService.sendResetCode(identifier);
      }

      final int cooldown = data["cooldown"] ?? 60;

      // Show "Code Sent"
      _setCodeSentFlag(type, true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _setCodeSentFlag(type, false);
      });

      // Start cooldown + disable ALL buttons
      setState(() {
        _activeCodeType = type;
        _countdowns[type] = cooldown;
        _codeDisabled = true;
      });

      _timers[type]?.cancel();
      _timers[type] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        setState(() {
          if (_countdowns[type]! > 0) {
            _countdowns[type] = _countdowns[type]! - 1;
          } else {
            timer.cancel();
            _timers[type] = null;
            _activeCodeType = null;
            _codeDisabled = false;
          }
        });
      });
    } catch (e) {
      _errorStackKey.currentState?.showError(
        "Failed to send code. Please try again.",
      );
    }
  }

  void _setCodeSentFlag(String type, bool value) {
    setState(() {
      if (type == 'email') _showEmailCodeSent = value;
      if (type == 'sms') _showSMSCodeSent = value;
      if (type == 'auth') _showAuthCodeSent = value;
    });
  }

  void _onVerificationCodeChanged(
    String value,
    int index,
    List<String> codeList,
    List<FocusNode> focusNodes,
    String type,
  ) async {
    codeList[index] = value.isEmpty ? '' : value[0];

    if (value.isNotEmpty && index < focusNodes.length - 1) {
      focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      focusNodes[index - 1].requestFocus();
    }

    // Reset validity while typing
    setState(() {
      isCodeValidMap[type] = true;
      isCodeCorrectMap[type] = false;
    });

    // Only verify when all digits are filled
    if (codeList.every((c) => c.isNotEmpty)) {
      final email = _verificationEmailController.text.trim();
      bool valid = false;

      try {
        if (type == 'auth') {
          valid = await AuthService.verifyTOTP(
            email: email,
            code: codeList.join(),
          );
        } else {
          valid = await AuthService.verifyResetCode(
            identifier: email,
            code: codeList.join(),
          );
        }

        if (valid) {
          setState(() {
            isCodeCorrectMap[type] = true;
            isCodeValidMap[type] = true;
          });
          _timers[type]?.cancel();
          _timers[type] = null;
          _countdowns[type] = 0;
        } else {
          setState(() {
            isCodeValidMap[type] = false;
            isCodeCorrectMap[type] = false;
          });

          Timer(const Duration(seconds: 3), () {
            if (!mounted) return;
            setState(() {
              List<TextEditingController> controllers;
              switch (type) {
                case 'email':
                  controllers = _emailCodeControllers;
                  break;
                case 'sms':
                  controllers = _smsCodeControllers;
                  break;
                case 'auth':
                  controllers = _authCodeControllers;
                  break;
                default:
                  return;
              }

              for (var i = 0; i < controllers.length; i++) {
                controllers[i].clear();
                codeList[i] = '';
              }
              isCodeValidMap[type] = true;
              isCodeCorrectMap[type] = false;
            });
            focusNodes[0].requestFocus();
          });
        }
      } catch (e) {
        setState(() {
          isCodeValidMap[type] = false;
          isCodeCorrectMap[type] = false;
        });

        Timer(const Duration(seconds: 3), () {
          if (!mounted) return;
          setState(() {
            List<TextEditingController> controllers;
            switch (type) {
              case 'email':
                controllers = _emailCodeControllers;
                break;
              case 'sms':
                controllers = _smsCodeControllers;
                break;
              case 'auth':
                controllers = _authCodeControllers;
                break;
              default:
                return;
            }

            for (var i = 0; i < controllers.length; i++) {
              controllers[i].clear();
              codeList[i] = '';
            }
            isCodeValidMap[type] = true;
            isCodeCorrectMap[type] = false;
          });
          focusNodes[0].requestFocus();
        });
      }
    }

    setState(() {});
  }

  void _onButtonClick(String type) async {
    if (_countdowns[type]! > 0) return;

    if (_verificationEmailController.text.isEmpty) {
      _errorStackKey.currentState?.showError("Please enter your EID / Email");
      return;
    }

    setState(() {
      _isButtonClickedMap[type] = true;
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isButtonClickedMap[type] = false;
        });
      }
    });

    final identifier = _verificationEmailController.text.trim();

    try {
      Map<String, dynamic> data;

      if (type == "auth") {
        data = await AuthService.generateTOTP(identifier);
      } else {
        data = await AuthService.sendResetCode(identifier);
      }

      final int cooldown = data["cooldown"] ?? 60;

      setState(() {
        _hasCodeBeenSentMap[type] = true;
      });

      if (type == 'email') _showEmailCodeSent = true;
      if (type == 'sms') _showSMSCodeSent = true;
      if (type == 'auth') _showAuthCodeSent = true;

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            if (type == 'email') _showEmailCodeSent = false;
            if (type == 'sms') _showSMSCodeSent = false;
            if (type == 'auth') _showAuthCodeSent = false;
          });
        }
      });

      setState(() {
        _activeCodeType = type;
        _countdowns[type] = cooldown;
        _codeDisabled = false;
      });

      _timers[type]?.cancel();
      _timers[type] = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;

        setState(() {
          if (_countdowns[type]! > 0) {
            _countdowns[type] = _countdowns[type]! - 1;
          } else {
            timer.cancel();
            _timers[type] = null;
            _activeCodeType = null;
            _codeDisabled = false;
          }
        });
      });
    } catch (e) {
      _errorStackKey.currentState?.showError(
        "Failed to send code. Please try again.",
      );
    }
  }

  Widget _buildUnfreezeKeypad() {
    if (_unfreezeNumbers.isEmpty) {
      _unfreezeNumbers = List.generate(10, (i) => i.toString())..shuffle();
    }

    final buttons = [
      [_unfreezeNumbers[0], _unfreezeNumbers[1], _unfreezeNumbers[2]],
      [_unfreezeNumbers[3], _unfreezeNumbers[4], _unfreezeNumbers[5]],
      [_unfreezeNumbers[6], _unfreezeNumbers[7], _unfreezeNumbers[8]],
      ['Clear', _unfreezeNumbers[9], 'leftArrow'],
    ];

    return Column(
      children: buttons.map((row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: row.map((text) {
              final isLeftArrow = text == 'leftArrow';
              final isClear = text == 'Clear';

              return GestureDetector(
                onTap: () => _onUnfreezeKeyTap(text),
                child: Container(
                  width: 104,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isLeftArrow
                          ? const Color(0xFF00F0FF)
                          : (isClear
                                ? const Color(0xFFFF0000)
                                : const Color(0xFF00F0FF)),
                      width: isLeftArrow || isClear ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  alignment: Alignment.center,
                  child: isLeftArrow
                      ? SvgPicture.asset(
                          'assets/images/leftArrowWhite.svg',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        )
                      : isClear
                      ? Text(
                          'clear',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          text,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
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

  Widget _buildVerificationEmailInput() {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.92;
    bool hasText = _verificationEmailController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: containerWidth,
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
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Image.asset(
                    'assets/images/SVGRepo_iconCarrier.png',
                    width: 20,
                    height: 20,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _verificationEmailController,
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'EID / Email',
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
                  text: hasText ? 'Clear' : 'Paste',
                  width: 65,
                  height: 32,
                  fontSize: 15,
                  textColor: Colors.white,
                  backgroundColor: const Color(0xFF0B1320),
                  borderColor: const Color(0xFF00F0FF),
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  onTap: () async {
                    if (hasText) {
                      _verificationEmailController.clear();
                    } else {
                      final clipboardData = await Clipboard.getData(
                        'text/plain',
                      );
                      final text = clipboardData?.text;
                      if (text != null) {
                        _verificationEmailController.text = text;
                      }
                    }
                    setState(() {});
                  },
                ),
              ],
            ),
          ),
          if (hasText)
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

  Widget _buildVerificationSection({
    required String title,
    required List<TextEditingController> codeControllers,
    required List<FocusNode> focusNodes,
    required List<String> codeList,
    required String type,
  }) {
    bool isCodeCorrect = isCodeCorrectMap[type] ?? false;
    bool isCodeValid = isCodeValidMap[type] ?? true;
    bool showCodeSent = type == 'email'
        ? _showEmailCodeSent
        : type == 'sms'
        ? _showSMSCodeSent
        : _showAuthCodeSent;
    int secondsLeft = _countdowns[type] ?? 0;
    bool isButtonClicked = _isButtonClickedMap[type] ?? false;
    bool hasCodeBeenSent = _hasCodeBeenSentMap[type] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: SizedBox(
        height: 85,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -4,
              left: -1,
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  height: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
            if (showCodeSent)
              Positioned(
                top: 25,
                left: 50,
                child: Container(
                  width: 110,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F0FF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    "Code Sent",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            if (!showCodeSent)
              Positioned(
                top: 12,
                left: 0,
                child: Row(
                  children: [
                    ...List.generate(6, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 35,
                              height: 35,
                              child: TextField(
                                controller: codeControllers[index],
                                focusNode: focusNodes[index],
                                showCursor: !_codeDisabled,
                                enabled: !_codeDisabled,
                                readOnly: _codeDisabled,
                                textAlign: TextAlign.center,
                                maxLength: 1,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: _codeDisabled
                                      ? Colors.grey
                                      : isCodeCorrect
                                      ? const Color(0xFF00F0FF)
                                      : (isCodeValid == false
                                            ? Colors.red
                                            : Colors.white),
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                cursorColor: _codeDisabled
                                    ? Colors.grey
                                    : isCodeCorrect
                                    ? const Color(0xFF00F0FF)
                                    : (isCodeValid == false
                                          ? Colors.red
                                          : Colors.white),
                                decoration: const InputDecoration(
                                  counterText: "",
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (value) =>
                                    _onVerificationCodeChanged(
                                      value,
                                      index,
                                      codeList,
                                      focusNodes,
                                      type,
                                    ),
                              ),
                            ),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: 35,
                              height: isCodeCorrect ? 0 : 2,
                              color: _codeDisabled
                                  ? Colors.grey
                                  : isCodeCorrect
                                  ? Colors.transparent
                                  : (isCodeValid == false
                                        ? Colors.red
                                        : Colors.white),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (isCodeCorrect || isCodeValid == false)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, top: 10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCodeCorrect
                                ? const Color(0xFF00F0FF)
                                : Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCodeCorrect ? Icons.check : Icons.close,
                            color: isCodeCorrect ? Colors.black : Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Positioned(
              top: 21,
              left: 277,
              child: GestureDetector(
                onTap: (secondsLeft == 0) ? () => _onButtonClick(type) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  width: 90,
                  height: 26,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: isButtonClicked
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
                              spreadRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: secondsLeft > 0
                        ? Text(
                            formatCooldown(secondsLeft),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 18,
                              color: Colors.black,
                            ),
                          )
                        : Text(
                            hasCodeBeenSent ? "Send Again" : "Get Code",
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _unfreezeTextController.dispose();
    _verificationEmailController.dispose();
    for (var c in _emailCodeControllers) c.dispose();
    for (var f in _emailFocusNodes) f.dispose();
    for (var c in _smsCodeControllers) c.dispose();
    for (var f in _smsFocusNodes) f.dispose();
    for (var c in _authCodeControllers) c.dispose();
    for (var f in _authFocusNodes) f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final unfreezeMenuHeight = screenHeight * 0.9;
    final patternMenuHeight = screenHeight * 0.62;
    final verificationMenuHeight = screenHeight * 0.7;
    final fontProvider = Provider.of<FontSizeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Main content
          Container(
            width: double.infinity,
            height: double.infinity,
            color: const Color(0xFF0B1320),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 186),
                  // SVG Image
                  SvgPicture.asset(
                    'assets/images/frozenIcon.svg',
                    width: 120,
                    height: 120,
                  ),

                  const SizedBox(height: 24),
                  // Text content
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: Text(
                      'Your account is frozen,\nunfreeze it to continue\nyour activity',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 90),
                  // Unfreeze Button - This triggers the unfreeze flow
                  CustomButton(
                    text: 'Unfreeze',
                    onTap: _toggleUnfreezeMenu,
                    width: 106,
                    height: 40,
                    borderColor: const Color(0xFF00F0FF),
                    textColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    borderRadius: 10,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),

                  const SizedBox(height: 90),
                  // Custom Navigation Widget with Delete Account and Switch Account buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.0),
                    child: CustomNavigationWidget(
                      leftText: 'Delete Account',
                      onClickLeftButton: () {
                        print('Delete Account button tapped');
                      },
                      rightText: 'Switch Account',
                      onClickRightButton: () {
                        print('Switch Account button tapped');
                      },
                      leftButtonWidth: 155,
                      leftButtonHeight: 40,
                      leftFontSize: 20,
                      leftFontWeight: FontWeight.w600,
                      leftTextColor: Colors.white,
                      leftBorderColor: const Color(0xFF00F0FF),
                      leftBackgroundColor: Colors.transparent,
                      leftBorderRadius: 10,
                      rightButtonWidth: 162,
                      rightButtonHeight: 40,
                      rightFontSize: 20,
                      rightFontWeight: FontWeight.w600,
                      rightTextColor: Colors.white,
                      rightBorderColor: const Color(0xFF00F0FF),
                      rightBackgroundColor: Colors.transparent,
                      rightBorderRadius: 10,
                      lineHeight: 4,
                      lineRadius: 11,
                      spacing: 16,
                      startGradientColor: const Color(0xFF00F0FF),
                      endGradientColor: const Color(0xFF0B1320),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay
          if (_showUnfreezeMenu || _showPatternMenu || _showVerificationMenu)
            GestureDetector(
              onTap: _closeAllMenus,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Unfreeze Menu
          SlideUpMenu(
            menuHeight: unfreezeMenuHeight,
            isVisible: _showUnfreezeMenu,
            onToggle: _toggleUnfreezeMenu,
            onClose: _closeAllMenus,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/freezeIcon.svg',
                          width: 32,
                          height: 32,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Unfreeze Account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Your account will be reactivated',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Please type "',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: 'UNFREEZE ACCOUNT',
                            style: TextStyle(
                              fontSize: 20,
                              color: Color(0xFF00FEFF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text: '" below to unfreeze your account',
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      child: Container(
                        width: double.infinity,
                        alignment: Alignment.centerLeft,
                        child: Stack(
                          children: [
                            Container(
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: Colors.white,
                                    width: 1.1,
                                  ),
                                ),
                              ),
                              child: TextField(
                                controller: _unfreezeTextController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.left,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.only(bottom: 8),
                                ),
                              ),
                            ),
                            if (_showCheckImage)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 8,
                                child: Image.asset(
                                  'assets/images/blueCircleCheck.png',
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.contain,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // PIN Input Section for Unfreeze
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Enter PIN To Continue',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: 28,
                                color: Colors.white,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                () =>
                                    _obscureUnfreezePin = !_obscureUnfreezePin,
                              ),
                              icon: Icon(
                                _obscureUnfreezePin
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (index) {
                            final filled = index < _unfreezePin.length;
                            return Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              width: 50,
                              height: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _unfreezePinError && filled
                                      ? const Color(0xFFFF0000)
                                      : Colors.white.withOpacity(0.9),
                                  width: _unfreezePinError && filled ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(3),
                                color: Colors.transparent,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                filled
                                    ? (_obscureUnfreezePin
                                          ? '*'
                                          : _unfreezePin[index])
                                    : '',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: fontProvider.getScaledSize(24),
                                  color: _unfreezePinError && filled
                                      ? const Color(0xFFFF0000)
                                      : Colors.white,
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 30),

                        _buildUnfreezeKeypad(),

                        const SizedBox(height: 20),

                        // CustomNavigationWidget for Unfreeze
                        CustomNavigationWidget(
                          onClickLeftButton: _closeAllMenus,
                          onClickRightButton: _handleUnfreezeNextTap,
                          leftText: "Cancel",
                          rightText: "Next",
                          leftButtonWidth: 106,
                          leftButtonHeight: 40,
                          leftFontSize: 20,
                          leftFontWeight: FontWeight.w600,
                          leftTextColor: Colors.white,
                          leftBorderColor: const Color(0xFF00F0FF),
                          leftBackgroundColor: Colors.transparent,
                          leftBorderRadius: 10,
                          rightButtonWidth: 106,
                          rightButtonHeight: 40,
                          rightFontSize: 20,
                          rightFontWeight: FontWeight.w600,
                          rightTextColor: _areUnfreezeConditionsMet()
                              ? Colors.white
                              : const Color(0xFF718096),
                          rightBorderColor: _areUnfreezeConditionsMet()
                              ? const Color(0xFF00F0FF)
                              : const Color(0xFF4A5568),
                          rightBackgroundColor: Colors.transparent,
                          rightBorderRadius: 10,
                          lineHeight: 4,
                          lineRadius: 11,
                          spacing: 16,
                          startGradientColor: const Color(0xFF00F0FF),
                          endGradientColor: const Color(0xFF0B1320),
                          isRightButtonEnabled: _areUnfreezeConditionsMet(),
                          rightDisabledTextColor: const Color(0xFF718096),
                          rightDisabledBorderColor: const Color(0xFF4A5568),
                          onRightButtonDisabledTap: () {
                            if (_unfreezeTextController.text !=
                                'UNFREEZE ACCOUNT') {
                              _errorStackKey.currentState?.showError(
                                'Please enter "UNFREEZE ACCOUNT" first',
                              );
                            } else if (_unfreezePin.length < 4) {
                              _errorStackKey.currentState?.showError(
                                'Please Enter 4 digits PIN first',
                              );
                            } else if (_unfreezePinError) {
                              _errorStackKey.currentState?.showError(
                                'Incorrect PIN. Try again.',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Pattern Menu (same as freeze)
          SlideUpMenu(
            menuHeight: patternMenuHeight,
            isVisible: _showPatternMenu,
            onToggle: _togglePatternMenu,
            onClose: _closeAllMenus,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Enter Pattern To Continue',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 25,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showPatternLines = !_showPatternLines;
                              _isPatternEyeVisible = !_isPatternEyeVisible;
                            });
                          },
                          child: Image.asset(
                            _isPatternEyeVisible
                                ? 'assets/images/whiteEye.png'
                                : 'assets/images/whiteEyeSlash.png',
                            width: 24,
                            height: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          key: _gridKey,
                          width: 280,
                          height: 280,
                          child: GestureDetector(
                            onPanStart: _onPatternPanStart,
                            onPanUpdate: _onPatternPanUpdate,
                            onPanEnd: _onPatternPanEnd,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                double cellSize =
                                    constraints.maxWidth / _patternGridSize;
                                List<Offset> dotCenters = [];
                                for (
                                  int row = 0;
                                  row < _patternGridSize;
                                  row++
                                ) {
                                  for (
                                    int col = 0;
                                    col < _patternGridSize;
                                    col++
                                  ) {
                                    double x = (col + 0.5) * cellSize;
                                    double y = (row + 0.5) * cellSize;
                                    dotCenters.add(Offset(x, y));
                                  }
                                }

                                return Stack(
                                  children: [
                                    Opacity(
                                      opacity: _patternCompleted ? 0.7 : 1.0,
                                      child: Stack(
                                        children: [
                                          if (_showPatternLines)
                                            CustomPaint(
                                              size: Size.infinite,
                                              painter: _PatternPainter(
                                                selectedDots:
                                                    _selectedPatternDots,
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
                                                  _patternDotSize / 2,
                                              top:
                                                  dotCenters[i].dy -
                                                  _patternDotSize / 2,
                                              child: Container(
                                                width: _patternDotSize,
                                                height: _patternDotSize,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: _showPatternLines
                                                      ? (_selectedPatternDots
                                                                .contains(i)
                                                            ? const Color(
                                                                0xFF00F0FF,
                                                              )
                                                            : Colors.white)
                                                      : Colors.white,
                                                  boxShadow:
                                                      (_showPatternLines &&
                                                          _selectedPatternDots
                                                              .contains(i))
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

                    const SizedBox(height: 20),

                    // CustomNavigationWidget for Pattern Menu
                    CustomNavigationWidget(
                      onClickLeftButton: _closeAllMenus,
                      onClickRightButton: _handlePatternNextTap,
                      leftText: "Cancel",
                      rightText: "Next",
                      leftButtonWidth: 106,
                      leftButtonHeight: 40,
                      leftFontSize: 20,
                      leftFontWeight: FontWeight.w600,
                      leftTextColor: Colors.white,
                      leftBorderColor: const Color(0xFF00F0FF),
                      leftBackgroundColor: Colors.transparent,
                      leftBorderRadius: 10,
                      rightButtonWidth: 106,
                      rightButtonHeight: 40,
                      rightFontSize: 20,
                      rightFontWeight: FontWeight.w600,
                      rightTextColor: _selectedPatternDots.length >= 4
                          ? Colors.white
                          : const Color(0xFF718096),
                      rightBorderColor: _selectedPatternDots.length >= 4
                          ? const Color(0xFF00F0FF)
                          : const Color(0xFF4A5568),
                      rightBackgroundColor: Colors.transparent,
                      rightBorderRadius: 10,
                      lineHeight: 4,
                      lineRadius: 11,
                      spacing: 16,
                      startGradientColor: const Color(0xFF00F0FF),
                      endGradientColor: const Color(0xFF0B1320),
                      isRightButtonEnabled: _selectedPatternDots.length >= 4,
                      rightDisabledTextColor: const Color(0xFF718096),
                      rightDisabledBorderColor: const Color(0xFF4A5568),
                      onRightButtonDisabledTap: () {
                        _errorStackKey.currentState?.showError(
                          "Minimum 4 dots required",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Verification Menu (same as freeze)
          SlideUpMenu(
            menuHeight: verificationMenuHeight,
            isVisible: _showVerificationMenu,
            onToggle: _toggleVerificationMenu,
            onClose: _closeAllMenus,
            dragHandle: SvgPicture.asset(
              'assets/images/vLine.svg',
              width: 90,
              height: 9,
              fit: BoxFit.contain,
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),

                    // Title
                    const Text(
                      'Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Description
                    Text(
                      'Please enter your email address or EID\nfor verification.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: fontProvider.getScaledSize(15),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Email/EID Input
                    Center(child: _buildVerificationEmailInput()),
                    const SizedBox(height: 30),

                    // Verification Sections
                    _buildVerificationSection(
                      title: 'Email Verification',
                      codeControllers: _emailCodeControllers,
                      focusNodes: _emailFocusNodes,
                      codeList: _emailCode,
                      type: 'email',
                    ),
                    const SizedBox(height: 10),

                    _buildVerificationSection(
                      title: 'SMS Verification',
                      codeControllers: _smsCodeControllers,
                      focusNodes: _smsFocusNodes,
                      codeList: _smsCode,
                      type: 'sms',
                    ),
                    const SizedBox(height: 10),

                    _buildVerificationSection(
                      title: 'Authenticator App',
                      codeControllers: _authCodeControllers,
                      focusNodes: _authFocusNodes,
                      codeList: _authCode,
                      type: 'auth',
                    ),
                    const SizedBox(height: 15),

                    // CustomNavigationWidget for Verification Menu
                    CustomNavigationWidget(
                      onClickLeftButton: _closeAllMenus,
                      onClickRightButton: () {
                        _closeAllMenus();
                        Navigator.pushReplacementNamed(context, '/sign-in');
                      },
                      leftText: "Cancel",
                      rightText: "Next",
                      leftButtonWidth: 106,
                      leftButtonHeight: 40,
                      leftFontSize: 20,
                      leftFontWeight: FontWeight.w600,
                      leftTextColor: Colors.white,
                      leftBorderColor: const Color(0xFF00F0FF),
                      leftBackgroundColor: Colors.transparent,
                      leftBorderRadius: 10,
                      rightButtonWidth: 106,
                      rightButtonHeight: 40,
                      rightFontSize: 20,
                      rightFontWeight: FontWeight.w600,
                      rightTextColor: Colors.white,
                      rightBorderColor: const Color(0xFF00F0FF),
                      rightBackgroundColor: Colors.transparent,
                      rightBorderRadius: 10,
                      lineHeight: 4,
                      lineRadius: 11,
                      spacing: 16,
                      startGradientColor: const Color(0xFF00F0FF),
                      endGradientColor: const Color(0xFF0B1320),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

          // Error Stack
          ErrorStack(key: _errorStackKey),
        ],
      ),
    );
  }
}
