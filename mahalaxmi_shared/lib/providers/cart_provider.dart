import 'package:riverpod/riverpod.dart';

import '../models/cart_item.dart';
import '../models/cart_state.dart';
import '../services/validation.dart';

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState.initial);

  void restoreFrom(List<CartItem> items) {
    state = CartState(
      lines: items.map((item) => CartLine.create(item)).toList(),
    );
  }

  CartMutationResult addItem(CartItem item, String category) {
    final error = validateCartItem(item, category);
    if (error != null) {
      return CartValidationError(
        itemNumber: item.itemNumber,
        message: error,
      );
    }

    final existingIndex = state.lines.indexWhere(
      (line) =>
          line.item.itemNumber == item.itemNumber &&
          line.item.color == item.color &&
          line.item.grindType == item.grindType &&
          line.item.boxType == item.boxType &&
          line.item.notes == item.notes &&
          line.item.category == item.category,
    );

    if (existingIndex >= 0) {
      final existing = state.lines[existingIndex];
      final merged = _mergeItems(existing.item, item);
      final newLines = [...state.lines];
      newLines[existingIndex] = existing.copyWith(item: merged);
      state = CartState(lines: newLines);
      return CartAddSuccess(lineId: existing.id, merged: true);
    }

    final line = CartLine.create(item);
    state = CartState(lines: [...state.lines, line]);
    return CartAddSuccess(lineId: line.id, merged: false);
  }

  CartItem _mergeItems(CartItem existing, CartItem added) {
    if (existing.hasSizes || added.hasSizes) {
      return existing.copyWith(
        qty22: existing.qty22 + added.qty22,
        qty24: existing.qty24 + added.qty24,
        qty26: existing.qty26 + added.qty26,
        qty28: existing.qty28 + added.qty28,
        qty210: existing.qty210 + added.qty210,
        qty212: existing.qty212 + added.qty212,
        quantity: 0,
        unitPrice: added.unitPrice,
      );
    }
    return existing.copyWith(
      quantity: existing.quantity + added.quantity,
      unitPrice: added.unitPrice,
    );
  }

  void removeItem(String lineId) {
    state = CartState(
      lines: [...state.lines.where((line) => line.id != lineId)],
    );
  }

  CartMutationResult updateItem(String lineId, CartItem updated) {
    final index = state.lines.indexWhere((line) => line.id == lineId);
    if (index < 0) {
      return CartMutationError('Cart line not found: $lineId');
    }

    final error = validateCartItem(updated, updated.category);
    if (error != null) {
      return CartValidationError(
        itemNumber: updated.itemNumber,
        message: error,
      );
    }

    final newLines = [...state.lines];
    newLines[index] = newLines[index].copyWith(item: updated);
    state = CartState(lines: newLines);
    return CartUpdateSuccess(lineId: lineId);
  }

  void clear() {
    state = CartState.initial;
  }

  List<CartValidationError> validateAll() {
    final errors = <CartValidationError>[];
    for (final line in state.lines) {
      final error = validateCartItem(line.item, line.item.category);
      if (error != null) {
        errors.add(CartValidationError(
          itemNumber: line.item.itemNumber,
          message: error,
        ));
      }
    }
    return errors;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).itemCount;
});

final cartLinesProvider = Provider<List<CartLine>>((ref) {
  return ref.watch(cartProvider).lines;
});
