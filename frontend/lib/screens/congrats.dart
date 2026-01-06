import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_project/main.dart';
import 'package:flutter_project/screens/register.dart';
import 'package:flutter_project/widgets/footer_widgets.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_button.dart';
import 'package:flutter/services.dart';

class ResponsiveRegisterLivePage extends StatelessWidget {
  const ResponsiveRegisterLivePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const TabletRegisterLivePage();
        } else {
          return const MobileRegisterLivePage();
        }
      },
    );
  }
}

class MobileRegisterLivePage extends StatefulWidget {
  const MobileRegisterLivePage({super.key});

  @override
  State<MobileRegisterLivePage> createState() => _MobileRegisterLivePageState();
}

class _MobileRegisterLivePageState extends State<MobileRegisterLivePage>
    with SingleTickerProviderStateMixin {
  bool _showCopiedFeedback = false;
  Timer? _feedbackTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  bool _isGetStartedHovered = false;
  bool _isGetStartedPressed = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Then initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String eid) {
    Clipboard.setData(ClipboardData(text: eid));

    setState(() {
      _showCopiedFeedback = true;
    });

    // Animate in
    _animationController.forward();

    // Cancel any existing timer
    _feedbackTimer?.cancel();

    // Start new timer to hide the feedback after 3 seconds
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Animate out
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showCopiedFeedback = false;
            });
          }
        });
      }
    });
  }

  // Helper function to capitalize first letter of each word
  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  void _handleGetStartedTap() {
    setState(() {
      _isGetStartedPressed = true;
    });

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isGetStartedPressed = false;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RegisterPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    // Capitalize first and last names
    final capitalizedFirstName = _capitalizeName(userProvider.firstName);
    final capitalizedLastName = _capitalizeName(userProvider.lastName);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Congratulations! You're In!"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Congratulations! You're In!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: MediaQuery.of(context).size.width > 350 ? 30 : 26,
                    color: Colors.white,
                  ),
                ),
              ),

              // Spacing between texts
              const SizedBox(height: 20),

              // "Welcome to Egety Trust"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Welcome to Egety Trust",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: MediaQuery.of(context).size.width > 350 ? 25 : 22,
                    color: Colors.white,
                  ),
                ),
              ),

              // Spacing before gradient bar
              const SizedBox(height: 40),

              // Gradient bar with user name
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color.fromRGBO(0, 240, 255, 0),
                      const Color.fromRGBO(0, 240, 255, 0.8),
                      const Color.fromRGBO(0, 240, 255, 0),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // User Name - Using capitalized names
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "$capitalizedFirstName $capitalizedLastName",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: MediaQuery.of(context).size.width > 350
                              ? 30
                              : 26,
                          color: const Color(0xFF0B1320),
                        ),
                      ),
                    ),

                    // EID + Icon OR "EID COPIED" feedback with animation
                    GestureDetector(
                      onTap: () {
                        _copyToClipboard(userProvider.eid);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          switchInCurve: Curves.easeInOut,
                          switchOutCurve: Curves.easeInOut,
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  ),
                                );
                              },
                          child: _showCopiedFeedback
                              ? Text(
                                  "EID COPIED",
                                  key: const ValueKey('copied'),
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w700,
                                    fontSize:
                                        MediaQuery.of(context).size.width > 350
                                        ? 25
                                        : 20,
                                    color: const Color(0xFF0B1320),
                                  ),
                                )
                              : Row(
                                  key: const ValueKey('eid'),
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "EID: ${userProvider.eid}",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w500,
                                        fontSize:
                                            MediaQuery.of(context).size.width >
                                                350
                                            ? 25
                                            : 20,
                                        color: const Color(0xFF0B1320),
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: Image.asset(
                                        'assets/images/DoubleSquare.png',
                                        width: 18,
                                        height: 18,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Spacing after gradient bar
              const SizedBox(height: 20),

              // Description text
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  "Your EID is your unique ID across all apps. Save it safely you'll need it to access everything",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    fontSize: MediaQuery.of(context).size.width > 350 ? 24 : 20,
                    color: Colors.white,
                  ),
                ),
              ),

              // Spacing before animation
              const SizedBox(height: 32),

              // Unlocked animation image
              Container(
                width: 153,
                height: 200,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/Unlocked animstion.png',
                  fit: BoxFit.contain,
                ),
              ),

              // Flexible spacer to push remaining content to bottom
              Expanded(child: Container()),

              // Bottom section with gradient lines and button
              Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    // Button and gradient lines row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Left gradient line
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
                                gradient: const LinearGradient(
                                  begin: Alignment.centerRight,
                                  end: Alignment.centerLeft,
                                  colors: [
                                    Color(0xFF00F0FF),
                                    Color(0xFF0B1320),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // "Get Started" button
                          MouseRegion(
                            onEnter: (_) =>
                                setState(() => _isGetStartedHovered = true),
                            onExit: (_) =>
                                setState(() => _isGetStartedHovered = false),
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTapDown: (_) =>
                                  setState(() => _isGetStartedPressed = true),
                              onTapUp: (_) => _handleGetStartedTap(),
                              onTapCancel: () =>
                                  setState(() => _isGetStartedPressed = false),
                              child: Transform.scale(
                                scale: _isGetStartedPressed ? 0.95 : 1.0,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  width: 161,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF),
                                      width: 2,
                                    ),
                                    color: _isGetStartedHovered
                                        ? const Color(
                                            0xFF00F0FF,
                                          ).withOpacity(0.15)
                                        : (_isGetStartedPressed
                                              ? const Color(
                                                  0xFF00F0FF,
                                                ).withOpacity(0.25)
                                              : const Color(0xFF0B1320)),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "Get Started",
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          // Right gradient line
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(11),
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
                  ],
                ),
              ),

              // Footer
              const FooterWidget(),
            ],
          ),
        ),
      ),
    );
  }
}

