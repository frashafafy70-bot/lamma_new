import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:auto_route/auto_route.dart';

import 'package:lamma_new/core/theme/app_colors.dart';
import 'package:lamma_new/features/auth/presentation/pages/login_page.dart';
import 'package:lamma_new/features/home/home_page.dart';

@RoutePage(name: 'AuthWrapperRoute') 
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;
        
        if (user != null) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              
              if (docSnapshot.hasData && docSnapshot.data!.exists) {
                 return const HomePage();
              }
              
              return Scaffold(
                backgroundColor: AppColors.primaryDark,
                body: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              );
            },
          );
        }
        
        return const LoginPage(); 
      },
    );
  }
}