part of 'trip_repository_impl.dart';

mixin TripQueriesRepository on TripRepositoryBase {

  Stream<List<TripEntity>> getTrips() {
    return firestore.collection(collectionName).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<TripEntity>> getUserTrips(String userId) {
    return firestore.collection(collectionName).where(
      Filter.or(Filter('driverId', isEqualTo: userId), Filter('passengerId', isEqualTo: userId))
    ).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<TripEntity>> getTripsStream(String userId, {bool isPassenger = true}) {
    try {
      Query query = firestore.collection(collectionName);
      if (isPassenger) {
        query = query.where('passengerId', isEqualTo: userId);
      } else {
        query = query.where('driverId', isEqualTo: userId);
      }
      query = query.orderBy('createdAt', descending: true);

      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      });
    } catch (e) {
      throw Exception('حدث خطأ أثناء جلب الرحلات: $e');
    }
  }

  Stream<int> getDriverActiveOrdersCountStream(String uid) {
    var bookingsStream = firestore.collection('trip_bookings')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating']).snapshots();

    var tripsStream = firestore.collection(collectionName)
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started', 'in_progress']).snapshots();

    return Rx.combineLatest2(
      bookingsStream,
      tripsStream,
      (QuerySnapshot bookings, QuerySnapshot trips) => bookings.docs.length + trips.docs.length,
    );
  }

  Stream<int> getPassengerActiveOrdersCountStream(String uid) {
    var tripsStream = firestore.collection(collectionName)
        .where('passengerId', isEqualTo: uid)
        .where('isDriverPost', isEqualTo: false).snapshots();

    var bookingsStream = firestore.collection('trip_bookings')
        .where('passengerId', isEqualTo: uid)
        .where('status', whereIn: ['pending', 'accepted', 'negotiating']).snapshots();

    return Rx.combineLatest2(
      tripsStream,
      bookingsStream,
      (QuerySnapshot trips, QuerySnapshot bookings) {
        int validTrips = 0;
        for (var doc in trips.docs) {
          final data = (doc.data() as Map<String, dynamic>?) ?? {}; 
          bool isDeleted = data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
          String status = data['status'] ?? '';
          bool isFinished = status == 'canceled' || status == 'completed';
          if (!isDeleted && !isFinished) validTrips++;
        }
        return validTrips + bookings.docs.length;
      }
    );
  }

  Future<Either<Failure, List<TripEntity>>> getDriverActiveTrips({
    required String uid,
    required int limit,
    TripEntity? lastTrip,
  }) async {
    try {
      Query query = firestore.collection(collectionName)
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['available', 'accepted', 'negotiating', 'arrived', 'started', 'in_progress']);

      final snapshot = await query.get();
      List<TripEntity> trips = snapshot.docs.map((doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      trips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  Future<Either<Failure, List<TripEntity>>> getPassengerActiveTrips({
    required String uid,
    required int limit,
    TripEntity? lastTrip,
  }) async {
    try {
      Query query = firestore.collection(collectionName)
          .where('passengerId', isEqualTo: uid)
          .where('isDriverPost', isEqualTo: false);

      final snapshot = await query.get();
      List<TripEntity> trips = [];
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        bool isDeleted = data['isDeletedForPassenger'] == true || data['isDeleted'] == true;
        String status = data['status'] ?? '';
        bool isFinished = status == 'cancelled' || status == 'canceled' || status == 'completed';
        
        if (!isDeleted && !isFinished) {
          trips.add(TripModel.fromMap(data, doc.id));
        }
      }

      trips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(trips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e'));
    }
  }

  Future<Either<Failure, List<TripEntity>>> getDriverHistoryTrips({
    required String uid,
    required int limit,
    TripEntity? lastTrip,
  }) async {
    try {
      Query query = firestore.collection(collectionName)
          .where('driverId', isEqualTo: uid)
          .where('status', whereIn: ['completed', 'canceled', 'cancelled']);

      final snapshot = await query.get();
      List<TripEntity> historyTrips = [];
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['isDeletedForDriver'] == true) continue;
        historyTrips.add(TripModel.fromMap(data, doc.id));
      }

      historyTrips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(historyTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e')); 
    }
  }

  Future<Either<Failure, List<TripEntity>>> getAvailableTravels({
    required int limit,
    TripEntity? lastTrip,
  }) async {
    try {
      Query query = firestore.collection(collectionName)
          .where('isDriverPost', isEqualTo: true)
          .where('status', isEqualTo: 'available');

      final snapshot = await query.get();
      List<TripEntity> availableTrips = snapshot.docs.map((doc) => TripModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      availableTrips.sort((a, b) {
        final bTime = (b.createdAt as DateTime?) ?? DateTime.now();
        final aTime = (a.createdAt as DateTime?) ?? DateTime.now();
        return bTime.compareTo(aTime);
      });
      return Right(availableTrips);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ: $e')); 
    }
  }

  Future<Either<Failure, bool>> checkHasActiveTrip(String driverId) async {
    try {
      final snapshot = await firestore.collection(collectionName).where('driverId', isEqualTo: driverId).get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        bool isNotDeleted = data['isDeletedForDriver'] != true;
        bool isActiveStatus = data['status'] == 'available' || data['status'] == 'negotiating' || data['status'] == 'accepted' || data['status'] == 'arrived' || data['status'] == 'in_progress';
        if (isNotDeleted && isActiveStatus) return const Right(true);
      }
      return const Right(false);
    } catch (e) {
      return Left(ServerFailure(message: 'خطأ أثناء التحقق: $e'));
    }
  }
}