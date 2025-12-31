import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../models/stock_adjustment.dart';
import '../../view_models/stock_adjustment_view_model.dart';
import '../../view_models/product_view_model.dart';
import '../../theme/app_spacing.dart';
import '../../views/stock_adjustment_history_screen.dart';
import '../forms/custom_text_field.dart';
import '../buttons/wide_action_button.dart';

class StockAdjustmentDialog extends StatefulWidget {
  final Product product;

  const StockAdjustmentDialog({
    super.key,
    required this.product,
  });

  @override
  State<StockAdjustmentDialog> createState() => _StockAdjustmentDialogState();
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  
  AdjustmentType _selectedType = AdjustmentType.addition;
  AdjustmentReason _selectedReason = AdjustmentReason.stockCount;
  bool _isSubmitting = false;

  int get _quantityChange {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    return _selectedType == AdjustmentType.subtraction ? -quantity : quantity;
  }

  int get _newQuantity {
    return widget.product.stockQuantity + _quantityChange;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitAdjustment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final viewModel = context.read<StockAdjustmentViewModel>();
    final success = await viewModel.createAdjustment(
      product: widget.product,
      quantityChange: _quantityChange,
      type: _selectedType,
      reason: _selectedReason,
      notes: _notesController.text.trim().isEmpty 
          ? null 
          : _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isSubmitting = false);

      if (success) {
        // Refresh products list
        await context.read<ProductViewModel>().fetchProducts();
        
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stock adjusted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to adjust stock'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Adjust Stock',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StockAdjustmentHistoryScreen(
                              productId: widget.product.id,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.history, size: 18),
                      label: const Text('History'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                
                // Product Info
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Text('Current Stock: '),
                            Text(
                              '${widget.product.stockQuantity} ${widget.product.unit}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Adjustment Type
                Text(
                  'Adjustment Type',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                SegmentedButton<AdjustmentType>(
                  segments: [
                    ButtonSegment(
                      value: AdjustmentType.addition,
                      label: const Text('Add Stock'),
                      icon: const Icon(Icons.add),
                    ),
                    ButtonSegment(
                      value: AdjustmentType.subtraction,
                      label: const Text('Remove Stock'),
                      icon: const Icon(Icons.remove),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<AdjustmentType> newSelection) {
                    setState(() => _selectedType = newSelection.first);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // Quantity
                CustomTextField(
                  controller: _quantityController,
                  labelText: 'Quantity',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    final qty = int.tryParse(value);
                    if (qty == null || qty <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    if (_newQuantity < 0) {
                      return 'Insufficient stock (current: ${widget.product.stockQuantity})';
                    }
                    return null;
                  },
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.lg),

                // New Quantity Preview
                if (_quantityController.text.isNotEmpty)
                  Card(
                    color: _newQuantity >= 0
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'New Stock Level:',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Text(
                            '$_newQuantity ${widget.product.unit}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _newQuantity >= 0
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),

                // Reason
                Text(
                  'Reason',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<AdjustmentReason>(
                  initialValue: _selectedReason,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: AdjustmentReason.values.map((reason) {
                    return DropdownMenuItem(
                      value: reason,
                      child: Text(reason.displayName),
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
                CustomTextField(
                  controller: _notesController,
                  labelText: 'Notes (Optional)',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.xl),

                // Submit Button
                WideActionButton(
                  label: _isSubmitting ? 'Processing...' : 'Confirm Adjustment',
                  onPressed: _isSubmitting ? null : _submitAdjustment,
                  icon: Icons.check,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
