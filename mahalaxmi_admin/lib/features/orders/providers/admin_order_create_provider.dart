import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahalaxmi_shared/mahalaxmi_shared.dart';

bool _isSameVariant(CartItem a, CartItem b) {
  final sameBase = a.itemNumber == b.itemNumber &&
      a.color == b.color &&
      a.grindType == b.grindType &&
      a.boxType == b.boxType &&
      a.notes == b.notes &&
      a.hasSizes == b.hasSizes;
  if (!sameBase) return false;
  final aCust = a.customization;
  final bCust = b.customization;
  if (aCust == null && bCust == null) return true;
  if (aCust == null || bCust == null) return false;
  return aCust.pattiName == bCust.pattiName &&
      aCust.colorName == bCust.colorName &&
      aCust.customColorText == bCust.customColorText &&
      aCust.boxName == bCust.boxName;
}

class AdminOrderCreateState {
  final Customer? selectedCustomer;
  final String customerName;
  final String customerMobile;
  final List<CartLine> lines;
  final bool placing;
  final int? orderSuccessOrderId;

  const AdminOrderCreateState({
    this.selectedCustomer,
    this.customerName = '',
    this.customerMobile = '',
    this.lines = const [],
    this.placing = false,
    this.orderSuccessOrderId,
  });

  AdminOrderCreateState copyWith({
    Customer? selectedCustomer,
    String? customerName,
    String? customerMobile,
    List<CartLine>? lines,
    bool? placing,
    int? orderSuccessOrderId,
    bool clearSuccess = false,
  }) {
    return AdminOrderCreateState(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      lines: lines ?? this.lines,
      placing: placing ?? this.placing,
      orderSuccessOrderId: clearSuccess ? null : (orderSuccessOrderId ?? this.orderSuccessOrderId),
    );
  }

  double get totalAmount {
    double total = 0;
    for (final line in lines) {
      final qty = line.item.hasSizes
          ? line.item.totalSizeQty.toDouble()
          : line.item.quantity;
      total += qty * line.item.unitPrice;
    }
    return total;
  }

  int get itemCount => lines.length;

  String? get matchingLineId {
    return null;
  }

  String? findMatchingLineId(CartItem item) {
    for (final line in lines) {
      if (_isSameVariant(line.item, item)) return line.id;
    }
    return null;
  }
}

class AdminOrderCreateNotifier extends StateNotifier<AdminOrderCreateState> {
  AdminOrderCreateNotifier() : super(const AdminOrderCreateState());

  void selectCustomer(Customer? customer) {
    if (customer == null) {
      state = state.copyWith(
        selectedCustomer: null,
        customerName: '',
        customerMobile: '',
      );
    } else {
      state = state.copyWith(
        selectedCustomer: customer,
        customerName: customer.shopName,
        customerMobile: customer.mobile,
      );
    }
  }

  void setCustomerName(String name) {
    state = state.copyWith(customerName: name, selectedCustomer: null);
  }

  void setCustomerMobile(String mobile) {
    state = state.copyWith(customerMobile: mobile);
  }

  void addLine(CartItem item) {
    final newLine = CartLine.create(item);
    state = state.copyWith(lines: [...state.lines, newLine]);
  }

  void mergeIntoLine(String lineId, CartItem item) {
    state = state.copyWith(
      lines: state.lines.map((l) {
        if (l.id != lineId) return l;
        final existing = l.item;
        if (item.hasSizes) {
          return l.copyWith(
            item: existing.copyWith(
              qty22: existing.qty22 + item.qty22,
              qty24: existing.qty24 + item.qty24,
              qty26: existing.qty26 + item.qty26,
              qty28: existing.qty28 + item.qty28,
              qty210: existing.qty210 + item.qty210,
              qty212: existing.qty212 + item.qty212,
            ),
          );
        }
        return l.copyWith(
          item: existing.copyWith(quantity: existing.quantity + item.quantity),
        );
      }).toList(),
    );
  }

  void removeLine(String lineId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.id != lineId).toList(),
    );
  }

  void updateLine(String lineId, CartItem updated) {
    state = state.copyWith(
      lines: state.lines.map((l) {
        if (l.id == lineId) return l.copyWith(item: updated);
        return l;
      }).toList(),
    );
  }

  void setPlacing(bool value) {
    state = state.copyWith(placing: value);
  }

  void markSuccess(int orderId) {
    state = state.copyWith(placing: false, orderSuccessOrderId: orderId);
  }

  void clearSuccess() {
    state = state.copyWith(clearSuccess: true);
  }

  void reset() {
    state = const AdminOrderCreateState();
  }
}

final adminOrderCreateProvider =
    StateNotifierProvider<AdminOrderCreateNotifier, AdminOrderCreateState>(
  (ref) => AdminOrderCreateNotifier(),
);
