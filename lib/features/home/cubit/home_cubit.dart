import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_state.dart';
import '../domain/use_cases/get_service_categories_use_case.dart';
import '../domain/use_cases/get_active_orders_summary_use_case.dart';

class HomeCubit extends Cubit<HomeState> {
  final GetServiceCategoriesUseCase _getServiceCategoriesUseCase;
  final GetActiveOrdersSummaryUseCase _getActiveOrdersSummaryUseCase;

  HomeCubit({
    required GetServiceCategoriesUseCase getServiceCategoriesUseCase,
    required GetActiveOrdersSummaryUseCase getActiveOrdersSummaryUseCase,
  })  : _getServiceCategoriesUseCase = getServiceCategoriesUseCase,
        _getActiveOrdersSummaryUseCase = getActiveOrdersSummaryUseCase,
        super(HomeState());

  void changeTab(int index) {
    emit(state.copyWith(bottomNavIndex: index));
  }

  Future<void> fetchHomeDashboardData() async {
    emit(state.copyWith(status: HomeStatus.loading));

    // 🟢 الحل البرو: تشغيل الطلبين في نفس الوقت (بالتوازي) لتسريع استجابة التطبيق للضعف!
    final categoriesFuture = _getServiceCategoriesUseCase();
    final ordersFuture = _getActiveOrdersSummaryUseCase();

    // ننتظر النتيجتين معاً
    final categoriesResult = await categoriesFuture;
    final ordersResult = await ordersFuture;

    if (isClosed) return; // حماية من الكراش

    categoriesResult.fold(
      (failure) {
        emit(state.copyWith(status: HomeStatus.error, errorMessage: failure.message));
      },
      (categories) {
        ordersResult.fold(
          (failure) {
             emit(state.copyWith(status: HomeStatus.error, errorMessage: failure.message));
          },
          (orders) {
             emit(state.copyWith(
                status: HomeStatus.loaded,
                categories: categories,
                activeOrders: orders,
             ));
          }
        );
      },
    );
  }
}