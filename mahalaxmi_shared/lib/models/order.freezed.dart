// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Order _$OrderFromJson(Map<String, dynamic> json) {
  return _Order.fromJson(json);
}

/// @nodoc
mixin _$Order {
  @JsonKey(name: 'order_id')
  int? get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_name')
  String get customerName => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_date')
  String get orderDate => throw _privateConstructorUsedError;
  String get color => throw _privateConstructorUsedError;
  @JsonKey(name: 'grind_type')
  String? get grindType => throw _privateConstructorUsedError;
  @JsonKey(name: 'box_type')
  String? get boxType => throw _privateConstructorUsedError;
  @JsonKey(name: 'additional_info')
  String get additionalInfo => throw _privateConstructorUsedError;
  @JsonKey(name: 'total_amount')
  double get totalAmount => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_mobile')
  String? get customerMobile => throw _privateConstructorUsedError;
  @JsonKey(name: 'customer_id')
  int? get customerId => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'status_updated_at')
  String? get statusUpdatedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'order_items')
  List<OrderItem> get orderItems => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'deleted_by')
  String? get deletedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'delete_reason')
  String? get deleteReason => throw _privateConstructorUsedError;

  /// Serializes this Order to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCopyWith<Order> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCopyWith<$Res> {
  factory $OrderCopyWith(Order value, $Res Function(Order) then) =
      _$OrderCopyWithImpl<$Res, Order>;
  @useResult
  $Res call(
      {@JsonKey(name: 'order_id') int? orderId,
      @JsonKey(name: 'customer_name') String customerName,
      @JsonKey(name: 'order_date') String orderDate,
      String color,
      @JsonKey(name: 'grind_type') String? grindType,
      @JsonKey(name: 'box_type') String? boxType,
      @JsonKey(name: 'additional_info') String additionalInfo,
      @JsonKey(name: 'total_amount') double totalAmount,
      String source,
      @JsonKey(name: 'customer_mobile') String? customerMobile,
      @JsonKey(name: 'customer_id') int? customerId,
      String status,
      @JsonKey(name: 'status_updated_at') String? statusUpdatedAt,
      @JsonKey(name: 'order_items') List<OrderItem> orderItems,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'deleted_by') String? deletedBy,
      @JsonKey(name: 'delete_reason') String? deleteReason});
}

/// @nodoc
class _$OrderCopyWithImpl<$Res, $Val extends Order>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = freezed,
    Object? customerName = null,
    Object? orderDate = null,
    Object? color = null,
    Object? grindType = freezed,
    Object? boxType = freezed,
    Object? additionalInfo = null,
    Object? totalAmount = null,
    Object? source = null,
    Object? customerMobile = freezed,
    Object? customerId = freezed,
    Object? status = null,
    Object? statusUpdatedAt = freezed,
    Object? orderItems = null,
    Object? deletedAt = freezed,
    Object? deletedBy = freezed,
    Object? deleteReason = freezed,
  }) {
    return _then(_value.copyWith(
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as int?,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      grindType: freezed == grindType
          ? _value.grindType
          : grindType // ignore: cast_nullable_to_non_nullable
              as String?,
      boxType: freezed == boxType
          ? _value.boxType
          : boxType // ignore: cast_nullable_to_non_nullable
              as String?,
      additionalInfo: null == additionalInfo
          ? _value.additionalInfo
          : additionalInfo // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      customerMobile: freezed == customerMobile
          ? _value.customerMobile
          : customerMobile // ignore: cast_nullable_to_non_nullable
              as String?,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      statusUpdatedAt: freezed == statusUpdatedAt
          ? _value.statusUpdatedAt
          : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      orderItems: null == orderItems
          ? _value.orderItems
          : orderItems // ignore: cast_nullable_to_non_nullable
              as List<OrderItem>,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedBy: freezed == deletedBy
          ? _value.deletedBy
          : deletedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      deleteReason: freezed == deleteReason
          ? _value.deleteReason
          : deleteReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderImplCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$$OrderImplCopyWith(
          _$OrderImpl value, $Res Function(_$OrderImpl) then) =
      __$$OrderImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'order_id') int? orderId,
      @JsonKey(name: 'customer_name') String customerName,
      @JsonKey(name: 'order_date') String orderDate,
      String color,
      @JsonKey(name: 'grind_type') String? grindType,
      @JsonKey(name: 'box_type') String? boxType,
      @JsonKey(name: 'additional_info') String additionalInfo,
      @JsonKey(name: 'total_amount') double totalAmount,
      String source,
      @JsonKey(name: 'customer_mobile') String? customerMobile,
      @JsonKey(name: 'customer_id') int? customerId,
      String status,
      @JsonKey(name: 'status_updated_at') String? statusUpdatedAt,
      @JsonKey(name: 'order_items') List<OrderItem> orderItems,
      @JsonKey(name: 'deleted_at') DateTime? deletedAt,
      @JsonKey(name: 'deleted_by') String? deletedBy,
      @JsonKey(name: 'delete_reason') String? deleteReason});
}

