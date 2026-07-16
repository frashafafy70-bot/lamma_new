import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';

class SendNotificationUseCase {
  final FirebaseFirestore firestore;

  SendNotificationUseCase(this.firestore);

  Future<Either<dynamic, void>> call({
    required String tripId,
    required String title,
    required String body,
  }) async {
    try {
      var tripDoc = await firestore.collection('trips').doc(tripId).get();
      if (!tripDoc.exists) return const Right(null);
      
      String driverId = tripDoc.data()?['driverId'] ?? '';
      if (driverId.isEmpty) return const Right(null);

      var userDoc = await firestore.collection('users').doc(driverId).get();
      String? fcmToken = userDoc.data()?['fcmToken'];

      if (fcmToken != null) {
        String serverKey = dotenv.env['FCM_SERVER_KEY'] ?? ''; 
        await http.post(
          Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'key=$serverKey',
          },
          body: jsonEncode({
            'to': fcmToken,
            'notification': {'title': title, 'body': body, 'sound': 'default'},
            'data': {'tripId': tripId, 'type': 'passenger_action', 'channel_id': 'lamma_final_sound'}
          }),
        );
      }
      return const Right(null);
    } catch (e) {
      return Left(e);
    }
  }
}