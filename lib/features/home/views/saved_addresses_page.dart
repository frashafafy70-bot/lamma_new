import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // 🟢 تم إضافة استيراد الـ Auth هنا لقفل الثغرة الأمنية

import 'package:lamma_new/theme/app_colors.dart';
import '../../profile/presentation/cubit/address_cubit.dart'; 
import 'package:lamma_new/features/trips/presentation/widgets/trip_map.dart';

class SavedAddressesPage extends StatelessWidget {
  const SavedAddressesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddressCubit()..fetchAddresses(),
      child: const _SavedAddressesContent(),
    );
  }
}

class _SavedAddressesContent extends StatefulWidget {
  const _SavedAddressesContent();

  @override
  State<_SavedAddressesContent> createState() => _SavedAddressesContentState();
}

class _SavedAddressesContentState extends State<_SavedAddressesContent> {

  Map<String, dynamic> _getIconAndColor(String title) {
    if (title.contains('منزل') || title.contains('بيت')) {
      return {'icon': Icons.home_rounded, 'color': LammaColors.info};
    } else if (title.contains('عمل') || title.contains('شغل') || title.contains('شركة')) {
      return {'icon': Icons.work_rounded, 'color': LammaColors.warning};
    }
    return {'icon': Icons.location_on_rounded, 'color': LammaColors.success};
  }

  void _showAddressBottomSheet({Map<String, dynamic>? existingAddress}) {
    final titleController = TextEditingController(text: existingAddress?['title'] ?? '');
    final addressController = TextEditingController(text: existingAddress?['address'] ?? '');
    bool isDefault = existingAddress?['isDefault'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
                top: 20.h, left: 20.w, right: 20.w,
              ),
              decoration: BoxDecoration(
                color: LammaColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w, height: 5.h,
                      decoration: BoxDecoration(color: LammaColors.dividerColor, borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    existingAddress == null ? 'إضافة عنوان جديد' : 'تعديل العنوان',
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, fontWeight: FontWeight.bold, color: LammaColors.primaryNavy),
                  ),
                  SizedBox(height: 20.h),
                  
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'اسم العنوان (مثال: المنزل، العمل)',
                      labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.textMuted),
                      prefixIcon: const Icon(Icons.title_rounded, color: LammaColors.accentGold),
                      filled: true, fillColor: LammaColors.cardWhite,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: LammaColors.accentGold)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'تفاصيل العنوان',
                      labelStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.textMuted),
                      
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.location_on_outlined, color: LammaColors.accentGold),
                        onPressed: () async {
                          FocusScope.of(context).unfocus(); // إخفاء الكيبورد

                          // استدعاء شاشة الخريطة مع تفعيل متغير اختيار العنوان
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TripMap(isAddressSelectionMode: true)), 
                          );

                          if (result != null && result is Map<String, dynamic>) {
                            setModalState(() {
                              addressController.text = result['address'] ?? '';
                            });
                          }
                        },
                      ),
                      
                      filled: true, fillColor: LammaColors.cardWhite,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: const BorderSide(color: LammaColors.accentGold)),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  SwitchListTile(
                    title: Text('تعيين كعنوان أساسي', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: LammaColors.textDark)),
                    value: isDefault,
                    activeColor: LammaColors.accentGold,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setModalState(() => isDefault = value);
                    },
                  ),
                  SizedBox(height: 20.h),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty && addressController.text.isNotEmpty) {
                          final data = {
                            'uid': FirebaseAuth.instance.currentUser?.uid, // 🟢 تم ربط الـ uid الخاص بالمستخدم هنا ليمر بأمان عبر الـ Rules المشفرة
                            'title': titleController.text,
                            'address': addressController.text,
                            'isDefault': isDefault,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          if (existingAddress == null) {
                            this.context.read<AddressCubit>().addAddress(data);
                          } else {
                            this.context.read<AddressCubit>().updateAddress(existingAddress['id'], data);
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: LammaColors.primaryNavy,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                      ),
                      child: Text('حفظ العنوان', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteDialog(String docId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: LammaColors.error, size: 28.sp),
              SizedBox(width: 10.w),
              Text('حذف العنوان', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp, color: LammaColors.textDark)),
            ],
          ),
          content: Text('هل أنت متأكد من حذف هذا العنوان بشكل نهائي؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: LammaColors.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                this.context.read<AddressCubit>().deleteAddress(docId);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: LammaColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text('حذف', style: TextStyle(fontFamily: 'Cairo', color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LammaColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text('العناوين المحفوظة', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 20.sp, color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [LammaColors.primaryNavy, LammaColors.royalGreen],
              begin: Alignment.topRight, end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(25.r), bottomRight: Radius.circular(25.r)),
          ),
        ),
      ),
      
      body: BlocBuilder<AddressCubit, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(child: CircularProgressIndicator(color: LammaColors.accentGold));
          } else if (state is AddressError) {
            return Center(child: Text(state.message, style: TextStyle(fontFamily: 'Cairo', color: LammaColors.error)));
          } else if (state is AddressLoaded) {
            final addresses = state.addresses;
            
            if (addresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded, size: 80.sp, color: LammaColors.dividerColor),
                    SizedBox(height: 16.h),
                    Text('لا توجد عناوين محفوظة', style: TextStyle(fontFamily: 'Cairo', fontSize: 18.sp, color: LammaColors.textMuted, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              physics: const BouncingScrollPhysics(),
              itemCount: addresses.length,
              itemBuilder: (context, index) {
                final address = addresses[index];
                final styleData = _getIconAndColor(address['title']); 

                return Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildAddressCard(
                    id: address['id'],
                    icon: styleData['icon'],
                    iconColor: styleData['color'],
                    title: address['title'],
                    address: address['address'],
                    isDefault: address['isDefault'] ?? false,
                    fullAddressData: address,
                  ),
                );
              },
            );
          }
          return const SizedBox(); 
        },
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 30.h, top: 10.h),
        child: ElevatedButton.icon(
          onPressed: () => _showAddressBottomSheet(),
          style: ElevatedButton.styleFrom(
            backgroundColor: LammaColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            elevation: 5,
            shadowColor: LammaColors.primaryNavy.withOpacity(0.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          ),
          icon: Icon(Icons.add_location_alt_rounded, size: 24.sp, color: LammaColors.accentGold),
          label: Text('إضافة عنوان جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp)),
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required String id,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String address,
    required bool isDefault,
    required Map<String, dynamic> fullAddressData,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: LammaColors.cardWhite,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: LammaColors.dividerColor),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        title: Row(
          children: [
            Text(title, style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16.sp, color: LammaColors.textDark)),
            if (isDefault) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(color: LammaColors.primaryNavy.withOpacity(0.1), borderRadius: BorderRadius.circular(10.r)),
                child: Text('الأساسي', style: TextStyle(fontFamily: 'Cairo', fontSize: 10.sp, fontWeight: FontWeight.bold, color: LammaColors.primaryNavy)),
              )
            ]
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(address, style: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: LammaColors.textMuted)),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: LammaColors.textMuted),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          color: LammaColors.cardWhite,
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 20.sp, color: LammaColors.info), SizedBox(width: 8.w), Text('تعديل', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.textDark))])),
            PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20.sp, color: LammaColors.error), SizedBox(width: 8.w), Text('حذف', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.error))])),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showAddressBottomSheet(existingAddress: fullAddressData);
            } else if (value == 'delete') {
              _showDeleteDialog(id);
            }
          },
        ),
      ),
    );
  }
}