/// @nodoc
class __$$OrderImplCopyWithImpl<$Res>
    extends _$OrderCopyWithImpl<$Res, _$OrderImpl>
    implements _$$OrderImplCopyWith<$Res> {
  __$$OrderImplCopyWithImpl(
      _$OrderImpl _value, $Res Function(_$OrderImpl) _then)
      : super(_value, _then);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = freezed,
    Object? customerName = null,
    Object? orderDate = null,
    Object? color = null,
    Object? grindType = freezed,
    Object? boxType = freezed,
    Object? additionalInfo = null,
    Object? totalAmount = null,
    Object? source = null,
    Object? customerMobile = freezed,
    Object? customerId = freezed,
    Object? status = null,
    Object? statusUpdatedAt = freezed,
    Object? orderItems = null,
    Object? deletedAt = freezed,
    Object? deletedBy = freezed,
    Object? deleteReason = freezed,
  }) {
    return _then(_$OrderImpl(
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as int?,
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as String,
      color: null == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String,
      grindType: freezed == grindType
          ? _value.grindType
          : grindType // ignore: cast_nullable_to_non_nullable
              as String?,
      boxType: freezed == boxType
          ? _value.boxType
          : boxType // ignore: cast_nullable_to_non_nullable
              as String?,
      additionalInfo: null == additionalInfo
          ? _value.additionalInfo
          : additionalInfo // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      customerMobile: freezed == customerMobile
          ? _value.customerMobile
          : customerMobile // ignore: cast_nullable_to_non_nullable
              as String?,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as int?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      statusUpdatedAt: freezed == statusUpdatedAt
          ? _value.statusUpdatedAt
          : statusUpdatedAt // ignore: cast_nullable_to_non_nullable
              as String?,
      orderItems: null == orderItems
          ? _value._orderItems
          : orderItems // ignore: cast_nullable_to_non_nullable
              as List<OrderItem>,
      deletedAt: freezed == deletedAt
          ? _value.deletedAt
          : deletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      deletedBy: freezed == deletedBy
          ? _value.deletedBy
          : deletedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      deleteReason: freezed == deleteReason
          ? _value.deleteReason
          : deleteReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderImpl implements _Order {
  const _$OrderImpl(
      {@JsonKey(name: 'order_id') this.orderId,
      @JsonKey(name: 'customer_name') required this.customerName,
      @JsonKey(name: 'order_date') required this.orderDate,
      this.color = '',
      @JsonKey(name: 'grind_type') this.grindType,
      @JsonKey(name: 'box_type') this.boxType,
      @JsonKey(name: 'additional_info') this.additionalInfo = '',
      @JsonKey(name: 'total_amount') this.totalAmount = 0.0,
      this.source = 'admin',
      @JsonKey(name: 'customer_mobile') this.customerMobile,
      @JsonKey(name: 'customer_id') this.customerId,
      this.status = 'pending',
      @JsonKey(name: 'status_updated_at') this.statusUpdatedAt,
      @JsonKey(name: 'order_items')
      final List<OrderItem> orderItems = const <OrderItem>[],
      @JsonKey(name: 'deleted_at') this.deletedAt,
      @JsonKey(name: 'deleted_by') this.deletedBy,
      @JsonKey(name: 'delete_reason') this.deleteReason})
      : _orderItems = orderItems;

  factory _$OrderImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderImplFromJson(json);

  @override
  @JsonKey(name: 'order_id')
  final int? orderId;
  @override
  @JsonKey(name: 'customer_name')
  final String customerName;
  @override
  @JsonKey(name: 'order_date')
  final String orderDate;
  @override
  @JsonKey()
  final String color;
  @override
  @JsonKey(name: 'grind_type')
  final String? grindType;
  @override
  @JsonKey(name: 'box_type')
  final String? boxType;
  @override
  @JsonKey(name: 'additional_info')
  final String additionalInfo;
  @override
  @JsonKey(name: 'total_amount')
  final double totalAmount;
  @override
  @JsonKey()
  final String source;
  @override
  @JsonKey(name: 'customer_mobile')
  final String? customerMobile;
  @override
  @JsonKey(name: 'customer_id')
  final int? customerId;
  @override
  @JsonKey()
  final String status;
  @override
  @JsonKey(name: 'status_updated_at')
  final String? statusUpdatedAt;
  final List<OrderItem> _orderItems;
  @override
  @JsonKey(name: 'order_items')
  List<OrderItem> get orderItems {
    if (_orderItems is EqualUnmodifiableListView) return _orderItems;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_orderItems);
  }

  @override
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;
  @override
  @JsonKey(name: 'deleted_by')
  final String? deletedBy;
  @override
  @JsonKey(name: 'delete_reason')
  final String? deleteReason;

  @override
  String toString() {
    return 'Order(orderId: $orderId, customerName: $customerName, orderDate: $orderDate, color: $color, grindType: $grindType, boxType: $boxType, additionalInfo: $additionalInfo, totalAmount: $totalAmount, source: $source, customerMobile: $customerMobile, customerId: $customerId, status: $status, statusUpdatedAt: $statusUpdatedAt, orderItems: $orderItems, deletedAt: $deletedAt, deletedBy: $deletedBy, deleteReason: $deleteReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.orderDate, orderDate) ||
                other.orderDate == orderDate) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.grindType, grindType) ||
                other.grindType == grindType) &&
            (identical(other.boxType, boxType) || other.boxType == boxType) &&
            (identical(other.additionalInfo, additionalInfo) ||
                other.additionalInfo == additionalInfo) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.customerMobile, customerMobile) ||
                other.customerMobile == customerMobile) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.statusUpdatedAt, statusUpdatedAt) ||
                other.statusUpdatedAt == statusUpdatedAt) &&
            const DeepCollectionEquality()
                .equals(other._orderItems, _orderItems) &&
            (identical(other.deletedAt, deletedAt) ||
                other.deletedAt == deletedAt) &&
            (identical(other.deletedBy, deletedBy) ||
                other.deletedBy == deletedBy) &&
            (identical(other.deleteReason, deleteReason) ||
                other.deleteReason == deleteReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      orderId,
      customerName,
      orderDate,
      color,
      grindType,
      boxType,
      additionalInfo,
      totalAmount,
      source,
      customerMobile,
      customerId,
      status,
      statusUpdatedAt,
      const DeepCollectionEquality().hash(_orderItems),
      deletedAt,
      deletedBy,
      deleteReason);

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      __$$OrderImplCopyWithImpl<_$OrderImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderImplToJson(
      this,
    );
  }
}

