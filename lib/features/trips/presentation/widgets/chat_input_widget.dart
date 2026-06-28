import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'; 

// 🟢 استدعاء الألوان الموحدة
import 'package:lamma_new/core/theme/app_colors.dart';

import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/blinking_mic.dart';

class ChatInputWidget extends StatefulWidget {
  final String tripId;
  final String currentUserId;

  const ChatInputWidget({super.key, required this.tripId, required this.currentUserId});

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  bool isTyping = false;
  bool isEmojiVisible = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        isTyping = _messageController.text.trim().isNotEmpty;
      });
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        setState(() {
          isEmojiVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null && mounted) {
      context.read<TripChatCubit>().sendImageMessage(widget.tripId, File(pickedFile.path));
    }
  }

  void _showAttachmentBottomSheet() {
    _focusNode.unfocus();
    setState(() {
      isEmojiVisible = false;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, 
      builder: (innerContext) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(innerContext).viewInsets.bottom),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            padding: EdgeInsets.only(top: 10.h, bottom: 20.h, left: 16.w, right: 16.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r), 
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttachmentOption(
                      icon: Icons.insert_photo_rounded, 
                      color: const Color(0xFFBF59CF), 
                      label: 'المعرض', 
                      onTap: () {
                        Navigator.pop(innerContext);
                        _pickImage(ImageSource.gallery);
                      }
                    ),
                    _buildAttachmentOption(
                      icon: Icons.camera_alt_rounded, 
                      color: const Color(0xFFD3396D), 
                      label: 'الكاميرا', 
                      onTap: () {
                        Navigator.pop(innerContext);
                        _pickImage(ImageSource.camera);
                      }
                    ),
                    _buildAttachmentOption(
                      icon: Icons.location_on_rounded, 
                      color: const Color(0xFF1DAA61), 
                      label: 'الموقع', 
                      onTap: () {
                        Navigator.pop(innerContext);
                        ScaffoldMessenger.of(innerContext).showSnackBar(const SnackBar(content: Text('سيتم إرسال الموقع')));
                      }
                    ),
                    _buildAttachmentOption(
                      icon: Icons.person_rounded, 
                      color: const Color(0xFF0A7ECA), 
                      label: 'جهة اتصال', 
                      onTap: () {
                        Navigator.pop(innerContext);
                        ScaffoldMessenger.of(innerContext).showSnackBar(const SnackBar(content: Text('سيتم فتح جهات الاتصال')));
                      }
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildAttachmentOption({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26.r, 
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 8.h),
          Text(
            label, 
            style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.black87)
          ),
        ],
      ),
    );
  }

  void _toggleEmojiKeyboard() {
    if (isEmojiVisible) {
      _focusNode.requestFocus(); 
    } else {
      _focusNode.unfocus(); 
    }
    setState(() {
      isEmojiVisible = !isEmojiVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<TripChatCubit, TripChatState>(
          builder: (context, state) {
            bool isRecording = context.read<TripChatCubit>().isRecording;

            return Padding(
              padding: EdgeInsets.only(left: 8.w, right: 8.w, top: 4.h, bottom: 8.h),
              child: isRecording ? _buildRecordingUI() : _buildTypingUI(),
            );
          },
        ),
        
        if (isEmojiVisible)
          SizedBox(
            height: 250.h,
            child: EmojiPicker(
              textEditingController: _messageController,
              config: Config(
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  backgroundColor: AppColors.backgroundLight, 
                  columns: 7,
                  emojiSizeMax: 28 * (Platform.isIOS ? 1.3 : 1.0),
                ),
                categoryViewConfig: const CategoryViewConfig(
                  backgroundColor: AppColors.backgroundLight,
                  indicatorColor: AppColors.royalGreen,
                  iconColorSelected: AppColors.royalGreen,
                  iconColor: Colors.grey,
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  showBackspaceButton: true,
                  showSearchViewButton: false,
                  backgroundColor: AppColors.backgroundLight,
                  buttonColor: AppColors.backgroundLight,
                  buttonIconColor: Colors.grey,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTypingUI() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(isEmojiVisible ? Icons.keyboard : Icons.emoji_emotions_outlined, color: Colors.grey.shade600, size: 24.sp),
                  onPressed: _toggleEmojiKeyboard,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                IconButton(
                  icon: Transform.rotate(
                    angle: -0.5, 
                    child: Icon(Icons.attach_file_rounded, color: Colors.grey.shade600, size: 22.sp),
                  ),
                  onPressed: _showAttachmentBottomSheet,
                ),
                if (!isTyping)
                  Padding(
                    padding: EdgeInsets.only(left: 4.w),
                    child: IconButton(
                      icon: Icon(Icons.camera_alt, color: Colors.grey.shade600, size: 22.sp),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () {
            if (isTyping) {
              context.read<TripChatCubit>().sendMessage(widget.tripId, widget.currentUserId, _messageController.text);
              _messageController.clear();
            } else {
              context.read<TripChatCubit>().startRecording();
            }
          },
          child: CircleAvatar(
            radius: 24.r,
            backgroundColor: AppColors.royalGreen, 
            child: Icon(
              isTyping ? Icons.send_rounded : Icons.mic, 
              color: AppColors.accentGold, // 🟢 إضافة لمسة ذهبية لأيقونة الإرسال والمايك
              size: 22.sp
            ),
          ),
        )
      ],
    );
  }

  Widget _buildRecordingUI() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade700, size: 26.sp),
            onPressed: () => context.read<TripChatCubit>().cancelRecording(),
          ),
          Expanded(
            child: BlinkingMic(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, color: Colors.red.shade600, size: 24.sp),
                  SizedBox(width: 8.w),
                  Text('جاري التسجيل...', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.read<TripChatCubit>().stopRecordingAndSend(widget.tripId),
            child: CircleAvatar(
              radius: 20.r,
              backgroundColor: AppColors.royalGreen,
              child: Icon(Icons.send_rounded, color: AppColors.accentGold, size: 18.sp),
            ),
          )
        ],
      ),
    );
  }
}