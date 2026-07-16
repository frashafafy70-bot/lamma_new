import 'package:auto_route/auto_route.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// استيراد الراوتر للوصول إلى LoginRoute
import 'app_router.dart'; 

class AuthGuard extends AutoRouteGuard {
  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (docSnapshot.exists) {
          resolver.next(true);
        } else {
          await FirebaseAuth.instance.signOut();
          resolver.redirect(const LoginRoute());
        }
      } catch (e) {
        resolver.redirect(const LoginRoute());
      }
    } else {
      resolver.redirect(const LoginRoute());
    }
  }
}