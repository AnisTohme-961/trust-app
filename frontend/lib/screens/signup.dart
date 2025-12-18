import 'package:flutter/material.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'protect_access.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/services.dart';
import 'package:flutter_project/widgets/footer_widgets.dart';
import 'package:flutter_project/widgets/error_widgets.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<ErrorStackState> errorStackKey = GlobalKey<ErrorStackState>();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Use tablet view for screens wider than 600 pixels
    if (screenWidth >= 600) {
      return SignUpPageTablet(errorStackKey: errorStackKey);
    } else {
      return SignUpPageMobile(errorStackKey: errorStackKey);
    }
  }
}

class SignUpPageMobile extends StatefulWidget {
  final GlobalKey<ErrorStackState> errorStackKey;

  const SignUpPageMobile({super.key, required this.errorStackKey});

  @override
  State<SignUpPageMobile> createState() => _SignUpPageMobileState();
}

class _SignUpPageMobileState extends State<SignUpPageMobile> {
  bool _isButtonHovered = false;
  String _selectedGender = '';
  bool _isMaleHovered = false;
  bool _isFemaleHovered = false;
  bool _isNextHovered = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _sponsorController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  final FocusNode _firstFocusNode = FocusNode();
  final FocusNode _lastFocusNode = FocusNode();
  final FocusNode _sponsorFocusNode = FocusNode();

  // Validation states
  bool _firstNameValid = false;
  bool _lastNameValid = false;
  bool _genderValid = false;
  String? _firstNameError;
  String? _lastNameError;

