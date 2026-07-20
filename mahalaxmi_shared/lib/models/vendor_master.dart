import 'package:freezed_annotation/freezed_annotation.dart';

part 'vendor_master.freezed.dart';
part 'vendor_master.g.dart';

int? _parseId(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return (value as num).toInt();
}

@freezed
class VendorMaster with _$VendorMaster {
  const factory VendorMaster({
    @JsonKey(name: 'id', fromJson: _parseId) int? id,
    required String name,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
  }) = _VendorMaster;

  factory VendorMaster.fromJson(Map<String, Object?> json) =>
      _$VendorMasterFromJson(json);
}
