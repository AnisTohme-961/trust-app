import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/signup_data_provider.dart';

class SelectAccountContent extends StatelessWidget {
  final VoidCallback onClose;
  const SelectAccountContent({required this.onClose, super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return Stack(
      children: [
        // Cyan horizontal line (main title)
        // Positioned(
        //   top: 74,
        //   left: 93,
        //   child: CustomPaint(
        //     size: const Size(244, 0),
        //     painter: VLinePainter(),
        //   ),
        // ),

        // Title
        const Positioned(
          top: 60,
          left: 145,
          child: Text(
            'Select an Account',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),

        // V-line handle (clickable)
        Positioned(
          top: 10, // adjust to place above or below title
          left: 155, // centered horizontally
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onClose, // close dropdown when clicked
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CustomPaint(
                  size: const Size(120, 20), // same as your language dropdown
                  painter: VLinePainter(),
                ),
              ),
            ),
          ),
        ),

        // Account frame
        // Account frame
        // Account frame
        Positioned(
          top: 114,
          left: 59,
          child: Container(
            width: 312,
            height: 514,
            color: Colors.transparent,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/sign-in');
                },
                child: Container(
                  width: 312,
                  height: 69,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF00F0FF),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      // Profile Image
                      Positioned(
                        top: 9,
                        left: 11,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white12,
                            image: const DecorationImage(
                              image: AssetImage('assets/images/image1.png'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      // User Full Name
                      Positioned(
                        top: 12,
                        left: 95,
                        child: Text(
                          '${userProvider.firstName}${userProvider.lastName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            height: 1.0,
                          ),
                        ),
                      ),
                      // EID
                      Positioned(
                        top: 38,
                        left: 96,
                        child: Text(
                          'EID: ${userProvider.eid}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Cyan horizontal line painter
class VLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F0FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();

    path.moveTo(0, size.height / 2);
    path.lineTo(size.width / 2 - 10, size.height / 2);
    path.lineTo(size.width / 2, size.height / 2 + 5);
    path.lineTo(size.width / 2 + 10, size.height / 2);
    path.lineTo(size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
