import 'package:flutter/material.dart';
import 'custom_button.dart';

class AddNewProfileButton extends StatelessWidget {
  final bool isTablet;
  final VoidCallback onTap;
  final String buttonText;
  final Color startColor;
  final Color endColor;
  final Color textColor;
  final Color backgroundColor;
  final Color borderColor;

  const AddNewProfileButton({
    super.key,
    required this.isTablet,
    required this.onTap,
    this.buttonText = 'Add New Profile',
    this.startColor = const Color(0xFF0B1320),
    this.endColor = const Color(0xFF00F0FF),
    this.textColor = Colors.white,
    this.backgroundColor = const Color(0xFF0B1320),
    this.borderColor = const Color(0xFF00F0FF),
  });

  @override
  Widget build(BuildContext context) {
    final buttonWidth = isTablet ? 220.0 : 180.0;
    final buttonHeight = isTablet ? 50.0 : 40.0;
    final fontSize = isTablet ? 22.0 : 20.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: isTablet ? 50 : 10),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [startColor, endColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: isTablet ? 30 : 20),
        CustomButton(
          text: buttonText,
          width: buttonWidth,
          height: buttonHeight,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          textColor: textColor,
          borderColor: borderColor,
          backgroundColor: backgroundColor,
          onTap: onTap,
        ),
        SizedBox(width: isTablet ? 30 : 20),
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isTablet ? 50 : 10),
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [endColor, startColor],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
