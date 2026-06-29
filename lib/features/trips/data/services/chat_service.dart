import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:audioplayers/audioplayers.dart'; // 🟢 استيراد مكتبة الصوت

// 🟢 تحويل الكلاس لـ StatefulWidget عشان نقدر نتحكم في حالة تشغيل الصوت
class MessageBubble extends StatefulWidget {
  final Map<String, dynamic> msg;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;
  Duration duration = Duration.zero;
  Duration position = Duration.zero;

  @override
  void initState() {
    super.initState();
    // 🟢 تهيئة مشغل الصوت لو الرسالة نوعها صوت
    if (widget.msg['type'] == 'audio' && widget.msg['audioUrl'] != null) {
      _audioPlayer.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            isPlaying = state == PlayerState.playing;
          });
        }
      });

      _audioPlayer.onDurationChanged.listen((newDuration) {
        if (mounted) {
          setState(() {
            duration = newDuration;
          });
        }
      });

      _audioPlayer.onPositionChanged.listen((newPosition) {
        if (mounted) {
          setState(() {
            position = newPosition;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime date = (timestamp as Timestamp).toDate();
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  Widget _buildMessageStatus() {
    if (!widget.isMe) return const SizedBox.shrink();

    if (widget.msg['timestamp'] == null) {
      return Icon(Icons.access_time, size: 12.sp, color: Colors.grey.shade400);
    }
    if (widget.msg['isRead'] == true) {
      return Icon(Icons.done_all, size: 16.sp, color: Colors.blueAccent);
    }
    return Icon(Icons.check, size: 14.sp, color: Colors.grey.shade500);
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, left: widget.isMe ? 40.w : 0, right: widget.isMe ? 0 : 40.w),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: widget.isMe ? AppColors.royalGreen : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: widget.isMe ? Radius.circular(16.r) : const Radius.circular(0),
            bottomRight: widget.isMe ? const Radius.circular(0) : Radius.circular(16.r),
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
            _buildContent(),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  _formatTime(widget.msg['timestamp']),
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 10.sp,
                    color: widget.isMe ? Colors.white70 : Colors.grey.shade500,
                  ),
                ),
                if (widget.isMe) ...[
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
    String type = widget.msg['type'] ?? 'text';

    if (type == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          widget.msg['imageUrl'] ?? '',
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
      return _buildAudioPlayer();
    }

    return Text(
      widget.msg['text'] ?? '',
      style: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.sp,
        color: widget.isMe ? Colors.white : AppColors.textDark,
        height: 1.4,
      ),
    );
  }

  // 🟢 ويدجت مشغل الصوت الحقيقي
  Widget _buildAudioPlayer() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () async {
            if (isPlaying) {
              await _audioPlayer.pause();
            } else {
              String? url = widget.msg['audioUrl']; 
              if (url != null && url.isNotEmpty) {
                await _audioPlayer.play(UrlSource(url));
              }
            }
          },
          child: Icon(
            isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
            color: widget.isMe ? AppColors.accentGold : AppColors.royalGreen,
            size: 36.sp,
          ),
        ),
        SizedBox(width: 4.w),
        // 🟢 شريط التمرير (Slider) عشان اليوزر يشوف الصوت واصل لفين
        SizedBox(
          width: 120.w,
          child: SliderTheme(
            data: SliderThemeData(
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
              trackHeight: 2.h,
            ),
            child: Slider(
              min: 0,
              max: duration.inSeconds.toDouble() > 0 ? duration.inSeconds.toDouble() : 1.0,
              value: position.inSeconds.toDouble() <= duration.inSeconds.toDouble() 
                     ? position.inSeconds.toDouble() 
                     : 0.0,
              activeColor: widget.isMe ? Colors.white : AppColors.royalGreen,
              inactiveColor: widget.isMe ? Colors.white30 : Colors.grey.shade300,
              onChanged: (value) async {
                final pos = Duration(seconds: value.toInt());
                await _audioPlayer.seek(pos);
              },
            ),
          ),
        ),
      ],
    );
  }
}