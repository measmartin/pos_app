import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_radius.dart';

/// Dialog for processing checkout with multiple payment methods
class PaymentDialog extends StatefulWidget {
  final double totalAmount;

  const PaymentDialog({
    super.key,
    required this.totalAmount,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final List<Payment> _payments = [];
  PaymentMethodType _selectedMethod = PaymentMethodType.cash;
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  double get _totalPaid => _payments.fold(0, (sum, p) => sum + p.amount);
  double get _remaining => widget.totalAmount - _totalPaid;
  bool get _isFullyPaid => _remaining <= 0;

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  void _addPayment() {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text);
      final payment = Payment(
        method: _selectedMethod,
        amount: amount,
        reference: _referenceController.text.isEmpty ? null : _referenceController.text,
      );

      setState(() {
        _payments.add(payment);
        _amountController.clear();
        _referenceController.clear();
        
        // If fully paid, auto-set next payment to exact remaining
        if (_remaining > 0) {
          _amountController.text = _remaining.toStringAsFixed(2);
        }
      });
    }
  }

  void _removePayment(int index) {
    setState(() {
      _payments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Process Payment'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Amount Summary
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount:',
                            style: theme.textTheme.titleMedium,
                          ),
                          Text(
                            '\$${widget.totalAmount.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      if (_payments.isNotEmpty) ...[
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Paid:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            Text(
                              '\$${_totalPaid.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _remaining >= 0 ? 'Remaining:' : 'Change:',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${_remaining.abs().toStringAsFixed(2)}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: _remaining >= 0 ? theme.colorScheme.error : Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Existing Payments
                if (_payments.isNotEmpty) ...[
                  Text(
                    'Payments:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return Card(
                        child: ListTile(
                          dense: true,
                          leading: Text(payment.methodIcon, style: const TextStyle(fontSize: 24)),
                          title: Text(payment.methodName),
                          subtitle: payment.reference != null
                              ? Text('Ref: ${payment.reference}')
                              : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '\$${payment.amount.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                onPressed: () => _removePayment(index),
                                tooltip: 'Remove',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                // Add Payment Form (only show if not fully paid)
                if (!_isFullyPaid) ...[
                  Text(
                    'Add Payment:',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Payment Method Selection
                  DropdownButtonFormField<PaymentMethodType>(
                    initialValue: _selectedMethod,
                    decoration: const InputDecoration(
                      labelText: 'Payment Method',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment),
                    ),
                    items: PaymentMethodType.values.map((method) {
                      final payment = Payment(method: method, amount: 0);
                      return DropdownMenuItem(
                        value: method,
                        child: Row(
                          children: [
                            Text(payment.methodIcon, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: AppSpacing.sm),
                            Text(payment.methodName),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedMethod = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Amount Input
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.attach_money),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.auto_fix_high),
                        onPressed: () {
                          _amountController.text = _remaining.toStringAsFixed(2);
                        },
                        tooltip: 'Exact Amount',
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter amount';
                      }
                      final num = double.tryParse(value);
                      if (num == null || num <= 0) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Reference Input (Optional)
                  TextFormField(
                    controller: _referenceController,
                    decoration: const InputDecoration(
                      labelText: 'Reference (Optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.tag),
                      hintText: 'Check #, Card last 4, etc.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Add Payment Button
                  FilledButton.icon(
                    onPressed: _addPayment,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isFullyPaid
              ? () => Navigator.pop(context, _payments)
              : null,
          child: const Text('Complete'),
        ),
      ],
    );
  }
}
