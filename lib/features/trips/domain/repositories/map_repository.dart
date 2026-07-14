import 'package:dartz/dartz.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/errors/failures.dart';
import '../entities/place_search_entity.dart';

abstract class MapRepository {
  /// المتغيرات العامة التي تحتاجها الواجهة
  String get googleApiKey;
  BitmapDescriptor? get carMarker;
  BitmapDescriptor? get bikeMarker;
  BitmapDescriptor? get tuktokMarker;

  /// تهيئة المفتاح وتحميل أيقونات السيارات
  Future<void> initMapResources({required String apiKey});

  /// تحويل الإحداثيات إلى عنوان مقروء ونظيف
  Future<Either<Failure, String>> getAddressFromCoordinates(LatLng latLng);

  /// البحث عن الأماكن (Autocomplete)
  Future<Either<Failure, List<PlaceSearchEntity>>> searchPlaces(String input);

  /// جلب الإحداثيات الدقيقة لمكان معين بناءً على الـ placeId
  Future<Either<Failure, LatLng>> getPlaceCoordinates(String placeId);

  /// جلب الموقع الحالي للمستخدم (مع معالجة الصلاحيات)
  Future<Either<Failure, Position>> getUserCurrentLocation();

  /// جلب إحداثيات المسار (Polyline) بين نقطتين
  Future<Either<Failure, List<LatLng>>> getRouteCoordinates(LatLng origin, LatLng destination);
}