abstract class _Order implements Order {
  const factory _Order(
          {@JsonKey(name: 'order_id') final int? orderId,
          @JsonKey(name: 'customer_name') required final String customerName,
          @JsonKey(name: 'order_date') required final String orderDate,
          final String color,
          @JsonKey(name: 'grind_type') final String? grindType,
          @JsonKey(name: 'box_type') final String? boxType,
          @JsonKey(name: 'additional_info') final String additionalInfo,
          @JsonKey(name: 'total_amount') final double totalAmount,
          final String source,
          @JsonKey(name: 'customer_mobile') final String? customerMobile,
          @JsonKey(name: 'customer_id') final int? customerId,
          final String status,
          @JsonKey(name: 'status_updated_at') final String? statusUpdatedAt,
          @JsonKey(name: 'order_items') final List<OrderItem> orderItems,
          @JsonKey(name: 'deleted_at') final DateTime? deletedAt,
          @JsonKey(name: 'deleted_by') final String? deletedBy,
          @JsonKey(name: 'delete_reason') final String? deleteReason}) =
      _$OrderImpl;

  factory _Order.fromJson(Map<String, dynamic> json) = _$OrderImpl.fromJson;

  @override
  @JsonKey(name: 'order_id')
  int? get orderId;
  @override
  @JsonKey(name: 'customer_name')
  String get customerName;
  @override
  @JsonKey(name: 'order_date')
  String get orderDate;
  @override
  String get color;
  @override
  @JsonKey(name: 'grind_type')
  String? get grindType;
  @override
  @JsonKey(name: 'box_type')
  String? get boxType;
  @override
  @JsonKey(name: 'additional_info')
  String get additionalInfo;
  @override
  @JsonKey(name: 'total_amount')
  double get totalAmount;
  @override
  String get source;
  @override
  @JsonKey(name: 'customer_mobile')
  String? get customerMobile;
  @override
  @JsonKey(name: 'customer_id')
  int? get customerId;
  @override
  String get status;
  @override
  @JsonKey(name: 'status_updated_at')
  String? get statusUpdatedAt;
  @override
  @JsonKey(name: 'order_items')
  List<OrderItem> get orderItems;
  @override
  @JsonKey(name: 'deleted_at')
  DateTime? get deletedAt;
  @override
  @JsonKey(name: 'deleted_by')
  String? get deletedBy;
  @override
  @JsonKey(name: 'delete_reason')
  String? get deleteReason;

