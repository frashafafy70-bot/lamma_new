// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 🟢 استدعاء ملف الترجمة الخاص بالمشروع
import 'package:lamma_new/l10n/app_localizations.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/core/theme/app_colors.dart';
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
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('منزل') ||
        lowerTitle.contains('بيت') ||
        lowerTitle.contains('home')) {
      return {'icon': Icons.home_rounded, 'color': AppColors.info};
    } else if (lowerTitle.contains('عمل') ||
        lowerTitle.contains('شغل') ||
        lowerTitle.contains('شركة') ||
        lowerTitle.contains('work') ||
        lowerTitle.contains('office')) {
      return {'icon': Icons.work_rounded, 'color': AppColors.warning};
    }
    return {'icon': Icons.location_on_rounded, 'color': AppColors.success};
  }

  void _showAddressBottomSheet({Map<String, dynamic>? existingAddress}) {
    final l10n = AppLocalizations.of(context)!;
    final titleController =
        TextEditingController(text: existingAddress?['title'] ?? '');
    final addressController =
        TextEditingController(text: existingAddress?['address'] ?? '');
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
                top: 20.h,
                left: 20.w,
                right: 20.w,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50.w,
                      height: 5.h,
                      decoration: BoxDecoration(
                          color: AppColors.dividerColor,
                          borderRadius: BorderRadius.circular(10.r)),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    existingAddress == null
                        ? l10n.addNewAddress
                        : l10n.editAddressTitle,
                    style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy),
                  ),
                  SizedBox(height: 20.h),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: l10n.addressNameHint,
                      labelStyle: TextStyle(
                          fontSize: 14.sp, color: AppColors.textMuted),
                      prefixIcon: const Icon(Icons.title_rounded,
                          color: AppColors.accentGold),
                      filled: true,
                      fillColor: AppColors.cardWhite,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide:
                              const BorderSide(color: AppColors.accentGold)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  TextField(
                    controller: addressController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: l10n.addressDetailsHint,
                      labelStyle: TextStyle(
                          fontSize: 14.sp, color: AppColors.textMuted),
                      prefixIcon: IconButton(
                        icon: const Icon(Icons.location_on_outlined,
                            color: AppColors.accentGold),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();

                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const TripMap(
                                    isAddressSelectionMode: true)),
                          );

                          if (result != null &&
                              result is Map<String, dynamic>) {
                            setModalState(() {
                              addressController.text = result['address'] ?? '';
                            });
                          }
                        },
                      ),
                      filled: true,
                      fillColor: AppColors.cardWhite,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15.r),
                          borderSide:
                              const BorderSide(color: AppColors.accentGold)),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SwitchListTile(
                    title: Text(l10n.setAsDefaultAddress,
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    value: isDefault,
                    activeColor: AppColors.accentGold,
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
                        if (titleController.text.isNotEmpty &&
                            addressController.text.isNotEmpty) {
                          final data = {
                            'uid': FirebaseAuth.instance.currentUser?.uid,
                            'title': titleController.text,
                            'address': addressController.text,
                            'isDefault': isDefault,
                            'createdAt': FieldValue.serverTimestamp(),
                          };

                          if (existingAddress == null) {
                            this.context.read<AddressCubit>().addAddress(data);
                          } else {
                            this
                                .context
                                .read<AddressCubit>()
                                .updateAddress(existingAddress['id'], data);
                          }
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.r)),
                      ),
                      child: Text(l10n.saveAddress,
                          style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 28.sp),
              SizedBox(width: 10.w),
              Text(l10n.deleteAddressTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: AppColors.textDark)),
            ],
          ),
          content: Text(l10n.deleteAddressConfirmation,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.cancel,
                  style: TextStyle(
                      color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                this.context.read<AddressCubit>().deleteAddress(docId);
                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text(l10n.delete,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(l10n.savedAddresses,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.sp,
                color: Colors.white)),
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryNavy, AppColors.royalGreen],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25.r),
                bottomRight: Radius.circular(25.r)),
          ),
        ),
      ),
      body: BlocBuilder<AddressCubit, AddressState>(
        builder: (context, state) {
          if (state is AddressLoading) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.accentGold));
          } else if (state is AddressError) {
            return Center(
                child: Text(state.message,
                    style: TextStyle(color: AppColors.error)));
          } else if (state is AddressLoaded) {
            final addresses = state.addresses;

            if (addresses.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_off_rounded,
                        size: 80.sp, color: AppColors.dividerColor),
                    SizedBox(height: 16.h),
                    Text(l10n.noSavedAddresses,
                        style: TextStyle(
                            fontSize: 18.sp,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.bold)),
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
        padding:
            EdgeInsets.only(left: 20.w, right: 20.w, bottom: 30.h, top: 10.h),
        child: ElevatedButton.icon(
          onPressed: () => _showAddressBottomSheet(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryNavy,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            elevation: 5,
            shadowColor: AppColors.primaryNavy.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.r)),
          ),
          icon: Icon(Icons.add_location_alt_rounded,
              size: 24.sp, color: AppColors.accentGold),
          label: Text(l10n.addNewAddress,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp)),
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
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: AppColors.dividerColor),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 24.sp),
        ),
        title: Row(
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: AppColors.textDark)),
            if (isDefault) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: AppColors.primaryNavy.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10.r)),
                child: Text(l10n.defaultAddressLabel,
                    style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy)),
              )
            ]
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 6.h),
          child: Text(address,
              style: TextStyle(fontSize: 13.sp, color: AppColors.textMuted)),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          color: AppColors.cardWhite,
          itemBuilder: (context) => [
            PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  Icon(Icons.edit_outlined, size: 20.sp, color: AppColors.info),
                  SizedBox(width: 8.w),
                  Text(l10n.edit,
                      style:
                          TextStyle(fontSize: 14.sp, color: AppColors.textDark))
                ])),
            PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline_rounded,
                      size: 20.sp, color: AppColors.error),
                  SizedBox(width: 8.w),
                  Text(l10n.delete,
                      style: TextStyle(fontSize: 14.sp, color: AppColors.error))
                ])),
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
