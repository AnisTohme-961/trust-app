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

  bool _isAddNewProfileHovered = false;
  bool _isAddNewProfilePressed = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = _getAccounts(userProvider);

    return Container(
      color: const Color(0xFF0B1320),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header - Fixed height
              Container(
                height: 50,
                padding: const EdgeInsets.all(12),
                alignment: Alignment.center,
                child: Text(
                  'Select an Account',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    fontSize: 19,
                  ),
                ),
              ),

              // Content area - Takes remaining space
              SizedBox(
                height: constraints.maxHeight - 120, // Header(50) + Button(70)
                child: _buildContent(
                  context,
                  accounts,
                  userProvider,
                  constraints.maxWidth,
                ),
              ),

              // Bottom button - Fixed height (only show if there are accounts)
              if (accounts.isNotEmpty)
                Container(
                  height: 70,
                  padding: const EdgeInsets.all(12),
                  child: _buildAddNewProfileButton(
                    context,
                    false,
                    constraints.maxWidth,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<Map<String, String>> accounts,
    UserProvider userProvider,
    double maxWidth,
  ) {
    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.account_circle_outlined,
              size: 50,
              color: Colors.white38,
            ),
            SizedBox(height: 8),
            Text(
              'No account found',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final double accountWidth = maxWidth * 0.75; // 70% of available width

    return SingleChildScrollView(
      controller: _scrollController,
      child: Center(
        child: SizedBox(
          width: accountWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final account in accounts)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AccountFrame(
                    firstName: account['firstName'] ?? 'First Name',
                    lastName: account['lastName'] ?? 'Last Name',
                    eid: account['eid'] ?? 'N/A',
                    imagePath: account['image'] ?? '',
                    onTap: () {
                      userProvider.setEID(account['eid'] ?? '');
                      Navigator.pushNamed(context, '/sign-in');
                    },
                    isTablet: false,
                    width: accountWidth,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Map<String, String>> _getAccounts(UserProvider userProvider) {
    return userProvider.accounts;
  }

  Widget _buildAddNewProfileButton(
    BuildContext context,
    bool isTablet,
    double maxWidth,
  ) {
    final buttonWidth = isTablet ? 200.0 : 160.0;
    final buttonHeight = isTablet ? 45.0 : 35.0;
    final fontSize = isTablet ? 20.0 : 18.0;

    return Center(
      child: SizedBox(
        width: maxWidth * 1, // 70% of available width
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: isTablet ? 30 : 8),
                child: Container(
                  height: 3,
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
            SizedBox(width: isTablet ? 20 : 10),
            MouseRegion(
              onEnter: (_) => setState(() => _isAddNewProfileHovered = true),
              onExit: (_) => setState(() => _isAddNewProfileHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isAddNewProfilePressed = true);
                },
                onTapUp: (_) {
                  setState(() => _isAddNewProfilePressed = false);
                  Navigator.pushNamed(context, '/sign-in');
                },
                onTapCancel: () {
                  setState(() => _isAddNewProfilePressed = false);
                },
                child: Transform.scale(
                  scale: _isAddNewProfilePressed ? 0.95 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: buttonWidth,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _isAddNewProfileHovered
                          ? const Color(0xFF00F0FF).withOpacity(0.15)
                          : (_isAddNewProfilePressed
                                ? const Color(0xFF00F0FF).withOpacity(0.25)
                                : const Color(0xFF0B1320)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Add New Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isTablet ? 30 : 8),
                child: Container(
                  height: 3,
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
        ),
      ),
    );
  }
}

class MobileSelectAccountContent extends StatefulWidget {
  final VoidCallback onClose;
  final ScrollController scrollController;

  const MobileSelectAccountContent({
    required this.onClose,
    required this.scrollController,
    super.key,
  });

  @override
  State<MobileSelectAccountContent> createState() =>
      _MobileSelectAccountContentState();
}

class _MobileSelectAccountContentState
    extends State<MobileSelectAccountContent> {
  bool _isAddNewProfileHovered = false;
  bool _isAddNewProfilePressed = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = _getAccounts(userProvider);

    return Container(
      color: const Color(0xFF0B1320),
      child: Column(
        children: [
          // Header - Fixed height
          SizedBox(
            height: 50,
            child: Center(
              child: Text(
                'Select an Account',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 19,
                ),
              ),
            ),
          ),

          // Divider
          Container(height: 1, color: Colors.white24),

          // Accounts List - Takes remaining space
          Expanded(child: _buildAccountsList(context, accounts, userProvider)),

          // Bottom button - Fixed height
          if (accounts.isNotEmpty &&
              userProvider.eid != null &&
              userProvider.eid!.isNotEmpty)
            Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: _buildAddNewProfileButton(context, false),
            ),
        ],
      ),
    );
  }

  Widget _buildAccountsList(
    BuildContext context,
    List<Map<String, String>> accounts,
    UserProvider userProvider,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final accountWidth = screenWidth * 0.7; // 70% of screen width

    if (accounts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.account_circle_outlined,
              size: 50,
              color: Colors.white38,
            ),
            SizedBox(height: 8),
            Text(
              'No account found',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SizedBox(
        width: accountWidth,
        child: ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AccountFrame(
                firstName: account['firstName'] ?? 'First Name',
                lastName: account['lastName'] ?? 'Last Name',
                eid: account['eid'] ?? 'N/A',
                imagePath: account['image'] ?? '',
                onTap: () {
                  userProvider.setEID(account['eid'] ?? '');
                  Navigator.pushNamed(context, '/sign-in');
                },
                isTablet: false,
                width: accountWidth,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddNewProfileButton(BuildContext context, bool isTablet) {
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.7;
    final buttonWidth = isTablet ? 200.0 : 160.0;
    final buttonHeight = isTablet ? 45.0 : 35.0;
    final fontSize = isTablet ? 20.0 : 18.0;

    return Center(
      child: SizedBox(
        width: containerWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: isTablet ? 30 : 8),
                child: Container(
                  height: 2,
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
            SizedBox(width: isTablet ? 20 : 10),
            MouseRegion(
              onEnter: (_) => setState(() => _isAddNewProfileHovered = true),
              onExit: (_) => setState(() => _isAddNewProfileHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isAddNewProfilePressed = true);
                },
                onTapUp: (_) {
                  setState(() => _isAddNewProfilePressed = false);
                  Navigator.pushNamed(context, '/sign-in');
                },
                onTapCancel: () {
                  setState(() => _isAddNewProfilePressed = false);
                },
                child: Transform.scale(
                  scale: _isAddNewProfilePressed ? 0.95 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: buttonWidth,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _isAddNewProfileHovered
                          ? const Color(0xFF00F0FF).withOpacity(0.15)
                          : (_isAddNewProfilePressed
                                ? const Color(0xFF00F0FF).withOpacity(0.25)
                                : const Color(0xFF0B1320)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Add New Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isTablet ? 30 : 8),
                child: Container(
                  height: 2,
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
        ),
      ),
    );
  }
}

class TabletSelectAccountContent extends StatefulWidget {
  final VoidCallback onClose;
  final ScrollController scrollController;

  const TabletSelectAccountContent({
    required this.onClose,
    required this.scrollController,
    super.key,
  });

  @override
  State<TabletSelectAccountContent> createState() =>
      _TabletSelectAccountContentState();
}

class _TabletSelectAccountContentState
    extends State<TabletSelectAccountContent> {
  bool _isAddNewProfileHovered = false;
  bool _isAddNewProfilePressed = false;

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final accounts = _getAccounts(userProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth * 0.7;

    return Container(
      color: const Color(0xFF0B1320),
      child: Column(
        children: [
          // V-line handle (centered)
          Center(
            child: GestureDetector(
              onTap: widget.onClose,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                child: CustomPaint(
                  size: const Size(100.0, 18.0),
                  painter: VLinePainter(),
                ),
              ),
            ),
          ),

          // Title (centered)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Select an Account',
                style: TextStyle(
                  color: Colors.white,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 22.0,
                ),
              ),
            ),
          ),

          // Account grid area
          Expanded(
            child: Center(
              child: SizedBox(
                width: containerWidth,
                child: GridView.builder(
                  controller: widget.scrollController,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12.0,
                    crossAxisSpacing: 15.0,
                    childAspectRatio: 300 / 75,
                  ),
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final account = accounts[index];
                    return AccountFrame(
                      firstName: account['firstName'] ?? 'First Name',
                      lastName: account['lastName'] ?? 'Last Name',
                      eid: account['eid'] ?? 'N/A',
                      imagePath: account['image'] ?? '',
                      onTap: () {
                        userProvider.setEID(account['eid']!);
                        Navigator.pushNamed(context, '/sign-in');
                      },
                      isTablet: true,
                      width:
                          (containerWidth - 15) /
                          2, // Account width for 2-column grid
                    );
                  },
                ),
              ),
            ),
          ),

          // Add New Profile Button for tablet
          Container(
            height: 60,
            padding: const EdgeInsets.only(bottom: 15.0, top: 10.0),
            child: _buildAddNewProfileButton(context, true, screenWidth),
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewProfileButton(
    BuildContext context,
    bool isTablet,
    double screenWidth,
  ) {
    final containerWidth = screenWidth * 0.8;
    final buttonWidth = isTablet ? 200.0 : 160.0;
    final buttonHeight = isTablet ? 45.0 : 35.0;
    final fontSize = isTablet ? 20.0 : 18.0;

    return Center(
      child: SizedBox(
        width: containerWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: isTablet ? 30 : 8),
                child: Container(
                  height: 2,
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
            SizedBox(width: isTablet ? 20 : 10),
            MouseRegion(
              onEnter: (_) => setState(() => _isAddNewProfileHovered = true),
              onExit: (_) => setState(() => _isAddNewProfileHovered = false),
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isAddNewProfilePressed = true);
                },
                onTapUp: (_) {
                  setState(() => _isAddNewProfilePressed = false);
                  Navigator.pushNamed(context, '/sign-in');
                },
                onTapCancel: () {
                  setState(() => _isAddNewProfilePressed = false);
                },
                child: Transform.scale(
                  scale: _isAddNewProfilePressed ? 0.95 : 1.0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: buttonWidth,
                    height: buttonHeight,
                    decoration: BoxDecoration(
                      color: _isAddNewProfileHovered
                          ? const Color(0xFF00F0FF).withOpacity(0.15)
                          : (_isAddNewProfilePressed
                                ? const Color(0xFF00F0FF).withOpacity(0.25)
                                : const Color(0xFF0B1320)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF00F0FF),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Add New Profile',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                          fontSize: fontSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: isTablet ? 20 : 10),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isTablet ? 30 : 8),
                child: Container(
                  height: 2,
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
        ),
      ),
    );
  }
}

List<Map<String, String>> _getAccounts(UserProvider userProvider) {
  return userProvider.accounts;
}

// Updated AccountFrame with width parameter
class AccountFrame extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String eid;
  final String imagePath;
  final VoidCallback onTap;
  final bool isTablet;
  final double? width; // New width parameter

  const AccountFrame({
    required this.firstName,
    required this.lastName,
    required this.eid,
    required this.imagePath,
    required this.onTap,
    required this.isTablet,
    this.width, // Make width optional
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Use provided width or calculate based on screen
    final frameWidth = width ?? (isTablet ? 280.0 : 280.0);
    final height = isTablet ? 65.0 : 65.0;
    final imageSize = isTablet ? 45.0 : 45.0;
    final nameFontSize = isTablet ? 20.0 : 18.0;
    final eidFontSize = isTablet ? 14.0 : 14.0;
    final leftPadding = frameWidth * 0.3; // Dynamic left padding based on width

    final topDivider = (height - imageSize) / 2.5;

    return SizedBox(
      width: frameWidth,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF00F0FF), width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              // Profile Image
              Positioned(
                top: topDivider,
                left: 12,
                child: _buildProfileImage(imageSize),
              ),
              // User Full Name
              Positioned(
                top: isTablet ? 8 : 10,
                left: leftPadding,
                child: SizedBox(
                  width: frameWidth - leftPadding - 12, // Limit width
                  child: Text(
                    '$firstName $lastName',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      fontSize: nameFontSize,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // EID
              Positioned(
                top: isTablet ? 32 : 34,
                left: leftPadding,
                child: SizedBox(
                  width: frameWidth - leftPadding - 12, // Limit width
                  child: Text(
                    'EID: $eid',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: eidFontSize,
                      height: 1.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(double size) {
    // If imagePath is empty or null, use the icon
    if (imagePath.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white12,
        ),
        child: Icon(
          Icons.account_circle_outlined,
          color: Colors.white,
          size: size * 0.8,
        ),
      );
    }

    // Otherwise, try to load the image
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
              child: Icon(
                Icons.account_circle_outlined,
                color: Colors.white,
                size: size * 0.8,
              ),
            );
          },
        ),
      ),
    );
  }
}

class VerticalScrollbar extends StatefulWidget {
  final ScrollController? controller;
  final double height;

  const VerticalScrollbar({super.key, this.controller, this.height = 300});

  @override
  State<VerticalScrollbar> createState() => _VerticalScrollbarState();
}

class _VerticalScrollbarState extends State<VerticalScrollbar> {
  late ScrollController _scrollController;
  double _scrollThumbPosition = 0;
  double _scrollThumbHeight = 50;
  bool _isDragging = false;
  bool _controllerReady = false;
  double _trackHeight = 300;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _initializeController();
  }

  void _initializeController() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Try to get height from context if available
        final context = this.context;
        if (context != null) {
          final renderBox = context.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            _trackHeight = renderBox.size.height;
          }
        }

        setState(() {
          _controllerReady = _scrollController.hasClients;
        });
        if (_controllerReady) {
          _scrollController.addListener(_updateScrollThumb);
          _updateScrollThumb();
        } else {
          Future.delayed(const Duration(milliseconds: 50), () {
            if (mounted) {
              setState(() {
                _controllerReady = _scrollController.hasClients;
              });
              if (_scrollController.hasClients) {
                _scrollController.addListener(_updateScrollThumb);
                _updateScrollThumb();
              }
            }
          });
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant VerticalScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.height != widget.height) {
      _scrollController.removeListener(_updateScrollThumb);
      _scrollController = widget.controller ?? ScrollController();
      _controllerReady = false;
      _initializeController();
    }
  }

  void _updateScrollThumb() {
    if (!_isDragging && mounted && _scrollController.hasClients) {
      try {
        final position = _scrollController.position;
        final maxScrollExtent = position.maxScrollExtent;
        final viewportDimension = position.viewportDimension;

        if (maxScrollExtent <= 0) {
          setState(() {
            _scrollThumbHeight = widget.height;
            _scrollThumbPosition = 0;
          });
          return;
        }

        final totalContentHeight = maxScrollExtent + viewportDimension;

        if (totalContentHeight > 0) {
          final visibleRatio = viewportDimension / totalContentHeight;
          _scrollThumbHeight = (widget.height * visibleRatio).clamp(
            25.0,
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
    if (!_controllerReady || !_scrollController.hasClients) return;
    _isDragging = true;
    _scrollToPosition(details.localPosition.dy);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_controllerReady || !_scrollController.hasClients) return;
    _scrollToPosition(details.localPosition.dy);
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    _isDragging = false;
    if (_controllerReady && _scrollController.hasClients) {
      _updateScrollThumb();
    }
  }

  void _scrollToPosition(double localPosition) {
    if (!_controllerReady || !_scrollController.hasClients) return;

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
  void dispose() {
    if (_controllerReady) {
      _scrollController.removeListener(_updateScrollThumb);
    }
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showThumb =
        _controllerReady &&
        _scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0;

    return Container(
      width: 2,
      height: widget.height,
      child: Stack(
        children: [
          if (showThumb)
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
