import 'product.dart';
import 'product_unit.dart';

class CartItem {
  final Product product;
  int quantity; // This is now count of the UNIT (e.g. 2 Packs)
  ProductUnit? unit; // Null means base unit

  CartItem({required this.product, this.quantity = 1, this.unit});

  double get subtotal {
    double price = product.sellingPrice;
    if (unit != null) {
      if (unit!.sellingPrice != null && unit!.sellingPrice! > 0) {
        price = unit!.sellingPrice!;
      } else {
        price = product.sellingPrice * unit!.factor;
      }
    }
    return price * quantity;
  }
}
