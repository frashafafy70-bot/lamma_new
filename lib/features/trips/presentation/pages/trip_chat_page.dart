// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String captainPhoneNumber = "01000000000"; 
  
  // 🟢 إضافة متحكم الـ Scroll لرصد الوصول لأعلى الشات
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🟢 اللوجيك الخاص برصد وصول المستخدم لآخر الرسايل المحملة
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
      context.read<TripChatCubit>().loadMoreMessages(widget.tripId);
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      debugPrint('لا يمكن الاتصال بالرقم $phoneNumber');
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
    final String safeTripId = widget.tripId.length >= 5 ? widget.tripId.substring(0, 5) : widget.tripId;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'محادثة الرحلة',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.sp),
              ),
              Text(
                'رقم: $safeTripId',
                style: TextStyle(fontFamily: 'Cairo', color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.call, color: AppColors.accentGold), 
          onPressed: () => _makePhoneCall(captainPhoneNumber),
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
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade400, size: 70.sp),
            SizedBox(height: 16.h),
            Text('حدث خطأ!', style: TextStyle(fontFamily: 'Cairo', color: Colors.red.shade700, fontSize: 18.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            Text(errorMessage, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade700, fontSize: 14.sp)),
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
      controller: _scrollController, // 🟢 تم ربط المتحكم هنا
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
            style: TextStyle(fontFamily: 'Cairo', color: Colors.black87, fontSize: 11.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}