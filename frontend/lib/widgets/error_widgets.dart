import 'dart:async';
import 'package:flutter/material.dart';

class ErrorBanner extends StatefulWidget {
  final String message;
  final Duration duration;

  const ErrorBanner({
    Key? key,
    required this.message,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1320),
                border: Border(
                  top: const BorderSide(color: Color(0xFFF42222), width: 2),
                  left: const BorderSide(color: Color(0xFFF42222), width: 2),
                  right: const BorderSide(color: Color(0xFFF42222), width: 2),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFAF2222),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(23, 20, 23, 20),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF42222),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.priority_high,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                                height: 1.3,
                                letterSpacing: 0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Progress bar as bottom border
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: 1 - _progressController.value,
                      child: Container(
                        height: 2,
                        color: const Color(0xFFF42222),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _createOverlay();
    });
  }

  void _createOverlay() {
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: IgnorePointer(
          ignoring: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < _errors.length; i++) ...[
                if (i != 0) const SizedBox(height: 16),
                AnimatedSlide(
                  key: ValueKey(_errors[i]),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  offset: const Offset(0, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    opacity: 1.0,
                    child: ErrorBanner(
                      message: _errors[i].message,
                      duration: const Duration(seconds: 3),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final item = _ErrorItem(message: message);
    setState(() => _errors.add(item));

    // Update the overlay
    _overlayEntry?.markNeedsBuild();

    // Auto-remove after duration
    item.timer = Timer(duration, () {
      if (mounted) {
        setState(() => _errors.remove(item));
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  @override
  void dispose() {
    for (var e in _errors) {
      e.timer?.cancel();
    }
    _overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Return an empty container since we're using Overlay
    return const SizedBox.shrink();
  }
}

class _ErrorItem {
  final String message;
  Timer? timer;
  _ErrorItem({required this.message});
}
