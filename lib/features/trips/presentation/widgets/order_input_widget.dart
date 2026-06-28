import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

// 🟢 استدعاء الألوان الخاصة بنا
import 'package:lamma_new/core/theme/app_colors.dart';

class OrderInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(File?) onAudioRecorded;

  const OrderInputWidget({
    super.key,
    required this.controller,
    required this.onAudioRecorded,
  });

  @override
  State<OrderInputWidget> createState() => _OrderInputWidgetState();
}

class _OrderInputWidgetState extends State<OrderInputWidget> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _timer;
  File? _recordedAudio;

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  // 🟢 بدء التسجيل
  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        String filePath = '${directory.path}/order_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _startTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('برجاء الموافقة على صلاحية الميكروفون')),
        );
      }
    } catch (e) {
      debugPrint('خطأ في بدء التسجيل: $e');
    }
  }

  // 🟢 إيقاف التسجيل وحفظ الملف
  Future<void> _stopRecording() async {
    try {
      _timer?.cancel();
      final path = await _audioRecorder.stop();

      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        setState(() {
          _recordedAudio = File(path);
        });
        widget.onAudioRecorded(_recordedAudio); // إرسال الملف للشاشة الرئيسية
      }
    } catch (e) {
      debugPrint('خطأ في إيقاف التسجيل: $e');
    }
  }

  // 🟢 إلغاء التسجيل ومسحه
  Future<void> _cancelRecording() async {
    try {
      _timer?.cancel();
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedAudio = null;
        _recordDuration = 0;
      });
      widget.onAudioRecorded(null);
    } catch (e) {
      debugPrint('خطأ في إلغاء التسجيل: $e');
    }
  }

  // 🟢 مسح الريكورد بعد ما اتسجل (لو العميل حب يكتب نص بدل الصوت)
  void _deleteRecordedAudio() {
    setState(() {
      _recordedAudio = null;
      _recordDuration = 0;
    });
    widget.onAudioRecorded(null);
  }

  // 🟢 مؤقت التسجيل
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  // تنسيق الوقت
  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _isRecording 
          ? _buildRecordingUI() 
          : (_recordedAudio != null ? _buildRecordedAudioUI() : _buildTextInputUI()),
    );
  }

  // 1. واجهة النص العادية والمايك
  Widget _buildTextInputUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: 12.w),
        Icon(Icons.shopping_bag_outlined, color: AppColors.accentGold, size: 24.sp),
        SizedBox(width: 8.w),
        Expanded(
          child: TextField(
            controller: widget.controller,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'اكتب طلباتك بالتفصيل...',
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.mic, color: AppColors.primaryDark, size: 26.sp),
          onPressed: () {
            FocusScope.of(context).unfocus(); // إخفاء الكيبورد
            widget.controller.clear(); // مسح النص لو هيكلم صوت
            _startRecording();
          },
        ),
      ],
    );
  }

  // 2. واجهة أثناء التسجيل (لايف)
  Widget _buildRecordingUI() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26.sp),
            onPressed: _cancelRecording,
          ),
          Row(
            children: [
              Text(
                _formatDuration(_recordDuration),
                style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: AppColors.error, fontWeight: FontWeight.bold),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.mic, color: AppColors.error, size: 24.sp), // ممكن تضيف أنيميشن وميض هنا
            ],
          ),
          GestureDetector(
            onTap: _stopRecording,
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.royalGreen,
              child: Icon(Icons.stop_rounded, color: Colors.white, size: 20.sp),
            ),
          ),
        ],
      ),
    );
  }

  // 3. واجهة بعد الانتهاء من التسجيل ووجود ملف جاهز
  Widget _buildRecordedAudioUI() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: AppColors.error, size: 24.sp),
            onPressed: _deleteRecordedAudio, // مسح الريكورد والرجوع للكتابة
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.audiotrack_rounded, color: AppColors.royalGreen, size: 24.sp),
                SizedBox(width: 8.w),
                Text(
                  'تم تسجيل الطلب الصوتي',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: AppColors.primaryDark, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle_rounded, color: AppColors.success, size: 24.sp),
        ],
      ),
    );
  }
}