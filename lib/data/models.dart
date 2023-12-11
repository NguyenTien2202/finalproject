import 'package:json_annotation/json_annotation.dart';

part 'models.g.dart';

/// An annotation for the code generator to know that this class needs the
/// JSON serialization logic to be generated.
@JsonSerializable()
class CarbonData {
  CarbonData(this.electricity, this.transport, this.waste);

  @JsonKey(name: 'Electricity')
  Map<String, double> electricity;

  // Other fields

  @JsonKey(name: 'Transport')
  Map<String, double> transport;

  @JsonKey(name: 'Waste')
  Map<String, double> waste;

  factory CarbonData.fromJson(Map<String, dynamic> json) =>
      _$CarbonDataFromJson(json);

  Map<String, dynamic> toJson() => _$CarbonDataToJson(this);
}

@JsonSerializable()
class TotalData {
  TotalData(this.element);

  @JsonKey(name: 'Element')
  Map<String, double> element;

  factory TotalData.fromJson(Map<String, dynamic> json) =>
      _$TotalDataFromJson(json);

  Map<String, dynamic> toJson() => _$TotalDataToJson(this);
}
