import 'package:freezed_annotation/freezed_annotation.dart';

part 'customer.freezed.dart';
part 'customer.g.dart';

@freezed
class Customer with _$Customer {
  const factory Customer({
    @JsonKey(name: 'id') int? id,
    required String pin,
    @JsonKey(name: 'shop_name') required String shopName,
    @JsonKey(name: 'owner_name') @Default('') String ownerName,
    @Default('') String mobile,
    @Default('') String city,
    @Default('') String notes,
    @JsonKey(name: 'is_active') @Default(true) bool isActive,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'last_active_at') String? lastActiveAt,
  }) = _Customer;

  factory Customer.fromJson(Map<String, Object?> json) =>
      _$CustomerFromJson(json);
}
