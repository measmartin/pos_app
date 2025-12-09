import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../view_models/product_view_model.dart';

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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _costPriceController = TextEditingController(text: widget.product?.costPrice.toString() ?? '');
    _sellingPriceController = TextEditingController(text: widget.product?.sellingPrice.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stockQuantity.toString() ?? '');
    _unitController = TextEditingController(text: widget.product?.unit ?? 'pcs');
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
      });
    }
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        barcode: _barcodeController.text,
        costPrice: double.tryParse(_costPriceController.text) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0.0,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        unit: _unitController.text,
      );

      if (widget.product == null) {
        context.read<ProductViewModel>().addProduct(product);
      } else {
        context.read<ProductViewModel>().updateProduct(product);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _barcodeController,
                        decoration: const InputDecoration(labelText: 'Barcode'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.qr_code_scanner),
                      onPressed: _scanBarcode,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        decoration: const InputDecoration(labelText: 'Cost Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        decoration: const InputDecoration(labelText: 'Selling Price'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: const InputDecoration(labelText: 'Stock Quantity'),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _unitController,
                        decoration: const InputDecoration(labelText: 'Unit (e.g., pcs, kg)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProduct,
                  child: const Text('Save Product'),
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