class TabletRegisterLivePage extends StatefulWidget {
  const TabletRegisterLivePage({super.key});

  @override
  State<TabletRegisterLivePage> createState() => _TabletRegisterLivePageState();
}

class _TabletRegisterLivePageState extends State<TabletRegisterLivePage>
    with SingleTickerProviderStateMixin {
  bool _showCopiedFeedback = false;
  Timer? _feedbackTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller first
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Then initialize animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _copyToClipboard(String eid) {
    Clipboard.setData(ClipboardData(text: eid));

    setState(() {
      _showCopiedFeedback = true;
    });

    // Animate in
    _animationController.forward();

    // Cancel any existing timer
    _feedbackTimer?.cancel();

    // Start new timer to hide the feedback after 3 seconds
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // Animate out
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _showCopiedFeedback = false;
            });
          }
        });
      }
    });
  }

  // Helper function to capitalize first letter of each word
  String _capitalizeName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Capitalize first and last names
    final capitalizedFirstName = _capitalizeName(userProvider.firstName);
    final capitalizedLastName = _capitalizeName(userProvider.lastName);

    return Scaffold(
      backgroundColor: const Color(0xFF0B1320),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content area - Removed SingleChildScrollView
            Positioned.fill(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: screenHeight * 0.05),

                  // Congratulations text
                  const Text(
                    "Congratulations! You're In!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Welcome text
                  const Text(
                    "Welcome to Egety Trust",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: 25,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔹 Full-width Gradient bar with user info (no side padding)
                  Container(
                    width: double.infinity, // Full width of the screen
                    height: 87,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color.fromRGBO(0, 240, 255, 0),
                          Color.fromRGBO(0, 240, 255, 0.8),
                          Color.fromRGBO(0, 240, 255, 0),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // User Name - Using capitalized names
                        Text(
                          "$capitalizedFirstName $capitalizedLastName",
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            fontSize: 30,
                            color: Color(0xFF0B1320),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // EID + Icon OR "EID COPIED" feedback with animation
                        GestureDetector(
                          onTap: () {
                            _copyToClipboard(userProvider.eid);
                          },
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: FadeTransition(
                                      opacity: animation,
                                      child: child,
                                    ),
                                  );
                                },
                            child: _showCopiedFeedback
                                ? Text(
                                    "EID COPIED",
                                    key: const ValueKey('copied'),
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 25,
                                      color: Color(0xFF0B1320),
                                    ),
                                  )
                                : Row(
                                    key: const ValueKey('eid'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "EID: ${userProvider.eid}",
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 25,
                                          color: Color(0xFF0B1320),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Image.asset(
                                        'assets/images/DoubleSquare.png',
                                        width: 16,
                                        height: 16,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Description text
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                    ), // restore padding here
                    child: const Text(
                      "Your EID is your unique ID across all apps.Save it safely you'll need it to access everything",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Unlocked animation image
                  Container(
                    width: 153,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/Unlocked animstion.png',
                      fit: BoxFit.contain,
                    ),
                  ),

                  // Flexible spacer to fill remaining space
                  Expanded(child: Container()),

                  // Button section with gradient lines
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.1,
                    ), // restore padding again
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Left gradient line
                        Container(
                          width: 55,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF00F0FF), Color(0xFF0B1320)],
                            ),
                          ),
                        ),

                        const SizedBox(width: 20),

                        // Get Started button
                        CustomButton(
                          text: "Get Started",
                          width: 272,
                          height: 50,
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          textColor: Colors.white,
                          backgroundColor: Colors.transparent,
                          borderColor: const Color(0xFF00F0FF),
                          borderRadius: 12,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(width: 20),

                        // Right gradient line
                        Container(
                          width: 55,
                          height: 5,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(11),
                            gradient: const LinearGradient(
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                              colors: [Color(0xFF0B1320), Color(0xFF00F0FF)],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Footer
                  const FooterWidget(),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // Bottom right image with orientation-based sizing
            Positioned(
              bottom: 0, // Distance from bottom
              right: -10, // Distance from right
              child: Image.asset(
                'assets/images/Rectangle2.png',
                width: isLandscape
                    ? 150
                    : 120, // Adjust size based on orientation
                height: isLandscape ? 150 : 120,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
