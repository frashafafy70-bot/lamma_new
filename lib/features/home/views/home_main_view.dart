// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../cubit/home_cubit.dart';
import 'widgets/service_square_card.dart';
import 'account_switch_widget.dart'; 

import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_radar_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_active_trips_tab.dart';
import 'package:lamma_new/features/trips/presentation/pages/driver_tabs/driver_history_tab.dart';
import 'package:lamma_new/features/trips/cubit/driver/driver_active_trips_cubit.dart';

class HomeMainView extends StatefulWidget {
  final String activeRole;
  final String userName;
  final String profileImageUrl;
  final VoidCallback onOpenNotifications;

  const HomeMainView({
    super.key,
    required this.activeRole,
    required this.userName,
    required this.profileImageUrl,
    required this.onOpenNotifications,
  });

  @override
  State<HomeMainView> createState() => _HomeMainViewState();
}

class _HomeMainViewState extends State<HomeMainView> {
  
  final Color royalGreen = const Color(0xFF1B4332);
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  String _getRoleArabicName(String role) {
    switch (role) {
      case 'customer': return 'عميل';
      case 'captain': return 'كابتن';
      case 'lawyer': return 'محامي';
      case 'doctor': return 'طبيب';
      case 'nurse': return 'تمريض';
      default: return 'مقدم خدمة';
    }
  }

  void _openAccountSwitchPage(BuildContext mainContext) async {
    final String? newSelectedRole = await Navigator.push<String>(
      mainContext,
      MaterialPageRoute(
        builder: (context) => AccountSwitchWidget(currentRole: widget.activeRole),
      ),
    );

    if (newSelectedRole != null && newSelectedRole != widget.activeRole && mainContext.mounted) {
      mainContext.read<HomeCubit>().switchUserRole(newSelectedRole);
    }
  }

