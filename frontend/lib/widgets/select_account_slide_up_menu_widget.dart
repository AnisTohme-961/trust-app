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
  final double closeThreshold;
  final double openThreshold;

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
    this.closeThreshold = 0.15,
    this.openThreshold = 0.85,
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
  double _startDragY = 0;
  double _startDragHeight = 0;
  bool _isDragging = false;
  bool _closingNormally = false;

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
        _closingNormally = false;
        _animationController.forward();
      } else if (widget.isVisible == false && !_closingNormally) {
        _animationController.reverse();
      }
    }
  }

  void _toggleMenu() {
    if (widget.isVisible == null) {
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else {
        _currentHeight = widget.menuHeight;
        _animationController.forward();
      }
    } else {
      widget.onToggle?.call();
    }
  }

  void _closeFromDrag() {
    _closingNormally = false;
    _animationController.value = 0;
    widget.onClose?.call();
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
    newHeight = newHeight.clamp(widget.minHeight, widget.maxHeight);

    setState(() {
      _currentHeight = newHeight;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    final screenHeight = MediaQuery.of(context).size.height;
    final currentHeightPercentage = _currentHeight / screenHeight;

    if (currentHeightPercentage < widget.closeThreshold) {
      _closeFromDrag();
    } else if (currentHeightPercentage > widget.openThreshold) {
      _closeMenuByOpeningFully();
    }

    setState(() {
      _isDragging = false;
    });
  }

  void _closeMenuByOpeningFully() {
    setState(() {
      _currentHeight = widget.maxHeight;
    });

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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        // Don't render if animation is at 0 and not visible
        if (!_closingNormally && _animationController.value == 0) {
          return const SizedBox.shrink();
        }

        double displayHeight;

        if (_isDragging) {
          displayHeight = _currentHeight;
        } else if (_animationController.value < 1.0) {
          displayHeight = widget.menuHeight * _animation.value;
        } else {
          displayHeight = _currentHeight;
        }

        // Ensure displayHeight is at least minHeight
        displayHeight = displayHeight.clamp(widget.minHeight, widget.maxHeight);

        final bottomPosition =
            -(widget.menuHeight) + (_animation.value * widget.menuHeight);

        // Calculate content height (ensure it's not negative)
        final double dragHandleHeight = 50;
        final double contentHeight = displayHeight - dragHandleHeight;
        final double safeContentHeight = contentHeight > 0 ? contentHeight : 0;

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
                  // Drag handle area
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_animationController.status ==
                          AnimationStatus.completed) {
                        _closeNormally();
                        widget.onToggle?.call();
                      } else {
                        _toggleMenu();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      height: dragHandleHeight,
                      color: Colors.transparent,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: widget.dragHandle ?? _defaultDragHandle(),
                        ),
                      ),
                    ),
                  ),

                  // Menu content - Use Expanded instead of fixed height
                  if (safeContentHeight > 0)
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