  /// Create a copy of Order
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderImplCopyWith<_$OrderImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) {
  return _OrderItem.fromJson(json);
}

/// @nodoc
mixin _$OrderItem {
  @JsonKey(name: 'order_id')
  int? get orderId => throw _privateConstructorUsedError;
  @JsonKey(name: 'item_number')
  String get itemNumber => throw _privateConstructorUsedError;
  String get category => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty_2_2')
  int get qty22 => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty_2_4')
  int get qty24 => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty_2_6')
  int get qty26 => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty_2_8')
  int get qty28 => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty_2_10')
  int get qty210 => throw _privateConstructorUsedError;
  @JsonKey(name: 'qty_2_12')
  int get qty212 => throw _privateConstructorUsedError;
  double get quantity => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  @JsonKey(name: 'grind_type')
  String? get grindType => throw _privateConstructorUsedError;
  @JsonKey(name: 'box_type')
  String? get boxType => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  @JsonKey(name: 'unit_price')
  double get unitPrice => throw _privateConstructorUsedError;
  @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
  Map<String, String> get productionStatus =>
      throw _privateConstructorUsedError;
  @JsonKey(name: 'customization', fromJson: _customizationFromJson)
  Map<String, dynamic>? get customization => throw _privateConstructorUsedError;

  /// Serializes this OrderItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderItemCopyWith<OrderItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderItemCopyWith<$Res> {
  factory $OrderItemCopyWith(OrderItem value, $Res Function(OrderItem) then) =
      _$OrderItemCopyWithImpl<$Res, OrderItem>;
  @useResult
  $Res call(
      {@JsonKey(name: 'order_id') int? orderId,
      @JsonKey(name: 'item_number') String itemNumber,
      String category,
      @JsonKey(name: 'qty_2_2') int qty22,
      @JsonKey(name: 'qty_2_4') int qty24,
      @JsonKey(name: 'qty_2_6') int qty26,
      @JsonKey(name: 'qty_2_8') int qty28,
      @JsonKey(name: 'qty_2_10') int qty210,
      @JsonKey(name: 'qty_2_12') int qty212,
      double quantity,
      String? unit,
      String? color,
      @JsonKey(name: 'grind_type') String? grindType,
      @JsonKey(name: 'box_type') String? boxType,
      String? notes,
      @JsonKey(name: 'unit_price') double unitPrice,
      @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
      Map<String, String> productionStatus,
      @JsonKey(name: 'customization', fromJson: _customizationFromJson)
      Map<String, dynamic>? customization});
}

