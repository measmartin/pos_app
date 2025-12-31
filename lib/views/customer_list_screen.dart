import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/customer.dart';
import '../view_models/customer_view_model.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/forms/search_field.dart';
import '../theme/app_spacing.dart';
import 'add_customer_screen.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    await Provider.of<CustomerViewModel>(context, listen: false).fetchCustomers();
    setState(() => _isLoading = false);
  }

  void _navigateToAddCustomer() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddCustomerScreen(),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      _loadCustomers();
    }
  }

  void _navigateToCustomerDetail(Customer customer) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerDetailScreen(customer: customer),
      ),
    );

    if (result == true) {
      _loadCustomers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Consumer<CustomerViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.inactiveCustomers > 0) {
                return IconButton(
                  icon: Icon(
                    viewModel.showInactiveCustomers
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: viewModel.toggleShowInactive,
                  tooltip: viewModel.showInactiveCustomers
                      ? 'Hide Inactive'
                      : 'Show Inactive',
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SearchField(
              controller: _searchController,
              hintText: 'Search by name, phone, or email...',
              onChanged: (query) {
                context.read<CustomerViewModel>().searchCustomers(query);
              },
            ),
          ),

          // Customer Stats
          Consumer<CustomerViewModel>(
            builder: (context, viewModel, child) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      context,
                      'Total',
                      '${viewModel.totalCustomers}',
                      Icons.people,
                    ),
                    if (viewModel.showInactiveCustomers)
                      _buildStatItem(
                        context,
                        'Inactive',
                        '${viewModel.inactiveCustomers}',
                        Icons.person_off,
                        color: Colors.orange,
                      ),
                  ],
                ),
              );
            },
          ),

          // Customer List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Consumer<CustomerViewModel>(
                    builder: (context, viewModel, child) {
                      if (viewModel.filteredCustomers.isEmpty) {
                        return EmptyState(
                          icon: Icons.people_outline,
                          message: viewModel.searchQuery.isNotEmpty
                              ? 'No customers found matching "${viewModel.searchQuery}"'
                              : 'No customers yet',
                          actionLabel: viewModel.searchQuery.isEmpty ? 'Add Customer' : null,
                          onAction: viewModel.searchQuery.isEmpty ? _navigateToAddCustomer : null,
                        );
                      }

                      return RefreshIndicator(
                        onRefresh: _loadCustomers,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: viewModel.filteredCustomers.length,
                          itemBuilder: (context, index) {
                            final customer = viewModel.filteredCustomers[index];
                            return _CustomerCard(
                              customer: customer,
                              onTap: () => _navigateToCustomerDetail(customer),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddCustomer,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Customer'),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerCard({
    required this.customer,
    required this.onTap,
  });

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

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 28,
                backgroundColor: _getTierColor(customer.tier).withValues(alpha: 0.2),
                child: Text(
                  customer.initials,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: _getTierColor(customer.tier),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.md),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and Tier
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            customer.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: customer.isActive
                                  ? null
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getTierColor(customer.tier).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            customer.tier.displayName,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: _getTierColor(customer.tier),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Contact Info
                    if (customer.hasPhone)
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            customer.formattedPhone,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),

                    if (customer.hasEmail)
                      Row(
                        children: [
                          Icon(
                            Icons.email,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              customer.email!,
                              style: theme.textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: AppSpacing.xs),

                    // Stats
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '\$${customer.totalSpent.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(
                          Icons.stars,
                          size: 14,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${customer.loyaltyPoints.toStringAsFixed(0)} pts',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ],
                    ),

                    // Last purchase
                    if (customer.lastPurchaseDate != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Last purchase: ${dateFormat.format(customer.lastPurchaseDate!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // Inactive badge
                    if (!customer.isActive) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'INACTIVE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow icon
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
