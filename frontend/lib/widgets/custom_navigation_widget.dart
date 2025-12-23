// custom_navigation_widget.dart
import 'package:flutter/material.dart';
import 'custom_button.dart';

class CustomNavigationWidget extends StatefulWidget {
  final String cancelText;
  final String nextText;
  final VoidCallback onCancel;
  final VoidCallback? onNext;

  // Cancel button specific styling
  final double cancelButtonWidth;
  final double cancelButtonHeight;
  final double cancelFontSize;
  final FontWeight cancelFontWeight;
  final Color cancelTextColor;
  final Color cancelBorderColor;
  final Color cancelBackgroundColor;
  final double cancelBorderRadius;
  final Gradient? cancelGradient;
  final List<BoxShadow>? cancelBoxShadow;
  final Widget? cancelChild;

  // Next button specific styling
  final double nextButtonWidth;
  final double nextButtonHeight;
  final double nextFontSize;
  final FontWeight nextFontWeight;
  final Color nextTextColor;
  final Color nextBorderColor;
  final Color nextBackgroundColor;
  final double nextBorderRadius;
  final Gradient? nextGradient;
  final List<BoxShadow>? nextBoxShadow;
  final Widget? nextChild;

  // Line styling
  final double lineHeight;
  final double lineRadius;
  final double spacing;
  final Color startGradientColor;
  final Color endGradientColor;

  // New properties for disable state and error handling
  final bool isNextEnabled;
  final Color nextDisabledTextColor;
  final Color nextDisabledBorderColor;
  final VoidCallback?
  onNextDisabledTap; // Callback when disabled Next is tapped

  const CustomNavigationWidget({
    Key? key,
    // Common properties
    this.cancelText = "Cancel",
    this.nextText = "Next",
    required this.onCancel,
    this.onNext,
    this.spacing = 16,

    // Cancel button defaults
    this.cancelButtonWidth = 106,
    this.cancelButtonHeight = 40,
    this.cancelFontSize = 20,
    this.cancelFontWeight = FontWeight.w600,
    this.cancelTextColor = Colors.white,
    this.cancelBorderColor = const Color(0xFF00F0FF),
    this.cancelBackgroundColor = Colors.transparent,
    this.cancelBorderRadius = 10,
    this.cancelGradient,
    this.cancelBoxShadow,
    this.cancelChild,

    // Next button defaults
    this.nextButtonWidth = 106,
    this.nextButtonHeight = 40,
    this.nextFontSize = 20,
    this.nextFontWeight = FontWeight.w600,
    this.nextTextColor = Colors.white,
    this.nextBorderColor = const Color(0xFF00F0FF),
    this.nextBackgroundColor = Colors.transparent,
    this.nextBorderRadius = 10,
    this.nextGradient,
    this.nextBoxShadow,
    this.nextChild,

    // Line defaults
    this.lineHeight = 4,
    this.lineRadius = 11,
    this.startGradientColor = const Color(0xFF00F0FF),
    this.endGradientColor = const Color(0xFF0B1320),

    // New properties
    this.isNextEnabled = true,
    this.nextDisabledTextColor = const Color(0xFF718096),
    this.nextDisabledBorderColor = const Color(0xFF4A5568),
    this.onNextDisabledTap,
  }) : super(key: key);

  @override
  State<CustomNavigationWidget> createState() => _CustomNavigationWidgetState();
}

class _CustomNavigationWidgetState extends State<CustomNavigationWidget> {
  bool _isNextHovered = false;

  void _handleNextTap() {
    if (widget.isNextEnabled) {
      widget.onNext?.call();
    } else {
      widget.onNextDisabledTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left gradient line
          Expanded(
            child: Container(
              height: widget.lineHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.lineRadius),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [widget.startGradientColor, widget.endGradientColor],
                ),
              ),
            ),
          ),

          SizedBox(width: widget.spacing),

          // Cancel button with custom styling
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomButton(
              text: widget.cancelText,
              child: widget.cancelChild,
              width: widget.cancelButtonWidth,
              height: widget.cancelButtonHeight,
              fontSize: widget.cancelFontSize,
              fontWeight: widget.cancelFontWeight,
              textColor: widget.cancelTextColor,
              backgroundColor: widget.cancelBackgroundColor,
              borderColor: widget.cancelBorderColor,
              borderRadius: widget.cancelBorderRadius,
              gradient: widget.cancelGradient,
              boxShadow: widget.cancelBoxShadow,
              onTap: widget.onCancel,
            ),
          ),

          SizedBox(width: widget.spacing),

          // Next button with hover effects and disable state
          MouseRegion(
            onEnter: (_) => widget.isNextEnabled
                ? setState(() => _isNextHovered = true)
                : null,
            onExit: (_) => setState(() => _isNextHovered = false),
            cursor: widget.isNextEnabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: _handleNextTap,
              child: CustomButton(
                text: widget.nextText,
                child: widget.nextChild,
                width: widget.nextButtonWidth,
                height: widget.nextButtonHeight,
                fontSize: widget.nextFontSize,
                fontWeight: widget.nextFontWeight,
                textColor: widget.isNextEnabled
                    ? widget.nextTextColor
                    : widget.nextDisabledTextColor,
                backgroundColor: widget.isNextEnabled
                    ? (_isNextHovered
                          ? const Color(0xFF00F0FF).withOpacity(0.15)
                          : widget.nextBackgroundColor)
                    : widget.nextBackgroundColor,
                borderColor: widget.isNextEnabled
                    ? widget.nextBorderColor
                    : widget.nextDisabledBorderColor,
                borderRadius: widget.nextBorderRadius,
                gradient: widget.nextGradient,
                boxShadow: widget.nextBoxShadow,
                onTap: null, // Handled by parent GestureDetector
              ),
            ),
          ),

          SizedBox(width: widget.spacing),

          // Right gradient line
          Expanded(
            child: Container(
              height: widget.lineHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.lineRadius),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [widget.endGradientColor, widget.startGradientColor],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
