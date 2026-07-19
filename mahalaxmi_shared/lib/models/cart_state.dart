import 'package:uuid/uuid.dart';

import 'cart_item.dart';

const _uuid = Uuid();

class CartLine {
  final String id;
  final CartItem item;

  const CartLine({required this.id, required this.item});

  factory CartLine.create(CartItem item) {
    return CartLine(id: _uuid.v4(), item: item);
  }

  CartLine copyWith({CartItem? item}) {
    return CartLine(id: id, item: item ?? this.item);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CartLine && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class CartState {
  final List<CartLine> lines;

  const CartState({required this.lines});

  static const initial = CartState(lines: []);

  int get itemCount => lines.length;

  List<CartItem> get items => lines.map((l) => l.item).toList();

  CartLine? findById(String id) {
    for (final line in lines) {
      if (line.id == id) return line;
    }
    return null;
  }
}

sealed class CartMutationResult {
  const CartMutationResult();
}

class CartAddSuccess extends CartMutationResult {
  final String lineId;
  final bool merged;
  const CartAddSuccess({required this.lineId, required this.merged});
}

class CartUpdateSuccess extends CartMutationResult {
  final String lineId;
  const CartUpdateSuccess({required this.lineId});
}

class CartValidationError extends CartMutationResult {
  final String itemNumber;
  final String message;
  const CartValidationError({
    required this.itemNumber,
    required this.message,
  });
}

class CartMutationError extends CartMutationResult {
  final String message;
  const CartMutationError(this.message);
}
