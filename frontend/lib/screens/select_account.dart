import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/signup_data_provider.dart';
import '../widgets/custom_button.dart';

class SelectAccountContent extends StatefulWidget {
  final VoidCallback onClose;
  const SelectAccountContent({required this.onClose, super.key});

  @override
  State<SelectAccountContent> createState() => _SelectAccountContentState();
}

class _SelectAccountContentState extends State<SelectAccountContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return TabletSelectAccountContent(
            onClose: widget.onClose,
            scrollController: _scrollController,
          );
        } else {
          return MobileSelectAccountContent(
            onClose: widget.onClose,
            scrollController: _scrollController,
          );
        }
      },
    );
  }
}

class MobileSelectAccountContent extends StatelessWidget {
  final VoidCallback onClose;
  final ScrollController scrollController;

  const MobileSelectAccountContent({
    required this.onClose,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = _getAccounts(userProvider);

    return Column(
      children: [
        const SizedBox(height: 14),
        // V-line handle (clickable)
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onClose,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CustomPaint(
                size: const Size(120, 20),
                painter: VLinePainter(),
              ),
            ),
          ),
        ),

        const SizedBox(height: 50),

        // Title
        const Text(
          'Select an Account',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),

        const SizedBox(height: 40),

        // Account list with scrollbar for mobile
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: 530,
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    children: [
                      for (final account in accounts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: AccountFrame(
                            firstName: account['firstName'] ?? 'First Name',
                            lastName: account['lastName'] ?? 'Last Name',
                            eid: account['eid'] ?? 'N/A',
                            imagePath:
                                account['image'] ??
                                'assets/images/placeholder.png',
                            onTap: () {
                              Navigator.pushNamed(context, '/sign-in');
                            },
                            isTablet: false,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),
            VerticalScrollbar(controller: scrollController),
          ],
        ),

        const SizedBox(height: 30),

        // Add New Profile Button
        _buildAddNewProfileButton(context, false),
      ],
    );
  }
}

class TabletSelectAccountContent extends StatelessWidget {
  final VoidCallback onClose;
  final ScrollController scrollController;

