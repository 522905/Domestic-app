import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SwipeActionButton extends StatefulWidget {
  final VoidCallback onReject;
  final VoidCallback onApprove;

  const SwipeActionButton({
    Key? key,
    required this.onReject,
    required this.onApprove,
  }) : super(key: key);

  @override
  _SwipeActionButtonState createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragDistance = 0;
  final double _dragThreshold = 100.0;
  final double _dragFeedbackThreshold = 20.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
    );

    _controller.addListener(() {
      if (_controller.isCompleted) {
        setState(() {
          _dragDistance = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dx;
      // Restrict the drag within a reasonable range
      _dragDistance = _dragDistance.clamp(-_dragThreshold, _dragThreshold);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_dragDistance <= -_dragFeedbackThreshold) {
      // Swiped left significantly - trigger reject
      _animation = Tween<double>(
        begin: _dragDistance,
        end: -_dragThreshold,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ));

      _controller.reset();
      _controller.forward().then((_) {
        widget.onReject();
        setState(() {
          _dragDistance = 0;
        });
      });
    } else if (_dragDistance >= _dragFeedbackThreshold) {
      // Swiped right significantly - trigger approve
      _animation = Tween<double>(
        begin: _dragDistance,
        end: _dragThreshold,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack,
      ));

      _controller.reset();
      _controller.forward().then((_) {
        widget.onApprove();
        setState(() {
          _dragDistance = 0;
        });
      });
    } else {
      // Not swiped far enough - animate back to center
      _animation = Tween<double>(
        begin: _dragDistance,
        end: 0,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ));

      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final double currentDrag = _controller.isAnimating
              ? _animation.value
              : _dragDistance;

          // Calculate how much "progress" we've made toward rejection/approval
          final double rejectProgress = (-currentDrag / _dragThreshold).clamp(0.0, 1.0);
          final double approveProgress = (currentDrag / _dragThreshold).clamp(0.0, 1.0);

          return Container(
            height: 60.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Reject Button
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onReject,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                            const Color(0xFFFFEBEE),
                            const Color(0xFFF44336).withOpacity(0.3),
                            rejectProgress
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30.r),
                          bottomLeft: Radius.circular(30.r),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF44336),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'REJECT',
                              style: TextStyle(
                                color: const Color(0xFFF44336),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Swipe Button (actually just the center part)
                Transform.translate(
                  offset: Offset(currentDrag, 0),
                  child: Container(
                    transform: Matrix4.translationValues(currentDrag, 0, 0),
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: currentDrag > _dragFeedbackThreshold
                          ? const Color(0xFFE8F5E9) // Greenish background for approval
                          : currentDrag < -_dragFeedbackThreshold
                              ? const Color(0xFFFFEBEE) // Reddish background for rejection
                              : Colors.grey.shade200, // Neutral background
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'SWIPE',
                        style: TextStyle(
                          color: currentDrag > _dragFeedbackThreshold
                              ? const Color(0xFF4CAF50)
                              : currentDrag < -_dragFeedbackThreshold
                              ? const Color(0xFFF44336)
                              : Colors.grey.shade700,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
                // Approve Button
                Expanded(
                  child: GestureDetector(
                    onTap: widget.onApprove,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                            const Color(0xFFE8F5E9),
                            const Color(0xFF4CAF50).withOpacity(0.3),
                            approveProgress
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(30.r),
                          bottomRight: Radius.circular(30.r),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'APPROVE',
                              style: TextStyle(
                                color: const Color(0xFF4CAF50),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              width: 30.w,
                              height: 30.w,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}