/// @nodoc
class _$OrderItemCopyWithImpl<$Res, $Val extends OrderItem>
    implements $OrderItemCopyWith<$Res> {
  _$OrderItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = freezed,
    Object? itemNumber = null,
    Object? category = null,
    Object? qty22 = null,
    Object? qty24 = null,
    Object? qty26 = null,
    Object? qty28 = null,
    Object? qty210 = null,
    Object? qty212 = null,
    Object? quantity = null,
    Object? unit = freezed,
    Object? color = freezed,
    Object? grindType = freezed,
    Object? boxType = freezed,
    Object? notes = freezed,
    Object? unitPrice = null,
    Object? productionStatus = null,
    Object? customization = freezed,
  }) {
    return _then(_value.copyWith(
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as int?,
      itemNumber: null == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      qty22: null == qty22
          ? _value.qty22
          : qty22 // ignore: cast_nullable_to_non_nullable
              as int,
      qty24: null == qty24
          ? _value.qty24
          : qty24 // ignore: cast_nullable_to_non_nullable
              as int,
      qty26: null == qty26
          ? _value.qty26
          : qty26 // ignore: cast_nullable_to_non_nullable
              as int,
      qty28: null == qty28
          ? _value.qty28
          : qty28 // ignore: cast_nullable_to_non_nullable
              as int,
      qty210: null == qty210
          ? _value.qty210
          : qty210 // ignore: cast_nullable_to_non_nullable
              as int,
      qty212: null == qty212
          ? _value.qty212
          : qty212 // ignore: cast_nullable_to_non_nullable
              as int,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      grindType: freezed == grindType
          ? _value.grindType
          : grindType // ignore: cast_nullable_to_non_nullable
              as String?,
      boxType: freezed == boxType
          ? _value.boxType
          : boxType // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      productionStatus: null == productionStatus
          ? _value.productionStatus
          : productionStatus // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      customization: freezed == customization
          ? _value.customization
          : customization // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderItemImplCopyWith<$Res>
    implements $OrderItemCopyWith<$Res> {
  factory _$$OrderItemImplCopyWith(
          _$OrderItemImpl value, $Res Function(_$OrderItemImpl) then) =
      __$$OrderItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(name: 'order_id') int? orderId,
      @JsonKey(name: 'item_number') String itemNumber,
      String category,
      @JsonKey(name: 'qty_2_2') int qty22,
      @JsonKey(name: 'qty_2_4') int qty24,
      @JsonKey(name: 'qty_2_6') int qty26,
      @JsonKey(name: 'qty_2_8') int qty28,
      @JsonKey(name: 'qty_2_10') int qty210,
      @JsonKey(name: 'qty_2_12') int qty212,
      double quantity,
      String? unit,
      String? color,
      @JsonKey(name: 'grind_type') String? grindType,
      @JsonKey(name: 'box_type') String? boxType,
      String? notes,
      @JsonKey(name: 'unit_price') double unitPrice,
      @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
      Map<String, String> productionStatus,
      @JsonKey(name: 'customization', fromJson: _customizationFromJson)
      Map<String, dynamic>? customization});
}

/// @nodoc
class __$$OrderItemImplCopyWithImpl<$Res>
    extends _$OrderItemCopyWithImpl<$Res, _$OrderItemImpl>
    implements _$$OrderItemImplCopyWith<$Res> {
  __$$OrderItemImplCopyWithImpl(
      _$OrderItemImpl _value, $Res Function(_$OrderItemImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? orderId = freezed,
    Object? itemNumber = null,
    Object? category = null,
    Object? qty22 = null,
    Object? qty24 = null,
    Object? qty26 = null,
    Object? qty28 = null,
    Object? qty210 = null,
    Object? qty212 = null,
    Object? quantity = null,
    Object? unit = freezed,
    Object? color = freezed,
    Object? grindType = freezed,
    Object? boxType = freezed,
    Object? notes = freezed,
    Object? unitPrice = null,
    Object? productionStatus = null,
    Object? customization = freezed,
  }) {
    return _then(_$OrderItemImpl(
      orderId: freezed == orderId
          ? _value.orderId
          : orderId // ignore: cast_nullable_to_non_nullable
              as int?,
      itemNumber: null == itemNumber
          ? _value.itemNumber
          : itemNumber // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      qty22: null == qty22
          ? _value.qty22
          : qty22 // ignore: cast_nullable_to_non_nullable
              as int,
      qty24: null == qty24
          ? _value.qty24
          : qty24 // ignore: cast_nullable_to_non_nullable
              as int,
      qty26: null == qty26
          ? _value.qty26
          : qty26 // ignore: cast_nullable_to_non_nullable
              as int,
      qty28: null == qty28
          ? _value.qty28
          : qty28 // ignore: cast_nullable_to_non_nullable
              as int,
      qty210: null == qty210
          ? _value.qty210
          : qty210 // ignore: cast_nullable_to_non_nullable
              as int,
      qty212: null == qty212
          ? _value.qty212
          : qty212 // ignore: cast_nullable_to_non_nullable
              as int,
      quantity: null == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      grindType: freezed == grindType
          ? _value.grindType
          : grindType // ignore: cast_nullable_to_non_nullable
              as String?,
      boxType: freezed == boxType
          ? _value.boxType
          : boxType // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      unitPrice: null == unitPrice
          ? _value.unitPrice
          : unitPrice // ignore: cast_nullable_to_non_nullable
              as double,
      productionStatus: null == productionStatus
          ? _value._productionStatus
          : productionStatus // ignore: cast_nullable_to_non_nullable
              as Map<String, String>,
      customization: freezed == customization
          ? _value._customization
          : customization // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderItemImpl extends _OrderItem {
  const _$OrderItemImpl(
      {@JsonKey(name: 'order_id') this.orderId,
      @JsonKey(name: 'item_number') required this.itemNumber,
      this.category = 'Chuda',
      @JsonKey(name: 'qty_2_2') this.qty22 = 0,
      @JsonKey(name: 'qty_2_4') this.qty24 = 0,
      @JsonKey(name: 'qty_2_6') this.qty26 = 0,
      @JsonKey(name: 'qty_2_8') this.qty28 = 0,
      @JsonKey(name: 'qty_2_10') this.qty210 = 0,
      @JsonKey(name: 'qty_2_12') this.qty212 = 0,
      this.quantity = 0.0,
      this.unit,
      this.color,
      @JsonKey(name: 'grind_type') this.grindType,
      @JsonKey(name: 'box_type') this.boxType,
      this.notes,
      @JsonKey(name: 'unit_price') this.unitPrice = 0.0,
      @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
      final Map<String, String> productionStatus = const <String, String>{},
      @JsonKey(name: 'customization', fromJson: _customizationFromJson)
      final Map<String, dynamic>? customization})
      : _productionStatus = productionStatus,
        _customization = customization,
        super._();

  factory _$OrderItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderItemImplFromJson(json);

  @override
  @JsonKey(name: 'order_id')
  final int? orderId;
  @override
  @JsonKey(name: 'item_number')
  final String itemNumber;
  @override
  @JsonKey()
  final String category;
  @override
  @JsonKey(name: 'qty_2_2')
  final int qty22;
  @override
  @JsonKey(name: 'qty_2_4')
  final int qty24;
  @override
  @JsonKey(name: 'qty_2_6')
  final int qty26;
  @override
  @JsonKey(name: 'qty_2_8')
  final int qty28;
  @override
  @JsonKey(name: 'qty_2_10')
  final int qty210;
  @override
  @JsonKey(name: 'qty_2_12')
  final int qty212;
  @override
  @JsonKey()
  final double quantity;
  @override
  final String? unit;
  @override
  final String? color;
  @override
  @JsonKey(name: 'grind_type')
  final String? grindType;
  @override
  @JsonKey(name: 'box_type')
  final String? boxType;
  @override
  final String? notes;
  @override
  @JsonKey(name: 'unit_price')
  final double unitPrice;
  final Map<String, String> _productionStatus;
  @override
  @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
  Map<String, String> get productionStatus {
    if (_productionStatus is EqualUnmodifiableMapView) return _productionStatus;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_productionStatus);
  }

  final Map<String, dynamic>? _customization;
  @override
  @JsonKey(name: 'customization', fromJson: _customizationFromJson)
  Map<String, dynamic>? get customization {
    final value = _customization;
    if (value == null) return null;
    if (_customization is EqualUnmodifiableMapView) return _customization;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'OrderItem(orderId: $orderId, itemNumber: $itemNumber, category: $category, qty22: $qty22, qty24: $qty24, qty26: $qty26, qty28: $qty28, qty210: $qty210, qty212: $qty212, quantity: $quantity, unit: $unit, color: $color, grindType: $grindType, boxType: $boxType, notes: $notes, unitPrice: $unitPrice, productionStatus: $productionStatus, customization: $customization)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderItemImpl &&
            (identical(other.orderId, orderId) || other.orderId == orderId) &&
            (identical(other.itemNumber, itemNumber) ||
                other.itemNumber == itemNumber) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.qty22, qty22) || other.qty22 == qty22) &&
            (identical(other.qty24, qty24) || other.qty24 == qty24) &&
            (identical(other.qty26, qty26) || other.qty26 == qty26) &&
            (identical(other.qty28, qty28) || other.qty28 == qty28) &&
            (identical(other.qty210, qty210) || other.qty210 == qty210) &&
            (identical(other.qty212, qty212) || other.qty212 == qty212) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.grindType, grindType) ||
                other.grindType == grindType) &&
            (identical(other.boxType, boxType) || other.boxType == boxType) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.unitPrice, unitPrice) ||
                other.unitPrice == unitPrice) &&
            const DeepCollectionEquality()
                .equals(other._productionStatus, _productionStatus) &&
            const DeepCollectionEquality()
                .equals(other._customization, _customization));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      orderId,
      itemNumber,
      category,
      qty22,
      qty24,
      qty26,
      qty28,
      qty210,
      qty212,
      quantity,
      unit,
      color,
      grindType,
      boxType,
      notes,
      unitPrice,
      const DeepCollectionEquality().hash(_productionStatus),
      const DeepCollectionEquality().hash(_customization));

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      __$$OrderItemImplCopyWithImpl<_$OrderItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderItemImplToJson(
      this,
    );
  }
}

