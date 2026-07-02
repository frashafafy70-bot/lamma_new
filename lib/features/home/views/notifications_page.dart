// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

import 'package:lamma_new/features/home/cubit/home_cubit.dart';
import 'package:lamma_new/features/home/cubit/home_state.dart';
import 'package:lamma_new/features/auth/presentation/pages/login_page.dart'; 
import 'package:lamma_new/features/profile/edit_profile_page.dart'; 
import 'package:lamma_new/features/home/views/home_main_view.dart';
import 'package:lamma_new/features/home/views/search_view.dart';
import 'package:lamma_new/features/home/views/orders_view.dart';
import 'package:lamma_new/features/home/views/profile_view.dart';
import 'package:lamma_new/features/home/role_registration_sheets.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color royalGreen = const Color(0xFF1B4332); 
  final Color goldAccent = const Color(0xFFD4AF37); 
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late HomeCubit _homeCubit;

  @override
  void initState() {
    super.initState();
    _homeCubit = HomeCubit()..loadUserProfile();
  }

  @override
  void dispose() {
    _homeCubit.close();
    super.dispose();
  }

  void _openNotifications(BuildContext context) {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('جاري تحميل بياناتك، يرجى المحاولة بعد قليل...', style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    context.read<HomeCubit>().markAllNotificationsAsRead();

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (bottomSheetContext) {
        return SizedBox(
          height: MediaQuery.of(bottomSheetContext).size.height * 0.65, 
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                Container(width: 40.w, height: 5.h, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r))),
                SizedBox(height: 16.h),
                Text('الإشعارات', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
                const Divider(),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').orderBy('timestamp', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('لا توجد إشعارات حالياً 🔕', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp)));
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var notif = snapshot.data!.docs[index];
                          return ListTile(
                            leading: CircleAvatar(backgroundColor: goldAccent.withValues(alpha: 0.2), child: Icon(Icons.notifications_active, color: goldAccent)), 
                            title: Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
                            subtitle: Text(notif['body'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _homeCubit,
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (previous, current) => previous.actionStatus != current.actionStatus,
        listener: (context, state) {
          if (state.actionStatus == HomeActionStatus.success && state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.successMessage!, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
            context.read<HomeCubit>().clearActionStatus(); 
          }
          else if (state.actionStatus == HomeActionStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
            context.read<HomeCubit>().clearActionStatus(); 
          }
          else if (state.actionStatus == HomeActionStatus.registrationRequired) {
            final role = state.pendingRegistrationRole;
            final fullName = state.userName;
            final cubit = context.read<HomeCubit>();
            cubit.clearActionStatus(); 

            if (role == 'captain') RoleRegistrationSheets.showCaptain(context, cubit, fullName);
            else if (role == 'lawyer') RoleRegistrationSheets.showLawyer(context, cubit, fullName);
            else if (role == 'doctor') RoleRegistrationSheets.showDoctor(context, cubit, fullName);
            else if (role == 'nurse') RoleRegistrationSheets.showNurse(context, cubit, fullName);
          }
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            Widget bodyContent;
            switch (state.bottomNavIndex) {
              case 0: 
                bodyContent = HomeMainView(
                  userName: state.userName, 
                  activeRole: state.activeRole, 
                  profileImageUrl: state.profileImageUrl,
                  unreadCount: state.unreadNotificationsCount,
                  activeOrdersCount: state.activeOrdersCount, 
                  onOpenNotifications: () => _openNotifications(context) 
                ); 
                break;
              case 1: bodyContent = SearchView(activeRole: state.activeRole); break;
              case 2: bodyContent = OrdersView(activeRole: state.activeRole); break;
              case 3: 
                bodyContent = ProfileView(
                  activeRole: state.activeRole,
                  isLoadingProfile: state.status == HomeStatus.loading,
                  profileImageUrl: state.profileImageUrl,
                  userName: state.userName,
                  userEmail: state.userEmail,
                  onEditProfile: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfilePage())),
                  onPasswordReset: () => _confirmPasswordReset(context),
                  onSupport: () => _showSupportDialog(context, state.userName, state.userEmail),
                  onLogout: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                  },
                ); 
                break;
              default: 
                bodyContent = HomeMainView(
                  userName: state.userName, 
                  activeRole: state.activeRole, 
                  profileImageUrl: state.profileImageUrl,
                  unreadCount: state.unreadNotificationsCount, 
                  activeOrdersCount: state.activeOrdersCount, 
                  onOpenNotifications: () => _openNotifications(context)
                );
            }

            return Stack(
              children: [
                PopScope(
                  canPop: state.bottomNavIndex == 0,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    context.read<HomeCubit>().changeTab(0);
                  },
                  child: Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: const Color(0xFFF8FAFC), 
                    extendBody: true, 
                    body: Directionality(textDirection: TextDirection.rtl, child: bodyContent),
                    bottomNavigationBar: Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(
                        margin: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 24.h), 
                        decoration: BoxDecoration(
                          color: primaryNavy, 
                          borderRadius: BorderRadius.circular(30.r), 
                          boxShadow: [
                            BoxShadow(
                              color: primaryNavy.withValues(alpha: 0.3), 
                              blurRadius: 20,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: BottomNavigationBar(
                            currentIndex: state.bottomNavIndex, 
                            onTap: (index) => context.read<HomeCubit>().changeTab(index), 
                            type: BottomNavigationBarType.fixed, 
                            backgroundColor: Colors.transparent, 
                            selectedItemColor: goldAccent, 
                            unselectedItemColor: Colors.grey.shade500, 
                            selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13), 
                            unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
                            showUnselectedLabels: true,
                            elevation: 0, 
                            items: [
                              const BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_rounded)), label: 'الرئيسية'), 
                              const BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.search_rounded)), label: 'البحث'), 
                              
                              BottomNavigationBarItem(
                                icon: Padding(
                                  padding: const EdgeInsets.only(bottom: 4), 
                                  child: Badge(
                                    // 🟢 التعديل هنا: شيلنا شرط (state.activeRole == 'customer')
                                    // عشان اللمبة الحمرا تظهر للكابتن والعميل مع بعض
                                    isLabelVisible: state.activeOrdersCount > 0 || state.hasNewNotification, 
                                    label: state.activeOrdersCount > 0 ? Text(state.activeOrdersCount.toString(), style: const TextStyle(fontFamily: 'Cairo')) : null,
                                    backgroundColor: Colors.red,
                                    child: const Icon(Icons.receipt_long_rounded),
                                  ),
                                ), 
                                label: 'الطلبات'
                              ), 
                              
                              const BottomNavigationBarItem(icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.person_rounded)), label: 'الحساب')
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                if (state.actionStatus == HomeActionStatus.loading)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7), 
                    child: Center(
                      child: CircularProgressIndicator(color: royalGreen),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _confirmPasswordReset(BuildContext pageContext) {
    showDialog(context: pageContext, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)), 
      title: Row(textDirection: TextDirection.rtl, children: [Icon(Icons.lock_reset_rounded, color: primaryNavy), SizedBox(width: 8.w), const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))]), 
      content: const Text('هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14), textDirection: TextDirection.rtl), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); pageContext.read<HomeCubit>().sendPasswordResetEmail(); }, child: const Text('إرسال الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))),
      ],
    ));
  }

  void _showSupportDialog(BuildContext pageContext, String currentUserName, String currentUserEmail) {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(context: pageContext, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)), 
      title: Row(textDirection: TextDirection.rtl, children: [const Icon(Icons.support_agent_rounded, color: Colors.orange), SizedBox(width: 8.w), const Text('الدعم الفني والشكاوى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16))]), 
      content: TextField(
        controller: complaintCtrl, maxLines: 4, textDirection: TextDirection.rtl, 
        decoration: InputDecoration(hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...', hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: royalGreen, width: 2))),
      ), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: royalGreen, foregroundColor: Colors.white), 
          onPressed: () async { 
            if (complaintCtrl.text.trim().isEmpty) return; 
            Navigator.pop(ctx); 
            try { 
              User? user = FirebaseAuth.instance.currentUser; 
              await FirebaseFirestore.instance.collection('support_tickets').add({'uid': user?.uid, 'name': currentUserName, 'email': currentUserEmail, 'message': complaintCtrl.text.trim(), 'status': 'open', 'timestamp': FieldValue.serverTimestamp()}); 
              ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
            } catch(e) { 
              ScaffoldMessenger.of(pageContext).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال ❌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)); 
            } 
          }, 
          child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }
}