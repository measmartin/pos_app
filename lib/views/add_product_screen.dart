import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/product.dart';
import '../view_models/product_view_model.dart';
import '../view_models/unit_view_model.dart';
import 'unit_management_screen.dart'; // Import Unit Management Screen

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _stockController;
  late TextEditingController _unitController;
  File? _imageFile;

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
      _imageFile = File(widget.product!.imagePath!);
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      
      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  void _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleScannerScreen()),
    );
    if (result != null && result is String) {
      setState(() {
        _barcodeController.text = result;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        barcode: _barcodeController.text,
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
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? Icon(Icons.add_a_photo, size: 30, color: Theme.of(context).colorScheme.onSurfaceVariant)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(
                          labelText: 'Barcode',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Cost Price',
                          border: OutlineInputBorder(),
                          filled: true,
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Selling Price',
                          border: OutlineInputBorder(),
                          filled: true,
                          prefixText: '\$ ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Consumer<UnitViewModel>(
                        builder: (context, vm, child) {
                          return DropdownMenu<String>(
                            controller: _unitController,
                            label: const Text('Unit'),
                            width: 150, // Should handle width nicely or wrap in flexible
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
                const SizedBox(height: 24),
                
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

class SimpleScannerScreen extends StatelessWidget {
  const SimpleScannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              Navigator.pop(context, barcode.rawValue);
              break; // Return first detected
            }
          }
        },
      ),
    );
  }
}
