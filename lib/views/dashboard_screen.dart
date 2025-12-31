import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/journal_view_model.dart';
import '../view_models/product_view_model.dart';
import '../view_models/customer_view_model.dart';
import '../services/notification_service.dart';
import '../widgets/buttons/quick_action_button.dart';
import '../widgets/dashboard/sales_metrics_grid.dart';
import '../widgets/dashboard/trending_products_carousel.dart';
import '../widgets/dashboard/low_stock_alert.dart';
import '../widgets/dashboard/reports_section.dart';
import '../widgets/dashboard/customer_stats_card.dart';
import '../widgets/common/spacing.dart';
import '../theme/app_spacing.dart';
import '../services/report_service.dart';
import 'purchase_screen.dart';
import 'pos_screen.dart';
import 'global_unit_manager_screen.dart';
import 'sale_history_screen.dart';
import 'purchase_history_screen.dart';
import 'sales_report_screen.dart';
import 'inventory_report_screen.dart';
import 'financial_report_screen.dart';
import 'stock_adjustment_history_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';
import 'help_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ReportService _reportService = ReportService();
  final NotificationService _notificationService = NotificationService();
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    // Refresh data when dashboard opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<JournalViewModel>().fetchEntries();
      context.read<ProductViewModel>().fetchProducts();
      context.read<CustomerViewModel>().fetchCustomers();
      _loadLowStockCount();
      _checkLowStockAndNotify();
    });
  }

  Future<void> _loadLowStockCount() async {
    final count = await _reportService.getLowStockCount();
    if (mounted) {
      setState(() => _lowStockCount = count);
    }
  }

  Future<void> _checkLowStockAndNotify() async {
    // Check for low stock and send notification if needed
    await _notificationService.checkLowStockAndNotify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Sales History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SaleHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long),
            tooltip: 'Purchase History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (String value) {
              switch (value) {
                case 'settings':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  break;
                case 'backup':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BackupScreen()),
                  );
                  break;
                case 'help':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HelpScreen()),
                  );
                  break;
                case 'units':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GlobalUnitManagerScreen()),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'backup',
                child: Row(
                  children: [
                    Icon(Icons.backup),
                    SizedBox(width: 12),
                    Text('Backup & Restore'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline),
                    SizedBox(width: 12),
                    Text('Help'),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'units',
                child: Row(
                  children: [
                    Icon(Icons.straighten),
                    SizedBox(width: 12),
                    Text('Manage Units'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Low Stock Alert
            LowStockAlert(
              lowStockCount: _lowStockCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryReportScreen()),
                );
              },
            ),
            if (_lowStockCount > 0) const VerticalSpace.lg(),

            // Quick Actions
            Row(
              children: [
                Expanded(
                  child: QuickActionButton(
                    label: 'New Sale',
                    icon: Icons.point_of_sale,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const POSScreen()),
                      );
                    },
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                ),
                const HorizontalSpace.lg(),
                Expanded(
                  child: QuickActionButton(
                    label: 'Purchase Stock',
                    icon: Icons.shopping_cart_checkout,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PurchaseScreen()),
                      );
                    },
                    backgroundColor: theme.colorScheme.tertiary,
                    foregroundColor: theme.colorScheme.onTertiary,
                  ),
                ),
              ],
            ),
            const VerticalSpace.xl(),

            // Sales Overview Section
            Text(
              'Sales Overview',
              style: theme.textTheme.headlineSmall,
            ),
            const VerticalSpace.lg(),
            Consumer<JournalViewModel>(
              builder: (context, viewModel, child) {
                return SalesMetricsGrid(viewModel: viewModel);
              },
            ),
            const VerticalSpace.xxl(),

            // Customer Stats Section
            Text(
              'Customer Insights',
              style: theme.textTheme.headlineSmall,
            ),
            const VerticalSpace.lg(),
            const CustomerStatsCard(),
            const VerticalSpace.xxl(),

            // Reports Section
            ReportsSection(
              onSalesReportTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesReportScreen()),
                );
              },
              onInventoryReportTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryReportScreen()),
                );
              },
              onFinancialReportTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FinancialReportScreen()),
                );
              },
              onAdjustmentHistoryTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockAdjustmentHistoryScreen()),
                );
              },
            ),
            const VerticalSpace.xxl(),

            // Trending Products Section
            Text(
              'Trending Products',
              style: theme.textTheme.headlineSmall,
            ),
            const VerticalSpace.lg(),
            TrendingProductsCarousel(
              productsFuture: context.read<ProductViewModel>().fetchTrendingProducts(),
            ),
          ],
        ),
      ),
    );
  }
}
