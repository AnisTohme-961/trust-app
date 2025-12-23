// custom_navigation_widget.dart
import 'package:flutter/material.dart';
import 'custom_button.dart';

class CustomNavigationWidget extends StatefulWidget {
  final String leftText;
  final String rightText;
  final VoidCallback onClickLeftButton;
  final VoidCallback? onClickRightButton;

  // Cancel button specific styling
  final double leftButtonWidth;
  final double leftButtonHeight;
  final double leftFontSize;
  final FontWeight leftFontWeight;
  final Color leftTextColor;
  final Color leftBorderColor;
  final Color leftBackgroundColor;
  final double leftBorderRadius;
  final Gradient? leftGradient;
  final List<BoxShadow>? leftBoxShadow;
  final Widget? leftChild;

  // Next button specific styling
  final double rightButtonWidth;
  final double rightButtonHeight;
  final double rightFontSize;
  final FontWeight rightFontWeight;
  final Color rightTextColor;
  final Color rightBorderColor;
  final Color rightBackgroundColor;
  final double rightBorderRadius;
  final Gradient? rightGradient;
  final List<BoxShadow>? rightBoxShadow;
  final Widget? rightChild;

  // Line styling
  final double lineHeight;
  final double lineRadius;
  final double spacing;
  final Color startGradientColor;
  final Color endGradientColor;

  // New properties for disable state and error handling
  final bool isRightButtonEnabled;
  final Color rightDisabledTextColor;
  final Color rightDisabledBorderColor;
  final VoidCallback?
  onRightButtonDisabledTap; // Callback when disabled Next is tapped

  const CustomNavigationWidget({
    Key? key,
    // Common properties
    this.leftText = "Cancel",
    this.rightText = "Next",
    required this.onClickLeftButton,
    this.onClickRightButton,
    this.spacing = 16,

    // Left button defaults
    this.leftButtonWidth = 106,
    this.leftButtonHeight = 40,
    this.leftFontSize = 20,
    this.leftFontWeight = FontWeight.w600,
    this.leftTextColor = Colors.white,
    this.leftBorderColor = const Color(0xFF00F0FF),
    this.leftBackgroundColor = Colors.transparent,
    this.leftBorderRadius = 10,
    this.leftGradient,
    this.leftBoxShadow,
    this.leftChild,

    // Right button defaults
    this.rightButtonWidth = 106,
    this.rightButtonHeight = 40,
    this.rightFontSize = 20,
    this.rightFontWeight = FontWeight.w600,
    this.rightTextColor = Colors.white,
    this.rightBorderColor = const Color(0xFF00F0FF),
    this.rightBackgroundColor = Colors.transparent,
    this.rightBorderRadius = 10,
    this.rightGradient,
    this.rightBoxShadow,
    this.rightChild,

    // Line defaults
    this.lineHeight = 4,
    this.lineRadius = 11,
    this.startGradientColor = const Color(0xFF00F0FF),
    this.endGradientColor = const Color(0xFF0B1320),

    // New properties
    this.isRightButtonEnabled = true,
    this.rightDisabledTextColor = const Color(0xFF718096),
    this.rightDisabledBorderColor = const Color(0xFF4A5568),
    this.onRightButtonDisabledTap,
  }) : super(key: key);

  @override
  State<CustomNavigationWidget> createState() => _CustomNavigationWidgetState();
}

class _CustomNavigationWidgetState extends State<CustomNavigationWidget> {
  bool _isNextHovered = false;

  void _handleNextTap() {
    if (widget.isRightButtonEnabled) {
      widget.onClickRightButton?.call();
    } else {
      widget.onRightButtonDisabledTap?.call();
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
              text: widget.leftText,
              child: widget.leftChild,
              width: widget.leftButtonWidth,
              height: widget.leftButtonHeight,
              fontSize: widget.leftFontSize,
              fontWeight: widget.leftFontWeight,
              textColor: widget.leftTextColor,
              backgroundColor: widget.leftBackgroundColor,
              borderColor: widget.leftBorderColor,
              borderRadius: widget.leftBorderRadius,
              gradient: widget.leftGradient,
              boxShadow: widget.leftBoxShadow,
              onTap: widget.onClickLeftButton,
            ),
          ),

          SizedBox(width: widget.spacing),

          // Next button with hover effects and disable state
          MouseRegion(
            onEnter: (_) => widget.isRightButtonEnabled
                ? setState(() => _isNextHovered = true)
                : null,
            onExit: (_) => setState(() => _isNextHovered = false),
            cursor: widget.isRightButtonEnabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: GestureDetector(
              onTap: _handleNextTap,
              child: CustomButton(
                text: widget.rightText,
                child: widget.rightChild,
                width: widget.rightButtonWidth,
                height: widget.rightButtonHeight,
                fontSize: widget.rightFontSize,
                fontWeight: widget.rightFontWeight,
                textColor: widget.isRightButtonEnabled
                    ? widget.rightTextColor
                    : widget.rightDisabledTextColor,
                backgroundColor: widget.isRightButtonEnabled
                    ? (_isNextHovered
                          ? const Color(0xFF00F0FF).withOpacity(0.15)
                          : widget.rightBackgroundColor)
                    : widget.rightBackgroundColor,
                borderColor: widget.isRightButtonEnabled
                    ? widget.rightBorderColor
                    : widget.rightDisabledBorderColor,
                borderRadius: widget.rightBorderRadius,
                gradient: widget.rightGradient,
                boxShadow: widget.rightBoxShadow,
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
