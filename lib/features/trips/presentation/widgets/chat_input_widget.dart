import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSendText;
  final Function(File) onSendImage;
  final VoidCallback onStartVoiceRecording;
  final VoidCallback onStopVoiceRecording;
  final VoidCallback onCancelVoiceRecording; 
  final Function(String, String) onSendContact; 
  final Color royalGreen;
  final bool isSending;
  final bool isRecording; 

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSendText,
    required this.onSendImage,
    required this.onStartVoiceRecording,
    required this.onStopVoiceRecording,
    required this.onCancelVoiceRecording,
    required this.onSendContact,
    required this.royalGreen,
    required this.isSending,
    required this.isRecording,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  bool _isLocked = false;
  bool _showTapHint = false;

  void _handleTapHint() {
    setState(() => _showTapHint = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showTapHint = false);
    });
  }

  // 🟢 نافذة المرفقات (شكل الواتس اب)
  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15.r)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachOption(Icons.image, Colors.purple, 'المعرض', () async {
              Navigator.pop(context);
              final image = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (image != null) widget.onSendImage(File(image.path));
            }),
            _buildAttachOption(Icons.camera_alt, Colors.pink, 'الكاميرا', () async {
              Navigator.pop(context);
              final image = await ImagePicker().pickImage(source: ImageSource.camera);
              if (image != null) widget.onSendImage(File(image.path));
            }),
            _buildAttachOption(Icons.person, Colors.blue, 'جهة اتصال', () {
              Navigator.pop(context);
              _showContactDialog();
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption(IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 25.r, backgroundColor: color.withAlpha(25), child: Icon(icon, color: color, size: 28.sp)),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // 🟢 نافذة إدخال جهة الاتصال السريعة
  void _showContactDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController phoneCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text('إرسال جهة اتصال', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'الاسم')),
            SizedBox(height: 10.h),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(hintText: 'رقم الهاتف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey, fontFamily: 'Cairo'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.royalGreen),
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                widget.onSendContact(nameCtrl.text, phoneCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text('إرسال', style: TextStyle(color: Colors.white, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -2))],
      ),
      child: SafeArea(child: widget.isRecording ? _buildRecordingUI() : _buildNormalUI()),
    );
  }

  Widget _buildNormalUI() {
    return Row(
      children: [
        // 🟢 أيقونة الدبوس
        IconButton(
          icon: Transform.rotate(angle: -0.7, child: Icon(Icons.attach_file_rounded, color: widget.royalGreen, size: 26.sp)),
          onPressed: _showAttachmentSheet,
        ),
        Expanded(
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              TextField(
                controller: widget.controller,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'اكتب رسالتك...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide.none),
                ),
                onChanged: (val) => setState(() {}), 
              ),
              if (_showTapHint)
                Positioned(
                  left: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(color: Colors.black87.withAlpha(200), borderRadius: BorderRadius.circular(12.r)),
                    child: Text('اضغط مطولاً للتسجيل', style: TextStyle(color: Colors.white, fontSize: 11.sp, fontFamily: 'Cairo')),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _buildActionIcon(),
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.delete_rounded, color: Colors.grey.shade600, size: 26.sp),
          onPressed: () { setState(() => _isLocked = false); widget.onCancelVoiceRecording(); },
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                builder: (context, val, child) => Opacity(opacity: val, child: Icon(Icons.mic, color: Colors.redAccent, size: 20.sp)),
              ),
              SizedBox(width: 8.w),
              Text(
                _isLocked ? 'تسجيل مقفل 🔒' : 'اسحب للأعلى للقفل ⬆️',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.redAccent, fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _isLocked
            ? InkWell(
                onTap: () { setState(() => _isLocked = false); widget.onStopVoiceRecording(); },
                child: CircleAvatar(radius: 22.r, backgroundColor: widget.royalGreen, child: Icon(Icons.send_rounded, color: Colors.white, size: 20.sp)),
              )
            : GestureDetector(
                onLongPressEnd: (_) { if (!_isLocked) widget.onStopVoiceRecording(); },
                onLongPressMoveUpdate: (details) {
                  if (details.localPosition.dy < -40 && !_isLocked) setState(() => _isLocked = true);
                  if (details.localPosition.dx > 40 && !_isLocked) { setState(() => _isLocked = false); widget.onCancelVoiceRecording(); }
                },
                child: CircleAvatar(radius: 22.r, backgroundColor: widget.royalGreen, child: Icon(Icons.mic_rounded, color: Colors.white, size: 20.sp)),
              ),
      ],
    );
  }

  Widget _buildActionIcon() {
    bool hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText) {
      return InkWell(
        onTap: widget.isSending ? null : () { widget.onSendText(); widget.controller.clear(); },
        child: CircleAvatar(
          radius: 22.r,
          backgroundColor: widget.royalGreen,
          child: widget.isSending 
            ? SizedBox(width: 15.w, height: 15.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
        ),
      );
    }
    return GestureDetector(
      onTap: _handleTapHint,
      onLongPressStart: (_) { setState(() => _isLocked = false); widget.onStartVoiceRecording(); },
      onLongPressEnd: (_) { if (!_isLocked && widget.isRecording) widget.onStopVoiceRecording(); },
      onLongPressMoveUpdate: (details) {
        if (details.localPosition.dy < -40 && !_isLocked) setState(() => _isLocked = true);
        if (details.localPosition.dx > 40 && !_isLocked) { setState(() => _isLocked = false); widget.onCancelVoiceRecording(); }
      },
      child: CircleAvatar(radius: 22.r, backgroundColor: widget.royalGreen, child: Icon(Icons.mic_rounded, color: Colors.white, size: 20.sp)),
    );
  }
}