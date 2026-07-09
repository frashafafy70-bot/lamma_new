import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 🟢 استدعاء ملف الستيت المنفصل
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<RemoteMessage>? _notificationSubscription;
  StreamSubscription<QuerySnapshot>? _unreadNotificationsSub;
  StreamSubscription<User?>? _authSubscription; 

  NotificationCubit() : super(NotificationState()) {
    _listenToForegroundNotifications();
    _initAuthAndUnreadListener();
  }

  void _initAuthAndUnreadListener() {
    _authSubscription?.cancel();
    _authSubscription = _auth.authStateChanges().listen((User? user) {
      if (user != null) {
        _listenToUnreadNotifications(user.uid);
      } else {
        _unreadNotificationsSub?.cancel();
        emit(NotificationState()); 
      }
    });
  }

  void _listenToForegroundNotifications() {
    _notificationSubscription?.cancel();
    _notificationSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      emit(state.copyWith(hasNewNotification: true));
    });
  }

  void _listenToUnreadNotifications(String uid) {
    _unreadNotificationsSub?.cancel();
    _unreadNotificationsSub = _firestore
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      emit(state.copyWith(
        unreadNotificationsCount: snapshot.docs.length,
        status: NotificationStatus.loaded,
      ));
    }, onError: (error) {
      emit(state.copyWith(status: NotificationStatus.error, errorMessage: error.toString()));
    });
  }

  Future<void> markAllNotificationsAsRead() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      var unreadDocs = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadDocs.docs.isEmpty) {
        emit(state.copyWith(hasNewNotification: false, unreadNotificationsCount: 0));
        return;
      }

      WriteBatch batch = _firestore.batch();
      for (var doc in unreadDocs.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      emit(state.copyWith(hasNewNotification: false, unreadNotificationsCount: 0));
    } catch (e) {
      emit(state.copyWith(status: NotificationStatus.error, errorMessage: 'حدث خطأ أثناء تحديث الإشعارات'));
    }
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _unreadNotificationsSub?.cancel();
    _authSubscription?.cancel(); 
    return super.close();
  }
}