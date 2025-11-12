import 'dart:async';
import 'package:flutter/material.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  const ErrorBanner({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 430,
        height: 200,
        padding: const EdgeInsets.fromLTRB(23, 14, 23, 40),
        decoration: BoxDecoration(
          color: const Color(0xFF0B1320),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          border: Border.all(color: const Color(0xFFF42222), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFAF2222),
              offset: Offset(0, -3),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Red line above everything
            Container(width: 80, height: 2, color: const Color(0xFFF42222)),
            const SizedBox(height: 12),
            // Row with image on the left and text on the right
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Image.asset('assets/images/attention.png'),
                ),
                const SizedBox(width: 12), // spacing between image and text
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      height: 1.2,
                      letterSpacing: 0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ErrorStack extends StatefulWidget {
  const ErrorStack({Key? key}) : super(key: key);

  @override
  State<ErrorStack> createState() => ErrorStackState();
}

class ErrorStackState extends State<ErrorStack> {
  final List<_ErrorItem> _errors = [];

  void showError(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final item = _ErrorItem(message: message);
    setState(() => _errors.add(item));

    // Auto-remove after duration
    item.timer = Timer(duration, () {
      if (mounted) {
        setState(() => _errors.remove(item));
      }
    });
  }

  @override
  void dispose() {
    for (var e in _errors) {
      e.timer?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        ignoring: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          verticalDirection: VerticalDirection.up, // bottom → top order
          children: [
            for (int i = 0; i < _errors.length; i++) ...[
              AnimatedSlide(
                key: ValueKey(_errors[i]),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOut,
                offset: Offset(0, 0), // start at position
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOut,
                  opacity: 1.0,
                  child: ErrorBanner(message: _errors[i].message),
                ),
              ),
              if (i != _errors.length - 1) const SizedBox(height: 30),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorItem {
  final String message;
  Timer? timer;
  _ErrorItem({required this.message});
}
