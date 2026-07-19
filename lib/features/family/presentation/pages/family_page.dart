import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../cubit/family_cubit.dart';
import '../../cubit/family_state.dart';
import '../../data/services/family_service.dart';
import 'family_trip_tracking_page.dart';

class FamilyPage extends StatelessWidget {
  const FamilyPage({super.key});

  @override
  Widget build(BuildContext context) {
    // جلب معرف المستخدم الحالي (الأب)
    final String currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return BlocProvider(
      create: (context) =>
          FamilyCubit(FamilyService())..loadFamilyMembers(currentUserUid),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الاشتراك العائلي'),
          centerTitle: true,
        ),
        body: BlocConsumer<FamilyCubit, FamilyState>(
          listener: (context, state) {
            if (state is FamilyActionSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green),
              );
              // تحديث القائمة بعد الإضافة أو الحذف
              context.read<FamilyCubit>().loadFamilyMembers(currentUserUid);
            } else if (state is FamilyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is FamilyLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is FamilyLoaded) {
              if (state.members.isEmpty) {
                return const Center(
                  child: Text(
                    'لم تقم بإضافة أي أفراد لعائلتك بعد.\nاضغط على + للإضافة',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: state.members.length,
                itemBuilder: (context, index) {
                  final member = state.members[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      title: Text(member.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(member.phoneNumber),
                      trailing: IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () {
                          _showDeleteConfirmation(
                              context, currentUserUid, member.uid, member.name);
                        },
                      ),
                      onTap: () {
                        // الانتقال المباشر لشاشة التتبع الخاصة بالابن
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FamilyTripTrackingPage(
                              childUid: member.uid,
                              childName: member.name,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('حدث خطأ في جلب البيانات'));
          },
        ),
        floatingActionButton: Builder(builder: (context) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddMemberDialog(context, currentUserUid),
            icon: const Icon(Icons.person_add),
            label: const Text('إضافة فرد'),
          );
        }),
      ),
    );
  }

  // نافذة إضافة فرد جديد برقم الهاتف
  void _showAddMemberDialog(BuildContext parentContext, String parentUid) {
    final phoneController = TextEditingController();
    final cubit = parentContext.read<FamilyCubit>();

    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('إضافة فرد للعائلة'),
          content: TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'رقم الهاتف',
              hintText: 'أدخل رقم هاتف الحساب المراد إضافته',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final phone = phoneController.text.trim();
                if (phone.isNotEmpty) {
                  Navigator.pop(context);
                  cubit.searchAndAddMember(parentUid, phone);
                }
              },
              child: const Text('بحث وإضافة'),
            ),
          ],
        );
      },
    );
  }

  // نافذة تأكيد حذف فرد من العائلة
  void _showDeleteConfirmation(BuildContext parentContext, String parentUid,
      String childUid, String childName) {
    final cubit = parentContext.read<FamilyCubit>();
    showDialog(
      context: parentContext,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
              'هل أنت متأكد من رغبتك في إزالة "$childName" من قائمة تتبع العائلة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(context);
                cubit.removeMember(parentUid, childUid);
              },
              child: const Text('إزالة', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
