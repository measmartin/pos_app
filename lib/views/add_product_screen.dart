import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../view_models/product_view_model.dart';
import '../view_models/unit_view_model.dart';
import '../services/barcode_service.dart';
import '../widgets/product/image_picker_avatar.dart';
import '../widgets/forms/custom_text_field.dart';
import '../widgets/forms/currency_text_field.dart';
import '../widgets/forms/barcode_field.dart';
import '../widgets/common/spacing.dart';
import '../theme/app_spacing.dart';
import '../screens/simple_scanner_screen.dart';
import 'unit_management_screen.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _barcodeService = BarcodeService();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;
  dynamic _imageFile;
  bool _autoGenerateBarcode = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _costPriceController = TextEditingController(text: widget.product?.costPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');
    _unitController = TextEditingController(text: widget.product?.unit ?? 'pcs');
    if (widget.product?.imagePath != null) {
      _imageFile = widget.product!.imagePath!;
    }
    
    // Fetch unique units
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UnitViewModel>().fetchBaseUnits();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
    );
    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
        _autoGenerateBarcode = false; // Disable auto-generate when manually scanned
      });
    }
  }

  Future<void> _generateBarcode() async {
    final productViewModel = context.read<ProductViewModel>();
    
    // Get the highest product ID to generate a unique barcode
    int maxId = 0;
    if (productViewModel.products.isNotEmpty) {
      maxId = productViewModel.products
          .map((p) => p.id ?? 0)
          .reduce((a, b) => a > b ? a : b);
    }
    
    // Generate a unique barcode
    final barcode = _barcodeService.generateBarcode(maxId + 1);
    
    setState(() {
      _barcodeController.text = barcode;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated barcode: ${_barcodeService.formatBarcode(barcode)}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      // Auto-generate barcode if enabled and barcode is empty
      String barcode = _barcodeController.text.trim();
      if (_autoGenerateBarcode && barcode.isEmpty) {
        final productViewModel = context.read<ProductViewModel>();
        int maxId = 0;
        if (productViewModel.products.isNotEmpty) {
          maxId = productViewModel.products
              .map((p) => p.id ?? 0)
              .reduce((a, b) => a > b ? a : b);
        }
        barcode = _barcodeService.generateBarcode(maxId + 1);
      }

      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        barcode: barcode,
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        unit: _unitController.text,
        imagePath: _imageFile?.path,
      );

      if (widget.product == null) {
        await context.read<ProductViewModel>().addProduct(product);
      } else {
        await context.read<ProductViewModel>().updateProduct(product);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                ImagePickerAvatar(
                  initialImage: _imageFile,
                  onImageChanged: (file) {
                    setState(() {
                      _imageFile = file;
                    });
                  },
                  radius: 50,
                ),
                const VerticalSpace.lg(),
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Product Name',
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const VerticalSpace.lg(),
                BarcodeField(
                  controller: _barcodeController,
                  onScan: _scanBarcode,
                ),
                const VerticalSpace.sm(),
                
                // Barcode generation options
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Auto-generate barcode',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Generate if not provided',
                          style: TextStyle(fontSize: 12),
                        ),
                        value: _autoGenerateBarcode,
                        onChanged: widget.product == null 
                            ? (value) => setState(() => _autoGenerateBarcode = value ?? false)
                            : null, // Disable for existing products
                        dense: true,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: widget.product == null ? _generateBarcode : null,
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: const Text('Generate'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Display validation info if barcode exists
                if (_barcodeController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Row(
                      children: [
                        Icon(
                          _barcodeService.validateEan13(_barcodeController.text)
                              ? Icons.check_circle
                              : Icons.info,
                          size: 16,
                          color: _barcodeService.validateEan13(_barcodeController.text)
                              ? Colors.green
                              : Colors.orange,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            _barcodeService.isInternallyGenerated(_barcodeController.text)
                                ? 'System-generated barcode'
                                : _barcodeService.validateEan13(_barcodeController.text)
                                    ? 'Valid EAN-13 barcode'
                                    : 'Custom barcode format',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const VerticalSpace.lg(),
                Row(
                  children: [
                    Expanded(
                      child: CurrencyTextField(
                        controller: _costPriceController,
                        labelText: 'Cost Price',
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const HorizontalSpace.lg(),
                    Expanded(
                      child: CurrencyTextField(
                        controller: _sellingPriceController,
                        labelText: 'Selling Price',
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const VerticalSpace.lg(),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _stockController,
                        labelText: 'Stock Quantity',
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const HorizontalSpace.lg(),
                    Expanded(
                      child: Consumer<UnitViewModel>(
                        builder: (context, vm, child) {
                          return DropdownMenu<String>(
                            controller: _unitController,
                            label: const Text('Unit'),
                            width: 150,
                            dropdownMenuEntries: vm.baseUnits.map((String unit) {
                              return DropdownMenuEntry<String>(
                                value: unit,
                                label: unit,
                              );
                            }).toList(),
                            enableSearch: true,
                            requestFocusOnTap: true,
                          );
                        }
                      ),
                    ),
                  ],
                ),
                const VerticalSpace.xl(),
                
                // Only show "Manage Units" if editing an existing product
                if (widget.product != null)
                  OutlinedButton.icon(
                    onPressed: () {
                       Navigator.push(
                         context, 
                         MaterialPageRoute(builder: (_) => UnitManagementScreen(product: widget.product!))
                       );
                    }, 
                    icon: const Icon(Icons.category), 
                    label: const Text('Manage Additional Units (Packs, Boxes)'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
