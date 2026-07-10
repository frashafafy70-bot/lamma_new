import 'dart:async';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_state.dart';
import '../domain/use_cases/get_service_categories_use_case.dart';
import '../domain/use_cases/get_active_orders_summary_use_case.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetServiceCategoriesUseCase _getServiceCategoriesUseCase;
  final GetActiveOrdersSummaryUseCase _getActiveOrdersSummaryUseCase;

  // 🟢 اشتراكات الستريمز لمراقبة البادجات لايف
  StreamSubscription<QuerySnapshot>? _radarSubscription;
  StreamSubscription<QuerySnapshot>? _activeTripsSubscription;
  StreamSubscription<QuerySnapshot>? _clientRequestsSubscription;

  HomeCubit({
    required GetServiceCategoriesUseCase getServiceCategoriesUseCase,
    required GetActiveOrdersSummaryUseCase getActiveOrdersSummaryUseCase,
  })  : _getServiceCategoriesUseCase = getServiceCategoriesUseCase,
        _getActiveOrdersSummaryUseCase = getActiveOrdersSummaryUseCase,
        super(HomeState());

  void changeTab(int index) {
    emit(state.copyWith(bottomNavIndex: index));
  }

  // 🟢 دالة احترافية لمراقبة وحساب البادجات بالخلفية بدلاً من الـ UI
  void startListeningToBadges(String currentUserId) {
    if (currentUserId.isEmpty) return;

    // 1. مراقبة بادج الرادار
    _radarSubscription?.cancel();
    _radarSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('isDriverPost', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      final count = snapshot.docs.where((doc) {
        var d = doc.data();
        if (d['isDeletedForDriver'] == true) return false;
        
        String status = d['status'] ?? '';
        String driverId = d['driverId'] ?? '';
        String ownerId = d['userId'] ?? d['passengerId'] ?? '';
        
        bool isPending = status == 'pending';
        bool isNegotiatingWithAnother = status == 'negotiating' && driverId != currentUserId;
        
        return (isPending || isNegotiatingWithAnother) && ownerId != currentUserId;
      }).length;
      
      emit(state.copyWith(radarBadgeCount: count));
    });

    // 2. مراقبة بادج الرحلات النشطة للسائق
    _activeTripsSubscription?.cancel();
    _activeTripsSubscription = FirebaseFirestore.instance
        .collection('trip_bookings')
        .where('driverId', isEqualTo: currentUserId)
        .snapshots()
        .listen((snapshot) {
      final count = snapshot.docs.where((doc) {
        var d = doc.data();
        return d['status'] == 'pending';
      }).length;
      
      emit(state.copyWith(activeTripsBadgeCount: count));
    });

    // 3. مراقبة بادج الطلبات والرحلات المتاحة للعميل
    _clientRequestsSubscription?.cancel();
    _clientRequestsSubscription = FirebaseFirestore.instance
        .collection('trips')
        .where('isDriverPost', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      final count = snapshot.docs.where((doc) {
        var d = doc.data();
        return d['status'] == 'available' && (d['driverId'] ?? '') != currentUserId;
      }).length;
      
      emit(state.copyWith(clientRequestsBadgeCount: count));
    });
  }

  Future<void> fetchHomeDashboardData() async {
    try {
      debugPrint("🔥 HomeCubit: البدء في جلب البيانات...");
      emit(state.copyWith(status: HomeStatus.loading));

      final categoriesFuture = _getServiceCategoriesUseCase();
      final ordersFuture = _getActiveOrdersSummaryUseCase();

      final categoriesResult = await categoriesFuture;
      final ordersResult = await ordersFuture;

      if (isClosed) return; 

      categoriesResult.fold(
        (failure) {
          debugPrint("❌ HomeCubit Error (Categories): ${failure.message}");
          emit(state.copyWith(status: HomeStatus.error, errorMessage: failure.message));
        },
        (categories) {
          debugPrint("✅ HomeCubit: تم جلب ${categories.length} أقسام بنجاح.");
          
          ordersResult.fold(
            (failure) {
               debugPrint("⚠️ HomeCubit Warning (Orders): ${failure.message}");
               // 🟢 التعديل الجوهري: لو الطلبات فشلت لأي سبب، نعرض الأقسام عادي وموقفش التطبيق على الشيمر!
               emit(state.copyWith(
                  status: HomeStatus.loaded,
                  categories: categories,
                  errorMessage: failure.message,
               ));
            },
            (orders) {
               debugPrint("✅ HomeCubit: تم جلب ${orders.length} طلبات نشطة بنجاح.");
               emit(state.copyWith(
                  status: HomeStatus.loaded,
                  categories: categories,
                  activeOrders: orders,
               ));
            }
          );
        },
      );
    } catch (e) {
      debugPrint("💥 HomeCubit Fatal Error: $e");
      if (!isClosed) {
        emit(state.copyWith(status: HomeStatus.error, errorMessage: e.toString()));
      }
    }
  }

  // 🟢 إلغاء كل الاشتراكات عند قفل الـ Cubit لحماية الذاكرة
  @override
  Future<void> close() {
    _radarSubscription?.cancel();
    _activeTripsSubscription?.cancel();
    _clientRequestsSubscription?.cancel();
    return super.close();
  }
}