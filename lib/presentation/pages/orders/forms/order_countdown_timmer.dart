import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OrderCountdownTimer extends StatefulWidget {
  final DateTime createdAt;
  final int limitMinutes; // 90 for Refill orders

  const OrderCountdownTimer({
    Key? key,
    required this.createdAt,
    required this.limitMinutes,
  }) : super(key: key);

  @override
  State<OrderCountdownTimer> createState() => _OrderCountdownTimerState();
}

class _OrderCountdownTimerState extends State<OrderCountdownTimer>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Duration? _remaining;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulse animation FIRST
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Now safe to calculate
    _calculateRemaining();

    // Start timer to update every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateRemaining();
    });
  }

  void _calculateRemaining() {
    final now = DateTime.now();
    final deadline = widget.createdAt.add(Duration(minutes: widget.limitMinutes));
    final diff = deadline.difference(now);

    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;

      // Start pulsing if < 10 minutes
      if (_remaining!.inMinutes < 10 && _remaining!.inSeconds > 0) {
        if (!_pulseController.isAnimating) {
          _pulseController.repeat(reverse: true);
        }
      } else {
        if (_pulseController.isAnimating) {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'CLOSED';

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining == null) {
      return const SizedBox.shrink();
    }

    final isClosed = _remaining!.inSeconds <= 0;
    final isWarning = _remaining!.inMinutes < 10 && !isClosed;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isWarning ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isClosed
                  ? const Color(0xFFF44336).withOpacity(0.1)
                  : isWarning
                  ? const Color(0xFFF44336).withOpacity(0.15)
                  : const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16.r),
              border: isWarning
                  ? Border.all(
                color: const Color(0xFFF44336).withOpacity(0.3),
                width: 1.5,
              )
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isClosed
                      ? Icons.block
                      : isWarning
                      ? Icons.warning_rounded
                      : Icons.timer_outlined,
                  size: 14.sp,
                  color: isClosed
                      ? const Color(0xFFF44336)
                      : isWarning
                      ? const Color(0xFFF44336)
                      : const Color(0xFF4CAF50),
                ),
                SizedBox(width: 4.w),
                Text(
                  _formatDuration(_remaining!),
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isClosed
                        ? const Color(0xFFF44336)
                        : isWarning
                        ? const Color(0xFFF44336)
                        : const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}