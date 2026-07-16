import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';

// 🟢 استدعاءات الـ UseCases بالكامل (Clean Architecture)
import '../../domain/use_cases/get_user_profile_use_case.dart';
import '../../domain/use_cases/update_user_profile_use_case.dart';
import '../../domain/use_cases/switch_user_role_use_case.dart';
import '../../domain/use_cases/upload_document_use_case.dart';
import '../../domain/use_cases/submit_role_registration_use_case.dart';

// 🟢 الـ Repository متبقي فقط لدالة الدعم الفني (sendSupportTicket)
import '../../domain/repositories/profile_repository.dart';

// 🟢 استيراد ملف الـ State
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final GetUserProfileUseCase _getUserProfileUseCase;
  final UpdateUserProfileUseCase _updateUserProfileUseCase;
  final SwitchUserRoleUseCase _switchUserRoleUseCase;
  final UploadDocumentUseCase _uploadDocumentUseCase;
  final SubmitRoleRegistrationUseCase _submitRoleRegistrationUseCase;
  final ProfileRepository _repository;

  ProfileCubit({
    required GetUserProfileUseCase getUserProfileUseCase,
    required UpdateUserProfileUseCase updateUserProfileUseCase,
    required SwitchUserRoleUseCase switchUserRoleUseCase,
    required UploadDocumentUseCase uploadDocumentUseCase,
    required SubmitRoleRegistrationUseCase submitRoleRegistrationUseCase,
    required ProfileRepository repository,
  })  : _getUserProfileUseCase = getUserProfileUseCase,
        _updateUserProfileUseCase = updateUserProfileUseCase,
        _switchUserRoleUseCase = switchUserRoleUseCase,
        _uploadDocumentUseCase = uploadDocumentUseCase,
        _submitRoleRegistrationUseCase = submitRoleRegistrationUseCase,
        _repository = repository,
        super(ProfileState());

  Future<void> loadUserProfile() async {
    emit(state.copyWith(status: ProfileStatus.loading));
    final result = await _getUserProfileUseCase();
    if (isClosed) return; 
    
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
    emit(state.copyWith(activeRole: newRole)); 
    
    final result = await _switchUserRoleUseCase(newRole);
    if (isClosed) return;
    
    result.fold(
      (failure) {
        emit(state.copyWith(actionStatus: ProfileActionStatus.error, errorMessage: failure.message));
        loadUserProfile();
      },
      (_) {
        loadUserProfile();
      },
    );
  }

  Future<String> uploadDocument({required String role, required String docName, required File file}) async {
    // 🟢 التعديل هنا: إرسال المتغيرات بأسمائها (Named Arguments)
    final result = await _uploadDocumentUseCase(role: role, docName: docName, file: file);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (url) => url,
    );
  }

  Future<void> submitRoleRegistration({required String role, required Map<String, dynamic> profileData}) async {
    emit(state.copyWith(actionStatus: ProfileActionStatus.loading));
    
    // 🟢 التعديل هنا: إرسال المتغيرات بأسمائها (Named Arguments)
    final result = await _submitRoleRegistrationUseCase(role: role, profileData: profileData);
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(state.copyWith(actionStatus: ProfileActionStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(actionStatus: ProfileActionStatus.success, successMessage: 'تم تفعيل الحساب بنجاح!'));
        switchUserRole(role);
      },
    );
  }

  Future<void> sendSupportTicket({required String message}) async {
    emit(state.copyWith(actionStatus: ProfileActionStatus.loading));
    
    final result = await _repository.sendSupportTicket(
      name: state.userName, 
      email: state.userEmail, 
      message: message,
    );
    
    if (isClosed) return;
    
    result.fold(
      (failure) => emit(state.copyWith(actionStatus: ProfileActionStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(actionStatus: ProfileActionStatus.success, successMessage: 'تم إرسال رسالتك للدعم الفني بنجاح ✅')),
    );
  }

  void resetProfile() {
    emit(ProfileState());
  }
}