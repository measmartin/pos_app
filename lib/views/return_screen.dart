import 'package:flutter/material.dart';
import '../models/product_return.dart';
import '../services/database_service.dart';
import '../theme/app_spacing.dart';
import '../theme/app_radius.dart';
import '../widgets/common/empty_state.dart';

/// Screen for processing product returns/refunds
class ReturnScreen extends StatefulWidget {
  final Map<String, dynamic> saleItem; // Original sale item

  const ReturnScreen({
    super.key,
    required this.saleItem,
  });

  @override
  State<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends State<ReturnScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedReason = ReturnReasons.customerRequest;
  bool _isProcessing = false;

  int get _originalQuantity => widget.saleItem['quantity'] as int;
  int get _returnedQuantity => (widget.saleItem['returned_quantity'] as int?) ?? 0;
  int get _availableToReturn => _originalQuantity - _returnedQuantity;
  double get _unitPrice => (widget.saleItem['selling_price'] as num).toDouble();
  String get _productName => widget.saleItem['product_name'] as String;
  int get _productId => widget.saleItem['product_id'] as int;
  int get _saleItemId => widget.saleItem['id'] as int;
  String? get _transactionId => widget.saleItem['transaction_id'] as String?;

  @override
  void initState() {
    super.initState();
    // Default to return all available quantity
    _quantityController.text = _availableToReturn.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _processReturn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final quantityToReturn = int.parse(_quantityController.text);
      final refundAmount = quantityToReturn * _unitPrice;

      final productReturn = ProductReturn(
        saleItemId: _saleItemId,
        productId: _productId,
        productName: _productName,
        quantityReturned: quantityToReturn,
        refundAmount: refundAmount,
        reason: _selectedReason,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        transactionId: _transactionId,
      );

      final db = await DatabaseService().database;
      
      await db.transaction((txn) async {
        // 1. Insert return record
        await txn.insert('returns', productReturn.toMap());

        // 2. Update sale_items returned_quantity
        final newReturnedQty = _returnedQuantity + quantityToReturn;
        await txn.update(
          'sale_items',
          {'returned_quantity': newReturnedQty},
          where: 'id = ?',
          whereArgs: [_saleItemId],
        );

        // 3. Restore stock (add back to inventory)
        await txn.rawUpdate(
          'UPDATE products SET stockQuantity = stockQuantity + ? WHERE id = ?',
          [quantityToReturn, _productId],
        );

        // 4. Create journal entry for refund
        final now = DateTime.now();
        final headerId = await txn.insert('journal_headers', {
          'date': now.toIso8601String(),
          'description': 'Return - $_productName (Qty: $quantityToReturn)',
          'reference_type': 'RETURN',
        });

        // Get Account IDs
        final cashAccount = await txn.query(
          'accounts',
          where: 'name = ?',
          whereArgs: ['Cash on Hand - USD'],
        );
        final salesAccount = await txn.query(
          'accounts',
          where: 'name = ?',
          whereArgs: ['Sales Revenue - USD'],
        );

        final cashId = cashAccount.first['id'];
        final salesId = salesAccount.first['id'];

        // Post 1: Credit Cash (Asset Decreases)
        await txn.insert('journal_lines', {
          'header_id': headerId,
          'account_id': cashId,
          'debit': 0,
          'credit': refundAmount,
        });

        // Post 2: Debit Sales Revenue (Income Decreases)
        await txn.insert('journal_lines', {
          'header_id': headerId,
          'account_id': salesId,
          'debit': refundAmount,
          'credit': 0,
        });
      });

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Return processed: \$${refundAmount.toStringAsFixed(2)} refunded'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing return: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_availableToReturn <= 0) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Process Return'),
        ),
        body: const EmptyState(
          message: 'All items have already been returned',
          icon: Icons.check_circle_outline,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Process Return'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _productName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Unit Price:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '\$${_unitPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Original Quantity:',
                            style: theme.textTheme.bodyMedium,
                          ),
                          Text(
                            '$_originalQuantity',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_returnedQuantity > 0) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Already Returned:',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            Text(
                              '$_returnedQuantity',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available to Return:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$_availableToReturn',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Return Quantity
              Text(
                'Return Quantity',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Quantity to Return',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.inventory),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_fix_high),
                    onPressed: () {
                      _quantityController.text = _availableToReturn.toString();
                    },
                    tooltip: 'Return All',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  final qty = int.tryParse(value);
                  if (qty == null || qty <= 0) {
                    return 'Please enter valid quantity';
                  }
                  if (qty > _availableToReturn) {
                    return 'Cannot exceed $_availableToReturn';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}), // Refresh refund amount
              ),
              const SizedBox(height: AppSpacing.lg),

              // Return Reason
              Text(
                'Return Reason',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.help_outline),
                ),
                items: ReturnReasons.all.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedReason = value);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Notes
              Text(
                'Notes (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Any additional details...',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: AppSpacing.xl),

              // Refund Amount Preview
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Refund Amount:',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                    Text(
                      '\$${(_unitPrice * (int.tryParse(_quantityController.text) ?? 0)).toStringAsFixed(2)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Process Button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isProcessing ? null : _processReturn,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.keyboard_return),
                  label: Text(_isProcessing ? 'Processing...' : 'Process Return'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(AppSpacing.md),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
