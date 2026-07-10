import 'package:hive/hive.dart';
import '../../domain/entities/service_category_entity.dart';

part 'service_category_model.g.dart'; // ده الملف اللي هيتولد تلقائياً

@HiveType(typeId: 0) // استخدم ID فريد لكل موديل (0، 1، 2...)
class ServiceCategoryModel extends ServiceCategoryEntity {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String iconUrl;
  @HiveField(3)
  final String routeName;

  ServiceCategoryModel({
    required this.id,
    required this.title,
    required this.iconUrl,
    required this.routeName,
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