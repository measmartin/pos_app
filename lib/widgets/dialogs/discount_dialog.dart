import 'package:flutter/material.dart';
import '../../models/discount.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

/// Dialog for applying discounts
class DiscountDialog extends StatefulWidget {
  final double amount; // Current amount to calculate preview
  final String title; // "Cart Discount" or "Item Discount"

  const DiscountDialog({
    super.key,
    required this.amount,
    this.title = 'Apply Discount',
  });

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  DiscountType _selectedType = DiscountType.percentage;
  final _valueController = TextEditingController();
  final _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double get _discountAmount {
    final value = double.tryParse(_valueController.text) ?? 0;
    if (_selectedType == DiscountType.percentage) {
      return widget.amount * (value / 100);
    } else {
      return value > widget.amount ? widget.amount : value;
    }
  }

  double get _finalAmount {
    return widget.amount - _discountAmount;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Discount Type Selection
              Text(
                'Discount Type',
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(
                    value: DiscountType.percentage,
                    label: Text('Percentage'),
                    icon: Icon(Icons.percent),
                  ),
                  ButtonSegment(
                    value: DiscountType.fixed,
                    label: Text('Fixed'),
                    icon: Icon(Icons.attach_money),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<DiscountType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    _valueController.clear();
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Discount Value Input
              TextFormField(
                controller: _valueController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: _selectedType == DiscountType.percentage
                      ? 'Percentage (%)'
                      : 'Amount (\$)',
                  prefixIcon: Icon(
                    _selectedType == DiscountType.percentage
                        ? Icons.percent
                        : Icons.attach_money,
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a value';
                  }
                  final numValue = double.tryParse(value);
                  if (numValue == null || numValue <= 0) {
                    return 'Please enter a valid positive number';
                  }
                  if (_selectedType == DiscountType.percentage && numValue > 100) {
                    return 'Percentage cannot exceed 100%';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {}), // Refresh preview
              ),
              const SizedBox(height: AppSpacing.md),

              // Reason Input (Optional)
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (Optional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Loyalty discount, Promotion',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Preview Card
              if (_valueController.text.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preview',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Original:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Text(
                            '\$${widget.amount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discount:',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          Text(
                            '-\$${_discountAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Final:',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$${_finalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final discount = Discount(
                type: _selectedType,
                scope: DiscountScope.cart, // Will be set by caller
                value: double.parse(_valueController.text),
                reason: _reasonController.text.isEmpty
                    ? null
                    : _reasonController.text,
              );
              Navigator.pop(context, discount);
            }
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
