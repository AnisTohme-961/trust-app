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
  final bool initiallyVisible;
  final bool? isVisible; // Add this for external control
  final Widget? child; // Add this for menu content

  const SlideUpMenu({
    Key? key,
    required this.menuHeight,
    this.backgroundColor = const Color(0xFF0B1320),
    this.shadowColor = const Color(0xFF00F0FF),
    this.borderRadius = 20.0,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeInOut,
    this.dragHandle,
    this.onToggle,
    this.initiallyVisible = false,
    this.isVisible,
    this.child,
  }) : super(key: key);

  @override
  State<SlideUpMenu> createState() => _SlideUpMenuState();
}

class _SlideUpMenuState extends State<SlideUpMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.curve,
    );

    // Initialize based on external control or internal state
    if (widget.isVisible ?? widget.initiallyVisible) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(covariant SlideUpMenu oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle external visibility changes
    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible == true) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _toggleMenu() {
    if (widget.isVisible == null) {
      // If no external control, handle internally
      if (_animationController.status == AnimationStatus.completed) {
        _animationController.reverse();
      } else {
        _animationController.forward();
      }
    }
    widget.onToggle?.call();
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
        return Positioned(
          bottom: -(widget.menuHeight) + (_animation.value * widget.menuHeight),
          left: 7,
          right: 7,
          child: Container(
            height: widget.menuHeight,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              boxShadow: _animation.value > 0.1
                  ? [
                      // Only show shadow when menu is sufficiently visible
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
                // Drag handle
                GestureDetector(
                  onTap: _toggleMenu,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Center(
                      child: widget.dragHandle ?? _defaultDragHandle(),
                    ),
                  ),
                ),
                // Menu content
                Expanded(child: widget.child ?? _defaultContent()),
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
