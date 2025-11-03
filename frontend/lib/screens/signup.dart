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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>();

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _sponsorController.text = user.sponsorCode;
    _genderController.text = user.gender;
    _selectedGender = user.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sponsorController.dispose();
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    _sponsorFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final signUpData = Provider.of<UserProvider>(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: Stack(
        children: [
          // Your existing mobile layout code here...
          // [Include all the Positioned widgets from your original mobile code]
          Positioned(
            width: 430,
            height: 932,
            child: Stack(
              children: [
                // Sign Up / Sign In buttons
                Positioned(
                  top: 100,
                  left: 99,
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

                // Title
                Positioned(
                  top: 152,
                  left: 67,
                  width: 296,
                  height: 36,
                  child: Center(
                    child: Text(
                      "Let's Start With You",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w700,
                        fontSize: 30,
                        height: 1.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Progress Steps
                Positioned(
                  top: 200,
                  left: 0,
                  right: 10,
                  child: SizedBox(
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
                ),

                // Name section
                Positioned(
                  top: 280,
                  left: 18,
                  child: SizedBox(
                    width: 394,
                    height: 86,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 0),
                        const SizedBox(
                          width: double.infinity,
                          height: 23,
                          child: Text(
                            "Your Real Name?",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _firstNameController,
                                focusNode: _firstFocusNode,
                                onChanged: (value) {
                                  context.read<UserProvider>().setFirstName(
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
                            SizedBox(
                              width: 180,
                              child: TextField(
                                controller: _lastNameController,
                                focusNode: _lastFocusNode,
                                onChanged: (value) {
                                  context.read<UserProvider>().setLastName(
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
                ),
              ],
            ),
          ),

          // Sponsor section
          Positioned(
            top: 385,
            left: 18,
            child: SizedBox(
              width: 394,
              child: Column(
                children: [
                  const SizedBox(
                    width: double.infinity,
                    height: 24,
                    child: Text(
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
                  ),
                  const SizedBox(height: 10),
                  Stack(
                    children: [
                      SizedBox(
                        width: 374,
                        child: TextField(
                          controller: _sponsorController,
                          focusNode: _sponsorFocusNode,
                          onChanged: (value) {
                            context.read<UserProvider>().setSponsorCode(value);
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
                            hintText: "Sponsor Code or link (Optional)",
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
                            floatingLabelBehavior: FloatingLabelBehavior.auto,
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
                                  setState(() {
                                    _sponsorController.text =
                                        clipboardData.text!;
                                    signUpData.setSponsorCode(
                                      clipboardData.text!,
                                    );
                                  });
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
          ),

          // Gender section
          Positioned(
            top: 490,
            left: 18,
            child: SizedBox(
              width: 394,
              height: 84,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 0),
                  const SizedBox(
                    width: 237.27,
                    height: 24,
                    child: Text(
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
                  ),
                  const SizedBox(height: 10),
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
                        },
                        (hovered) => setState(() => _isMaleHovered = hovered),
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
                          context.read<UserProvider>().setGender('Female');
                        },
                        (hovered) => setState(() => _isFemaleHovered = hovered),
                        18,
                        29,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Next button with gradient lines
          Positioned(
            top: 620,
            left: 28,
            child: SizedBox(
              width: 374,
              height: 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 14,
                    left: 0,
                    child: Container(
                      width: 125,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 134,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _isNextHovered = true),
                      onExit: (_) => setState(() => _isNextHovered = false),
                      cursor: SystemMouseCursors.click,
                      child: CustomButton(
                        text: "Next",
                        width: 106,
                        height: 40,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        borderRadius: 10,
                        borderColor: const Color(0xFF00F0FF),
                        backgroundColor: _isNextHovered
                            ? const Color(0xFF00F0FF).withOpacity(0.15)
                            : const Color(0xFF0B1320),
                        onTap: _handleNextTap,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    right: 0,
                    child: Container(
                      width: 125,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(11),
                        gradient: const LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quote text
          Positioned(
            top: 800,
            left: 28,
            child: SizedBox(
              width: 368,
              height: 47,
              child: const Text(
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
            ),
          ),

          Positioned(bottom: 40, left: 0, right: 0, child: FooterWidget()),
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
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final gender = _selectedGender;

    // Validation checks
    if (firstName.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        "Please enter your first name.",
      );
      return;
    }
    if (firstName.length < 3) {
      widget.errorStackKey.currentState?.showError(
        "First name must be at least 3 characters.",
      );
      return;
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!nameRegex.hasMatch(firstName)) {
      widget.errorStackKey.currentState?.showError(
        "First name can only include letters, apostrophes, hyphens, and spaces.",
      );
      return;
    }

    if (lastName.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        "Please enter your last name.",
      );
      return;
    }
    if (lastName.length < 3) {
      widget.errorStackKey.currentState?.showError(
        "Last name must be at least 3 characters.",
      );
      return;
    }
    final lastNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!lastNameRegex.hasMatch(lastName)) {
      widget.errorStackKey.currentState?.showError(
        "Last name can only include letters, apostrophes, hyphens, and spaces.",
      );
      return;
    }

    if (gender.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        "Please select your gender.",
      );
      return;
    }

    // Navigate to next page
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
            letterSpacing: 0,
            color: Colors.white,
          ),
        ),
      ],
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>();

    _firstNameController.text = user.firstName;
    _lastNameController.text = user.lastName;
    _sponsorController.text = user.sponsorCode;
    _genderController.text = user.gender;
    _selectedGender = user.gender;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _sponsorController.dispose();
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    _sponsorFocusNode.dispose();
    super.dispose();
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
                                                  context
                                                      .read<UserProvider>()
                                                      .setFirstName(value);
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
                                                  context
                                                      .read<UserProvider>()
                                                      .setLastName(value);
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
                                                      "Sponsor Code or link (Optional)",
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
                                                          setState(() {
                                                            _sponsorController
                                                                    .text =
                                                                clipboardData
                                                                    .text!;
                                                            signUpData
                                                                .setSponsorCode(
                                                                  clipboardData
                                                                      .text!,
                                                                );
                                                          });
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
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerLeft,
                                                end: Alignment.centerRight,
                                                colors: [
                                                  Color(0xFF0B1320),
                                                  Color(0xFF00F0FF),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        MouseRegion(
                                          onEnter: (_) => setState(
                                            () => _isNextHovered = true,
                                          ),
                                          onExit: (_) => setState(
                                            () => _isNextHovered = false,
                                          ),
                                          cursor: SystemMouseCursors.click,
                                          child: CustomButton(
                                            text: "Next",
                                            width: 106,
                                            height: 40,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            borderRadius: 12,
                                            borderColor: const Color(
                                              0xFF00F0FF,
                                            ),
                                            backgroundColor: _isNextHovered
                                                ? const Color(
                                                    0xFF00F0FF,
                                                  ).withOpacity(0.15)
                                                : const Color(0xFF0B1320),
                                            onTap: _handleNextTap,
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
                                              gradient: const LinearGradient(
                                                begin: Alignment.centerRight,
                                                end: Alignment.centerLeft,
                                                colors: [
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
          ErrorStack(key: widget.errorStackKey),
        ],
      ),
    );
  }

  // ... rest of your methods remain exactly the same
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
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final gender = _selectedGender;

    // Validation checks (same as mobile)
    if (firstName.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        "Please enter your first name.",
      );
      return;
    }
    if (firstName.length < 3) {
      widget.errorStackKey.currentState?.showError(
        "First name must be at least 3 characters.",
      );
      return;
    }
    final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!nameRegex.hasMatch(firstName)) {
      widget.errorStackKey.currentState?.showError(
        "First name can only include letters, apostrophes, hyphens, and spaces.",
      );
      return;
    }

    if (lastName.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        "Please enter your last name.",
      );
      return;
    }
    if (lastName.length < 3) {
      widget.errorStackKey.currentState?.showError(
        "Last name must be at least 3 characters.",
      );
      return;
    }
    final lastNameRegex = RegExp(r"^[a-zA-ZÀ-ÿ'-\s]+$");
    if (!lastNameRegex.hasMatch(lastName)) {
      widget.errorStackKey.currentState?.showError(
        "Last name can only include letters, apostrophes, hyphens, and spaces.",
      );
      return;
    }

    if (gender.isEmpty) {
      widget.errorStackKey.currentState?.showError(
        "Please select your gender.",
      );
      return;
    }

    // Navigate to next page
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
