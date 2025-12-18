import 'dart:async';
import 'package:flutter/material.dart';

class ErrorBanner extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismiss;
  final Function(bool, Duration?) onTap;
  final VoidCallback? onDismissAllAbove;
  final bool initiallyPaused;
  final Duration? initialRemainingTime;

  const ErrorBanner({
    Key? key,
    required this.message,
    required this.onDismiss,
    required this.onTap,
    this.onDismissAllAbove,
    this.duration = const Duration(seconds: 3),
    this.initiallyPaused = false,
    this.initialRemainingTime,
  }) : super(key: key);

  @override
  State<ErrorBanner> createState() => _ErrorBannerState();
}

class _ErrorBannerState extends State<ErrorBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Timer _autoDismissTimer;
  bool _isPaused = false;
  bool _isDismissing = false;
  double _dragOffset = 0.0;
  double _verticalDragOffset = 0.0;
  double _dragStart = 0.0;
  double _verticalDragStart = 0.0;
  bool _isDragging = false;
  bool _isVerticalDrag = false;
  Duration? _remainingDuration;

  @override
  void initState() {
    super.initState();

    _isPaused = widget.initiallyPaused;

    double initialProgress = 0.0;
    if (widget.initialRemainingTime != null) {
      final totalMs = widget.duration.inMilliseconds;
      final remainingMs = widget.initialRemainingTime!.inMilliseconds;
      initialProgress = 1.0 - (remainingMs / totalMs);
    }

    _progressController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _progressController.value = initialProgress;

    if (_isPaused) {
      _remainingDuration = widget.initialRemainingTime ?? widget.duration;
      _progressController.stop();
    } else {
      _startTimer(widget.initialRemainingTime ?? widget.duration);
      _progressController.forward(from: initialProgress);
    }
  }

  void _startTimer(Duration duration) {
    _autoDismissTimer = Timer(duration, () {
      if (!_isPaused && !_isDismissing) {
        widget.onDismiss();
      }
    });
  }

  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _autoDismissTimer.cancel();
        _progressController.stop();

        final remainingMilliseconds =
            widget.duration.inMilliseconds * (1 - _progressController.value);
        _remainingDuration = Duration(
          milliseconds: remainingMilliseconds.round(),
        );

        widget.onTap(_isPaused, _remainingDuration);
      } else {
        final remainingDuration =
            _remainingDuration ??
            Duration(
              milliseconds:
                  (widget.duration.inMilliseconds *
                          (1 - _progressController.value))
                      .round(),
            );

        if (remainingDuration.inMilliseconds > 0) {
          _startTimer(remainingDuration);
          _progressController.animateTo(1.0, duration: remainingDuration);
        }
        _remainingDuration = null;

        widget.onTap(_isPaused, null);
      }
    });
  }

  void _handleDragStart(DragStartDetails details) {
    _dragStart = details.globalPosition.dx;
    _verticalDragStart = details.globalPosition.dy;
    _isDragging = true;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;

    final dx = details.globalPosition.dx - _dragStart;
    final dy = details.globalPosition.dy - _verticalDragStart;

    if (!_isVerticalDrag && dy.abs() > 20 && dy.abs() > dx.abs() * 2) {
      _isVerticalDrag = true;
    }

    if (_isVerticalDrag) {
      setState(() {
        _verticalDragOffset = dy.clamp(-200, 0);
      });
    } else {
      setState(() {
        _dragOffset = dx;
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!_isDragging) return;

    if (_isVerticalDrag) {
      final double screenHeight = MediaQuery.of(context).size.height;
      final double velocity = details.velocity.pixelsPerSecond.dy;

      if (_verticalDragOffset.abs() > 48 || velocity.abs() > 500) {
        _isDismissing = true;
        setState(() {
          _verticalDragOffset = -screenHeight;
        });

        Future.delayed(const Duration(milliseconds: 10), () {
          widget.onDismissAllAbove?.call();
          widget.onDismiss();
        });
      } else {
        setState(() {
          _verticalDragOffset = 0.0;
        });
      }
    } else {
      final double screenWidth = MediaQuery.of(context).size.width;
      final double velocity = details.velocity.pixelsPerSecond.dx;

      if (_dragOffset.abs() > screenWidth * 0.3 || velocity.abs() > 500) {
        _isDismissing = true;
        final double direction = _dragOffset > 0 ? 1.0 : -1.0;
        setState(() {
          _dragOffset = direction * screenWidth;
        });

        Future.delayed(const Duration(milliseconds: 10), () {
          widget.onDismiss();
        });
      } else {
        setState(() {
          _dragOffset = 0.0;
        });
      }
    }

    _isDragging = false;
    _isVerticalDrag = false;
  }

  @override
  void dispose() {
    _autoDismissTimer.cancel();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _togglePause,
      onVerticalDragStart: _handleDragStart,
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      child: AnimatedContainer(
        duration: _isDragging
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: _isDragging ? Curves.linear : Curves.easeOut,
        transform: Matrix4.translationValues(
          _dragOffset,
          _verticalDragOffset,
          0,
        ),
        child: AnimatedBuilder(
          animation: _progressController,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF0B1320),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFFAF2222),
                    offset: Offset(0, 3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Stack(
                  children: [
                    Padding(
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
                                decoration: TextDecoration.none,
                                decorationColor: Colors.transparent,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: 1.0 - _progressController.value,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF42222),
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFF42222,
                                    ).withOpacity(0.5),
                                    blurRadius: 3,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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
  final Map<_ErrorItem, _BannerState> _bannerStates = {};
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
      builder: (context) {
        final bannerHeight = 120.0;
        final spacing = 16.0;

        // Explicitly convert to double by multiplying with 1.0
        final double totalHeight = _errors.isNotEmpty
            ? (_errors.length * (bannerHeight + spacing) - spacing).toDouble()
            : 0.0;

        return Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: IgnorePointer(
            ignoring: false,
            child: SizedBox(
              height: totalHeight,
              child: Stack(
                children: [
                  for (int i = 0; i < _errors.length; i++)
                    _buildPositionedBanner(
                      _errors[i],
                      i,
                      bannerHeight,
                      spacing,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  Widget _buildPositionedBanner(
    _ErrorItem item,
    int index,
    double bannerHeight,
    double spacing,
  ) {
    final state = _bannerStates[item];

    return Positioned(
      key: ValueKey(item),
      // Explicitly convert to double
      top: (index * (bannerHeight + spacing)).toDouble(),
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        opacity: item.isDismissing ? 0.0 : 1.0,
        onEnd: () {
          if (item.isDismissing && _errors.contains(item)) {
            _performItemRemoval(item);
          }
        },
        child: ErrorBanner(
          key: ValueKey(item),
          message: item.message,
          duration: const Duration(seconds: 3),
          onDismiss: () => _removeError(item),
          onTap: (isPaused, remainingTime) =>
              _handleBannerTap(item, isPaused, remainingTime),
          onDismissAllAbove: () => _removeAllAbove(item),
          initiallyPaused: state?.isPaused ?? false,
          initialRemainingTime: state?.remainingTime,
        ),
      ),
    );
  }

  void _removeError(_ErrorItem item) {
    if (!_errors.contains(item)) return;

    setState(() {
      item.isDismissing = true;
      item.timer?.cancel();
    });

    _overlayEntry?.markNeedsBuild();
  }

  void _performItemRemoval(_ErrorItem item) {
    if (!_errors.contains(item)) return;

    if (mounted) {
      setState(() {
        _errors.remove(item);
        _bannerStates.remove(item);
      });

      _overlayEntry?.markNeedsBuild();
    }
  }

  void _removeAllAbove(_ErrorItem item) {
    if (!_errors.contains(item)) return;

    final itemIndex = _errors.indexOf(item);
    if (itemIndex <= 0) return;

    final itemsToRemove = _errors.sublist(0, itemIndex);

    for (var errorItem in itemsToRemove) {
      setState(() {
        errorItem.isDismissing = true;
        errorItem.timer?.cancel();
        _bannerStates.remove(errorItem);
      });
    }

    _overlayEntry?.markNeedsBuild();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _errors.removeRange(0, itemIndex);
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _handleBannerTap(
    _ErrorItem item,
    bool isPaused,
    Duration? remainingTime,
  ) {
    if (mounted) {
      setState(() {
        item.isPaused = isPaused;
        _bannerStates[item] = _BannerState(
          isPaused: isPaused,
          remainingTime: remainingTime,
        );
      });
    }
  }

  void showError(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final item = _ErrorItem(message: message);

    if (mounted) {
      setState(() {
        _errors.add(item);
      });
    }

    _overlayEntry?.markNeedsBuild();

    item.timer = Timer(duration, () {
      if (mounted && !item.isPaused && !item.isDismissing) {
        _removeError(item);
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
    return const SizedBox.shrink();
  }
}

class _ErrorItem {
  final String message;
  Timer? timer;
  bool isPaused = false;
  bool isDismissing = false;

  _ErrorItem({required this.message});
}

class _BannerState {
  final bool isPaused;
  final Duration? remainingTime;

  _BannerState({required this.isPaused, this.remainingTime});
}
