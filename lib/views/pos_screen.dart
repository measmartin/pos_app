import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../view_models/product_view_model.dart';
import '../view_models/cart_view_model.dart';
import '../view_models/customer_view_model.dart';
import '../utils/pdf_generator.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../models/product_unit.dart';
import '../models/customer.dart';
import '../models/discount.dart';
import '../models/payment.dart';
import '../screens/simple_scanner_screen.dart';
import '../widgets/forms/search_field.dart';
import '../widgets/product/product_list_item.dart';
import '../widgets/cart/cart_item_card.dart';
import '../widgets/cart/checkout_footer.dart';
import '../widgets/cart/unit_selection_sheet.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/keyboard_shortcuts.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import '../widgets/dialogs/discount_dialog.dart';
import '../widgets/dialogs/payment_dialog.dart';
import '../widgets/dialogs/held_transactions_dialog.dart';
import '../theme/app_spacing.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isCheckingOut = false;

  @override
  void initState() {
    super.initState();
    // Ensure we have products and customers loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductViewModel>().fetchProducts();
      context.read<CustomerViewModel>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onScanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
    );
    
    if (result != null && result is String && mounted) {
      _addToCartByBarcode(result);
    }
  }

  void _addToCartByBarcode(String barcode) {
    final productViewModel = context.read<ProductViewModel>();
    try {
      final product = productViewModel.products.firstWhere(
        (p) => p.barcode == barcode,
      );
      context.read<CartViewModel>().addToCart(product);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${product.name}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found!')),
        );
      }
    }
  }

  void _addToCart(Product product, {ProductUnit? unit}) {
    context.read<CartViewModel>().addToCart(product, unit: unit);
  }

  Future<void> _showItemDiscountDialog(CartItem item) async {
    final discount = await showDialog<Discount?>(
      context: context,
      builder: (context) => DiscountDialog(
        amount: item.subtotalBeforeDiscount,
        title: 'Item Discount - ${item.product.name}',
      ),
    );

    if (discount != null && mounted) {
      context.read<CartViewModel>().applyItemDiscount(item, discount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discount applied to item')),
        );
      }
    }
  }

  Future<void> _showCartDiscountDialog() async {
    final cart = context.read<CartViewModel>();
    final discount = await showDialog<Discount?>(
      context: context,
      builder: (context) => DiscountDialog(
        amount: cart.subtotalAfterItemDiscounts,
        title: 'Cart Discount',
      ),
    );

    if (discount != null && mounted) {
      cart.applyCartDiscount(discount);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart discount applied')),
        );
      }
    }
  }

  Future<void> _showCustomerSelectionDialog() async {
    final customerViewModel = context.read<CustomerViewModel>();
    
    final selectedCustomer = await showDialog<Customer?>(
      context: context,
      builder: (context) => _CustomerSelectionDialog(
        customers: customerViewModel.filteredCustomers,
      ),
    );

    if (selectedCustomer != null && mounted) {
      context.read<CartViewModel>().setCustomer(selectedCustomer.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer: ${selectedCustomer.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _clearCustomer() {
    context.read<CartViewModel>().clearCustomer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Customer cleared')),
    );
  }

  Future<void> _showUnitSelectionDialog(Product product) async {
    if (product.sellingPrice == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set selling price first!')),
      );
      return;
    }
    
    // If no extra units, just add base
    if (product.additionalUnits.isEmpty) {
      _addToCart(product);
      return;
    }

    final unit = await UnitSelectionSheet.show(context, product);
    if (mounted) {
      _addToCart(product, unit: unit);
    }
  }

  Future<void> _handleCheckout() async {
    final cart = context.read<CartViewModel>();
    
    // Validate selling prices
    for (var item in cart.items) {
      if (item.product.sellingPrice <= 0 && 
          (item.unit == null || 
           (item.unit!.sellingPrice == null || item.unit!.sellingPrice! <= 0))) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot checkout: ${item.product.name} has no selling price!'),
            ),
          );
        }
        return;
      }
    }

    // Show payment dialog
    final payments = await showDialog<List<Payment>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentDialog(
        totalAmount: cart.totalAmount,
      ),
    );

    // If user cancelled payment
    if (payments == null || payments.isEmpty) return;

    setState(() => _isCheckingOut = true);

    // Capture data before checkout clears them
    final currentItems = List<CartItem>.from(cart.items);
    final subtotalBeforeDiscount = cart.subtotalBeforeDiscount;
    final discountAmount = cart.totalDiscountAmount;
    final finalAmount = cart.totalAmount;
    final customerId = cart.selectedCustomerId;
    
    // Get customer object if selected
    Customer? currentCustomer;
    double? pointsEarned;
    if (customerId != null) {
      final customerViewModel = context.read<CustomerViewModel>();
      try {
        currentCustomer = customerViewModel.customers.firstWhere(
          (c) => c.id == customerId,
        );
        pointsEarned = finalAmount * 0.01; // 1% of purchase as points
      } catch (e) {
        // Customer not found
      }
    }
    
    // Capture discounts for receipt
    final discounts = <Discount>[];
    for (var item in cart.items) {
      if (item.discount != null) {
        discounts.add(item.discount!);
      }
    }
    if (cart.cartDiscount != null) {
      discounts.add(cart.cartDiscount!);
    }

    String? transactionId = await cart.checkout(payments: payments);
    
    setState(() => _isCheckingOut = false);

    if (transactionId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction Completed!')),
      );
      context.read<ProductViewModel>().fetchProducts();
      
      // Ask for receipt
      final printReceipt = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Transaction Successful'),
          content: const Text('Do you want to print a receipt?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Print'),
            ),
          ],
        ),
      );

      if (printReceipt == true && mounted) {
        await PdfGenerator.generateEnhancedReceipt(
          transactionId: transactionId,
          items: currentItems,
          payments: payments,
          subtotalBeforeDiscount: subtotalBeforeDiscount,
          discountAmount: discountAmount,
          finalAmount: finalAmount,
          customer: currentCustomer,
          pointsEarned: pointsEarned,
          discounts: discounts.isNotEmpty ? discounts : null,
        );
      }
    }
  }

  Future<void> _holdTransaction() async {
    final cart = context.read<CartViewModel>();

    if (cart.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty')),
      );
      return;
    }

    // Ask for optional notes
    final notes = await showDialog<String>(
      context: context,
      builder: (context) {
        final notesController = TextEditingController();
        return AlertDialog(
          title: const Text('Hold Transaction'),
          content: TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'e.g., Customer name, reference',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, notesController.text),
              child: const Text('Hold'),
            ),
          ],
        );
      },
    );

    if (notes == null) return; // User cancelled

    final holdId = await cart.holdTransaction(notes: notes.isEmpty ? null : notes);

    if (holdId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction held successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to hold transaction'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showHeldTransactions() async {
    final cart = context.read<CartViewModel>();
    final heldTransactions = await cart.getHeldTransactions();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) => HeldTransactionsDialog(
        heldTransactions: heldTransactions,
        onRecall: (holdId) async {
          final success = await cart.recallTransaction(holdId);
          if (mounted) {
            if (success) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Transaction recalled'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to recall transaction'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onDelete: (holdId) async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Held Transaction'),
              content: const Text('Are you sure? This cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            final success = await cart.deleteHeldTransaction(holdId);
            if (mounted) {
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Held transaction deleted')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    // Define keyboard shortcuts
    final shortcuts = <LogicalKeySet, VoidCallback>{
      // F1 - Show shortcuts help
      LogicalKeySet(LogicalKeyboardKey.f1): () => _showKeyboardShortcutsHelp(),
      // F2 - Focus search
      LogicalKeySet(LogicalKeyboardKey.f2): () => _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      ),
      // F3 - Scan barcode
      LogicalKeySet(LogicalKeyboardKey.f3): _onScanBarcode,
      // F4 - Select customer
      LogicalKeySet(LogicalKeyboardKey.f4): _showCustomerSelectionDialog,
      // F5 - Hold transaction
      LogicalKeySet(LogicalKeyboardKey.f5): cart.items.isNotEmpty ? _holdTransaction : () {},
      // F6 - Recall transaction
      LogicalKeySet(LogicalKeyboardKey.f6): _showHeldTransactions,
      // F9 - Clear cart
      LogicalKeySet(LogicalKeyboardKey.f9): cart.items.isNotEmpty ? _confirmAndClearCart : () {},
      // F12 - Checkout
      LogicalKeySet(LogicalKeyboardKey.f12): cart.items.isNotEmpty && !_isCheckingOut ? _handleCheckout : () {},
      // Ctrl+D - Apply cart discount
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyD): 
        cart.items.isNotEmpty ? _showCartDiscountDialog : () {},
    };

    return KeyboardShortcuts(
      shortcuts: shortcuts,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('POS Terminal / Sales'),
          actions: [
            // Help button for keyboard shortcuts
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: _showKeyboardShortcutsHelp,
              tooltip: 'Keyboard Shortcuts (F1)',
            ),
            // Recall held transactions
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: _showHeldTransactions,
              tooltip: 'Held Transactions (F6)',
            ),
            // Hold current transaction
            Consumer<CartViewModel>(
              builder: (context, cart, child) {
                return IconButton(
                  icon: const Icon(Icons.pause_circle_outline),
                  onPressed: cart.items.isNotEmpty ? _holdTransaction : null,
                  tooltip: 'Hold Transaction (F5)',
                );
              },
            ),
          ],
        ),
      body: Column(
        children: [
          // Search and Scan Area
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search Product...',
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filled(
                  onPressed: _onScanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: 'Scan Barcode',
                ),
              ],
            ),
          ),
          
          // Customer Selection Bar
          Consumer2<CartViewModel, CustomerViewModel>(
            builder: (context, cart, customerViewModel, child) {
              final customerId = cart.selectedCustomerId;
              Customer? customer;
              
              if (customerId != null) {
                try {
                  customer = customerViewModel.customers.firstWhere(
                    (c) => c.id == customerId,
                  );
                } catch (e) {
                  // Customer not found
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: customer != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  customer.name,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '${customer.loyaltyPoints.toStringAsFixed(0)} points',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            )
                          : Text(
                              'No customer selected',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                    ),
                    if (customer != null)
                      IconButton(
                        onPressed: _clearCustomer,
                        icon: const Icon(Icons.clear, size: 20),
                        tooltip: 'Clear Customer',
                      )
                    else
                      FilledButton.tonalIcon(
                        onPressed: _showCustomerSelectionDialog,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Select'),
                      ),
                  ],
                ),
              );
            },
          ),
          
          // Product Suggestion List (Visible when searching)
          if (_searchController.text.isNotEmpty)
            Expanded(
              flex: 1,
              child: Consumer<ProductViewModel>(
                builder: (context, viewModel, child) {
                  final filtered = viewModel.products.where((p) => 
                    p.name.toLowerCase().contains(_searchController.text.toLowerCase()) || 
                    p.barcode.contains(_searchController.text)
                  ).toList();
                  
                  if (filtered.isEmpty) {
                    return const EmptyState(
                      message: 'No products found',
                      icon: Icons.search_off,
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductListItem(
                        product: product,
                        subtitle: '${product.stockQuantity} in stock',
                        trailing: Text('\$${product.sellingPrice}'),
                        onTap: () {
                          _showUnitSelectionDialog(product);
                          _searchController.clear();
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),
            ),

          const Divider(),
          
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Text(
              'Current Cart',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Cart List
          Expanded(
            flex: 2,
            child: Consumer<CartViewModel>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) {
                  return const EmptyState(
                    message: 'Cart is empty',
                    icon: Icons.shopping_cart_outlined,
                  );
                }
                
                return ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];
                    return CartItemCard(
                      item: item,
                      onIncrement: () => cart.addToCart(
                        item.product,
                        unit: item.unit,
                      ),
                      onDecrement: () => cart.removeFromCart(
                        item.product,
                        unit: item.unit,
                      ),
                      onDiscount: () => _showItemDiscountDialog(item),
                      showStockWarning: true,
                    );
                  },
                );
              },
            ),
          ),
          
          // Checkout Footer
          Consumer<CartViewModel>(
            builder: (context, cart, child) {
              return CheckoutFooter(
                totalAmount: cart.totalAmount,
                itemCount: cart.items.length,
                isEnabled: cart.items.isNotEmpty,
                isLoading: _isCheckingOut,
                onCheckout: _handleCheckout,
                onApplyCartDiscount: cart.items.isNotEmpty ? _showCartDiscountDialog : null,
                subtotalBeforeDiscount: cart.hasDiscounts ? cart.subtotalBeforeDiscount : null,
                discountAmount: cart.hasDiscounts ? cart.totalDiscountAmount : null,
              );
            },
          ),
        ],
      ),
      ), // KeyboardShortcuts closing
    );
  }

  void _showKeyboardShortcutsHelp() {
    KeyboardShortcutsDialog.show(
      context,
      const [
        KeyboardShortcutInfo(keys: 'F1', description: 'Show keyboard shortcuts'),
        KeyboardShortcutInfo(keys: 'F2', description: 'Focus search field'),
        KeyboardShortcutInfo(keys: 'F3', description: 'Scan barcode'),
        KeyboardShortcutInfo(keys: 'F4', description: 'Select customer'),
        KeyboardShortcutInfo(keys: 'F5', description: 'Hold transaction'),
        KeyboardShortcutInfo(keys: 'F6', description: 'Recall held transaction'),
        KeyboardShortcutInfo(keys: 'F9', description: 'Clear cart'),
        KeyboardShortcutInfo(keys: 'F12', description: 'Checkout'),
        KeyboardShortcutInfo(keys: 'Ctrl+D', description: 'Apply cart discount'),
      ],
    );
  }

  Future<void> _confirmAndClearCart() async {
    final cart = context.read<CartViewModel>();
    if (cart.items.isEmpty) return;

    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Clear Cart',
      message: 'Are you sure you want to clear all items from the cart? This action cannot be undone.',
      confirmText: 'Clear',
      cancelText: 'Cancel',
      icon: Icons.delete_outline,
      isDestructive: true,
    );

    if (confirmed && mounted) {
      cart.clearCart();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart cleared')),
      );
    }
  }
}

