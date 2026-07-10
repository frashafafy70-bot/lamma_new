// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceCategoryModelAdapter extends TypeAdapter<ServiceCategoryModel> {
  @override
  final int typeId = 0;

  @override
  ServiceCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceCategoryModel(
      id: fields[0] as String,
      title: fields[1] as String,
      iconUrl: fields[2] as String,
      routeName: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceCategoryModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.iconUrl)
      ..writeByte(3)
      ..write(obj.routeName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceCategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
