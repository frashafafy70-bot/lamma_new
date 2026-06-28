import 'dart:async';
import 'dart:io'; // 🟢 تمت الإضافة للتعامل مع ملف الصوت
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart'; // 🟢 تمت الإضافة لرفع الصوت
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/trip_model.dart';
import 'trips_services_state.dart'; 

class TripsServicesCubit extends Cubit<TripsServicesState> {
  TripsServicesCubit() : super(TripsServicesInitial());

  StreamSubscription? _tripsSubscription;

  void fetchTrips(String currentUserId, {bool isPassenger = true}) {
    emit(TripsServicesLoading());

    try {
      final collection = FirebaseFirestore.instance.collection('trips');
      
      Query query = isPassenger 
          ? collection.where('passengerId', isEqualTo: currentUserId)
          : collection.where('driverId', isEqualTo: currentUserId);

      // ترتيب حسب الأحدث لضمان ظهور التحديثات فوراً
      query = query.orderBy('createdAt', descending: true);

      _tripsSubscription = query.snapshots().listen(
        (snapshot) {
          List<TripModel> trips = snapshot.docs.map((doc) {
            return TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
          }).toList();

          emit(TripsServicesSuccess(trips: trips));
        }, 
        onError: (error) {
          emit(TripsServicesError(error.toString()));
        }
      );

    } catch (e) {
      emit(TripsServicesError(e.toString()));
    }
  }

  Future<void> requestNewTrip({
    required String passengerId,
    required String passengerName,
    required String pickup,
    required String destination,
    required String suggestedPrice,
    required String vehicleType,
    GeoPoint? pickupLocation,
    GeoPoint? destinationLocation,
    File? orderAudioFile, // 🟢 تم إضافة استقبال ملف الصوت هنا
  }) async {
    
    // اختياري: ممكن تعمل emit(TripsServicesLoading()) هنا لو حابب تظهر مؤشر تحميل وقت الرفع
    
    try {
      String? audioUrl;

      // 🟢 لو العميل سجل صوت، نرفعه الأول على Firebase Storage
      if (orderAudioFile != null) {
        // بنعمل اسم مميز للملف عشان مفيش ملفين يمسحوا بعض
        final String fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        final Reference storageRef = FirebaseStorage.instance.ref().child('trip_audios').child(fileName);

        // رفع الملف
        final UploadTask uploadTask = storageRef.putFile(orderAudioFile);
        final TaskSnapshot snapshot = await uploadTask;

        // الحصول على رابط الملف بعد الرفع
        audioUrl = await snapshot.ref.getDownloadURL();
      }

      final newTrip = TripModel(
        isDriverPost: false, 
        passengerId: passengerId,
        passengerName: passengerName,
        pickup: pickup,
        destination: destination,
        pickupLocation: pickupLocation,
        destinationLocation: destinationLocation,
        suggestedPrice: suggestedPrice,
        vehicleType: vehicleType,
        status: 'pending', 
        createdAt: DateTime.now(),
        // المفروض نضيف هنا audioUrl: audioUrl بس محتاجين نعدل الموديل الأول
      );

      // 🟢 بنحول الموديل لـ Map، وبنضيف رابط الصوت لو موجود (لحد ما نعدل الموديل)
      Map<String, dynamic> tripData = newTrip.toMap();
      if (audioUrl != null) {
        tripData['audioUrl'] = audioUrl;
      }

      await FirebaseFirestore.instance.collection('trips').add(tripData);
      
      // اختياري: لو عندك State للنجاح وقت الإرسال تقدر تعملها emit هنا
      
    } catch (e) {
      emit(TripsServicesError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _tripsSubscription?.cancel();
    return super.close();
  }
}