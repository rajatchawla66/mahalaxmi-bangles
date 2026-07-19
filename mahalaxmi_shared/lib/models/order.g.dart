// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrderImpl _$$OrderImplFromJson(Map<String, dynamic> json) => _$OrderImpl(
      orderId: (json['order_id'] as num?)?.toInt(),
      customerName: json['customer_name'] as String,
      orderDate: json['order_date'] as String,
      color: json['color'] as String? ?? '',
      grindType: json['grind_type'] as String?,
      boxType: json['box_type'] as String?,
      additionalInfo: json['additional_info'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'admin',
      customerMobile: json['customer_mobile'] as String?,
      customerId: (json['customer_id'] as num?)?.toInt(),
      status: json['status'] as String? ?? 'pending',
      statusUpdatedAt: json['status_updated_at'] as String?,
      orderItems: (json['order_items'] as List<dynamic>?)
              ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OrderItem>[],
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      deletedBy: json['deleted_by'] as String?,
      deleteReason: json['delete_reason'] as String?,
    );

Map<String, dynamic> _$$OrderImplToJson(_$OrderImpl instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'customer_name': instance.customerName,
      'order_date': instance.orderDate,
      'color': instance.color,
      'grind_type': instance.grindType,
      'box_type': instance.boxType,
      'additional_info': instance.additionalInfo,
      'total_amount': instance.totalAmount,
      'source': instance.source,
      'customer_mobile': instance.customerMobile,
      'customer_id': instance.customerId,
      'status': instance.status,
      'status_updated_at': instance.statusUpdatedAt,
      'order_items': instance.orderItems,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'deleted_by': instance.deletedBy,
      'delete_reason': instance.deleteReason,
    };

_$OrderItemImpl _$$OrderItemImplFromJson(Map<String, dynamic> json) =>
    _$OrderItemImpl(
      orderId: (json['order_id'] as num?)?.toInt(),
      itemNumber: json['item_number'] as String,
      category: json['category'] as String? ?? 'Chuda',
      qty22: (json['qty_2_2'] as num?)?.toInt() ?? 0,
      qty24: (json['qty_2_4'] as num?)?.toInt() ?? 0,
      qty26: (json['qty_2_6'] as num?)?.toInt() ?? 0,
      qty28: (json['qty_2_8'] as num?)?.toInt() ?? 0,
      qty210: (json['qty_2_10'] as num?)?.toInt() ?? 0,
      qty212: (json['qty_2_12'] as num?)?.toInt() ?? 0,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      color: json['color'] as String?,
      grindType: json['grind_type'] as String?,
      boxType: json['box_type'] as String?,
      notes: json['notes'] as String?,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      productionStatus: json['production_status'] == null
          ? const <String, String>{}
          : _productionStatusFromJson(json['production_status']),
      customization: _customizationFromJson(json['customization']),
    );

Map<String, dynamic> _$$OrderItemImplToJson(_$OrderItemImpl instance) =>
    <String, dynamic>{
      'order_id': instance.orderId,
      'item_number': instance.itemNumber,
      'category': instance.category,
      'qty_2_2': instance.qty22,
      'qty_2_4': instance.qty24,
      'qty_2_6': instance.qty26,
      'qty_2_8': instance.qty28,
      'qty_2_10': instance.qty210,
      'qty_2_12': instance.qty212,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'color': instance.color,
      'grind_type': instance.grindType,
      'box_type': instance.boxType,
      'notes': instance.notes,
      'unit_price': instance.unitPrice,
      'production_status': instance.productionStatus,
      'customization': instance.customization,
    };

_$OrderCreateRequestImpl _$$OrderCreateRequestImplFromJson(
        Map<String, dynamic> json) =>
    _$OrderCreateRequestImpl(
      customerName: json['customerName'] as String,
      orderDate: json['orderDate'] as String,
      color: json['color'] as String?,
      grindType: json['grindType'] as String?,
      boxType: json['boxType'] as String?,
      additionalInfo: json['additionalInfo'] as String? ?? '',
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      source: json['source'] as String? ?? 'admin',
      customerMobile: json['customerMobile'] as String?,
      customerId: (json['customerId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$OrderCreateRequestImplToJson(
        _$OrderCreateRequestImpl instance) =>
    <String, dynamic>{
      'customerName': instance.customerName,
      'orderDate': instance.orderDate,
      'color': instance.color,
      'grindType': instance.grindType,
      'boxType': instance.boxType,
      'additionalInfo': instance.additionalInfo,
      'totalAmount': instance.totalAmount,
      'source': instance.source,
      'customerMobile': instance.customerMobile,
      'customerId': instance.customerId,
    };
