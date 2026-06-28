import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lamma_new/core/theme/app_colors.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
  });

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  // 🟢 اللوجيك الذكي لحالة الرسالة (علامات الصح)
  Widget _buildMessageStatus() {
    if (!isMe) return const SizedBox.shrink(); // الطرف الآخر لا يرى علامات صح

    // 1. جاري الإرسال (مفيش Timestamp لسه من السيرفر)
    if (msg['timestamp'] == null) {
      return Icon(Icons.access_time, size: 12.sp, color: Colors.grey.shade400);
    }
    
    // 2. تم المشاهدة (الطرف الآخر فتح الشات)
    if (msg['isRead'] == true) {
      return Icon(Icons.done_all, size: 16.sp, color: Colors.blueAccent);
    }
    
    // 3. تم الإرسال للـ Firebase (لكن لم يُقرأ بعد)
    return Icon(Icons.check, size: 14.sp, color: Colors.grey.shade500);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: isMe ? 40.w : 0, right: isMe ? 0 : 40.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isMe ? AppColors.royalGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isMe ? Radius.circular(16.r) : const Radius.circular(0),
            bottomRight: isMe ? const Radius.circular(0) : Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // المحتوى الأساسي (صورة، صوت، أو نص)
            _buildContent(),
            
            SizedBox(height: 4.h),
            
            // شريط الوقت وحالة القراءة
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTime(msg['timestamp']),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.sp,
                    color: isMe ? Colors.white70 : Colors.grey.shade500,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  _buildMessageStatus(),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    String type = msg['type'] ?? 'text';

    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          msg['imageUrl'],
          width: 200.w,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(
              width: 200.w, height: 150.h,
              color: Colors.grey.shade200,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (ctx, err, stack) => Icon(Icons.broken_image, size: 50.sp, color: Colors.grey),
        ),
      );
    } else if (type == 'audio') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.play_circle_fill_rounded, color: isMe ? AppColors.accentGold : AppColors.royalGreen, size: 36.sp),
          SizedBox(width: 8.w),
          Container(
            width: 100.w,
            height: 4.h,
            color: isMe ? Colors.white30 : Colors.grey.shade300,
          ),
        ],
      );
    }

    // Default Text
    return Text(
      msg['text'] ?? '',
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: isMe ? Colors.white : AppColors.textDark,
        height: 1.4,
      ),
    );
  }
}