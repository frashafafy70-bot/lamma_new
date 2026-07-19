import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

// مسار الـ Service بتاعتك
import 'package:lamma_new/features/auth/data/services/auth_service.dart';

// -----------------------------------------------------------------------------
// 1. الدوبليرز (Mocks) الخاصة بكل خدمات Firebase
// -----------------------------------------------------------------------------
class MockFirebaseAuth extends Mock implements firebase_auth.FirebaseAuth {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

class MockUser extends Mock implements firebase_auth.User {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late AuthService authService;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;
  late MockFirebaseMessaging mockMessaging;

  setUp(() {
    // 💡 بنوهم التطبيق إن الـ SharedPreferences شغالة عشان ميضربش إيرور بلجن
    SharedPreferences.setMockInitialValues({});

    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    mockMessaging = MockFirebaseMessaging();

    // بنحقن الدوبليرز جوه الـ AuthService
    authService = AuthService(
      firebaseAuth: mockAuth,
      firestore: mockFirestore,
      messaging: mockMessaging,
    );
  });

  const tEmail = 'test@test.com';
  const tPassword = 'password123';
  const tUid = '12345ABC';
  const tToken = 'fake_fcm_token';

  group('AuthService - loginUser Tests', () {
    test(
        'يجب أن يسجل الدخول بنجاح، يحدّث الـ FCM Token، ويحفظ الـ Role في الكاش',
        () async {
      // Arrange (التجهيز)
      final mockUserCred = MockUserCredential();
      final mockUser = MockUser();
      final mockCollection = MockCollectionReference();
      final mockDocRef = MockDocumentReference();
      final mockDocSnap = MockDocumentSnapshot();

      // 1. تجهيز رد FirebaseAuth
      when(() => mockUser.uid).thenReturn(tUid);
      when(() => mockUserCred.user).thenReturn(mockUser);
      when(() => mockAuth.signInWithEmailAndPassword(
          email: tEmail,
          password: tPassword)).thenAnswer((_) async => mockUserCred);

      // 2. تجهيز رد FirebaseMessaging (التوكن)
      when(() => mockMessaging.getToken()).thenAnswer((_) async => tToken);

      // 3. تجهيز رد Firestore (عشان يقدر يعمل Update ويجيب الـ Role)
      when(() => mockFirestore.collection('users')).thenReturn(mockCollection);
      when(() => mockCollection.doc(tUid)).thenReturn(mockDocRef);
      // بنفهمه إنه لما يحاول يعمل تحديث للتوكن ينجح عادي
      when(() => mockDocRef.update({'fcmToken': tToken}))
          .thenAnswer((_) async => Future.value());

      // بنفهمه إنه لما يحاول يقرا بيانات اليوزر، يرجع Role وهمي (driver مثلاً)
      when(() => mockDocRef.get()).thenAnswer((_) async => mockDocSnap);
      when(() => mockDocSnap.exists).thenReturn(true);
      when(() => mockDocSnap.data()).thenReturn({'activeRole': 'driver'});

      // Act (التنفيذ)
      final result =
          await authService.loginUser(email: tEmail, password: tPassword);

      // Assert (التحقق)
      // بنتأكد إن دالة تسجيل الدخول اتنادت
      verify(() => mockAuth.signInWithEmailAndPassword(
          email: tEmail, password: tPassword)).called(1);
      // بنتأكد إننا طلبنا التوكن الجديد
      verify(() => mockMessaging.getToken()).called(1);
      // بنتأكد إننا حدثنا التوكن في الداتابيز
      verify(() => mockDocRef.update({'fcmToken': tToken})).called(1);
      // بنتأكد إننا جبنا الداتا عشان نحفظ الـ Role
      verify(() => mockDocRef.get()).called(1);

      expect(result, equals(mockUserCred));
      expect(result.user!.uid, equals(tUid));

      // 💡 الضربة القاضية: بنتأكد إن الـ SharedPreferences حفظت الـ Role الصح
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('cached_active_role'), equals('driver'));
    });

    test(
        'يجب أن يرمي FirebaseAuthException عند فشل تسجيل الدخول (مثلاً كلمة مرور خاطئة)',
        () async {
      // Arrange (التجهيز)
      // بنخلي الفايربيز يضرب إيرور صريح
      when(() => mockAuth.signInWithEmailAndPassword(
              email: tEmail, password: tPassword))
          .thenThrow(
              firebase_auth.FirebaseAuthException(code: 'wrong-password'));

      // Act (التنفيذ)
      final call = authService.loginUser;

      // Assert (التحقق)
      // بنتأكد إن الـ Service رمت نفس الإيرور للي بيناديها
      expect(() => call(email: tEmail, password: tPassword),
          throwsA(isA<firebase_auth.FirebaseAuthException>()));

      verify(() => mockAuth.signInWithEmailAndPassword(
          email: tEmail, password: tPassword)).called(1);

      // 💡 بنتأكد إن باقي الدوال (Messaging و Firestore) متنداهتش أصلاً لأن العملية وقفت بسبب الإيرور
      verifyNever(() => mockMessaging.getToken());
      verifyNever(() => mockFirestore.collection('users'));
    });
  });
}
