// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarbonData _$CarbonDataFromJson(Map<String, dynamic> json) => CarbonData(
      (json['Electricity'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      (json['Transport'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      (json['Waste'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
    );

Map<String, dynamic> _$CarbonDataToJson(CarbonData instance) =>
    <String, dynamic>{
      'Electricity': instance.electricity,
      'Transport': instance.transport,
      'Waste': instance.waste,
    };

TotalData _$TotalDataFromJson(Map<String, dynamic> json) => TotalData(
      (json['Element'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, (e as num).toDouble()),
      ),
      (json['Total'] as num).toDouble(),
    );

Map<String, dynamic> _$TotalDataToJson(TotalData instance) => <String, dynamic>{
      'Element': instance.element,
      'Total': instance.total,
    };
