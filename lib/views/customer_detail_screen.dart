import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../view_models/customer_view_model.dart';
import '../services/database_service.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/dialogs/confirmation_dialog.dart';
import '../theme/app_spacing.dart';
import 'add_customer_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final Customer customer;

  const CustomerDetailScreen({
    super.key,
    required this.customer,
  });

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  late Customer _customer;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    // Refresh customer data
    final customerViewModel = context.read<CustomerViewModel>();
    final freshCustomer = await customerViewModel.getCustomer(_customer.id!);
    if (freshCustomer != null) {
      _customer = freshCustomer;
    }

    // Load transaction history
    await _loadTransactions();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadTransactions() async {
    final db = await DatabaseService().database;
    
    // Get all sales for this customer with product details
    final result = await db.rawQuery('''
      SELECT 
        s.date,
        s.selling_price,
        s.quantity,
        p.name as product_name,
        p.unit
      FROM sale_items s
      JOIN products p ON s.product_id = p.id
      WHERE s.customer_id = ? AND s.is_deleted = 0
      ORDER BY s.date DESC
    ''', [_customer.id]);

    setState(() {
      _transactions = result;
    });
  }

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupTransactionsByDate() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    
    for (var transaction in _transactions) {
      final date = transaction['date'] as String;
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(transaction);
    }
    
    return grouped;
  }

  Future<void> _editCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddCustomerScreen(customer: _customer),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _deleteCustomer() async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Customer',
      message: 'Are you sure you want to delete ${_customer.name}? This will mark the customer as inactive.',
      confirmText: 'Delete',
      icon: Icons.person_off_outlined,
      isDestructive: true,
    );

    if (confirmed && mounted) {
      final viewModel = context.read<CustomerViewModel>();
      final success = await viewModel.deleteCustomer(_customer.id!);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete customer'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Color _getTierColor(CustomerTier tier) {
    switch (tier) {
      case CustomerTier.bronze:
        return Colors.brown;
      case CustomerTier.silver:
        return Colors.grey;
      case CustomerTier.gold:
        return Colors.amber;
      case CustomerTier.platinum:
        return Colors.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, y');
    final groupedTransactions = _groupTransactionsByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCustomer,
            tooltip: 'Edit Customer',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteCustomer,
            tooltip: 'Delete Customer',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Customer Header
                    Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: _getTierColor(_customer.tier).withValues(alpha: 0.2),
                            child: Text(
                              _customer.initials,
                              style: theme.textTheme.displaySmall?.copyWith(
                                color: _getTierColor(_customer.tier),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _customer.name,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: _getTierColor(_customer.tier).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_customer.tier.displayName} • ${_customer.tier.description}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: _getTierColor(_customer.tier),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Stats Cards
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.shopping_bag,
                            label: 'Total Spent',
                            value: '\$${_customer.totalSpent.toStringAsFixed(2)}',
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.stars,
                            label: 'Loyalty Points',
                            value: _customer.loyaltyPoints.toStringAsFixed(0),
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Contact Information
                    Text(
                      'Contact Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          children: [
                            if (_customer.hasPhone)
                              _InfoRow(
                                icon: Icons.phone,
                                label: 'Phone',
                                value: _customer.formattedPhone,
                              ),
                            if (_customer.hasEmail) ...[
                              if (_customer.hasPhone) const Divider(),
                              _InfoRow(
                                icon: Icons.email,
                                label: 'Email',
                                value: _customer.email!,
                              ),
                            ],
                            if (_customer.address != null && _customer.address!.isNotEmpty) ...[
                              if (_customer.hasPhone || _customer.hasEmail) const Divider(),
                              _InfoRow(
                                icon: Icons.location_on,
                                label: 'Address',
                                value: _customer.address!,
                              ),
                            ],
                            if (_customer.notes != null && _customer.notes!.isNotEmpty) ...[
                              const Divider(),
                              _InfoRow(
                                icon: Icons.note,
                                label: 'Notes',
                                value: _customer.notes!,
                              ),
                            ],
                            const Divider(),
                            _InfoRow(
                              icon: Icons.calendar_today,
                              label: 'Member Since',
                              value: dateFormat.format(_customer.createdAt),
                            ),
                            if (_customer.lastPurchaseDate != null) ...[
                              const Divider(),
                              _InfoRow(
                                icon: Icons.shopping_cart,
                                label: 'Last Purchase',
                                value: dateFormat.format(_customer.lastPurchaseDate!),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Transaction History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Transaction History',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_transactions.length} items',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    if (groupedTransactions.isEmpty)
                      const EmptyState(
                        icon: Icons.receipt_long,
                        message: 'No transactions yet',
                      )
                    else
                      ...groupedTransactions.entries.map((entry) {
                        final date = DateTime.parse(entry.key);
                        final items = entry.value;
                        final total = items.fold<double>(
                          0,
                          (sum, item) =>
                              sum +
                              ((item['selling_price'] as num).toDouble() *
                                  (item['quantity'] as int)),
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TransactionGroupHeader(
                              date: date,
                              total: total,
                              itemCount: items.length,
                            ),
                            ...items.map((item) => _TransactionItem(item: item)),
                            const SizedBox(height: AppSpacing.md),
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionGroupHeader extends StatelessWidget {
  final DateTime date;
  final double total;
  final int itemCount;

  const _TransactionGroupHeader({
    required this.date,
    required this.total,
    required this.itemCount,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d, y');
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateFormat.format(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
              ),
              Text(
                '$itemCount item${itemCount > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionItem extends StatelessWidget {
  final Map<String, dynamic> item;

  const _TransactionItem({required this.item});

  @override
  Widget build(BuildContext context) {
    final productName = item['product_name'] as String;
    final quantity = item['quantity'] as int;
    final unit = item['unit'] as String;
    final sellingPrice = (item['selling_price'] as num).toDouble();
    final subtotal = sellingPrice * quantity;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      leading: CircleAvatar(
        child: Text('$quantity'),
      ),
      title: Text(productName),
      subtitle: Text('$quantity $unit × \$${sellingPrice.toStringAsFixed(2)}'),
      trailing: Text(
        '\$${subtotal.toStringAsFixed(2)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