  @override
  void initState() {
    super.initState();

    // Add focus listeners for validation on field exit
    _firstFocusNode.addListener(_validateFirstNameOnUnfocus);
    _lastFocusNode.addListener(_validateLastNameOnUnfocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>();

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _sponsorController.text = user.sponsorCode;
    _genderController.text = user.gender;
    _selectedGender = user.gender;

    // Validate initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFirstName();
      _validateLastName();
      _validateGender();
    });
  }

  @override
  void dispose() {
    _firstFocusNode.removeListener(_validateFirstNameOnUnfocus);
    _lastFocusNode.removeListener(_validateLastNameOnUnfocus);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sponsorController.dispose();
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    _sponsorFocusNode.dispose();
    super.dispose();
  }

  // Validation methods that trigger on field exit
  void _validateFirstNameOnUnfocus() {
    if (!_firstFocusNode.hasFocus && _firstNameController.text.isNotEmpty) {
      _validateFirstNameAndShowError();
    }
  }

  void _validateLastNameOnUnfocus() {
    if (!_lastFocusNode.hasFocus && _lastNameController.text.isNotEmpty) {
      _validateLastNameAndShowError();
    }
  }

  // Validation methods
  void _validateFirstName() {
    final firstName = _firstNameController.text.trim();

    if (firstName.isEmpty) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = null;
      });
      return;
    }

    if (firstName.length < 3) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = "First name must be at least 3 characters.";
      });
      return;
    }

    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!nameRegex.hasMatch(firstName)) {
      setState(() {
        _firstNameValid = false;
        _firstNameError =
            "First name can only include letters, apostrophes, hyphens, and spaces.";
      });
      return;
    }

    setState(() {
      _firstNameValid = true;
      _firstNameError = null;
    });
  }

  void _validateLastName() {
    final lastName = _lastNameController.text.trim();

    if (lastName.isEmpty) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = null;
      });
      return;
    }

    if (lastName.length < 3) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = "Last name must be at least 3 characters.";
      });
      return;
    }

    final lastNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!lastNameRegex.hasMatch(lastName)) {
      setState(() {
        _lastNameValid = false;
        _lastNameError =
            "Last name can only include letters, apostrophes, hyphens, and spaces.";
      });
      return;
    }

    setState(() {
      _lastNameValid = true;
      _lastNameError = null;
    });
  }

  void _validateGender() {
    setState(() {
      _genderValid = _selectedGender.isNotEmpty;
    });
  }

  // Validation methods that show errors when field loses focus
  void _validateFirstNameAndShowError() {
    final firstName = _firstNameController.text.trim();

    if (firstName.isEmpty) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = null;
      });
      return;
    }

    if (firstName.length < 3) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = "First name must be at least 3 characters.";
      });
      widget.errorStackKey.currentState?.showError(_firstNameError!);
      return;
    }

    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!nameRegex.hasMatch(firstName)) {
      setState(() {
        _firstNameValid = false;
        _firstNameError =
            "First name can only include letters, apostrophes, hyphens, and spaces.";
      });
      widget.errorStackKey.currentState?.showError(_firstNameError!);
      return;
    }

    setState(() {
      _firstNameValid = true;
      _firstNameError = null;
    });
  }

  void _validateLastNameAndShowError() {
    final lastName = _lastNameController.text.trim();

    if (lastName.isEmpty) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = null;
      });
      return;
    }

    if (lastName.length < 3) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = "Last name must be at least 3 characters.";
      });
      widget.errorStackKey.currentState?.showError(_lastNameError!);
      return;
    }

    final lastNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!lastNameRegex.hasMatch(lastName)) {
      setState(() {
        _lastNameValid = false;
        _lastNameError =
            "Last name can only include letters, apostrophes, hyphens, and spaces.";
      });
      widget.errorStackKey.currentState?.showError(_lastNameError!);
      return;
    }

    setState(() {
      _lastNameValid = true;
      _lastNameError = null;
    });
  }

  // Check if all required fields are valid
  bool get _allFieldsValid => _firstNameValid && _lastNameValid && _genderValid;

  // Function to validate all fields and show errors if any
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate first name
    final firstName = _firstNameController.text.trim();
    if (firstName.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        'Please enter your First Name.',
      );
      hasError = true;
    } else {
      _validateFirstName();
      if (_firstNameError != null && !_firstNameValid) {
        widget.errorStackKey.currentState?.showError(_firstNameError!);
        hasError = true;
      }
    }

    // Validate last name
    final lastName = _lastNameController.text.trim();
    if (lastName.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        'Please enter your last name.',
      );
      hasError = true;
    } else {
      _validateLastName();
      if (_lastNameError != null && !_lastNameValid) {
        widget.errorStackKey.currentState?.showError(_lastNameError!);
        hasError = true;
      }
    }

    // Validate gender
    _validateGender();
    if (!_genderValid) {
      widget.errorStackKey.currentState?.showError(
        "Please select your gender.",
      );
      hasError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpData = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Sign Up / Sign In buttons
                  SizedBox(
                    width: 230,
                    height: 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 126,
                          child: CustomButton(
                            text: 'Sign Up',
                            width: 104,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            onTap: () {},
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00F0FF).withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          child: CustomButton(
                            text: 'Sign In',
                            width: 106,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            onTap: () {
                              Navigator.pushNamed(context, '/sign-in');
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Title
                  const Text(
                    "Let's Start With You",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      height: 1.0,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Progress Steps
                  SizedBox(
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 9.5,
                          left: 32,
                          right: 32,
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStep("Profile\nStart", filled: true),
                              _buildStep(" "),
                              _buildStep(" "),
                              _buildStep(" "),
                              _buildStep(" "),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Name section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Your Real Name?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                focusNode: _firstFocusNode,
                                onChanged: (value) {
                                  // No auto-capitalization - preserve user's exact input
                                  context.read<UserProvider>().setFirstName(
                                    value,
                                  );
                                },
                                onEditingComplete: () {
                                  // Validate when user presses done/next
                                  _validateFirstNameAndShowError();
                                  // Move focus to next field
                                  FocusScope.of(
                                    context,
                                  ).requestFocus(_lastFocusNode);
                                },
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF00F0FF),
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  labelText: "First Name",
                                  labelStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.white54,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                focusNode: _lastFocusNode,
                                onChanged: (value) {
                                  // No auto-capitalization - preserve user's exact input
                                  context.read<UserProvider>().setLastName(
                                    value,
                                  );
                                },
                                onEditingComplete: () {
                                  // Validate when user presses done/next
                                  _validateLastNameAndShowError();
                                  // Remove focus
                                  FocusScope.of(context).unfocus();
                                },
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Color(0xFF00F0FF),
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  labelText: "Last Name",
                                  labelStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                    color: Colors.white54,
                                  ),
                                  floatingLabelStyle: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w500,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF00F0FF),
                                      width: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Sponsor section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        const Text(
                          "Who Invited You?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Stack(
                          children: [
                            TextField(
                              controller: _sponsorController,
                              focusNode: _sponsorFocusNode,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                context.read<UserProvider>().setSponsorCode(
                                  value,
                                );
                              },
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Color(0xFF00F0FF),
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 12,
                                ),
                                hintText: "Sponsor Code (Optional)",
                                hintStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.white54,
                                ),
                                labelText: "Sponsor",
                                labelStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 15,
                                  color: Colors.white54,
                                ),
                                floatingLabelStyle: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.auto,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00F0FF),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF00F0FF),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 10,
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                onEnter: (_) =>
                                    setState(() => _isButtonHovered = true),
                                onExit: (_) =>
                                    setState(() => _isButtonHovered = false),
                                child: GestureDetector(
                                  onTap: () async {
                                    if (_sponsorController.text.isEmpty) {
                                      ClipboardData? clipboardData =
                                          await Clipboard.getData(
                                            Clipboard.kTextPlain,
                                          );
                                      if (clipboardData != null &&
                                          clipboardData.text != null) {
                                        // Filter only digits from clipboard
                                        final digitsOnly = clipboardData.text!
                                            .replaceAll(RegExp(r'[^0-9]'), '');
                                        if (digitsOnly.isNotEmpty) {
                                          setState(() {
                                            _sponsorController.text =
                                                digitsOnly;
                                            signUpData.setSponsorCode(
                                              digitsOnly,
                                            );
                                          });
                                        } else {
                                          // Show error if clipboard doesn't contain digits
                                          widget.errorStackKey.currentState
                                              ?.showError(
                                                "Clipboard doesn't contain valid sponsor code (digits only).",
                                              );
                                        }
                                      }
                                    } else {
                                      setState(() {
                                        _sponsorController.clear();
                                        signUpData.setSponsorCode('');
                                      });
                                    }
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 62,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(7),
                                      border: Border.all(
                                        width: 1,
                                        color: const Color(0xFF00F0FF),
                                      ),
                                      gradient: _isButtonHovered
                                          ? const LinearGradient(
                                              begin: Alignment.bottomCenter,
                                              end: Alignment.topCenter,
                                              colors: [
                                                Color(0xFF0177B3),
                                                Color(0xFF00F0FF),
                                              ],
                                            )
                                          : null,
                                      color: _isButtonHovered
                                          ? null
                                          : Colors.transparent,
                                    ),
                                    child: Center(
                                      child: Text(
                                        _sponsorController.text.isEmpty
                                            ? "Paste"
                                            : "Clear",
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                          color: _isButtonHovered
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Gender section
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Your Official Gender?",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.0,
                            letterSpacing: 0,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildGenderButton(
                              "Male",
                              'assets/images/gender/Male.png',
                              _isMaleHovered,
                              _selectedGender == 'Male',
                              () {
                                setState(() => _selectedGender = 'Male');
                                context.read<UserProvider>().setGender('Male');
                                _validateGender();
                              },
                              (hovered) =>
                                  setState(() => _isMaleHovered = hovered),
                              23,
                              23,
                            ),
                            const SizedBox(width: 18),
                            _buildGenderButton(
                              "Female",
                              'assets/images/gender/Female.png',
                              _isFemaleHovered,
                              _selectedGender == 'Female',
                              () {
                                setState(() => _selectedGender = 'Female');
                                context.read<UserProvider>().setGender(
                                  'Female',
                                );
                                _validateGender();
                              },
                              (hovered) =>
                                  setState(() => _isFemaleHovered = hovered),
                              18,
                              29,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Next button with gradient lines
                  // Next button with gradient lines - Clean version
                  Container(
                    width: double.infinity,
                    height: 40,
                    child: Row(
                      children: [
                        // Left gradient line
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              top: 0,
                              right: 8,
                            ), // 8px space from button
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: const [
                                  Color(0xFF0B1320),
                                  Color(0xFF00F0FF),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Button
                        MouseRegion(
                          onEnter: (_) => _allFieldsValid
                              ? setState(() => _isNextHovered = true)
                              : null,
                          onExit: (_) => setState(() => _isNextHovered = false),
                          cursor: _allFieldsValid
                              ? SystemMouseCursors.click
                              : SystemMouseCursors.forbidden,
                          child: CustomButton(
                            text: "Next",
                            width: 106,
                            height: 40,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            borderRadius: 10,
                            borderColor: _allFieldsValid
                                ? const Color(0xFF00F0FF)
                                : const Color(0xFF4A5568),
                            textColor: _allFieldsValid
                                ? Colors.white
                                : const Color(0xFF718096),
                            backgroundColor: _allFieldsValid
                                ? (_isNextHovered
                                      ? const Color(
                                          0xFF00F0FF,
                                        ).withOpacity(0.15)
                                      : const Color(0xFF0B1320))
                                : const Color(0xFF0B1320),
                            onTap: () {
                              if (_allFieldsValid) {
                                _handleNextTap();
                              } else {
                                _validateAllFieldsAndShowErrors();
                              }
                            },
                          ),
                        ),

                        // Right gradient line
                        Expanded(
                          child: Container(
                            height: 4,
                            margin: EdgeInsets.only(
                              top: 0,
                              left: 8,
                            ), // 8px space from button
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              gradient: LinearGradient(
                                begin: Alignment.centerRight,
                                end: Alignment.centerLeft,
                                colors: const [
                                  Color(0xFF0B1320),
                                  Color(0xFF00F0FF),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 120),

                  // Quote text
                  const Text(
                    "Every system starts with its architect\nYou're laying the first stone of yours",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      height: 1.0,
                      letterSpacing: 0,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),
                  // Footer at the bottom
                  FooterWidget(),
                ],
              ),
            ),

            // ErrorStack widget (it uses Overlay so it renders separately)
            ErrorStack(key: widget.errorStackKey),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderButton(
    String gender,
    String iconPath,
    bool isHovered,
    bool isSelected,
    VoidCallback onTap,
    Function(bool) onHover,
    double iconWidth,
    double iconHeight,
  ) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 168,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(180),
            border: Border.all(width: 1, color: const Color(0xFF00F0FF)),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                  )
                : isHovered
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x2600F0FF), Color(0x260177B3)],
                  )
                : null,
            color: (isSelected || isHovered) ? null : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: iconWidth,
                height: iconHeight,
                color: isSelected ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 11),
              Text(
                gender,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNextTap() {
    // Navigate to next page (validation already done automatically)
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => ResponsiveProtectAccess(),
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildStep(String label, {bool filled = false}) {
    return SizedBox(
      height: 66,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: filled ? const Color(0xFF00F0FF) : Colors.white,
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
      ),
    );
  }
}

class SignUpPageTablet extends StatefulWidget {
  final GlobalKey<ErrorStackState> errorStackKey;

  const SignUpPageTablet({super.key, required this.errorStackKey});

  @override
  State<SignUpPageTablet> createState() => _SignUpPageTabletState();
}

class _SignUpPageTabletState extends State<SignUpPageTablet> {
  bool _isButtonHovered = false;
  String _selectedGender = '';
  bool _isMaleHovered = false;
  bool _isFemaleHovered = false;
  bool _isNextHovered = false;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _sponsorController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  final FocusNode _firstFocusNode = FocusNode();
  final FocusNode _lastFocusNode = FocusNode();
  final FocusNode _sponsorFocusNode = FocusNode();

  // Validation states
  bool _firstNameValid = false;
  bool _lastNameValid = false;
  bool _genderValid = false;
  String? _firstNameError;
  String? _lastNameError;

  @override
  void initState() {
    super.initState();

    // Add focus listeners for validation on field exit
    _firstFocusNode.addListener(_validateFirstNameOnUnfocus);
    _lastFocusNode.addListener(_validateLastNameOnUnfocus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>();

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _sponsorController.text = user.sponsorCode;
    _genderController.text = user.gender;
    _selectedGender = user.gender;

    // Validate initial values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _validateFirstName();
      _validateLastName();
      _validateGender();
    });
  }

  @override
  void dispose() {
    _firstFocusNode.removeListener(_validateFirstNameOnUnfocus);
    _lastFocusNode.removeListener(_validateLastNameOnUnfocus);
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sponsorController.dispose();
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    _sponsorFocusNode.dispose();
    super.dispose();
  }

  // Validation methods that trigger on field exit
  void _validateFirstNameOnUnfocus() {
    if (!_firstFocusNode.hasFocus && _firstNameController.text.isNotEmpty) {
      _validateFirstNameAndShowError();
    }
  }

  void _validateLastNameOnUnfocus() {
    if (!_lastFocusNode.hasFocus && _lastNameController.text.isNotEmpty) {
      _validateLastNameAndShowError();
    }
  }

  // Validation methods
  void _validateFirstName() {
    final firstName = _firstNameController.text.trim();

    if (firstName.isEmpty) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = null;
      });
      return;
    }

    if (firstName.length < 3) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = "First name must be at least 3 characters.";
      });
      return;
    }

    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!nameRegex.hasMatch(firstName)) {
      setState(() {
        _firstNameValid = false;
        _firstNameError =
            "First name can only include letters, apostrophes, hyphens, and spaces.";
      });
      return;
    }

    setState(() {
      _firstNameValid = true;
      _firstNameError = null;
    });
  }

  void _validateLastName() {
    final lastName = _lastNameController.text.trim();

    if (lastName.isEmpty) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = null;
      });
      return;
    }

    if (lastName.length < 3) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = "Last name must be at least 3 characters.";
      });
      return;
    }

    final lastNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!lastNameRegex.hasMatch(lastName)) {
      setState(() {
        _lastNameValid = false;
        _lastNameError =
            "Last name can only include letters, apostrophes, hyphens, and spaces.";
      });
      return;
    }

    setState(() {
      _lastNameValid = true;
      _lastNameError = null;
    });
  }

  void _validateGender() {
    setState(() {
      _genderValid = _selectedGender.isNotEmpty;
    });
  }

  // Validation methods that show errors when field loses focus
  void _validateFirstNameAndShowError() {
    final firstName = _firstNameController.text.trim();

    if (firstName.isEmpty) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = null;
      });
      return;
    }

    if (firstName.length < 3) {
      setState(() {
        _firstNameValid = false;
        _firstNameError = "First name must be at least 3 characters.";
      });
      widget.errorStackKey.currentState?.showError(_firstNameError!);
      return;
    }

    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!nameRegex.hasMatch(firstName)) {
      setState(() {
        _firstNameValid = false;
        _firstNameError =
            "First name can only include letters, apostrophes, hyphens, and spaces.";
      });
      widget.errorStackKey.currentState?.showError(_firstNameError!);
      return;
    }

    setState(() {
      _firstNameValid = true;
      _firstNameError = null;
    });
  }

  void _validateLastNameAndShowError() {
    final lastName = _lastNameController.text.trim();

    if (lastName.isEmpty) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = null;
      });
      return;
    }

    if (lastName.length < 3) {
      setState(() {
        _lastNameValid = false;
        _lastNameError = "Last name must be at least 3 characters.";
      });
      widget.errorStackKey.currentState?.showError(_lastNameError!);
      return;
    }

    final lastNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!lastNameRegex.hasMatch(lastName)) {
      setState(() {
        _lastNameValid = false;
        _lastNameError =
            "Last name can only include letters, apostrophes, hyphens, and spaces.";
      });
      widget.errorStackKey.currentState?.showError(_lastNameError!);
      return;
    }

    setState(() {
      _lastNameValid = true;
      _lastNameError = null;
    });
  }

  // Check if all required fields are valid
  bool get _allFieldsValid => _firstNameValid && _lastNameValid && _genderValid;

  // Function to validate all fields and show errors if any
  void _validateAllFieldsAndShowErrors() {
    bool hasError = false;

    // Validate first name
    _validateFirstName();
    if (_firstNameError != null && !_firstNameValid) {
      widget.errorStackKey.currentState?.showError(_firstNameError!);
      hasError = true;
    }

    // Validate last name
    _validateLastName();
    if (_lastNameError != null && !_lastNameValid) {
      widget.errorStackKey.currentState?.showError(_lastNameError!);
      hasError = true;
    }

    // Validate gender
    _validateGender();
    if (!_genderValid) {
      widget.errorStackKey.currentState?.showError(
        "Please select your gender.",
      );
      hasError = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final signUpData = Provider.of<UserProvider>(context);
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
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 30),
                                  // Sign Up / Sign In buttons
                                  SizedBox(
                                    width: 230,
                                    height: 50,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          left: 120,
                                          child: CustomButton(
                                            text: 'Sign Up',
                                            width: 106,
                                            height: 40,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            onTap: () {},
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF00F0FF),
                                                Color(0xFF0177B3),
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF00F0FF,
                                                ).withOpacity(0.5),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Positioned(
                                          left: 0,
                                          child: CustomButton(
                                            text: 'Sign In',
                                            width: 106,
                                            height: 40,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/sign-in',
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  // Title
                                  const Text(
                                    "Let's Start With You",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 30,
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Progress Steps - Make responsive
                                  SizedBox(
                                    width: isLandscape ? 500 : 420,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          top: 11,
                                          left: 40,
                                          right: 40,
                                          child: Container(
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              _buildStep(
                                                "Profile\nStart",
                                                filled: true,
                                              ),
                                              _buildStep("Contact\nand Verify"),
                                              _buildStep("Security\nBase"),
                                              _buildStep("Register\nLive"),
                                              _buildStep("Register\nPattern"),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // Name section - Make responsive
                                  SizedBox(
                                    width: isLandscape ? 450 : 380,
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Your Real Name?",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextField(
                                                controller:
                                                    _firstNameController,
                                                focusNode: _firstFocusNode,
                                                onChanged: (value) {
                                                  // No auto-capitalization - preserve user's exact input
                                                  context
                                                      .read<UserProvider>()
                                                      .setFirstName(value);
                                                },
                                                onEditingComplete: () {
                                                  // Validate when user presses done/next
                                                  _validateFirstNameAndShowError();
                                                  // Move focus to next field
                                                  FocusScope.of(
                                                    context,
                                                  ).requestFocus(
                                                    _lastFocusNode,
                                                  );
                                                },
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                  color: Color(0xFF00F0FF),
                                                ),
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15,
                                                      ),
                                                  labelText: "First Name",
                                                  labelStyle: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                    color: Colors.white54,
                                                  ),
                                                  floatingLabelStyle:
                                                      const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                      ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF00F0FF,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF00F0FF,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: TextField(
                                                controller: _lastNameController,
                                                focusNode: _lastFocusNode,
                                                onChanged: (value) {
                                                  // No auto-capitalization - preserve user's exact input
                                                  context
                                                      .read<UserProvider>()
                                                      .setLastName(value);
                                                },
                                                onEditingComplete: () {
                                                  // Validate when user presses done/next
                                                  _validateLastNameAndShowError();
                                                  // Remove focus
                                                  FocusScope.of(
                                                    context,
                                                  ).unfocus();
                                                },
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 15,
                                                  color: Color(0xFF00F0FF),
                                                ),
                                                decoration: InputDecoration(
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 15,
                                                      ),
                                                  labelText: "Last Name",
                                                  labelStyle: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 15,
                                                    color: Colors.white54,
                                                  ),
                                                  floatingLabelStyle:
                                                      const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                      ),
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF00F0FF,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF00F0FF,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // Sponsor section - Make responsive
                                  SizedBox(
                                    width: isLandscape ? 500 : 600,
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Who Invited You?",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            height: 1.0,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        SizedBox(
                                          width: isLandscape ? 400 : 378,
                                          child: Stack(
                                            children: [
                                              TextField(
                                                controller: _sponsorController,
                                                focusNode: _sponsorFocusNode,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [
                                                  FilteringTextInputFormatter
                                                      .digitsOnly,
                                                ],
                                                onChanged: (value) {
                                                  context
                                                      .read<UserProvider>()
                                                      .setSponsorCode(value);
                                                },
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 18,
                                                  color: Color(0xFF00F0FF),
                                                ),
                                                decoration: InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 16,
                                                      ),
                                                  hintText:
                                                      "Sponsor Code (Optional)",
                                                  hintStyle: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 18,
                                                    color: Colors.white54,
                                                  ),
                                                  labelText: "Sponsor",
                                                  labelStyle: const TextStyle(
                                                    fontFamily: 'Inter',
                                                    fontWeight: FontWeight.w500,
                                                    fontSize: 18,
                                                    color: Colors.white54,
                                                  ),
                                                  floatingLabelStyle:
                                                      const TextStyle(
                                                        fontFamily: 'Inter',
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 20,
                                                        color: Colors.white,
                                                      ),
                                                  floatingLabelBehavior:
                                                      FloatingLabelBehavior
                                                          .auto,
                                                  enabledBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF00F0FF,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                      ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: Color(
                                                                0xFF00F0FF,
                                                              ),
                                                              width: 1.5,
                                                            ),
                                                      ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 12,
                                                right: 15,
                                                child: MouseRegion(
                                                  cursor:
                                                      SystemMouseCursors.click,
                                                  onEnter: (_) => setState(
                                                    () =>
                                                        _isButtonHovered = true,
                                                  ),
                                                  onExit: (_) => setState(
                                                    () => _isButtonHovered =
                                                        false,
                                                  ),
                                                  child: GestureDetector(
                                                    onTap: () async {
                                                      if (_sponsorController
                                                          .text
                                                          .isEmpty) {
                                                        ClipboardData?
                                                        clipboardData =
                                                            await Clipboard.getData(
                                                              Clipboard
                                                                  .kTextPlain,
                                                            );
                                                        if (clipboardData !=
                                                                null &&
                                                            clipboardData
                                                                    .text !=
                                                                null) {
                                                          // Filter only digits from clipboard
                                                          final digitsOnly =
                                                              clipboardData
                                                                  .text!
                                                                  .replaceAll(
                                                                    RegExp(
                                                                      r'[^0-9]',
                                                                    ),
                                                                    '',
                                                                  );
                                                          if (digitsOnly
                                                              .isNotEmpty) {
                                                            setState(() {
                                                              _sponsorController
                                                                      .text =
                                                                  digitsOnly;
                                                              signUpData
                                                                  .setSponsorCode(
                                                                    digitsOnly,
                                                                  );
                                                            });
                                                          } else {
                                                            // Show error if clipboard doesn't contain digits
                                                            widget
                                                                .errorStackKey
                                                                .currentState
                                                                ?.showError(
                                                                  "Clipboard doesn't contain valid sponsor code (digits only).",
                                                                );
                                                          }
                                                        }
                                                      } else {
                                                        setState(() {
                                                          _sponsorController
                                                              .clear();
                                                          signUpData
                                                              .setSponsorCode(
                                                                '',
                                                              );
                                                        });
                                                      }
                                                    },
                                                    child: AnimatedContainer(
                                                      duration: const Duration(
                                                        milliseconds: 200,
                                                      ),
                                                      width: 70,
                                                      height: 35,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        border: Border.all(
                                                          width: 1.5,
                                                          color: const Color(
                                                            0xFF00F0FF,
                                                          ),
                                                        ),
                                                        gradient:
                                                            _isButtonHovered
                                                            ? const LinearGradient(
                                                                begin: Alignment
                                                                    .bottomCenter,
                                                                end: Alignment
                                                                    .topCenter,
                                                                colors: [
                                                                  Color(
                                                                    0xFF0177B3,
                                                                  ),
                                                                  Color(
                                                                    0xFF00F0FF,
                                                                  ),
                                                                ],
                                                              )
                                                            : null,
                                                        color: _isButtonHovered
                                                            ? null
                                                            : Colors
                                                                  .transparent,
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          _sponsorController
                                                                  .text
                                                                  .isEmpty
                                                              ? "Paste"
                                                              : "Clear",
                                                          style: TextStyle(
                                                            fontFamily: 'Inter',
                                                            fontWeight:
                                                                FontWeight.w500,
                                                            fontSize: 16,
                                                            color:
                                                                _isButtonHovered
                                                                ? Colors.black
                                                                : Colors.white,
                                                          ),
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
                                  ),

                                  const SizedBox(height: 25),

                                  // Gender section
                                  SizedBox(
                                    width: isLandscape ? 500 : 600,
                                    child: Column(
                                      children: [
                                        const Text(
                                          "Your Official Gender?",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontWeight: FontWeight.w600,
                                            fontSize: 20,
                                            height: 1.0,
                                            letterSpacing: 0,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            _buildGenderButton(
                                              "Male",
                                              'assets/images/gender/Male.png',
                                              _isMaleHovered,
                                              _selectedGender == 'Male',
                                              () {
                                                setState(
                                                  () =>
                                                      _selectedGender = 'Male',
                                                );
                                                context
                                                    .read<UserProvider>()
                                                    .setGender('Male');
                                                _validateGender();
                                              },
                                              (hovered) => setState(
                                                () => _isMaleHovered = hovered,
                                              ),
                                              28,
                                              28,
                                            ),
                                            const SizedBox(width: 25),
                                            _buildGenderButton(
                                              "Female",
                                              'assets/images/gender/Female.png',
                                              _isFemaleHovered,
                                              _selectedGender == 'Female',
                                              () {
                                                setState(
                                                  () => _selectedGender =
                                                      'Female',
                                                );
                                                context
                                                    .read<UserProvider>()
                                                    .setGender('Female');
                                                _validateGender();
                                              },
                                              (hovered) => setState(
                                                () =>
                                                    _isFemaleHovered = hovered,
                                              ),
                                              22,
                                              35,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 40),

                                  // Next button with gradient lines - Make responsive
                                  SizedBox(
                                    width: isLandscape ? 450 : 500,
                                    height: 50,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned(
                                          top: 25,
                                          left: 25,
                                          child: Container(
                                            width: isLandscape ? 100 : 100,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: _allFieldsValid
                                                    ? const [
                                                        Color(0xFF0B1320),
                                                        Color(0xFF00F0FF),
                                                      ]
                                                    : const [
                                                        Color(0xFF0B1320),
                                                        Color(0xFF4A5568),
                                                      ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        MouseRegion(
                                          onEnter: (_) => _allFieldsValid
                                              ? setState(
                                                  () => _isNextHovered = true,
                                                )
                                              : null,
                                          onExit: (_) => setState(
                                            () => _isNextHovered = false,
                                          ),
                                          cursor: _allFieldsValid
                                              ? SystemMouseCursors.click
                                              : SystemMouseCursors.forbidden,
                                          child: CustomButton(
                                            text: "Next",
                                            width: 106,
                                            height: 40,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            borderRadius: 12,
                                            borderColor: _allFieldsValid
                                                ? const Color(0xFF00F0FF)
                                                : const Color(0xFF4A5568),
                                            textColor: _allFieldsValid
                                                ? Colors.white
                                                : const Color(0xFF718096),
                                            backgroundColor: _allFieldsValid
                                                ? (_isNextHovered
                                                      ? const Color(
                                                          0xFF00F0FF,
                                                        ).withOpacity(0.15)
                                                      : const Color(0xFF0B1320))
                                                : const Color(0xFF0B1320),
                                            onTap: () {
                                              if (_allFieldsValid) {
                                                _handleNextTap();
                                              } else {
                                                // Validate all fields and show errors if any
                                                _validateAllFieldsAndShowErrors();
                                              }
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          top: 25,
                                          right: 25,
                                          child: Container(
                                            width: isLandscape ? 100 : 100,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(11),
                                              gradient: LinearGradient(
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                                colors: _allFieldsValid
                                                    ? const [
                                                        Color(0xFF0B1320),
                                                        Color(0xFF00F0FF),
                                                      ]
                                                    : const [
                                                        Color(0xFF0B1320),
                                                        Color(0xFF4A5568),
                                                      ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 70),

                                  // Quote text
                                  const Text(
                                    "Every system starts with its architect\nYou're laying the first stone of yours",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 20,
                                      height: 1,
                                      letterSpacing: 0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

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

                    // Bottom right image - positioned at the bottom right of the screen
                    Positioned(
                      bottom: 0,
                      right: -10,
                      child: Image.asset(
                        'assets/images/Rectangle2.png',
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

          // ErrorStack widget (it uses Overlay so it renders separately)
          ErrorStack(key: widget.errorStackKey),
        ],
      ),
    );
  }

  Widget _buildGenderButton(
    String gender,
    String iconPath,
    bool isHovered,
    bool isSelected,
    VoidCallback onTap,
    Function(bool) onHover,
    double iconWidth,
    double iconHeight,
  ) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 173,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(180),
            border: Border.all(width: 1.5, color: const Color(0xFF00F0FF)),
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF00F0FF), Color(0xFF0177B3)],
                  )
                : isHovered
                ? const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0x2600F0FF), Color(0x260177B3)],
                  )
                : null,
            color: (isSelected || isHovered) ? null : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                iconPath,
                width: iconWidth,
                height: iconHeight,
                color: isSelected ? Colors.black : Colors.white,
              ),
              const SizedBox(width: 15),
              Text(
                gender,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNextTap() {
    // Navigate to next page (validation already done automatically)
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, __, ___) => ResponsiveProtectAccess(),
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Column _buildStep(String label, {bool filled = false}) {
    return Column(
      children: [
        SizedBox(
          width: 23.7,
          height: 23.7,
          child: CircleAvatar(
            backgroundColor: filled ? const Color(0xFF00F0FF) : Colors.white,
            child: filled
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        ),

        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.0,
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