  const TabletSelectAccountContent({
    required this.onClose,
    required this.scrollController,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = _getAccounts(userProvider);

    // Get the actual device orientation
    final orientation = MediaQuery.of(context).orientation;

    return Container(
      height: 476.0, // Fixed total height
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
      child: Column(
        children: [
          // V-line handle (centered for tablet)
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClose,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: CustomPaint(
                  size: const Size(120.0, 20.0),
                  painter: VLinePainter(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20.0),

          // Title with larger font for tablet
          const Text(
            'Select an Account',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 24.0,
            ),
          ),

          const SizedBox(height: 30.0),

          // Fixed height account grid for tablet with 2x3 layout
          Builder(
            builder: (context) {
              // Get orientation inside Builder to ensure fresh context
              final currentOrientation = MediaQuery.of(context).orientation;

              // Set height based on orientation
              final containerHeight =
                  currentOrientation == Orientation.landscape
                  ? 280.0 // Horizontal/landscape mode
                  : 240.0; // Vertical/portrait mode

              final gridHeight = currentOrientation == Orientation.landscape
                  ? 280.0 // Match container height for landscape
                  : 240.0; // Match container height for portrait

              print('Current Orientation: $currentOrientation'); // Debug print

              return Container(
                height: containerHeight,
                width: 644.0, // Fixed width as requested
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Account grid with 2 columns and 3 rows
                    Expanded(
                      child: Container(
                        height: gridHeight,
                        child: GridView.builder(
                          controller: scrollController,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2, // 2 columns
                                mainAxisSpacing: 15.0,
                                crossAxisSpacing: 20.0,
                                childAspectRatio: 350 / 85,
                              ),
                          itemCount: accounts.length,
                          itemBuilder: (context, index) {
                            final account = accounts[index];
                            return AccountFrame(
                              firstName: account['firstName'] ?? 'First Name',
                              lastName: account['lastName'] ?? 'Last Name',
                              eid: account['eid'] ?? 'N/A',
                              imagePath:
                                  account['image'] ??
                                  'assets/images/placeholder.png',
                              onTap: () {
                                Navigator.pushNamed(context, '/sign-in');
                              },
                              isTablet: true,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 15.0),

                    // Custom scrollbar - height matches grid height
                    VerticalScrollbar(
                      controller: scrollController,
                      height: gridHeight,
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 25.0),

          // Add New Profile Button for tablet
          _buildAddNewProfileButton(context, true),
        ],
      ),
    );
  }
}

List<Map<String, String?>> _getAccounts(UserProvider userProvider) {
  return [
    {
      'firstName': userProvider.firstName,
      'lastName': userProvider.lastName,
      'eid': userProvider.eid,
      'image': 'assets/images/image1.png',
    },
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'eid': '123456',
      'image': 'assets/images/image2.png',
    },
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'eid': '123456',
      'image': 'assets/images/image2.png',
    },
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'eid': '123456',
      'image': 'assets/images/image2.png',
    },
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'eid': '123456',
      'image': 'assets/images/image2.png',
    },
    {
      'firstName': 'John',
      'lastName': 'Doe',
      'eid': '123456',
      'image': 'assets/images/image2.png',
    },
    {
      'firstName': 'Johnny',
      'lastName': 'Doe',
      'eid': '123456',
      'image': 'assets/images/image2.png',
    },
  ];
}

// Updated VerticalScrollbar Widget with customizable height
class VerticalScrollbar extends StatefulWidget {
  final ScrollController? controller;
  final double height;

  const VerticalScrollbar({super.key, this.controller, this.height = 530});

  @override
  State<VerticalScrollbar> createState() => _VerticalScrollbarState();
}

class _VerticalScrollbarState extends State<VerticalScrollbar> {
  late ScrollController _scrollController;
  double _scrollThumbPosition = 0;
  double _scrollThumbHeight = 50;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_updateScrollThumb);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollThumb();
    });
  }

  @override
  void didUpdateWidget(covariant VerticalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.height != widget.height) {
      _scrollController.removeListener(_updateScrollThumb);
      _scrollController = widget.controller ?? ScrollController();
      _scrollController.addListener(_updateScrollThumb);
      _updateScrollThumb();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollThumb);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _updateScrollThumb() {
    if (!_isDragging && _scrollController.hasClients) {
      try {
        final maxScrollExtent = _scrollController.position.maxScrollExtent;
        final viewportDimension = _scrollController.position.viewportDimension;
        final totalContentHeight = maxScrollExtent + viewportDimension;

        if (totalContentHeight > 0 && maxScrollExtent > 0) {
          final visibleRatio = viewportDimension / totalContentHeight;
          _scrollThumbHeight = (widget.height * visibleRatio).clamp(
            30.0,
            widget.height,
          );

          final scrollRatio = _scrollController.offset / maxScrollExtent;
          _scrollThumbPosition =
              (widget.height - _scrollThumbHeight) *
              scrollRatio.clamp(0.0, 1.0);
        } else {
          _scrollThumbHeight = widget.height;
          _scrollThumbPosition = 0;
        }

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Scrollbar update error: $e');
      }
    }
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
    _scrollToPosition(details.localPosition.dy);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    _scrollToPosition(details.localPosition.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isDragging = false;
  }

  void _scrollToPosition(double localPosition) {
    if (!_scrollController.hasClients) return;

    try {
      final trackHeight = widget.height;
      final thumbCenter = localPosition - (_scrollThumbHeight / 2);
      final availableTrack = trackHeight - _scrollThumbHeight;

      if (availableTrack <= 0) return;

      final scrollRatio = (thumbCenter / availableTrack).clamp(0.0, 1.0);

      final maxScrollExtent = _scrollController.position.maxScrollExtent;
      final newOffset = maxScrollExtent * scrollRatio;

      _scrollController.jumpTo(newOffset);
    } catch (e) {
      print('Scroll error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: widget.height,
      child: Stack(
        children: [
          if (_scrollController.hasClients &&
              _scrollController.position.maxScrollExtent > 0)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              top: _scrollThumbPosition,
              left: 0,
              right: 0,
              child: GestureDetector(
                onVerticalDragStart: _onVerticalDragStart,
                onVerticalDragUpdate: _onVerticalDragUpdate,
                onVerticalDragEnd: _onVerticalDragEnd,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    height: _scrollThumbHeight,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00F0FF),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Updated AccountFrame with tablet support
class AccountFrame extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String eid;
  final String imagePath;
  final VoidCallback onTap;
  final bool isTablet;

  const AccountFrame({
    required this.firstName,
    required this.lastName,
    required this.eid,
    required this.imagePath,
    required this.onTap,
    required this.isTablet,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final width = isTablet ? 312.0 : 312.0;
    final height = isTablet ? 69.0 : 69.0;
    final imageSize = isTablet ? 50.0 : 50.0;
    final nameFontSize = isTablet ? 22.0 : 20.0;
    final eidFontSize = isTablet ? 15.0 : 15.0;
    final leftPadding = isTablet ? 90.0 : 95.0;

    // Different divider calculations for tablet vs mobile
    final topDivider = isTablet
        ? (height - imageSize) / 3.8
        : (height - imageSize) / 2;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF00F0FF), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            // Profile Image with different dividers
            Positioned(
              top: topDivider, // Use the calculated divider
              left: 15,
              child: _buildProfileImage(imageSize),
            ),
            // User Full Name
            Positioned(
              top: isTablet ? 8 : 12,
              left: leftPadding,
              child: Text(
                '$firstName $lastName',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  fontSize: nameFontSize,
                  height: 1.0,
                ),
              ),
            ),
            // EID
            Positioned(
              top: isTablet ? 34 : 38,
              left: leftPadding,
              child: Text(
                'EID: $eid',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: eidFontSize,
                  height: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white12,
              ),
              child: Icon(Icons.person, color: Colors.white, size: size * 0.6),
            );
          },
        ),
      ),
    );
  }
}

// Cyan horizontal line painter
class VLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(0, size.height / 2);
    path.lineTo(size.width / 2 - 10, size.height / 2);
    path.lineTo(size.width / 2, size.height / 2 + 5);
    path.lineTo(size.width / 2 + 10, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

Widget _buildAddNewProfileButton(BuildContext context, bool isTablet) {
  final buttonWidth = isTablet ? 220.0 : 180.0;
  final buttonHeight = isTablet ? 50.0 : 40.0;
  final fontSize = isTablet ? 22.0 : 20.0;

  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(left: isTablet ? 50 : 10),
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
      SizedBox(width: isTablet ? 30 : 20),
      CustomButton(
        text: 'Add New Profile',
        width: buttonWidth,
        height: buttonHeight,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        textColor: Colors.white,
        borderColor: const Color(0xFF00F0FF),
        backgroundColor: const Color(0xFF0B1320),
        onTap: () {
          Navigator.pushNamed(context, '/sign-in');
        },
      ),
      SizedBox(width: isTablet ? 30 : 20),
      Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: isTablet ? 50 : 10),
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
  );
}
