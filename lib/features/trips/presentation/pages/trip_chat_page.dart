// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/trips/cubit/shared/trip_chat_cubit.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/message_bubble.dart';
import 'package:lamma_new/features/trips/presentation/widgets/chat_input_widget.dart';

class TripChatPage extends StatefulWidget {
  final String tripId;

  const TripChatPage({super.key, required this.tripId});

  @override
  State<TripChatPage> createState() => _TripChatPageState();
}

class _TripChatPageState extends State<TripChatPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  // متغيرات لحفظ بيانات الطرف الآخر (حية وديناميكية)
  String otherUserName = 'جاري التحميل...';
  String otherUserPhone = '';
  bool isLoadingInfo = true;
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // استدعاء دالة جلب بيانات الطرف الآخر فور فتح الشات
    _fetchOtherPartyInfo();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // اللوجيك الخاص برصد وصول المستخدم لآخر الرسايل المحملة
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      context.read<TripChatCubit>().loadMoreMessages(widget.tripId);
    }
  }

  // 🟢 الدالة الـ Pro Max لجلب بيانات الطرف التاني
  Future<void> _fetchOtherPartyInfo() async {
    try {
      // 1. جلب بيانات الرحلة
      var tripDoc = await FirebaseFirestore.instance.collection('trips').doc(widget.tripId).get();
      if (!tripDoc.exists) return;
      
      var tripData = tripDoc.data() as Map<String, dynamic>;
      String passengerId = tripData['passengerId'] ?? '';
      String driverId = tripData['driverId'] ?? '';
      
      // 2. تحديد من هو الطرف الآخر؟
      String otherUserId = (currentUserId == passengerId) ? driverId : passengerId;

      // 3. جلب بيانات الطرف الآخر من كولكشن المستخدمين
      if (otherUserId.isNotEmpty) {
         var userDoc = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
         if (userDoc.exists) {
            var userData = userDoc.data() as Map<String, dynamic>;
            if (mounted) {
              setState(() {
                 // لو مفيش اسم، هنحط لقب افتراضي بناءً على دوره
                 otherUserName = userData['name'] ?? (currentUserId == passengerId ? 'الكابتن' : 'العميل');
                 otherUserPhone = userData['phone'] ?? '';
                 isLoadingInfo = false;
              });
            }
         }
      } else {
        if (mounted) setState(() => isLoadingInfo = false);
      }
    } catch (e) {
      debugPrint("خطأ في جلب بيانات الطرف الآخر: $e");
      if (mounted) setState(() => isLoadingInfo = false);
    }
  }

  Future<void> _makePhoneCall(BuildContext context, String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('رقم هاتف الطرف الآخر غير متوفر حالياً', style: TextStyle(fontFamily: 'Cairo')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('لا يمكن الاتصال بالرقم $phoneNumber', style: const TextStyle(fontFamily: 'Cairo')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TripChatCubit()..loadChat(widget.tripId),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        resizeToAvoidBottomInset: true, 
        appBar: _buildAppBar(context),
        body: SafeArea(
          bottom: true,
          top: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                Expanded(
                  child: BlocBuilder<TripChatCubit, TripChatState>(
                    builder: (context, state) {
                      if (state is TripChatLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.royalGreen));
                      } 
                      else if (state is TripChatError) {
                        return _buildErrorState(context, state.error);
                      } 
                      else if (state is TripChatLoaded) {
                        return _buildChatList(state.messages);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                ChatInputWidget(tripId: widget.tripId, currentUserId: currentUserId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.royalGreen,
      elevation: 2,
      iconTheme: const IconThemeData(color: Colors.white),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: const NetworkImage('https://cdn-icons-png.flaticon.com/512/3135/3135715.png'),
            radius: 18.r,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoadingInfo ? 'جاري التحميل...' : otherUserName,
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isLoadingInfo ? 'الرجاء الانتظار' : (otherUserPhone.isNotEmpty ? 'متصل بالرحلة' : 'رقم غير متاح'),
                  style: TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (isLoadingInfo)
           Padding(
             padding: EdgeInsets.symmetric(horizontal: 16.w),
             child: const Center(
               child: SizedBox(
                 width: 20, height: 20, 
                 child: CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 2)
               )
             ),
           )
        else
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.accentGold), 
            onPressed: () => _makePhoneCall(context, otherUserPhone),
          ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String errorMessage) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 70.sp),
            SizedBox(height: 16.h),
            Text('حدث خطأ!', style: TextStyle(fontFamily: 'Cairo', color: AppColors.error, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', color: AppColors.textMuted.shade700, fontSize: 14.sp)),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.royalGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))),
              onPressed: () => context.read<TripChatCubit>().loadChat(widget.tripId),
              icon: const Icon(Icons.refresh, color: AppColors.accentGold),
              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<dynamic> messages) {
    return ListView.builder(
      controller: _scrollController, 
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
      itemCount: messages.length + 1, 
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return _buildEncryptionNotice();
        }
        var msg = messages[index];
        bool isMe = msg['senderId'] == currentUserId;
        return MessageBubble(msg: msg, isMe: isMe);
      },
    );
  }

  Widget _buildEncryptionNotice() {
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
            '🔒 الرسائل مشفرة تماماً',
            style: TextStyle(fontFamily: 'Cairo', color: AppColors.textDark, fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}