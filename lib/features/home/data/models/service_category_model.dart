import '../../domain/entities/service_category_entity.dart';

class ServiceCategoryModel extends ServiceCategoryEntity {
  ServiceCategoryModel({
    required String id,
    required String title,
    required String iconUrl,
    required String routeName,
  }) : super(
          id: id,
          title: title,
          iconUrl: iconUrl,
          routeName: routeName,
        );

  factory ServiceCategoryModel.fromJson(Map<String, dynamic> json, String id) {
    return ServiceCategoryModel(
      id: id,
      title: json['title'] ?? 'بدون اسم',
      iconUrl: json['iconUrl'] ?? '',
      routeName: json['routeName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'iconUrl': iconUrl,
      'routeName': routeName,
    };
  }
}