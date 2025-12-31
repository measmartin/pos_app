import 'dart:io';
import 'package:flutter/material.dart';

/// A widget that displays a product image with a fallback icon.
///
/// This widget handles loading product images from file paths and
/// provides a consistent fallback UI when no image is available.
///
/// Example:
/// ```dart
/// ProductImage(
///   imagePath: product.imagePath,
///   width: 100,
///   height: 100,
///   fit: BoxFit.cover,
/// )
/// ```
class ProductImage extends StatelessWidget {
  /// The file path to the product image
  final String? imagePath;

  /// The width of the image
  final double? width;

  /// The height of the image
  final double? height;

  /// How the image should fit within its bounds
  final BoxFit fit;

  /// The icon to display when no image is available
  final IconData fallbackIcon;

  /// The size of the fallback icon
  final double fallbackIconSize;

  /// Optional border radius for the image
  final BorderRadius? borderRadius;

  /// Whether the image should be circular
  final bool isCircular;

  /// Background color for the fallback container
  final Color? fallbackBackgroundColor;

  /// Creates a product image widget
  const ProductImage({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.inventory_2,
    this.fallbackIconSize = 48.0,
    this.borderRadius,
    this.isCircular = false,
    this.fallbackBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = fallbackBackgroundColor ?? 
                    theme.colorScheme.surfaceContainerHighest;

    Widget imageWidget;

    if (imagePath != null && imagePath!.isNotEmpty) {
      imageWidget = Image.file(
        File(imagePath!),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(bgColor, theme),
      );
    } else {
      imageWidget = _buildFallback(bgColor, theme);
    }

    if (isCircular) {
      return ClipOval(
        child: SizedBox(
          width: width,
          height: height,
          child: imageWidget,
        ),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback(Color bgColor, ThemeData theme) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Icon(
        fallbackIcon,
        size: fallbackIconSize,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
