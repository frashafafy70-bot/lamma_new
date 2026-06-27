import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:intl/intl.dart' hide TextDirection; 

// تأكد من صحة مسارات الاستيراد بناءً على مشروعك
import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart'; 
import 'live_tracking_map_header.dart';

class TripChatPage extends StatefulWidget {
  final String tripId;

  const TripChatPage({super.key, required this.tripId});

  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends State<TripChatPage> {
  final Color primaryGreen = const Color(0xFF1A3B2A);
  final Color accentGold = const Color(0xFFD4AF37);
  final Color chatBackground = const Color(0xFFE5DDD5); 
  
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _messageController = TextEditingController();
  
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {
        isTyping = _messageController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return 'الآن';
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }
    return DateFormat('hh:mm a', 'ar').format(date);
  }

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);

    if (pickedFile != null) {
      if (context.mounted) {
        context.read<TripChatCubit>().sendImageMessage(widget.tripId, File(pickedFile.path));
      }
    }
  }

  void _showAttachmentBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (innerContext) {
        return Container(
          margin: EdgeInsets.all(12.w),
          padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentOption(
                icon: Icons.image, 
                color: Colors.purple, 
                label: 'المعرض', 
                onTap: () {
                  Navigator.pop(innerContext);
                  _pickImage(ImageSource.gallery, context);
                }
              ),
              _buildAttachmentOption(
                icon: Icons.camera_alt, 
                color: Colors.pink, 
                label: 'الكاميرا', 
                onTap: () {
                  Navigator.pop(innerContext);
                  _pickImage(ImageSource.camera, context);
                }
              ),
            ],
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
            radius: 30.r,
            backgroundColor: color.withValues(alpha: 0.1),            
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: 8.h),
          Text(label, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripChatCubit()..loadChat(widget.tripId),
      child: Scaffold(
        backgroundColor: chatBackground, 
        appBar: AppBar(
          backgroundColor: primaryGreen,
          elevation: 2,
          centerTitle: true,
          iconTheme: IconThemeData(color: accentGold),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline, color: accentGold, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'محادثة الرحلة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp),
              ),
            ],
          ),
        ),
        body: Builder(
          builder: (innerContext) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: [
                  
                  // 🟢 الـ StreamBuilder يغلف الخريطة فقط عشان الأداء
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('trips').doc(widget.tripId).snapshots(),
                    builder: (context, snapshot) {
                      GeoPoint? pLoc;
                      GeoPoint? dLoc;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        
                        if (data['passengerLocation'] is GeoPoint) {
                          pLoc = data['passengerLocation'];
                        }
                        if (data['driverLocation'] is GeoPoint) {
                          dLoc = data['driverLocation'];
                        }
                      }

                      return LiveTrackingMapHeader(
                        passengerLocation: pLoc, 
                        driverLocation: dLoc,
                      );
                    },
                  ),

                  Expanded(
                    child: BlocBuilder<TripChatCubit, TripChatState>(
                      builder: (context, state) {
                        if (state is TripChatLoading) {
                          return Center(child: CircularProgressIndicator(color: primaryGreen));
                        } 
                        else if (state is TripChatError) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 70.sp),
                                  SizedBox(height: 16.h),
                                  Text('حدث خطأ في الإرسال!', style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade700, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 8.h),
                                  Text('غالباً الكابتن لا يملك صلاحية المايكروفون، أو توجد مشكلة في حماية Firebase Storage. يرجى المراجعة.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 14.sp)),
                                  SizedBox(height: 24.h),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
                                    onPressed: () => innerContext.read<TripChatCubit>().loadChat(widget.tripId),
                                    icon: Icon(Icons.refresh, color: accentGold),
                                    label: Text('تحديث المحادثة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                            ),
                          );
                        } 
                        else if (state is TripChatLoaded) {
                          return ListView.builder(
                            reverse: true,
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            itemCount: state.messages.length + 1, 
                            itemBuilder: (context, index) {
                              
                              if (index == state.messages.length) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEEFCD), 
                                        borderRadius: BorderRadius.circular(8.r),
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1))]
                                      ),
                                      child: Text(
                                        '🔒 الرسائل والمكالمات مشفرة تماماً',
                                        style: TextStyle(fontFamily: 'Cairo', color: Colors.black87, fontSize: 11.sp, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              var msg = state.messages[index];
                              bool isMe = msg['senderId'] == currentUserId;
                              
                              return _buildMessageBubble(msg, isMe);
                            },
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),

                  _buildBottomInput(innerContext),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    bool isAudio = msg['type'] == 'audio';
    bool isImage = msg['type'] == 'image';
    String text = msg['text'] ?? '';
    var time = msg['timestamp'];

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: isImage ? EdgeInsets.all(4.w) : EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFDCF8C6) : Colors.white, 
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
              bottomLeft: Radius.circular(isMe ? 16.r : 0),
              bottomRight: Radius.circular(isMe ? 0 : 16.r),
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
            ]
          ),
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isAudio) 
                _buildAudioMessage()
              else if (isImage) 
                _buildImageMessage(msg['imageUrl'])
              else 
                Text(
                  text,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: Colors.black87, fontWeight: FontWeight.w600, height: 1.3),
                ),
              
              SizedBox(height: 4.h),
              
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatMessageTime(time),
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4.w),
                    Icon(Icons.done_all_rounded, color: Colors.blue.shade400, size: 14.sp),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioMessage() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow_rounded, color: primaryGreen, size: 34.sp),
        SizedBox(width: 6.w),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(16, (index) {
            double height = (8 + (index % 4) * 4).h; 
            if (index % 2 == 0) height += 4.h;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 1.5.w),
              width: 3.w,
              height: height,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        ),
        SizedBox(width: 12.w),
        Text('0:00', style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade700, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildImageMessage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return const SizedBox();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Image.network(
        imageUrl,
        width: 220.w,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 220.w,
            height: 200.h,
            color: Colors.grey.shade200,
            child: Center(child: CircularProgressIndicator(color: primaryGreen)),
          );
        },
      ),
    );
  }

  Widget _buildBottomInput(BuildContext context) {
    return BlocBuilder<TripChatCubit, TripChatState>(
      builder: (context, state) {
        bool isRecording = context.read<TripChatCubit>().isRecording;

        return Container(
          padding: EdgeInsets.only(left: 10.w, right: 10.w, top: 10.h, bottom: 10.h + MediaQuery.of(context).padding.bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
          ),
          child: isRecording ? _buildRecordingUI(context) : _buildTypingUI(context),
        );
      },
    );
  }

  Widget _buildTypingUI(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'اكتب رسالتك هنا...',
              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade400),
              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              
              suffixIcon: IconButton(
                icon: Icon(Icons.attach_file_rounded, color: Colors.grey.shade600, size: 24.sp),
                onPressed: () => _showAttachmentBottomSheet(context),
              ),
              
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.r), borderSide: BorderSide.none),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
        ),
        SizedBox(width: 8.w),
        GestureDetector(
          onTap: () {
            if (isTyping) {
              context.read<TripChatCubit>().sendMessage(widget.tripId, currentUserId, _messageController.text);
              _messageController.clear();
            } else {
              context.read<TripChatCubit>().startRecording();
            }
          },
          child: CircleAvatar(
            radius: 24.r,
            backgroundColor: primaryGreen, 
            child: Icon(
              isTyping ? Icons.send_rounded : Icons.mic, 
              color: accentGold, 
              size: 22.sp
            ),
          ),
        )
      ],
    );
  }

  Widget _buildRecordingUI(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade700, size: 28.sp),
          onPressed: () => context.read<TripChatCubit>().cancelRecording(),
        ),
        Expanded(
          child: _BlinkingMic(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic, color: Colors.red.shade600, size: 24.sp),
                SizedBox(width: 8.w),
                Text('جاري التسجيل...', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: Colors.red.shade600, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.read<TripChatCubit>().stopRecordingAndSend(widget.tripId),
          child: CircleAvatar(
            radius: 24.r,
            backgroundColor: primaryGreen,
            child: Icon(Icons.send_rounded, color: accentGold, size: 22.sp),
          ),
        )
      ],
    );
  }
}

class _BlinkingMic extends StatefulWidget {
  final Widget child;
  const _BlinkingMic({required this.child});
  @override
  _BlinkingMicState createState() => _BlinkingMicState();
}

class _BlinkingMicState extends State<_BlinkingMic> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}