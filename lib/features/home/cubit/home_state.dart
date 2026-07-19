import '../domain/entities/service_category_entity.dart';
import '../domain/entities/order_summary_entity.dart';

enum HomeStatus { initial, loading, loaded, error }

enum HomeActionStatus { initial, success, error, registrationRequired }

class HomeState {
  final int bottomNavIndex;
  final HomeStatus status;
  final HomeActionStatus actionStatus;
  final List<ServiceCategoryEntity> categories;
  final List<OrderSummaryEntity> activeOrders;
  final String? errorMessage;
  final String? successMessage;
  final String? pendingRegistrationRole;

  // 🟢 المتغيرات الجديدة لحفظ أعداد البادجات لايف
  final int radarBadgeCount;
  final int activeTripsBadgeCount;
  final int clientRequestsBadgeCount;

  HomeState({
    this.bottomNavIndex = 0,
    this.status = HomeStatus.initial,
    this.actionStatus = HomeActionStatus.initial,
    this.categories = const [],
    this.activeOrders = const [],
    this.errorMessage,
    this.successMessage,
    this.pendingRegistrationRole,
    this.radarBadgeCount = 0,
    this.activeTripsBadgeCount = 0,
    this.clientRequestsBadgeCount = 0,
  });

  int get activeOrdersCount => activeOrders.length;

  HomeState copyWith({
    int? bottomNavIndex,
    HomeStatus? status,
    HomeActionStatus? actionStatus,
    List<ServiceCategoryEntity>? categories,
    List<OrderSummaryEntity>? activeOrders,
    String? errorMessage,
    String? successMessage,
    String? pendingRegistrationRole,
    int? radarBadgeCount,
    int? activeTripsBadgeCount,
    int? clientRequestsBadgeCount,
  }) {
    return HomeState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      categories: categories ?? this.categories,
      activeOrders: activeOrders ?? this.activeOrders,
      errorMessage: errorMessage,
      successMessage: successMessage,
      pendingRegistrationRole: pendingRegistrationRole,
      radarBadgeCount: radarBadgeCount ?? this.radarBadgeCount,
      activeTripsBadgeCount:
          activeTripsBadgeCount ?? this.activeTripsBadgeCount,
      clientRequestsBadgeCount:
          clientRequestsBadgeCount ?? this.clientRequestsBadgeCount,
    );
  }
}