// Customer Selection Dialog
class _CustomerSelectionDialog extends StatefulWidget {
  final List<Customer> customers;

  const _CustomerSelectionDialog({
    required this.customers,
  });

  @override
  State<_CustomerSelectionDialog> createState() => _CustomerSelectionDialogState();
}

class _CustomerSelectionDialogState extends State<_CustomerSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _filteredCustomers = widget.customers;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCustomers = widget.customers;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredCustomers = widget.customers.where((customer) {
          return customer.name.toLowerCase().contains(lowerQuery) ||
              (customer.phone?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Customer',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            const Divider(height: 1),
            
            // Search
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SearchField(
                controller: _searchController,
                hintText: 'Search by name or phone...',
                onChanged: _filterCustomers,
              ),
            ),
            
            // Customer List
            Expanded(
              child: _filteredCustomers.isEmpty
                  ? const EmptyState(
                      icon: Icons.person_search,
                      message: 'No customers found',
                    )
                  : ListView.builder(
                      itemCount: _filteredCustomers.length,
                      itemBuilder: (context, index) {
                        final customer = _filteredCustomers[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(customer.initials),
                          ),
                          title: Text(customer.name),
                          subtitle: customer.hasPhone
                              ? Text(customer.formattedPhone)
                              : null,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${customer.totalSpent.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              Text(
                                '${customer.loyaltyPoints.toStringAsFixed(0)} pts',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
