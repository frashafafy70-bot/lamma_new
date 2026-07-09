import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/use_cases/get_user_profile_use_case.dart';
import '../../domain/use_cases/update_user_profile_use_case.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final ProfileRepository _repository;

  ProfileCubit({
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required ProfileRepository repository,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserProfileUseCase = updateUserProfileUseCase,
        _repository = repository,
        super(ProfileState());

  Future<void> loadUserProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await _getUserProfileUseCase();
    if (isClosed) return; // 🟢 حماية
    result.fold(
      (failure) => emit(state.copyWith(status: ProfileStatus.error, errorMessage: failure.message)),
      (profile) => emit(state.copyWith(
        status: ProfileStatus.loaded,
        userName: profile.name,
        userEmail: profile.email,
        userPhone: profile.phone,       
        nationalId: profile.nationalId, 
        profileImageUrl: profile.profileImageUrl,
        activeRole: profile.activeRole,
        userRoles: profile.roles, 
      )),
    );
  }

  Future<void> updateProfile({required String name, required String phone, String? nationalId, File? newProfileImage}) async {
    emit(state.copyWith(actionStatus: ProfileActionStatus.loading));
    final result = await _updateUserProfileUseCase(
      name: name, phone: phone, nationalId: nationalId, newProfileImage: newProfileImage, currentImageUrl: state.profileImageUrl,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(actionStatus: ProfileActionStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(actionStatus: ProfileActionStatus.success, successMessage: 'تم التحديث بنجاح!'));
        loadUserProfile(); 
      },
    );
  }

  Future<void> switchUserRole(String newRole) async {
    // 🟢 السر هنا (Optimistic UI): تحديث الواجهة فوراً لتجنب التهنيج أو اللخبطة
    emit(state.copyWith(activeRole: newRole)); 
    
    final result = await _repository.switchUserRole(newRole);
    if (isClosed) return;
    result.fold(
      (failure) {
        // لو حصل مشكلة مع السيرفر نرجع نعرض رسالة الخطأ ونسحب الداتا الصح
        emit(state.copyWith(actionStatus: ProfileActionStatus.error, errorMessage: failure.message));
        loadUserProfile();
      },
      (_) {
        // في حالة النجاح، نسحب الداتا المحدثة من السيرفر بهدوء في الخلفية
        loadUserProfile();
      },
    );
  }

  Future<String> uploadDocument({required String role, required String docName, required File file}) async {
    final result = await _repository.uploadDocument(role, docName, file);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (url) => url,
    );
  }

  Future<void> submitRoleRegistration({required String role, required Map<String, dynamic> profileData}) async {
    emit(state.copyWith(actionStatus: ProfileActionStatus.loading));
    final result = await _repository.submitRoleRegistration(role, profileData);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(actionStatus: ProfileActionStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(actionStatus: ProfileActionStatus.success, successMessage: 'تم تفعيل الحساب بنجاح!'));
        switchUserRole(role);
      },
    );
  }

  void resetProfile() {
    emit(ProfileState());
  }
}