import 'package:flutter/material.dart';

class FooterWidget extends StatelessWidget {
  const FooterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 22,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // "Powered by"
          const Text(
            "Powered by",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 4),

          // "Egety" + TM as superscript
          Container(
            alignment: Alignment.center,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  color: Color(0xFF00F0FF),
                ),
                children: [
                  const TextSpan(text: "Egety"),
                  WidgetSpan(
                    child: Transform.translate(
                      offset: const Offset(0, -5), // shift up for superscript
                      child: const Text(
                        'TM',
                        textScaleFactor: 0.7, // smaller size for TM
                        style: TextStyle(
                          color: Color(0xFF00F0FF),
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),

          // "©2025 All Right Reserved"
          const Text(
            "©2025 All Right Reserved",
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
