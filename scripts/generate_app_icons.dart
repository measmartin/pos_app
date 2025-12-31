import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('🎨 Generating POS App Icons...\n');

  // Generate main icon (512x512)
  await generateMainIcon();
  
  // Generate foreground icon for adaptive (432x432)
  await generateForegroundIcon();
  
  print('\n✅ Icons generated successfully!');
  print('\nNext step: Run "dart run flutter_launcher_icons" to generate platform-specific icons');
}

Future<void> generateMainIcon() async {
  print('📱 Creating main icon (512x512)...');
  
  // Create a 512x512 image
  final icon = img.Image(width: 512, height: 512);
  
  // Fill with gradient background (green)
  for (int y = 0; y < 512; y++) {
    for (int x = 0; x < 512; x++) {
      // Create gradient from #4CAF50 to #45a049
      final factor = (x + y) / (512 + 512);
      final r = (76 + (69 - 76) * factor).round();
      final g = (175 + (160 - 175) * factor).round();
      final b = (80 + (73 - 80) * factor).round();
      
      icon.setPixelRgba(x, y, r, g, b, 255);
    }
  }
  
  // Draw rounded rectangle background
  // (Simplified version - just fill the whole area for now)
  
  // Draw a white rectangle for POS terminal (centered)
  final terminalX = 128;
  final terminalY = 220;
  final terminalWidth = 256;
  final terminalHeight = 160;
  
  img.fillRect(
    icon,
    x1: terminalX,
    y1: terminalY,
    x2: terminalX + terminalWidth,
    y2: terminalY + terminalHeight,
    color: img.ColorRgb8(255, 255, 255),
  );
  
  // Draw blue screen
  img.fillRect(
    icon,
    x1: terminalX + 20,
    y1: terminalY + 20,
    x2: terminalX + terminalWidth - 20,
    y2: terminalY + 100,
    color: img.ColorRgb8(33, 150, 243),
  );
  
  // Draw receipt paper (white rectangle above terminal)
  final receiptX = 256 - 28;
  final receiptY = 140;
  final receiptWidth = 56;
  final receiptHeight = 90;
  
  img.fillRect(
    icon,
    x1: receiptX,
    y1: receiptY,
    x2: receiptX + receiptWidth,
    y2: receiptY + receiptHeight,
    color: img.ColorRgb8(255, 255, 255),
  );
  
  // Draw some lines on receipt (to simulate text)
  for (int i = 0; i < 4; i++) {
    final lineY = receiptY + 20 + (i * 10);
    img.fillRect(
      icon,
      x1: receiptX + 10,
      y1: lineY,
      x2: receiptX + receiptWidth - 10,
      y2: lineY + 2,
      color: img.ColorRgb8(100, 100, 100),
    );
  }
  
  // Draw keypad buttons (5 circles at bottom)
  final buttonY = terminalY + 130;
  final buttonRadius = 12;
  for (int i = 0; i < 5; i++) {
    final buttonX = terminalX + 50 + (i * 40);
    img.fillCircle(
      icon,
      x: buttonX,
      y: buttonY,
      radius: buttonRadius,
      color: img.ColorRgb8(224, 224, 224),
    );
  }
  
  // Draw dollar sign accent (bottom right)
  img.fillCircle(
    icon,
    x: 420,
    y: 420,
    radius: 45,
    color: img.ColorRgb8(240, 240, 240), // Light overlay
  );
  
  // Save the image
  final pngBytes = img.encodePng(icon);
  final file = File('assets/images/icon.png');
  await file.writeAsBytes(pngBytes);
  
  print('  ✓ Saved to: assets/images/icon.png');
}

Future<void> generateForegroundIcon() async {
  print('📱 Creating foreground icon (432x432)...');
  
  // Create a 432x432 image with transparency
  final icon = img.Image(width: 432, height: 432);
  
  // Fill with transparent background
  img.fill(icon, color: img.ColorRgb8(0, 0, 0));
  
  // Draw a white POS terminal (centered, slightly larger)
  final terminalX = 88;
  final terminalY = 136;
  final terminalWidth = 256;
  final terminalHeight = 160;
  
  // Draw terminal body
  img.fillRect(
    icon,
    x1: terminalX,
    y1: terminalY,
    x2: terminalX + terminalWidth,
    y2: terminalY + terminalHeight,
    color: img.ColorRgb8(255, 255, 255),
  );
  
  // Draw blue screen
  img.fillRect(
    icon,
    x1: terminalX + 20,
    y1: terminalY + 20,
    x2: terminalX + terminalWidth - 20,
    y2: terminalY + 100,
    color: img.ColorRgb8(33, 150, 243),
  );
  
  // Draw receipt paper
  final receiptX = 216 - 28;
  final receiptY = 56;
  final receiptWidth = 56;
  final receiptHeight = 90;
  
  img.fillRect(
    icon,
    x1: receiptX,
    y1: receiptY,
    x2: receiptX + receiptWidth,
    y2: receiptY + receiptHeight,
    color: img.ColorRgb8(255, 255, 255),
  );
  
  // Draw lines on receipt
  for (int i = 0; i < 4; i++) {
    final lineY = receiptY + 20 + (i * 10);
    img.fillRect(
      icon,
      x1: receiptX + 10,
      y1: lineY,
      x2: receiptX + receiptWidth - 10,
      y2: lineY + 2,
      color: img.ColorRgb8(100, 100, 100),
    );
  }
  
  // Draw keypad buttons
  final buttonY = terminalY + 130;
  final buttonRadius = 12;
  for (int i = 0; i < 5; i++) {
    final buttonX = terminalX + 50 + (i * 40);
    img.fillCircle(
      icon,
      x: buttonX,
      y: buttonY,
      radius: buttonRadius,
      color: img.ColorRgb8(224, 224, 224),
    );
  }
  
  // Save the image
  final pngBytes = img.encodePng(icon);
  final file = File('assets/images/icon_foreground.png');
  await file.writeAsBytes(pngBytes);
  
  print('  ✓ Saved to: assets/images/icon_foreground.png');
}
