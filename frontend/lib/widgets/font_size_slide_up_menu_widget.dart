import 'package:flutter/material.dart';

class SimpleSlideUpMenu extends StatefulWidget {
  final double menuHeight;
  final Color backgroundColor;
  final Color shadowColor;
  final Color borderColor;
  final double borderRadius;
  final Duration duration;
  final Curve curve;
  final Widget? dragHandle;
  final VoidCallback? onToggle;
  final VoidCallback? onClose;
  final bool initiallyVisible;
  final bool? isVisible;
  final Widget? child;
  final double minHeight;
  final double maxHeight;

  const SimpleSlideUpMenu({
    Key? key,
    required this.menuHeight,
    this.minHeight = 100,
    this.maxHeight = double.infinity,
    this.backgroundColor = const Color(0xFF0B1320),
    this.shadowColor = const Color(0xFF00F0FF),
    this.borderColor = const Color(0xFF00F0FF),
    this.borderRadius = 20.0,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOut,
    this.dragHandle,
    this.onToggle,
    this.onClose,
    this.initiallyVisible = false,
    this.isVisible,
    this.child,
  }) : super(key: key);

  @override
  State<SimpleSlideUpMenu> createState() => _SimpleSlideUpMenuState();
}

class _SimpleSlideUpMenuState extends State<SimpleSlideUpMenu>
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
  void didUpdateWidget(covariant SimpleSlideUpMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible == true) {
        // When reopening, reset to static height
        _currentHeight = widget.menuHeight;
        _closingNormally = false;
        _animationController.forward();
      } else if (widget.isVisible == false && !_closingNormally) {
        // When closing from external (normal close), animate down
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
    _closingNormally = false;

    // Immediately set animation to 0 to hide
    _animationController.value = 0;

    // Call onClose callback
    widget.onClose?.call();

    // Reset to static height for next opening
    _currentHeight = widget.menuHeight;
  }

  void _closeNormally() {
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

    // Check if dragged below threshold (close condition)
    if (currentHeightPercentage < _closeThreshold) {
      // Close the menu immediately from drag (no slide down)
      _closeFromDrag();
    } else {
      // Keep the menu at the dragged height
      // No snap back - just stay where it is
    }

    setState(() {
      _isDragging = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // If menu is closing from drag and animation is at 0, don't render
        if (!_closingNormally && _animationController.value == 0) {
          return const SizedBox.shrink();
        }

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

        final bottomPosition = displayHeight * (_animation.value - 1);

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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.borderRadius),
                  topRight: Radius.circular(widget.borderRadius),
                ),
                // REMOVED the border completely
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
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(widget.borderRadius),
                  topRight: Radius.circular(widget.borderRadius),
                ),
                child: Stack(
                  children: [
                    // Drag handle (fixed at top)
                    Positioned(
                      top: 15,
                      left: 0,
                      right: 0,
                      child: GestureDetector(
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
                        child: Center(
                          child: widget.dragHandle ?? _defaultDragHandle(),
                        ),
                      ),
                    ),

                    // Content area - positioned below drag handle
                    Positioned(
                      top: 40, // Space for drag handle
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: displayHeight > 40 ? displayHeight - 40 : 0,
                        child: displayHeight > 40
                            ? SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                child: widget.child ?? _defaultContent(),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
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
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: Text('Menu Content', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
