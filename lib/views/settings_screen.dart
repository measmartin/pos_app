import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_settings.dart';
import '../view_models/settings_view_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  late TextEditingController _businessNameController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessPhoneController;
  late TextEditingController _businessEmailController;
  late TextEditingController _taxIdController;
  late TextEditingController _taxRateController;
  late TextEditingController _currencySymbolController;
  late TextEditingController _receiptHeaderController;
  late TextEditingController _receiptFooterController;
  late TextEditingController _lowStockThresholdController;
  
  // Boolean values
  bool _enableLoyaltyProgram = true;
  bool _enableLowStockAlerts = true;
  bool _printReceiptAutomatically = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _businessNameController = TextEditingController();
    _businessAddressController = TextEditingController();
    _businessPhoneController = TextEditingController();
    _businessEmailController = TextEditingController();
    _taxIdController = TextEditingController();
    _taxRateController = TextEditingController();
    _currencySymbolController = TextEditingController();
    _receiptHeaderController = TextEditingController();
    _receiptFooterController = TextEditingController();
    _lowStockThresholdController = TextEditingController();
    
    // Load settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    final viewModel = context.read<SettingsViewModel>();
    await viewModel.loadSettings();
    
    if (viewModel.settings != null) {
      _populateForm(viewModel.settings!);
    }
  }

  void _populateForm(AppSettings settings) {
    _businessNameController.text = settings.businessName;
    _businessAddressController.text = settings.businessAddress;
    _businessPhoneController.text = settings.businessPhone;
    _businessEmailController.text = settings.businessEmail;
    _taxIdController.text = settings.taxId;
    _taxRateController.text = settings.taxRate.toString();
    _currencySymbolController.text = settings.currencySymbol;
    _receiptHeaderController.text = settings.receiptHeader;
    _receiptFooterController.text = settings.receiptFooter;
    _lowStockThresholdController.text = settings.lowStockThreshold.toString();
    
    setState(() {
      _enableLoyaltyProgram = settings.enableLoyaltyProgram;
      _enableLowStockAlerts = settings.enableLowStockAlerts;
      _printReceiptAutomatically = settings.printReceiptAutomatically;
    });
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final newSettings = AppSettings(
      businessName: _businessNameController.text.trim(),
      businessAddress: _businessAddressController.text.trim(),
      businessPhone: _businessPhoneController.text.trim(),
      businessEmail: _businessEmailController.text.trim(),
      taxId: _taxIdController.text.trim(),
      taxRate: double.tryParse(_taxRateController.text) ?? 0.0,
      currencySymbol: _currencySymbolController.text.trim(),
      receiptHeader: _receiptHeaderController.text.trim(),
      receiptFooter: _receiptFooterController.text.trim(),
      enableLoyaltyProgram: _enableLoyaltyProgram,
      enableLowStockAlerts: _enableLowStockAlerts,
      lowStockThreshold: int.tryParse(_lowStockThresholdController.text) ?? 10,
      printReceiptAutomatically: _printReceiptAutomatically,
    );

    final viewModel = context.read<SettingsViewModel>();
    final success = await viewModel.saveSettings(newSettings);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.error ?? 'Failed to save settings'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _taxIdController.dispose();
    _taxRateController.dispose();
    _currencySymbolController.dispose();
    _receiptHeaderController.dispose();
    _receiptFooterController.dispose();
    _lowStockThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: Consumer<SettingsViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.settings == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBusinessInfoSection(),
                const SizedBox(height: 24),
                _buildTaxSection(),
                const SizedBox(height: 24),
                _buildReceiptSection(),
                const SizedBox(height: 24),
                _buildFeaturesSection(),
                const SizedBox(height: 24),
                _buildSaveButton(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessAddressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value)) {
                    return 'Enter a valid email';
                  }
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tax Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(
                labelText: 'Tax ID / Registration Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.receipt_long),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxRateController,
              decoration: const InputDecoration(
                labelText: 'Tax Rate (%)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.percent),
                hintText: '0.0',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final rate = double.tryParse(value);
                  if (rate == null || rate < 0 || rate > 100) {
                    return 'Enter a valid tax rate (0-100)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _currencySymbolController,
              decoration: const InputDecoration(
                labelText: 'Currency Symbol',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
                hintText: '\$',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Currency symbol is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Receipt Configuration',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _receiptHeaderController,
              decoration: const InputDecoration(
                labelText: 'Receipt Header Message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
                hintText: 'Thank you for your purchase!',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _receiptFooterController,
              decoration: const InputDecoration(
                labelText: 'Receipt Footer Message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.text_fields),
                hintText: 'Please come again',
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Features & Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Loyalty Program'),
              subtitle: const Text('Track customer loyalty points'),
              value: _enableLoyaltyProgram,
              onChanged: (value) {
                setState(() {
                  _enableLoyaltyProgram = value;
                });
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable Low Stock Alerts'),
              subtitle: const Text('Get notified when stock is low'),
              value: _enableLowStockAlerts,
              onChanged: (value) {
                setState(() {
                  _enableLowStockAlerts = value;
                });
              },
            ),
            if (_enableLowStockAlerts) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  controller: _lowStockThresholdController,
                  decoration: const InputDecoration(
                    labelText: 'Low Stock Threshold',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory_2),
                    hintText: '10',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Threshold is required';
                    }
                    final threshold = int.tryParse(value);
                    if (threshold == null || threshold < 1) {
                      return 'Enter a valid threshold (minimum 1)';
                    }
                    return null;
                  },
                ),
              ),
            ],
            const Divider(),
            SwitchListTile(
              title: const Text('Auto-print Receipts'),
              subtitle: const Text('Automatically print after checkout'),
              value: _printReceiptAutomatically,
              onChanged: (value) {
                setState(() {
                  _printReceiptAutomatically = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: FilledButton.icon(
        onPressed: _saveSettings,
        icon: const Icon(Icons.save),
        label: const Text('Save Settings'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }
}