abstract class _OrderItem extends OrderItem {
  const factory _OrderItem(
      {@JsonKey(name: 'order_id') final int? orderId,
      @JsonKey(name: 'item_number') required final String itemNumber,
      final String category,
      @JsonKey(name: 'qty_2_2') final int qty22,
      @JsonKey(name: 'qty_2_4') final int qty24,
      @JsonKey(name: 'qty_2_6') final int qty26,
      @JsonKey(name: 'qty_2_8') final int qty28,
      @JsonKey(name: 'qty_2_10') final int qty210,
      @JsonKey(name: 'qty_2_12') final int qty212,
      final double quantity,
      final String? unit,
      final String? color,
      @JsonKey(name: 'grind_type') final String? grindType,
      @JsonKey(name: 'box_type') final String? boxType,
      final String? notes,
      @JsonKey(name: 'unit_price') final double unitPrice,
      @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
      final Map<String, String> productionStatus,
      @JsonKey(name: 'customization', fromJson: _customizationFromJson)
      final Map<String, dynamic>? customization}) = _$OrderItemImpl;
  const _OrderItem._() : super._();

  factory _OrderItem.fromJson(Map<String, dynamic> json) =
      _$OrderItemImpl.fromJson;

  @override
  @JsonKey(name: 'order_id')
  int? get orderId;
  @override
  @JsonKey(name: 'item_number')
  String get itemNumber;
  @override
  String get category;
  @override
  @JsonKey(name: 'qty_2_2')
  int get qty22;
  @override
  @JsonKey(name: 'qty_2_4')
  int get qty24;
  @override
  @JsonKey(name: 'qty_2_6')
  int get qty26;
  @override
  @JsonKey(name: 'qty_2_8')
  int get qty28;
  @override
  @JsonKey(name: 'qty_2_10')
  int get qty210;
  @override
  @JsonKey(name: 'qty_2_12')
  int get qty212;
  @override
  double get quantity;
  @override
  String? get unit;
  @override
  String? get color;
  @override
  @JsonKey(name: 'grind_type')
  String? get grindType;
  @override
  @JsonKey(name: 'box_type')
  String? get boxType;
  @override
  String? get notes;
  @override
  @JsonKey(name: 'unit_price')
  double get unitPrice;
  @override
  @JsonKey(name: 'production_status', fromJson: _productionStatusFromJson)
  Map<String, String> get productionStatus;
  @override
  @JsonKey(name: 'customization', fromJson: _customizationFromJson)
  Map<String, dynamic>? get customization;