  void _showAddTravelBottomSheet(BuildContext context) {
    final TextEditingController fromCtrl = TextEditingController();
    final TextEditingController toCtrl = TextEditingController();
    final TextEditingController priceCtrl = TextEditingController();
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25.r))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext bottomSheetContext, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20.w, right: 20.w, top: 16.h,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: Container(width: 40.w, height: 5.h, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10.r)))),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Icon(Icons.directions_bus_filled_rounded, color: goldAccent, size: 28.sp),
                        SizedBox(width: 10.w),
                        Text('نشر رحلة سفر جديدة', style: TextStyle(fontFamily: 'Cairo', fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryNavy)),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    TextField(
                      controller: fromCtrl,
                      decoration: InputDecoration(
                        labelText: 'نقطة التحرك (من)',
                        prefixIcon: const Icon(Icons.my_location_rounded, color: Colors.blueAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: royalGreen, width: 2)),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextField(
                      controller: toCtrl,
                      decoration: InputDecoration(
                        labelText: 'وجهة السفر (إلى)',
                        prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.redAccent),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: royalGreen, width: 2)),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    InkWell(
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (pickedDate != null) {
                          TimeOfDay? pickedTime = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (pickedTime != null) {
                            setState(() {
                              selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_rounded, color: Colors.orange),
                            SizedBox(width: 10.w),
                            Text(
                              selectedDate == null 
                                  ? 'تاريخ ووقت التحرك' 
                                  : DateFormat('yyyy/MM/dd - hh:mm a', 'en').format(selectedDate!),
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: selectedDate == null ? Colors.grey.shade600 : primaryNavy),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'سعر المقعد المتوقع (ج.م)',
                        prefixIcon: Icon(Icons.payments_rounded, color: royalGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: royalGreen, width: 2)),
                      ),
                    ),
                    SizedBox(height: 24.h),

                    SizedBox(
                      width: double.infinity,
                      height: 50.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        ),
                        onPressed: () async {
                          if (fromCtrl.text.isEmpty || toCtrl.text.isEmpty || priceCtrl.text.isEmpty || selectedDate == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء إكمال جميع البيانات', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
                            return;
                          }

                          Navigator.pop(ctx); 
                          
                          try {
                            final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
                            await FirebaseFirestore.instance.collection('trips').add({
                              'driverId': currentUserId,
                              'driverName': widget.userName,
                              'pickupLocation': fromCtrl.text.trim(),
                              'dropoffLocation': toCtrl.text.trim(),
                              'travelDate': Timestamp.fromDate(selectedDate!),
                              'price': priceCtrl.text.trim(),
                              'tripCategory': 'سفر',
                              'isDriverPost': true, 
                              'status': 'available', 
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: const Text('تم نشر رحلة السفر بنجاح! 🚌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: royalGreen)
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)
                            );
                          }
                        },
                        child: Text('نشر الرحلة', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: goldAccent)),
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent, 
        appBar: AppBar(
          backgroundColor: primaryNavy,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: goldAccent, 
                backgroundImage: widget.profileImageUrl.isNotEmpty ? NetworkImage(widget.profileImageUrl) : null,
                child: widget.profileImageUrl.isEmpty ? Icon(Icons.person, color: primaryNavy, size: 20.sp) : null,
              ),
              SizedBox(width: 10.w),
              Expanded(child: Text('مرحباً، ${widget.userName}', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
            ],
          ),
          actions: [
            if (currentUserId.isNotEmpty)
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUserId)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false) 
                    .snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }

                  return IconButton(
                    icon: Badge(
                      isLabelVisible: unreadCount > 0, 
                      label: Text(unreadCount.toString(), style: const TextStyle(fontFamily: 'Cairo')),
                      backgroundColor: Colors.redAccent,
                      child: const Icon(Icons.notifications_none, color: Colors.white),
                    ),
                    onPressed: widget.onOpenNotifications,
                  );
                },
              )
            else
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white), 
                onPressed: widget.onOpenNotifications,
              ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          // 🟢 التعديل هنا: زيادة المسافة السفلية لـ 150.h عشان الكارت يظهر بالكامل فوق الـ Bottom Nav Bar
          padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 16.h, bottom: 150.h), 
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryNavy, royalGreen],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [BoxShadow(color: royalGreen.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))]
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('وضع الحساب الحالي', style: TextStyle(color: Colors.white70, fontSize: 13.sp, fontFamily: 'Cairo')),
                        SizedBox(height: 4.h),
                        Text(_getRoleArabicName(widget.activeRole), style: TextStyle(color: goldAccent, fontSize: 22.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: goldAccent, 
                        foregroundColor: primaryNavy,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r))
                      ),
                      onPressed: () => _openAccountSwitchPage(context),
                      icon: Icon(Icons.swap_horiz_rounded, size: 20.sp),
                      label: Text('تبديل', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 30.h),
              Text('الخدمات المتاحة', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: primaryNavy)),
              SizedBox(height: 16.h),
              
              if (widget.activeRole == 'captain') ...[
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: primaryNavy,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5))],
                    border: Border.all(color: goldAccent.withValues(alpha: 0.3), width: 1.w),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12.w, height: 12.w,
                                decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 8)]),
                              ),
                              SizedBox(width: 8.w),
                              Text('متصل وجاهز للطلبات', style: TextStyle(fontFamily: 'Cairo', color: Colors.greenAccent, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Icon(Icons.directions_car_rounded, color: goldAccent, size: 28.sp),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Text('جاهز لاستقبال مشاوير جديدة؟', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      SizedBox(height: 6.h),
                      Text('ادخل على الرادار لمتابعة الطلبات المتاحة في محيطك الآن.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400, fontSize: 13.sp)),
                      SizedBox(height: 20.h),
                      SizedBox(
                        width: double.infinity,
                        height: 50.h,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: goldAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CaptainRadarPage()));
                          },
                          child: Text('افتح الرادار الآن 📡', style: TextStyle(fontFamily: 'Cairo', color: primaryNavy, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 16.h), 

                TravelServiceCard(
                  onAddTravelTap: () => _showAddTravelBottomSheet(context),
                ),

              ] else if (widget.activeRole == 'lawyer') ...[
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16.w, mainAxisSpacing: 16.h, childAspectRatio: 0.95,
                  children: [
                    ServiceSquareCard(title: 'لوحة التحكم', subtitle: 'الاستشارات والتوكيلات', icon: Icons.gavel_rounded, iconColor: primaryNavy, onTap: () {}),
                  ],
                ),
              ] else ...[
                GridView.count(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, crossAxisSpacing: 16.w, mainAxisSpacing: 16.h, childAspectRatio: 0.95,
                  children: [
                    ServiceSquareCard(title: 'توصيل ورحلات', subtitle: 'اطلب كابتن فوراً', icon: Icons.local_taxi_rounded, iconColor: goldAccent, onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const TripsServicesPage()));
                    }),
                    ServiceSquareCard(title: 'خدمات قانونية', subtitle: 'استشارات وتوكيلات', icon: Icons.gavel_rounded, iconColor: primaryNavy, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('سيتم تفعيل قسم الخدمات القانونية قريباً', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryNavy));
                    }),
                    ServiceSquareCard(title: 'شوب ومتاجر', subtitle: 'تسوق منتجاتك', icon: Icons.storefront_rounded, iconColor: royalGreen, onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('قسم المتاجر تحت الإنشاء', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: royalGreen));
                    }),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class TravelServiceCard extends StatelessWidget {
  final VoidCallback onAddTravelTap;

  const TravelServiceCard({
    super.key, 
    required this.onAddTravelTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryNavy = const Color(0xFF0F172A);
    final Color goldAccent = const Color(0xFFD4AF37);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: primaryNavy,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: primaryNavy.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: goldAccent.withValues(alpha: 0.3), width: 1.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12.w, height: 12.w,
                    decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blueAccent, blurRadius: 8)]),
                  ),
                  SizedBox(width: 8.w),
                  Text('حجز مسبق', style: TextStyle(fontFamily: 'Cairo', color: Colors.blueAccent, fontSize: 14.sp, fontWeight: FontWeight.bold)),
                ],
              ),
              Icon(Icons.directions_bus_filled_rounded, color: goldAccent, size: 28.sp),
            ],
          ),
          SizedBox(height: 20.h),
          Text('مسافر لمحافظة تانية قريباً؟', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 6.h),
          Text('حدد مسارك وتاريخ رحلتك، وخلي العملاء تحجز معاك مقدماً وتشاركك التكلفة.', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade400, fontSize: 13.sp)),
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            height: 50.h,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: goldAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: onAddTravelTap,
              child: Text('إضافة رحلة سفر 🗓️', style: TextStyle(fontFamily: 'Cairo', color: primaryNavy, fontSize: 16.sp, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class CaptainRadarPage extends StatefulWidget {
  const CaptainRadarPage({super.key});

  @override
  State<CaptainRadarPage> createState() => _CaptainRadarPageState();
}

class _CaptainRadarPageState extends State<CaptainRadarPage> with SingleTickerProviderStateMixin {
  late TabController _captainTabController;

  @override
  void initState() {
    super.initState();
    _captainTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _captainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('لوحة تحكم الكابتن', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, color: Colors.white)),
          backgroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0,
          bottom: TabBar(
            controller: _captainTabController,
            indicatorColor: const Color(0xFFD4AF37),
            labelColor: const Color(0xFFD4AF37),
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(text: 'الرادار', icon: Icon(Icons.radar_rounded)),
              Tab(text: 'النشطة', icon: Icon(Icons.play_circle_fill_rounded)),
              Tab(text: 'السجل', icon: Icon(Icons.history_rounded)), 
            ],
          ),
        ),
        body: TabBarView(
          controller: _captainTabController,
          children: [
            DriverRadarTab(tabController: _captainTabController),
            
            BlocProvider(
              create: (context) => DriverActiveTripsCubit(),
              child: const DriverActiveTripsTab(), 
            ),
            
            const DriverHistoryTab(),
          ],
        ),
      ),
    );
  }
}