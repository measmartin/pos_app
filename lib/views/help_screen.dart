import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Documentation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HelpSection(
            title: 'Getting Started',
            icon: Icons.rocket_launch,
            items: [
              _HelpItem(
                title: 'Welcome to POS App',
                content: 'This Point of Sale application helps you manage your shop efficiently. '
                    'Start by adding products, then process sales through the POS screen.',
              ),
              _HelpItem(
                title: 'First Steps',
                content: '1. Add your business information in Settings\n'
                    '2. Add products to your inventory\n'
                    '3. Add customers (optional)\n'
                    '4. Start selling through the POS screen',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HelpSection(
            title: 'Products',
            icon: Icons.inventory_2,
            items: [
              _HelpItem(
                title: 'Adding Products',
                content: 'Go to the Products tab and tap the + button. '
                    'Enter product details including name, barcode, prices, and stock quantity. '
                    'You can also add product images.',
              ),
              _HelpItem(
                title: 'Multi-Unit Support',
                content: 'Products can have multiple units (e.g., box, pack, case). '
                    'Add units in the product details screen. Each unit can have its own selling price.',
              ),
              _HelpItem(
                title: 'Stock Adjustments',
                content: 'Adjust stock quantities through the product details screen. '
                    'Select a reason (damaged, expired, etc.) and add notes if needed.',
              ),
              _HelpItem(
                title: 'Low Stock Alerts',
                content: 'The app automatically tracks low stock items. '
                    'Configure the threshold in Settings. You\'ll see alerts on the dashboard.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HelpSection(
            title: 'Point of Sale (POS)',
            icon: Icons.point_of_sale,
            items: [
              _HelpItem(
                title: 'Processing Sales',
                content: '1. Search for products by name or scan barcode\n'
                    '2. Select quantity and unit\n'
                    '3. Add items to cart\n'
                    '4. Apply discounts if needed\n'
                    '5. Select customer (optional)\n'
                    '6. Checkout and process payment',
              ),
              _HelpItem(
                title: 'Keyboard Shortcuts',
                content: 'Press F1 on the POS screen to see all available shortcuts. '
                    'Key shortcuts include:\n'
                    '• F2: Focus search\n'
                    '• F4: Select customer\n'
                    '• F5: Hold transaction\n'
                    '• F12: Checkout',
                actions: [
                  TextButton.icon(
                    icon: const Icon(Icons.keyboard),
                    label: const Text('View All Shortcuts'),
                    onPressed: () => _showKeyboardShortcuts(context),
                  ),
                ],
              ),
              _HelpItem(
                title: 'Discounts',
                content: 'Apply discounts to individual items or the entire cart. '
                    'Supports both percentage and fixed amount discounts. '
                    'Add a reason for tracking purposes.',
              ),
              _HelpItem(
                title: 'Multi-Payment',
                content: 'Split payments across multiple methods (cash, card, mobile, bank transfer). '
                    'The system automatically calculates the remaining amount.',
              ),
              _HelpItem(
                title: 'Hold & Recall',
                content: 'Park transactions using F5 to serve other customers. '
                    'Recall held transactions anytime using F6.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HelpSection(
            title: 'Customers',
            icon: Icons.people,
            items: [
              _HelpItem(
                title: 'Customer Management',
                content: 'Add customers with contact information to track purchases and loyalty points. '
                    'View customer statistics including total spent and purchase history.',
              ),
              _HelpItem(
                title: 'Loyalty Program',
                content: 'Customers earn 1% of purchase amount as loyalty points. '
                    'Points are awarded after each completed transaction. '
                    'Customer tiers: Bronze (0-999), Silver (1000-4999), Gold (5000-9999), Platinum (10000+)',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HelpSection(
            title: 'Reports',
            icon: Icons.assessment,
            items: [
              _HelpItem(
                title: 'Sales Reports',
                content: 'View sales by day, week, or month. '
                    'See trends, top products, and revenue analysis. '
                    'Export reports for further analysis.',
              ),
              _HelpItem(
                title: 'Inventory Reports',
                content: 'Monitor stock levels, view low stock items, '
                    'and track stock movements. Generate inventory valuation reports.',
              ),
              _HelpItem(
                title: 'Financial Reports',
                content: 'Access Profit & Loss statements and Balance Sheets. '
                    'The app uses double-entry bookkeeping for accurate financial tracking.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HelpSection(
            title: 'Backup & Settings',
            icon: Icons.settings,
            items: [
              _HelpItem(
                title: 'Creating Backups',
                content: 'Regular backups are essential! Go to Dashboard > Menu > Backup & Restore. '
                    'Create backups and share them to cloud storage. '
                    'Backups include all data except app settings.',
              ),
              _HelpItem(
                title: 'Restoring Data',
                content: 'Import backup files to restore your data. '
                    'This will replace current data, so create a backup first if needed.',
              ),
              _HelpItem(
                title: 'App Settings',
                content: 'Configure business information, tax rates, currency symbol, '
                    'receipt messages, and app features in Settings.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _HelpSection(
            title: 'Returns & Refunds',
            icon: Icons.keyboard_return,
            items: [
              _HelpItem(
                title: 'Processing Returns',
                content: 'Go to Returns screen to process customer returns. '
                    'Search for the sale, select items to return, and enter reason. '
                    'Stock is automatically restored.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.help_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need More Help?',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Explore the app to discover more features. Most screens have tooltips and hints to guide you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showKeyboardShortcuts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keyboard Shortcuts'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('These shortcuts are available on the POS screen:'),
              const SizedBox(height: 16),
              _buildShortcutRow('F1', 'Show keyboard shortcuts'),
              _buildShortcutRow('F2', 'Focus search field'),
              _buildShortcutRow('F3', 'Scan barcode'),
              _buildShortcutRow('F4', 'Select customer'),
              _buildShortcutRow('F5', 'Hold transaction'),
              _buildShortcutRow('F6', 'Recall held transaction'),
              _buildShortcutRow('F9', 'Clear cart'),
              _buildShortcutRow('F12', 'Checkout'),
              _buildShortcutRow('Ctrl+D', 'Apply cart discount'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String key, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              key,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_HelpItem> items;

  const _HelpSection({
    required this.title,
    required this.icon,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: item,
        )),
      ],
    );
  }
}

class _HelpItem extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget>? actions;

  const _HelpItem({
    required this.title,
    required this.content,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actions != null && actions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
