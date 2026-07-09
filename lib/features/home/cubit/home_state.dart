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

  HomeState({
    this.bottomNavIndex = 0,
    this.status = HomeStatus.initial,
    this.actionStatus = HomeActionStatus.initial,
    this.categories = const [],
    this.activeOrders = const [],
    this.errorMessage,
    this.successMessage,
    this.pendingRegistrationRole,
  });

  // Getter ممتاز لاختصار الكود في الـ UI
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
  }) {
    return HomeState(
      bottomNavIndex: bottomNavIndex ?? this.bottomNavIndex,
      status: status ?? this.status,
      actionStatus: actionStatus ?? this.actionStatus,
      categories: categories ?? this.categories,
      activeOrders: activeOrders ?? this.activeOrders,
      // ترك هذه القيم بدون (??) ممتاز جداً لتفريغ الرسائل وعدم تكرار الـ SnackBar
      errorMessage: errorMessage,
      successMessage: successMessage,
      pendingRegistrationRole: pendingRegistrationRole,
    );
  }
}