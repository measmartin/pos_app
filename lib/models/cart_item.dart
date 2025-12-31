import 'product.dart';
import 'product_unit.dart';
import 'discount.dart';

class CartItem {
  final Product product;
  int quantity; // This is now count of the UNIT (e.g. 2 Packs)
  ProductUnit? unit; // Null means base unit
  Discount? discount; // Item-level discount

  CartItem({
    required this.product,
    this.quantity = 1,
    this.unit,
    this.discount,
  });

  /// Get unique key for this item (used for discount mapping)
  String get key => '${product.id}_${unit?.name ?? 'base'}';

  /// Get unit price before discount
  double get unitPrice {
    double price = product.sellingPrice;
    if (unit != null) {
      if (unit!.sellingPrice != null && unit!.sellingPrice! > 0) {
        price = unit!.sellingPrice!;
      } else {
        price = product.sellingPrice * unit!.factor;
      }
    }
    return price;
  }

  /// Get subtotal before discount
  double get subtotalBeforeDiscount {
    return unitPrice * quantity;
  }

  /// Get discount amount
  double get discountAmount {
    if (discount == null) return 0;
    return discount!.calculateAmount(subtotalBeforeDiscount);
  }

  /// Get final subtotal after discount
  double get subtotal {
    return subtotalBeforeDiscount - discountAmount;
  }

  /// Check if item has discount
  bool get hasDiscount => discount != null;
}
