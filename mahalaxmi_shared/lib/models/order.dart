import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class Order with _$Order {
  const factory Order({
    @JsonKey(name: 'order_id') int? orderId,
    @JsonKey(name: 'customer_name') required String customerName,
    @JsonKey(name: 'order_date') required String orderDate,
    @Default('') String color,
    @JsonKey(name: 'grind_type') String? grindType,
    @JsonKey(name: 'box_type') String? boxType,
    @JsonKey(name: 'additional_info') @Default('') String additionalInfo,
    @JsonKey(name: 'total_amount') @Default(0.0) double totalAmount,
    @Default('admin') String source,
    @JsonKey(name: 'customer_mobile') String? customerMobile,
    @JsonKey(name: 'customer_id') int? customerId,
    @Default('pending') String status,
    @JsonKey(name: 'status_updated_at') String? statusUpdatedAt,
    @JsonKey(name: 'order_items') @Default(<OrderItem>[]) List<OrderItem> orderItems,
    @JsonKey(name: 'deleted_at') DateTime? deletedAt,
    @JsonKey(name: 'deleted_by') String? deletedBy,
    @JsonKey(name: 'delete_reason') String? deleteReason,
  }) = _Order;

  factory Order.fromJson(Map<String, Object?> json) =>
      _$OrderFromJson(json);
}

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    @JsonKey(name: 'order_id') int? orderId,
    @JsonKey(name: 'item_number') required String itemNumber,
    @Default('Chuda') String category,
    @JsonKey(name: 'qty_2_2') @Default(0) int qty22,
    @JsonKey(name: 'qty_2_4') @Default(0) int qty24,
    @JsonKey(name: 'qty_2_6') @Default(0) int qty26,
    @JsonKey(name: 'qty_2_8') @Default(0) int qty28,
    @JsonKey(name: 'qty_2_10') @Default(0) int qty210,
    @JsonKey(name: 'qty_2_12') @Default(0) int qty212,
    @Default(0.0) double quantity,
    String? unit,
    String? color,
    @JsonKey(name: 'grind_type') String? grindType,
    @JsonKey(name: 'box_type') String? boxType,
    String? notes,
    @JsonKey(name: 'unit_price') @Default(0.0) double unitPrice,
    @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson) @Default(<String, String>{})
    Map<String, String> productionStatus,
    @JsonKey(name: 'customization', fromJson: _customizationFromJson) Map<String, dynamic>? customization,
  }) = _OrderItem;
  const OrderItem._();

  factory OrderItem.fromJson(Map<String, Object?> json) =>
      _$OrderItemFromJson(json);

  int get totalSizeQty => qty22 + qty24 + qty26 + qty28 + qty210 + qty212;
  double get lineTotal {
    if (totalSizeQty > 0) return unitPrice * totalSizeQty;
    return unitPrice * quantity;
  }
}

Map<String, dynamic>? _customizationFromJson(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {}
  }
  return null;
}

Map<String, String> _productionStatusFromJson(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value.map((k, e) => MapEntry(k, e.toString()));
  }
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return decoded.map((k, e) => MapEntry(k, e.toString()));
    } catch (_) {}
  }
  return const <String, String>{};
}

@freezed
class OrderCreateRequest with _$OrderCreateRequest {
  const factory OrderCreateRequest({
    required String customerName,
    required String orderDate,
    String? color,
    String? grindType,
    String? boxType,
    @Default('') String additionalInfo,
    @Default(0.0) double totalAmount,
    @Default('admin') String source,
    String? customerMobile,
    int? customerId,
  }) = _OrderCreateRequest;

  factory OrderCreateRequest.fromJson(Map<String, Object?> json) =>
      _$OrderCreateRequestFromJson(json);
}
