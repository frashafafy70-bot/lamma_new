import 'package:flutter_test/flutter_test.dart';
import 'package:lamma_new/features/auth/data/models/user_model.dart';
import 'package:lamma_new/features/auth/domain/entities/user_entity.dart';

void main() {
  final tUserModel = UserModel(
    uid: '12345ABC',
    name: 'Ahmed',
    email: 'ahmed@test.com',
    phone: '01012345678',
    roles: const ['passenger', 'driver'],
    activeRole: 'passenger',
  );

  group('UserModel Tests', () {
    
    test('should be a subclass of UserEntity', () {
      expect(tUserModel, isA<UserEntity>());
    });

    // الاختبار اللي أنا أكلته بتاع الـ Getter
    test('getter [role] should return the activeRole', () {
      expect(tUserModel.role, 'passenger');
    });

    test('should return a valid model when JSON has all fields', () {
      final Map<String, dynamic> jsonMap = {
        'uid': '12345ABC',
        'name': 'Ahmed',
        'email': 'ahmed@test.com',
        'phone': '01012345678',
        'roles': ['passenger', 'driver'],
        'activeRole': 'passenger',
      };

      final result = UserModel.fromJson(jsonMap);

      expect(result.uid, tUserModel.uid);
      expect(result.name, tUserModel.name);
      expect(result.email, tUserModel.email);
      expect(result.phone, tUserModel.phone);
      expect(result.roles, tUserModel.roles);
      expect(result.activeRole, tUserModel.activeRole);
    });

    test('should return a model with default values when JSON fields are empty', () {
      final Map<String, dynamic> emptyJsonMap = {};

      final result = UserModel.fromJson(emptyJsonMap);

      expect(result.uid, '');
      expect(result.name, '');
      expect(result.email, '');
      expect(result.phone, '');
      expect(result.roles, ['passenger']); 
      expect(result.activeRole, 'passenger'); 
    });

    test('should return a JSON map containing proper data', () {
      final result = tUserModel.toJson();

      final expectedMap = {
        'uid': '12345ABC',
        'name': 'Ahmed',
        'email': 'ahmed@test.com',
        'phone': '01012345678',
        'roles': ['passenger', 'driver'],
        'activeRole': 'passenger',
      };

      expect(result, expectedMap);
    });
    
  });
}