import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/services/family_service.dart';
import 'family_state.dart';

class FamilyCubit extends Cubit<FamilyState> {
  final FamilyService _familyService;
  StreamSubscription? _familySubscription;

  FamilyCubit(this._familyService) : super(FamilyInitial());

  void loadFamilyMembers(String parentUid) {
    emit(FamilyLoading());
    _familySubscription?.cancel();
    _familySubscription =
        _familyService.getFamilyMembersStream(parentUid).listen(
      (members) {
        emit(FamilyLoaded(members));
      },
      onError: (error) {
        emit(FamilyError(error.toString()));
      },
    );
  }

  Future<void> searchAndAddMember(String parentUid, String phoneNumber) async {
    emit(FamilyLoading());
    try {
      final userData = await _familyService.findUserByPhone(phoneNumber);

      if (userData != null) {
        // إذا وجدنا المستخدم، نقوم بإضافته فوراً
        await _familyService.addFamilyMember(parentUid, userData);
        emit(FamilyActionSuccess('تمت إضافة فرد العائلة بنجاح'));
      } else {
        emit(FamilyError('لم يتم العثور على مستخدم بهذا الرقم'));
      }
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  Future<void> removeMember(String parentUid, String childUid) async {
    try {
      await _familyService.removeFamilyMember(parentUid, childUid);
      emit(FamilyActionSuccess('تمت الإزالة بنجاح'));
    } catch (e) {
      emit(FamilyError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _familySubscription?.cancel();
    return super.close();
  }
}
