import 'package:flutter/material.dart';

class SelectAccountSlideUpMenu extends StatefulWidget {
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
  final double minHeight;
  final double maxHeight;

  const SelectAccountSlideUpMenu({
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
  }) : super(key: key);

  @override
  State<SelectAccountSlideUpMenu> createState() =>
      _SelectAccountSlideUpMenuState();
}

class _SelectAccountSlideUpMenuState extends State<SelectAccountSlideUpMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentHeight = 0;
  double _dragStartY = 0;
  double _dragStartHeight = 0;
  bool _isDragging = false;

  // Close threshold - if dragged below this height, close the menu
  static const double _closeThresholdRatio = 0.5; // 50% of menu height

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
  void didUpdateWidget(covariant SelectAccountSlideUpMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible == true) {
        _currentHeight = widget.menuHeight;
        _isDragging = false;
        _animationController.forward();
      } else if (widget.isVisible == false) {
        _animationController.reverse();
      }
    }
  }

  void _handleDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _dragStartY = details.globalPosition.dy;
      _dragStartHeight = _currentHeight;
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    // Calculate how much we've dragged (positive = down, negative = up)
    final double dragDelta = details.globalPosition.dy - _dragStartY;

    // New height = start height - drag distance
    // Positive dragDelta (drag down) = height decreases
    // Negative dragDelta (drag up) = height increases
    double newHeight = _dragStartHeight - dragDelta;

    // Constrain height
    newHeight = newHeight.clamp(widget.minHeight, widget.maxHeight);

    setState(() {
      _currentHeight = newHeight;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    // Check if dragged below threshold to close
    final closeThresholdHeight = widget.menuHeight * _closeThresholdRatio;

    if (_currentHeight <= closeThresholdHeight) {
      // Close the menu
      setState(() {
        _isDragging = false;
      });
      _animationController.value = 0;
      _currentHeight = widget.menuHeight; // Reset for next opening
      widget.onClose?.call();
    } else {
      // Keep the menu at the dragged height
      setState(() {
        _isDragging = false;
      });
    }
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
        // Don't render if animation is at 0 and not visible
        if (_animation.value == 0 && widget.isVisible == false) {
          return const SizedBox.shrink();
        }

        double displayHeight;

        if (_isDragging) {
          // When actively dragging, use current dragged height
          displayHeight = _currentHeight;
        } else if (_animationController.value < 1.0) {
          // When animating open/close
          displayHeight = widget.menuHeight * _animation.value;
        } else {
          // When fully open and not dragging, use current height
          displayHeight = _currentHeight;
        }

        // Ensure displayHeight is at least minHeight
        displayHeight = displayHeight.clamp(widget.minHeight, widget.maxHeight);

        final bottomPosition =
            -(widget.menuHeight) + (_animation.value * widget.menuHeight);

        // Calculate content height (ensure it's not negative)
        final double contentHeight = displayHeight - 50;
        final double safeContentHeight = contentHeight > 0 ? contentHeight : 0;

        return Positioned(
          bottom: bottomPosition,
          left: 7,
          right: 7,
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
                // Drag handle area
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragStart: _handleDragStart,
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  onTap: () {
                    if (_animationController.status ==
                        AnimationStatus.completed) {
                      _animationController.reverse().then((_) {
                        widget.onToggle?.call();
                      });
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    color: Colors.transparent,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: widget.dragHandle ?? _defaultDragHandle(),
                      ),
                    ),
                  ),
                ),

                // Menu content with explicit height constraint
                if (safeContentHeight >
                    0) // Only show content if there's positive height
                  SizedBox(
                    height: safeContentHeight,
                    child: widget.child ?? _defaultContent(),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _defaultDragHandle() {
    return Container(
      width: 90,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _defaultContent() {
    return const Center(
      child: Text('Menu Content', style: TextStyle(color: Colors.white)),
    );
  }
}
