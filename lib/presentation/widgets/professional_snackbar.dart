import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum SnackBarType { success, error, warning, info }

class ProfessionalSnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;

  const ProfessionalSnackBar({
    Key? key,
    required this.message,
    required this.type,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<ProfessionalSnackBar> createState() => _ProfessionalSnackBarState();

  static void show(
    BuildContext context, {
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    if (overlay == null) return;

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 16.w,
        right: 16.w,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSnackBar(
            message: message,
            type: type,
            onDismiss: () {
              overlayEntry.remove();
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _ProfessionalSnackBarState extends State<ProfessionalSnackBar> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class _AnimatedSnackBar extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final VoidCallback onDismiss;

  const _AnimatedSnackBar({
    Key? key,
    required this.message,
    required this.type,
    required this.onDismiss,
  }) : super(key: key);

  @override
  State<_AnimatedSnackBar> createState() => _AnimatedSnackBarState();
}

class _AnimatedSnackBarState extends State<_AnimatedSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF10B981);
      case SnackBarType.error:
        return const Color(0xFFEF4444);
      case SnackBarType.warning:
        return const Color(0xFFF59E0B);
      case SnackBarType.info:
        return const Color(0xFF3B82F6);
    }
  }

  Color _getSecondaryColor() {
    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF059669);
      case SnackBarType.error:
        return const Color(0xFFDC2626);
      case SnackBarType.warning:
        return const Color(0xFFD97706);
      case SnackBarType.info:
        return const Color(0xFF2563EB);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case SnackBarType.success:
        return 'Success';
      case SnackBarType.error:
        return 'Error';
      case SnackBarType.warning:
        return 'Warning';
      case SnackBarType.info:
        return 'Info';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                _getBackgroundColor(),
                _getSecondaryColor(),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: _getBackgroundColor().withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                await _controller.reverse();
                widget.onDismiss();
              },
              borderRadius: BorderRadius.circular(16.r),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 14.h,
                ),
                child: Row(
                  children: [
                    // Icon container with subtle background
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _getIcon(),
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Message content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getTitle(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Close button
                    GestureDetector(
                      onTap: () async {
                        await _controller.reverse();
                        widget.onDismiss();
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18.sp,
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
    );
  }
}

// Convenience methods for easier usage
extension ProfessionalSnackBarExtension on BuildContext {
  void showSuccessSnackBar(String message, {Duration? duration}) {
    ProfessionalSnackBar.show(
      this,
      message: message,
      type: SnackBarType.success,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showErrorSnackBar(String message, {Duration? duration}) {
    ProfessionalSnackBar.show(
      this,
      message: message,
      type: SnackBarType.error,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showWarningSnackBar(String message, {Duration? duration}) {
    ProfessionalSnackBar.show(
      this,
      message: message,
      type: SnackBarType.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  void showInfoSnackBar(String message, {Duration? duration}) {
    ProfessionalSnackBar.show(
      this,
      message: message,
      type: SnackBarType.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
}
