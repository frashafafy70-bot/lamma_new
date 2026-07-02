import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

class LiveAnimatedCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData fallbackIcon; // الأيقونة الاحتياطية
  final String? lottiePath; // مسار الأنيميشن الجديد
  final Color iconColor;
  final VoidCallback onTap;
  final bool hasNotification; 

  const LiveAnimatedCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
    this.lottiePath,
    required this.iconColor,
    required this.onTap,
    this.hasNotification = false,
  });

  @override
  State<LiveAnimatedCard> createState() => _LiveAnimatedCardState();
}

class _LiveAnimatedCardState extends State<LiveAnimatedCard> with TickerProviderStateMixin {
  late AnimationController _tapController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _tapController = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_tapController);
    
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  // 🟢 دالة ذكية لعرض الأنيميشن أو الأيقونة
  Widget _buildMediaContent() {
    if (widget.lottiePath != null && widget.lottiePath!.endsWith('.json')) {
      return Lottie.asset(
        widget.lottiePath!,
        width: 55.sp, 
        height: 55.sp,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => Icon(widget.fallbackIcon, size: 40.sp, color: widget.iconColor),
      );
    }
    return Icon(widget.fallbackIcon, size: 40.sp, color: widget.iconColor);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _tapController.forward(),
      onTapUp: (_) {
        _tapController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _tapController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25.r),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.hasNotification)
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 60.w,
                        height: 60.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.iconColor.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  // استدعاء الميديا هنا
                  _buildMediaContent(),
                ],
              ),
              SizedBox(height: 10.h),
              Text(widget.title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
              Text(widget.subtitle, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tapController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}