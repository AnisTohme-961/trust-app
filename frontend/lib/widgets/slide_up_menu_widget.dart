import 'package:flutter/material.dart';

class SlideUpMenu extends StatefulWidget {
  final double menuHeight;
  final Color backgroundColor;
  final Color shadowColor;
  final double borderRadius;
  final Duration duration;
  final Curve curve;
  final Widget? dragHandle;
  final VoidCallback? onToggle;
  final VoidCallback? onClose;
  final bool initiallyVisible;
  final bool? isVisible;
  final Widget? child;
  final double minHeight; // Minimum height when dragged
  final double maxHeight; // Maximum height (screen height - top margin)
  final double closeThreshold; // Percentage to close (dragged down)
  final double openThreshold; // Percentage to open fully (dragged up)

  const SlideUpMenu({
    Key? key,
    required this.menuHeight,
    this.minHeight = 100,
    this.maxHeight = double.infinity,
    this.backgroundColor = const Color(0xFF0B1320),
    this.shadowColor = const Color(0xFF00F0FF),
    this.borderRadius = 20.0,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
    this.dragHandle,
    this.onToggle,
    this.onClose,
    this.initiallyVisible = false,
    this.isVisible,
    this.child,
    this.closeThreshold = 0.15, // 15% of screen height to close
    this.openThreshold = 0.85, // 85% of screen height to open fully
  }) : super(key: key);

  @override
  State<SlideUpMenu> createState() => _SlideUpMenuState();
}

class _SlideUpMenuState extends State<SlideUpMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentHeight = 0;
  double _startDragY = 0;
  double _startDragHeight = 0;
  bool _isDragging = false;
  bool _closingNormally = false;

  // Close threshold (percentage of screen height)
  static const double _closeThreshold = 0.15;

  @override
  void initState() {
    super.initState();
    _currentHeight = widget.menuHeight;

    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    );

    if (widget.isVisible ?? widget.initiallyVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SlideUpMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible == true) {
        // When reopening, reset to static height
        _currentHeight = widget.menuHeight;
        _closingNormally = false;
        _animationController.forward();
      } else if (widget.isVisible == false && !_closingNormally) {
        // When closing from external (normal close), animate down
        // This happens when user taps outside, taps language item, etc.
        _animationController.reverse();
      }
      // If isVisible == false and _closingNormally is true,
      // it means we're closing from drag-to-bottom, so do nothing
    }
  }

  void _toggleMenu() {
    if (widget.isVisible == null) {
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else {
        // When opening, reset to static height
        _currentHeight = widget.menuHeight;
        _animationController.forward();
      }
    } else {
      // If externally controlled, just call onToggle
      widget.onToggle?.call();
    }
  }

  void _closeFromDrag() {
    // For drag-to-bottom closing:
    // 1. Mark that we're closing from drag (not normal close)
    // 2. Immediately hide the menu
    // 3. Call onClose to update external state

    _closingNormally = false;

    // Immediately set animation to 0 to hide
    _animationController.value = 0;

    // Call onClose callback
    widget.onClose?.call();

    // Reset to static height for next opening
    _currentHeight = widget.menuHeight;
  }

  void _closeNormally() {
    // For normal closing (tap handle, tap outside, etc.):
    // 1. Mark that we're closing normally
    // 2. Let the animation controller reverse naturally
    // 3. The external state change will trigger didUpdateWidget

    _closingNormally = true;
    _animationController.reverse();
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _startDragY = details.globalPosition.dy;
      _startDragHeight = _currentHeight;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final double deltaY = _startDragY - details.globalPosition.dy;
    double newHeight = _startDragHeight + deltaY;

    // Constrain height between minHeight and maxHeight
    newHeight = newHeight.clamp(widget.minHeight, widget.maxHeight);

    setState(() {
      _currentHeight = newHeight;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final currentHeightPercentage = _currentHeight / screenHeight;

    // Check if dragged below close threshold (close condition)
    if (currentHeightPercentage < widget.closeThreshold) {
      // Close the menu immediately from drag (no slide down)
      _closeFromDrag();
    }
    // Check if dragged above open threshold (open fully condition)
    else if (currentHeightPercentage > widget.openThreshold) {
      // Open menu fully - snap to maxHeight
      // This will actually close the menu since it goes off-screen
      _closeMenuByOpeningFully();
    } else {
      // Keep the menu at the dragged height
      // No snap back - just stay where it is
    }

    setState(() {
      _isDragging = false;
    });
  }

  void _closeMenuByOpeningFully() {
    // When dragged to top, we want to:
    // 1. Animate to maxHeight (or screen height) to slide off screen
    // 2. Then close the menu

    // First, animate to maxHeight
    setState(() {
      _currentHeight = widget.maxHeight;
    });

    // After animation, close the menu
    Future.delayed(const Duration(milliseconds: 200), () {
      _closeFromDrag();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // If menu is closing from drag and animation is at 0, don't render
        if (!_closingNormally && _animationController.value == 0) {
          return const SizedBox.shrink();
        }

        // If widget.isVisible is false but we're animating (normal close), still render
        // This allows the slide-down animation to complete

        // Use dragged height when dragging, otherwise use appropriate height
        double displayHeight;

        if (_isDragging) {
          // When dragging, use current dragged height
          displayHeight = _currentHeight;
        } else if (_animationController.value < 1.0) {
          // When animating open/close, use animated height
          displayHeight = widget.menuHeight * _animation.value;
        } else {
          // When fully open, use current height (may be dragged height or static height)
          displayHeight = _currentHeight;
        }

        final bottomPosition =
            -(widget.menuHeight) + (_animation.value * widget.menuHeight);

        return Positioned(
          bottom: bottomPosition,
          left: 7,
          right: 7,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: _handleDragStart,
            onVerticalDragUpdate: _handleDragUpdate,
            onVerticalDragEnd: _handleDragEnd,
            child: Container(
              height: displayHeight,
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                boxShadow:
                    _animation.value > 0.1 && displayHeight > widget.minHeight
                    ? [
                        BoxShadow(
                          color: widget.shadowColor,
                          offset: const Offset(0, -6),
                          blurRadius: 10,
                        ),
                      ]
                    : [],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.borderRadius),
                  topRight: Radius.circular(widget.borderRadius),
                ),
              ),
              child: Column(
                children: [
                  // Drag handle with visual feedback
                  GestureDetector(
                    onTap: () {
                      // For normal close when tapping handle
                      if (_animationController.status ==
                          AnimationStatus.completed) {
                        _closeNormally();
                        widget.onToggle?.call();
                      } else {
                        _toggleMenu();
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15),
                      child: Center(
                        child: widget.dragHandle ?? _defaultDragHandle(),
                      ),
                    ),
                  ),
                  // Menu content - FIXED: Removed ConstrainedBox, just use Expanded
                  if (displayHeight > 50)
                    Expanded(child: widget.child ?? _defaultContent()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _defaultDragHandle() {
    return Container(
      width: 90,
      height: 9,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(4.5),
      ),
    );
  }

  Widget _defaultContent() {
    return const Center(
      child: Text('Menu Content', style: TextStyle(color: Colors.white)),
    );
  }
}
