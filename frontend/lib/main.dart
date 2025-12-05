import 'package:flutter/material.dart';
import 'package:flutter_project/screens/sign_in_screen.dart';
import '../providers/language_provider.dart';
import '../providers/protect_access_provider.dart';
import './providers/font_size_provider.dart';
import 'package:flutter_project/providers/signup_data_provider.dart';
import 'screens/register.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../routes/routes.dart';
import 'widgets/footer_widgets.dart';
import '../screens/frozen_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());

  // final userProvider = UserProvider();
  // final storage = FlutterSecureStorage();

  // // Load saved user info
  // await userProvider.loadFromStorage(storage);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
        ChangeNotifierProvider(create: (context) => ProtectAccessProvider()),
        ChangeNotifierProvider(create: (context) => FontSizeProvider()),
      ],
      child: Builder(
        builder: (context) {
          // Load user data after provider is available
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );
          userProvider.loadFromStorage();

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              textSelectionTheme: const TextSelectionThemeData(
                cursorColor: Color(0xFF00F0FF),
              ),
            ),
            home: FreezeAccount(),
            routes: appRoutes(),
          );
        },
      ),
    );
  }
}

class ResponsiveHomePage extends StatelessWidget {
  const ResponsiveHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return const TabletHomePage();
        } else {
          return const MobileHomePage();
        }
      },
    );
  }
}

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  bool _swipeUp = false;

  void _onSwipeUp() {
    setState(() {
      _swipeUp = true;
    });
  }

  void _onSwipeEnd() {
    setState(() {
      _swipeUp = false;
    });
  }

  void _navigateToNextPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0, 1);
          const end = Offset.zero;
          var tween = Tween(
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

  @override
  Widget build(BuildContext context) {
    return Consumer<FontSizeProvider>(
      builder: (context, fontProvider, child) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            if (details.primaryDelta != null && details.primaryDelta! < -2) {
              _onSwipeUp();
            }
          },
          onVerticalDragEnd: (details) {
            _onSwipeEnd();
            if (details.primaryVelocity != null &&
                details.primaryVelocity! < -100) {
              _navigateToNextPage(context);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0B1320),
            body: SafeArea(
              child: Stack(
                children: [
                  // Main content column
                  Column(
                    children: [
                      // Top section with vector icon and welcome text
                      Stack(
                        children: [
                          // Vector icon at top-right
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: 20,
                                right: 20,
                              ),
                              child: Image.asset(
                                'assets/images/Vector.png',
                                width: 23,
                                height: 23,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          // Welcome texts
                          // Welcome texts - UPDATED SECTION
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              // Added Center widget here
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome to',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: fontProvider.getScaledSize(
                                        30.0,
                                      ),
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Egety Trust',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      fontSize: fontProvider.getScaledSize(
                                        50.0,
                                      ),
                                      height: 1.0,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Description text
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 20,
                        ),
                        child: Text(
                          'Step into a dynamic realm powered by decentralization, '
                          'where true data ownership and assets belong to you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: fontProvider.getScaledSize(20.0),
                            height: 1.0,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      // Central image
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 153,
                            height: 200,
                            child: Image.asset(
                              'assets/images/Unlocked animstion.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      // Swipe Up text and arrow section
                      // In your MobileHomePage build method, replace the Row with Stack:
                      Padding(
                        padding: const EdgeInsets.only(bottom: 40),
                        child: Column(
                          children: [
                            Text(
                              'Swipe Up \n To Continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                                fontSize: fontProvider.getScaledSize(30.0),
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height:
                                  179, // Same height as the GlowingVerticalOvalArrow
                              child: Stack(
                                children: [
                                  // Position the glowing oval arrow
                                  Positioned(
                                    left: 175.0,
                                    child: GlowingVerticalOvalArrow(
                                      arrowAsset: "assets/images/ArrowUp.svg",
                                      swipeUp: _swipeUp,
                                    ),
                                  ),
                                  // Position the animated SVG
                                  Positioned(
                                    top: 70,
                                    left:
                                        MediaQuery.of(context).size.width *
                                            0.7 -
                                        40.0, // Adjust based on the Row's left padding
                                    child: MobileSwipeUpDownAnimatedSvg(
                                      assetPath: "assets/images/Pointer.svg",
                                      startY:
                                          MediaQuery.of(context).size.height *
                                          0.89,
                                      endY:
                                          MediaQuery.of(context).size.height *
                                          0.78,
                                      width: 33.6,
                                      height: 50,
                                      durationMilliseconds: 1500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom-right rectangle (positioned element)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Image.asset(
                      "assets/images/Rectangle.png",
                      width: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class TabletHomePage extends StatefulWidget {
  const TabletHomePage({super.key});

  @override
  State<TabletHomePage> createState() => _TabletHomePageState();
}

class _TabletHomePageState extends State<TabletHomePage> {
  bool _swipeUp = false;

  void _onSwipeUp() {
    setState(() {
      _swipeUp = true;
    });
  }

  void _onSwipeEnd() {
    setState(() {
      _swipeUp = false;
    });
  }

  void _navigateToNextPage(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const RegisterPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0, 1);
          const end = Offset.zero;
          var tween = Tween(
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < -2) {
          _onSwipeUp();
        }
      },
      onVerticalDragEnd: (details) {
        _onSwipeEnd();
        if (details.primaryVelocity != null &&
            details.primaryVelocity! < -100) {
          _navigateToNextPage(context);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1320),
        body: Stack(
          children: [
            // Top-right Vector icon - positioned relative to screen size
            Positioned(
              top: screenHeight * 0.05,
              right: screenWidth * 0.05,
              child: Image.asset(
                'assets/images/Vector.png',
                width: 32,
                height: 32,
                color: Colors.white,
              ),
            ),

            // Bottom-right rectangle - larger for tablet
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                "assets/images/Rectangle.png",
                width: 150,
                fit: BoxFit.contain,
              ),
            ),

            // Content Area
            // Replace your Positioned.fill(...) block with this:
            Positioned.fill(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenHeight * 0.05,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Top content section
                      const SizedBox(height: 50),
                      const Text(
                        'Welcome to',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          fontSize: 30,
                          height: 1.0,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Egety Trust',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 50,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        'Step into a dynamic realm powered by decentralization,\n'
                        'where true data ownership and assets belong to you.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: 19,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: 144,
                        height: 193,
                        child: Image.asset(
                          'assets/images/Unlocked animstion.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 40),
                      // Swipe section
                      const Text(
                        'Swipe Up To Continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                          height: 1,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 100.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            GlowingVerticalOvalArrow(
                              arrowAsset: "assets/images/ArrowUp.svg",
                              swipeUp: _swipeUp,
                            ),
                            const SizedBox(width: 20),
                            SizedBox(
                              height: 80,
                              child: TabletSwipeUpDownAnimatedSvg(
                                assetPath: "assets/images/Pointer.svg",
                                width: 42,
                                height: 60,
                                durationMilliseconds: 1500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                      FooterWidget(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mobile Animated SVG Pointer
class MobileSwipeUpDownAnimatedSvg extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final double startY;
  final double endY;
  final int durationMilliseconds;

  const MobileSwipeUpDownAnimatedSvg({
    super.key,
    required this.assetPath,
    required this.startY,
    required this.endY,
    this.width = 33.6,
    this.height = 50,
    this.durationMilliseconds = 100,
  });

  @override
  State<MobileSwipeUpDownAnimatedSvg> createState() =>
      _MobileSwipeUpDownAnimatedSvgState();
}

class _MobileSwipeUpDownAnimatedSvgState
    extends State<MobileSwipeUpDownAnimatedSvg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMilliseconds),
      vsync: this,
    )..repeat();

    _positionAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.startY,
          end: widget.endY,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(widget.endY), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: widget.endY,
          end: widget.startY,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 40 * pi / 180,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(40 * pi / 180),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 40 * pi / 180,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: SvgPicture.asset(
            widget.assetPath,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

// Tablet version of the animated SVG pointer
class TabletSwipeUpDownAnimatedSvg extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final int durationMilliseconds;

  const TabletSwipeUpDownAnimatedSvg({
    super.key,
    required this.assetPath,
    this.width = 42,
    this.height = 60,
    this.durationMilliseconds = 100,
  });

  @override
  State<TabletSwipeUpDownAnimatedSvg> createState() =>
      _TabletSwipeUpDownAnimatedSvgState();
}

class _TabletSwipeUpDownAnimatedSvgState
    extends State<TabletSwipeUpDownAnimatedSvg>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _positionAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(milliseconds: widget.durationMilliseconds),
      vsync: this,
    )..repeat();

    _positionAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: -20,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(-20), weight: 20),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -20,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0,
          end: 40 * pi / 180,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(40 * pi / 180),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 40 * pi / 180,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _positionAnimation.value),
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: SvgPicture.asset(
              widget.assetPath,
              width: widget.width,
              height: widget.height,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }
}

// Glowing V// Glowing Vertical Oval Arrow (Updated for mobile only)
class GlowingVerticalOvalArrow extends StatefulWidget {
  final String arrowAsset;
  final bool swipeUp;

  const GlowingVerticalOvalArrow({
    super.key,
    required this.arrowAsset,
    this.swipeUp = false,
  });

  @override
  State<GlowingVerticalOvalArrow> createState() =>
      _GlowingVerticalOvalArrowState();
}

class _GlowingVerticalOvalArrowState extends State<GlowingVerticalOvalArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _arrowAnimation;
  late Animation<double> _glowIntensity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _arrowAnimation = Tween<double>(
      begin: 110,
      end: 130,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowIntensity = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        bool movingUp = _controller.value < 0.5;

        // Gradient background when swiped
        final gradient = widget.swipeUp
            ? const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Color(0xFF00FEFF), Color(0xFF0B1320)],
              )
            : null;

        final arrowTop = widget.swipeUp ? 20.0 : _arrowAnimation.value;
        final arrowColor = widget.swipeUp ? Colors.white : null;

        return Container(
          width: 65,
          height: 179,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            gradient: gradient,
            color: widget.swipeUp ? null : const Color(0xFF0B1320),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00F0FF).withOpacity(
                  movingUp ? _glowIntensity.value : 0.15,
                ), // subtle glow
                offset: movingUp ? const Offset(0, -2) : const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: arrowTop,
                left: (65 - 20) / 2,
                child: SvgPicture.asset(
                  widget.arrowAsset,
                  width: 20,
                  height: 20,
                  color: arrowColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
