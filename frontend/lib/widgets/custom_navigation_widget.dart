// custom_navigation_widget.dart
import 'package:flutter/material.dart';
import 'custom_button.dart';

class CustomNavigationWidget extends StatelessWidget {
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
  }) : super(key: key);

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
              height: lineHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(lineRadius),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [startGradientColor, endGradientColor],
                ),
              ),
            ),
          ),

          SizedBox(width: spacing),

          // Cancel button with custom styling
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomButton(
              text: cancelText,
              child: cancelChild,
              width: cancelButtonWidth,
              height: cancelButtonHeight,
              fontSize: cancelFontSize,
              fontWeight: cancelFontWeight,
              textColor: cancelTextColor,
              backgroundColor: cancelBackgroundColor,
              borderColor: cancelBorderColor,
              borderRadius: cancelBorderRadius,
              gradient: cancelGradient,
              boxShadow: cancelBoxShadow,
              onTap: onCancel,
            ),
          ),

          SizedBox(width: spacing),

          // Next button with custom styling
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomButton(
              text: nextText,
              child: nextChild,
              width: nextButtonWidth,
              height: nextButtonHeight,
              fontSize: nextFontSize,
              fontWeight: nextFontWeight,
              textColor: nextTextColor,
              backgroundColor: nextBackgroundColor,
              borderColor: nextBorderColor,
              borderRadius: nextBorderRadius,
              gradient: nextGradient,
              boxShadow: nextBoxShadow,
              onTap: onNext,
            ),
          ),

          SizedBox(width: spacing),

          // Right gradient line
          Expanded(
            child: Container(
              height: lineHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(lineRadius),
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: [endGradientColor, startGradientColor],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
