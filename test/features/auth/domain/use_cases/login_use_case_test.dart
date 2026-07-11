import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:lamma_new/features/auth/domain/entities/user_entity.dart';
import 'package:lamma_new/features/auth/domain/repositories/auth_repository.dart';
import 'package:lamma_new/features/auth/domain/use_cases/login_use_case.dart';

// 1. الدوبلير بتاعنا (الكائن الوهمي للفايربيس)
class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late LoginUseCase useCase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    // بيشتغل قبل كل اختبار عشان ينظف الذاكرة ويبدأ على نظافة
    mockAuthRepository = MockAuthRepository();
    useCase = LoginUseCase(mockAuthRepository);
  });

  // تجهيز البيانات الثابتة للاختبار
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

  group('LoginUseCase Tests', () {
    
    test('should return UserEntity from the repository when login is successful', () async {
      // Arrange (تجهيز المشهد):
      // بنقول للدوبلير لما يطلب منك دالة login بالمتغيرات دي بالاسم، رجع tUserEntity
      when(() => mockAuthRepository.login(
            email: any(named: 'email'), 
            password: any(named: 'password')
          )).thenAnswer((_) async => tUserEntity);

      // Act (التنفيذ): 
      // تشغيل الدالة بنفس الطريقة اللي مكتوبة في كلاسك الأساسي
      final result = await useCase.call(email: tEmail, password: tPassword); 

      // Assert (التأكد من النتيجة):
      expect(result, tUserEntity);
      
      // التأكد من إن الدالة اتكلمت مع الـ Repository فعلاً مرة واحدة وبنفس الداتا
      verify(() => mockAuthRepository.login(email: tEmail, password: tPassword)).called(1);
      
      // التأكد إنه معملش أي أكشنز تانية غير المطلوبة
      verifyNoMoreInteractions(mockAuthRepository);
    });

  });
}