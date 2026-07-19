import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../domain/use_cases/get_service_categories_use_case.dart';
import '../domain/use_cases/get_active_orders_summary_use_case.dart';
import '../domain/use_cases/home_badges_use_cases.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetServiceCategoriesUseCase _getServiceCategoriesUseCase;
  final GetActiveOrdersSummaryUseCase _getActiveOrdersSummaryUseCase;

  // 🟢 استدعاءات الـ UseCases الجديدة
  final GetRadarBadgeUseCase _getRadarBadgeUseCase;
  final GetActiveTripsBadgeUseCase _getActiveTripsBadgeUseCase;
  final GetClientRequestsBadgeUseCase _getClientRequestsBadgeUseCase;

  // 🟢 نوع الـ Subscription اتغير لـ int بدلاً من QuerySnapshot (نظافة تامة)
  StreamSubscription<int>? _radarSubscription;
  StreamSubscription<int>? _activeTripsSubscription;
  StreamSubscription<int>? _clientRequestsSubscription;

  HomeCubit({
    required GetServiceCategoriesUseCase getServiceCategoriesUseCase,
    required GetActiveOrdersSummaryUseCase getActiveOrdersSummaryUseCase,
    required GetRadarBadgeUseCase getRadarBadgeUseCase,
    required GetActiveTripsBadgeUseCase getActiveTripsBadgeUseCase,
    required GetClientRequestsBadgeUseCase getClientRequestsBadgeUseCase,
  })  : _getServiceCategoriesUseCase = getServiceCategoriesUseCase,
        _getActiveOrdersSummaryUseCase = getActiveOrdersSummaryUseCase,
        _getRadarBadgeUseCase = getRadarBadgeUseCase,
        _getActiveTripsBadgeUseCase = getActiveTripsBadgeUseCase,
        _getClientRequestsBadgeUseCase = getClientRequestsBadgeUseCase,
        super(HomeState());

  void changeTab(int index) {
    emit(state.copyWith(bottomNavIndex: index));
  }

  Future<void> fetchHomeDashboardData() async {
    debugPrint("🔥 HomeCubit: البدء في جلب البيانات...");
    emit(state.copyWith(status: HomeStatus.loading));

    final categoriesResult = await _getServiceCategoriesUseCase();
    final ordersResult = await _getActiveOrdersSummaryUseCase();

    if (isClosed) return;

    categoriesResult.fold(
      (failure) {
        debugPrint("❌ HomeCubit Error (Categories): ${failure.message}");
        emit(state.copyWith(
            status: HomeStatus.error, errorMessage: failure.message));
      },
      (categories) {
        debugPrint("✅ HomeCubit: تم جلب ${categories.length} أقسام بنجاح.");

        ordersResult.fold((failure) {
          debugPrint("⚠️ HomeCubit Warning (Orders): ${failure.message}");
          emit(state.copyWith(
            status: HomeStatus.loaded,
            categories: categories,
            errorMessage: failure.message,
          ));
        }, (orders) {
          debugPrint("✅ HomeCubit: تم جلب ${orders.length} طلبات نشطة بنجاح.");
          emit(state.copyWith(
            status: HomeStatus.loaded,
            categories: categories,
            activeOrders: orders,
          ));
        });
      },
    );
  }

  void startListeningToBadges(String currentUserId) {
    if (currentUserId.isEmpty) return;

    // 1. الاستماع لبادج الرادار
    _radarSubscription?.cancel();
    _radarSubscription = _getRadarBadgeUseCase(currentUserId).listen((count) {
      if (!isClosed) emit(state.copyWith(radarBadgeCount: count));
    });

    // 2. الاستماع لبادج الرحلات النشطة
    _activeTripsSubscription?.cancel();
    _activeTripsSubscription =
        _getActiveTripsBadgeUseCase(currentUserId).listen((count) {
      if (!isClosed) emit(state.copyWith(activeTripsBadgeCount: count));
    });

    // 3. الاستماع لبادج طلبات العملاء
    _clientRequestsSubscription?.cancel();
    _clientRequestsSubscription =
        _getClientRequestsBadgeUseCase(currentUserId).listen((count) {
      if (!isClosed) emit(state.copyWith(clientRequestsBadgeCount: count));
    });
  }

  @override
  Future<void> close() {
    _radarSubscription?.cancel();
    _activeTripsSubscription?.cancel();
    _clientRequestsSubscription?.cancel();
    return super.close();
  }
}
