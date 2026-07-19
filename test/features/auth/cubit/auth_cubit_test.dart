import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart'; // تمت إضافة هذه المكتبة

// مسارات الاستيراد الجديدة المظبوطة على التقسيمة بتاعتك بالظبط
import 'package:lamma_new/features/auth/cubit/auth_cubit.dart';
import 'package:lamma_new/features/auth/cubit/auth_state.dart';
import 'package:lamma_new/features/auth/domain/entities/user_entity.dart';
import 'package:lamma_new/features/auth/domain/use_cases/login_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_up_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/sign_out_use_case.dart';
import 'package:lamma_new/features/auth/domain/use_cases/auth_advanced_use_cases.dart';
import 'package:lamma_new/features/auth/domain/repositories/auth_repository.dart';

// 1. الدوبلير بتاعنا لكل كلاس
class MockLoginUseCase extends Mock implements LoginUseCase {}

class MockSignUpUseCase extends Mock implements SignUpUseCase {}

class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockLoginWithGoogleUseCase extends Mock
    implements LoginWithGoogleUseCase {}

class MockSendSignUpOtpUseCase extends Mock implements SendSignUpOtpUseCase {}

class MockVerifyOtpAndSignUpUseCase extends Mock
    implements VerifyOtpAndSignUpUseCase {}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AuthCubit authCubit;
  late MockLoginUseCase mockLoginUseCase;
  late MockSignUpUseCase mockSignUpUseCase;
  late MockSignOutUseCase mockSignOutUseCase;
  late MockLoginWithGoogleUseCase mockLoginWithGoogleUseCase;
  late MockSendSignUpOtpUseCase mockSendSignUpOtpUseCase;
  late MockVerifyOtpAndSignUpUseCase mockVerifyOtpAndSignUpUseCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockSignUpUseCase = MockSignUpUseCase();
    mockSignOutUseCase = MockSignOutUseCase();
    mockLoginWithGoogleUseCase = MockLoginWithGoogleUseCase();
    mockSendSignUpOtpUseCase = MockSendSignUpOtpUseCase();
    mockVerifyOtpAndSignUpUseCase = MockVerifyOtpAndSignUpUseCase();
    mockAuthRepository = MockAuthRepository();

    authCubit = AuthCubit(
      loginUseCase: mockLoginUseCase,
      signUpUseCase: mockSignUpUseCase,
      signOutUseCase: mockSignOutUseCase,
      loginWithGoogleUseCase: mockLoginWithGoogleUseCase,
      sendSignUpOtpUseCase: mockSendSignUpOtpUseCase,
      verifyOtpAndSignUpUseCase: mockVerifyOtpAndSignUpUseCase,
      authRepository: mockAuthRepository,
    );
  });

  tearDown(() {
    authCubit.close();
  });

  const tEmail = 'test@test.com';
  const tPassword = 'password123';
  final tUserEntity = UserEntity(
    uid: '12345ABC',
    name: 'Ahmed',
    email: tEmail,
    phone: '01012345678',
    roles: const ['passenger'],
    activeRole: 'passenger',
  );

  group('AuthCubit Tests', () {
    test('initial state should be AuthInitial', () {
      expect(authCubit.state, isA<AuthInitial>());
    });

    test('emits [AuthLoading, AuthSuccess] when login is successful', () async {
      // Arrange
      when(() => mockLoginUseCase.call(email: tEmail, password: tPassword))
          .thenAnswer((_) async => tUserEntity);

      // Assert
      final expectedStates = [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ];
      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      // Act
      await authCubit.login(email: tEmail, password: tPassword);

      // Verify
      verify(() => mockLoginUseCase.call(email: tEmail, password: tPassword))
          .called(1);
    });

    test('emits [AuthLoading, AuthError] when login fails', () async {
      // Arrange
      when(() => mockLoginUseCase.call(email: tEmail, password: tPassword))
          .thenThrow(Exception('Failed to login'));

      // Assert
      final expectedStates = [
        isA<AuthLoading>(),
        isA<AuthError>(),
      ];
      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      // Act
      await authCubit.login(email: tEmail, password: tPassword);
    });

    test('emits [AuthLoading, AuthLoggedOut] when signOut is successful',
        () async {
      // Arrange
      when(() => mockSignOutUseCase.call())
          .thenAnswer((_) async => Future.value());

      // Assert
      final expectedStates = [
        isA<AuthLoading>(),
        isA<AuthLoggedOut>(),
      ];
      expectLater(authCubit.stream, emitsInOrder(expectedStates));

      // Act
      await authCubit.signOut();
    });

    // 5. اختبار تسجيل حساب جديد (SignUp)
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthSuccess] when signUp is successful',
      build: () {
        when(() => mockSignUpUseCase.call(
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
              phone: any(named: 'phone'),
            )).thenAnswer((_) async => tUserEntity);
        return authCubit;
      },
      act: (cubit) => cubit.signUp(
          email: tEmail,
          password: tPassword,
          name: 'Ahmed',
          phone: '01012345678'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
    );

    // 6. اختبار إرسال كود الـ OTP
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthOtpSent] when sendSignUpOtp is successful',
      build: () {
        when(() => mockSendSignUpOtpUseCase.call(
              phone: any(named: 'phone'),
              onCodeSent: any(named: 'onCodeSent'),
              onError: any(named: 'onError'),
            )).thenAnswer((invocation) async {
          // محاكاة إرسال الكود بنجاح
          final onCodeSent =
              invocation.namedArguments[#onCodeSent] as Function(String);
          onCodeSent('123456');
        });
        return authCubit;
      },
      act: (cubit) => cubit.sendSignUpOtp(phone: '01012345678'),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthOtpSent>(),
      ],
    );

    // 7. اختبار تفعيل الكود وإكمال التسجيل
    blocTest<AuthCubit, AuthState>(
      'emits [AuthLoading, AuthSuccess] when verifyOtpAndCompleteSignUp is successful',
      build: () {
        when(() => mockVerifyOtpAndSignUpUseCase.call(
              verificationId: any(named: 'verificationId'),
              smsCode: any(named: 'smsCode'),
              email: any(named: 'email'),
              password: any(named: 'password'),
              name: any(named: 'name'),
              phone: any(named: 'phone'),
              role: any(named: 'role'),
            )).thenAnswer((_) async => tUserEntity);
        return authCubit;
      },
      act: (cubit) => cubit.verifyOtpAndCompleteSignUp(
        verificationId: '123456',
        smsCode: '000000',
        email: tEmail,
        password: tPassword,
        name: 'Ahmed',
        phone: '01012345678',
        role: 'passenger',
      ),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthSuccess>(),
      ],
    );
  }); // نهاية جروب الاختبارات
}
