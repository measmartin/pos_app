import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// A simple barcode scanner screen.
///
/// This screen uses the mobile_scanner package to scan barcodes.
/// Returns the scanned barcode value when a code is detected.
///
/// Example:
/// ```dart
/// final result = await Navigator.push(
///   context,
///   MaterialPageRoute(builder: (_) => const SimpleScannerScreen()),
/// );
/// if (result != null) {
///   print('Scanned: $result');
/// }
/// ```
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
