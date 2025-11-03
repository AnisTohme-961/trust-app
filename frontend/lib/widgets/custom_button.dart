import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final Widget? child; // add this
  final VoidCallback? onTap;
  final double width;
  final double height;
  final Color borderColor;
  final Color textColor;
  final Color backgroundColor;
  final double borderRadius;
  final double fontSize;
  final Duration animationDuration;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final String fontFamily;
  final FontWeight fontWeight;

  const CustomButton({
    Key? key,
    required this.text,
    this.child,
    required this.width,
    required this.height,
    this.onTap,
    this.borderColor = const Color(0xFF00F0FF),
    this.textColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.borderRadius = 10,
    this.fontSize = 14,
    this.animationDuration = const Duration(milliseconds: 100),
    this.gradient,
    this.boxShadow,
    this.fontFamily = 'Inter',
    this.fontWeight = FontWeight.w500,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: animationDuration,
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(width: 1.2, color: borderColor),
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          color: gradient == null ? backgroundColor : null,
          boxShadow: boxShadow,
        ),
        child:
            child ??
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
                fontSize: fontSize,
                color: textColor,
              ),
            ),
      ),
    );
  }
}