  /// Create a copy of OrderItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderItemImplCopyWith<_$OrderItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

OrderCreateRequest _$OrderCreateRequestFromJson(Map<String, dynamic> json) {
  return _OrderCreateRequest.fromJson(json);
}

/// @nodoc
mixin _$OrderCreateRequest {
  String get customerName => throw _privateConstructorUsedError;
  String get orderDate => throw _privateConstructorUsedError;
  String? get color => throw _privateConstructorUsedError;
  String? get grindType => throw _privateConstructorUsedError;
  String? get boxType => throw _privateConstructorUsedError;
  String get additionalInfo => throw _privateConstructorUsedError;
  double get totalAmount => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  String? get customerMobile => throw _privateConstructorUsedError;
  int? get customerId => throw _privateConstructorUsedError;

  /// Serializes this OrderCreateRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrderCreateRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrderCreateRequestCopyWith<OrderCreateRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrderCreateRequestCopyWith<$Res> {
  factory $OrderCreateRequestCopyWith(
          OrderCreateRequest value, $Res Function(OrderCreateRequest) then) =
      _$OrderCreateRequestCopyWithImpl<$Res, OrderCreateRequest>;
  @useResult
  $Res call(
      {String customerName,
      String orderDate,
      String? color,
      String? grindType,
      String? boxType,
      String additionalInfo,
      double totalAmount,
      String source,
      String? customerMobile,
      int? customerId});
}

/// @nodoc
class _$OrderCreateRequestCopyWithImpl<$Res, $Val extends OrderCreateRequest>
    implements $OrderCreateRequestCopyWith<$Res> {
  _$OrderCreateRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrderCreateRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerName = null,
    Object? orderDate = null,
    Object? color = freezed,
    Object? grindType = freezed,
    Object? boxType = freezed,
    Object? additionalInfo = null,
    Object? totalAmount = null,
    Object? source = null,
    Object? customerMobile = freezed,
    Object? customerId = freezed,
  }) {
    return _then(_value.copyWith(
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as String,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      grindType: freezed == grindType
          ? _value.grindType
          : grindType // ignore: cast_nullable_to_non_nullable
              as String?,
      boxType: freezed == boxType
          ? _value.boxType
          : boxType // ignore: cast_nullable_to_non_nullable
              as String?,
      additionalInfo: null == additionalInfo
          ? _value.additionalInfo
          : additionalInfo // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      customerMobile: freezed == customerMobile
          ? _value.customerMobile
          : customerMobile // ignore: cast_nullable_to_non_nullable
              as String?,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrderCreateRequestImplCopyWith<$Res>
    implements $OrderCreateRequestCopyWith<$Res> {
  factory _$$OrderCreateRequestImplCopyWith(_$OrderCreateRequestImpl value,
          $Res Function(_$OrderCreateRequestImpl) then) =
      __$$OrderCreateRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String customerName,
      String orderDate,
      String? color,
      String? grindType,
      String? boxType,
      String additionalInfo,
      double totalAmount,
      String source,
      String? customerMobile,
      int? customerId});
}

/// @nodoc
class __$$OrderCreateRequestImplCopyWithImpl<$Res>
    extends _$OrderCreateRequestCopyWithImpl<$Res, _$OrderCreateRequestImpl>
    implements _$$OrderCreateRequestImplCopyWith<$Res> {
  __$$OrderCreateRequestImplCopyWithImpl(_$OrderCreateRequestImpl _value,
      $Res Function(_$OrderCreateRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrderCreateRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customerName = null,
    Object? orderDate = null,
    Object? color = freezed,
    Object? grindType = freezed,
    Object? boxType = freezed,
    Object? additionalInfo = null,
    Object? totalAmount = null,
    Object? source = null,
    Object? customerMobile = freezed,
    Object? customerId = freezed,
  }) {
    return _then(_$OrderCreateRequestImpl(
      customerName: null == customerName
          ? _value.customerName
          : customerName // ignore: cast_nullable_to_non_nullable
              as String,
      orderDate: null == orderDate
          ? _value.orderDate
          : orderDate // ignore: cast_nullable_to_non_nullable
              as String,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
      grindType: freezed == grindType
          ? _value.grindType
          : grindType // ignore: cast_nullable_to_non_nullable
              as String?,
      boxType: freezed == boxType
          ? _value.boxType
          : boxType // ignore: cast_nullable_to_non_nullable
              as String?,
      additionalInfo: null == additionalInfo
          ? _value.additionalInfo
          : additionalInfo // ignore: cast_nullable_to_non_nullable
              as String,
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      source: null == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String,
      customerMobile: freezed == customerMobile
          ? _value.customerMobile
          : customerMobile // ignore: cast_nullable_to_non_nullable
              as String?,
      customerId: freezed == customerId
          ? _value.customerId
          : customerId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrderCreateRequestImpl implements _OrderCreateRequest {
  const _$OrderCreateRequestImpl(
      {required this.customerName,
      required this.orderDate,
      this.color,
      this.grindType,
      this.boxType,
      this.additionalInfo = '',
      this.totalAmount = 0.0,
      this.source = 'admin',
      this.customerMobile,
      this.customerId});

  factory _$OrderCreateRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrderCreateRequestImplFromJson(json);

  @override
  final String customerName;
  @override
  final String orderDate;
  @override
  final String? color;
  @override
  final String? grindType;
  @override
  final String? boxType;
  @override
  @JsonKey()
  final String additionalInfo;
  @override
  @JsonKey()
  final double totalAmount;
  @override
  @JsonKey()
  final String source;
  @override
  final String? customerMobile;
  @override
  final int? customerId;

  @override
  String toString() {
    return 'OrderCreateRequest(customerName: $customerName, orderDate: $orderDate, color: $color, grindType: $grindType, boxType: $boxType, additionalInfo: $additionalInfo, totalAmount: $totalAmount, source: $source, customerMobile: $customerMobile, customerId: $customerId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrderCreateRequestImpl &&
            (identical(other.customerName, customerName) ||
                other.customerName == customerName) &&
            (identical(other.orderDate, orderDate) ||
                other.orderDate == orderDate) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.grindType, grindType) ||
                other.grindType == grindType) &&
            (identical(other.boxType, boxType) || other.boxType == boxType) &&
            (identical(other.additionalInfo, additionalInfo) ||
                other.additionalInfo == additionalInfo) &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.customerMobile, customerMobile) ||
                other.customerMobile == customerMobile) &&
            (identical(other.customerId, customerId) ||
                other.customerId == customerId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      customerName,
      orderDate,
      color,
      grindType,
      boxType,
      additionalInfo,
      totalAmount,
      source,
      customerMobile,
      customerId);

  /// Create a copy of OrderCreateRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrderCreateRequestImplCopyWith<_$OrderCreateRequestImpl> get copyWith =>
      __$$OrderCreateRequestImplCopyWithImpl<_$OrderCreateRequestImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrderCreateRequestImplToJson(
      this,
    );
  }
}

abstract class _OrderCreateRequest implements OrderCreateRequest {
  const factory _OrderCreateRequest(
      {required final String customerName,
      required final String orderDate,
      final String? color,
      final String? grindType,
      final String? boxType,
      final String additionalInfo,
      final double totalAmount,
      final String source,
      final String? customerMobile,
      final int? customerId}) = _$OrderCreateRequestImpl;

  factory _OrderCreateRequest.fromJson(Map<String, dynamic> json) =
      _$OrderCreateRequestImpl.fromJson;

  @override
  String get customerName;
  @override
  String get orderDate;
  @override
  String? get color;
  @override
  String? get grindType;
  @override
  String? get boxType;
  @override
  String get additionalInfo;
  @override
  double get totalAmount;
  @override
  String get source;
  @override
  String? get customerMobile;
  @override
  int? get customerId;

  /// Create a copy of OrderCreateRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrderCreateRequestImplCopyWith<_$OrderCreateRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
