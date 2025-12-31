import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';

/// Vertical spacing widget for consistent spacing.
///
/// Use the named constructors for predefined spacing values:
/// - `VerticalSpace.xs()` - 4px
/// - `VerticalSpace.sm()` - 8px
/// - `VerticalSpace.md()` - 12px
/// - `VerticalSpace.lg()` - 16px
/// - `VerticalSpace.xl()` - 24px
/// - `VerticalSpace.xxl()` - 32px
/// - `VerticalSpace.xxxl()` - 48px
class VerticalSpace extends StatelessWidget {
  /// The height of the vertical space
  final double height;

  /// Creates a vertical space with custom height
  const VerticalSpace(this.height, {super.key});

  /// Extra small vertical space (4px)
  const VerticalSpace.xs({super.key}) : height = AppSpacing.xs;

  /// Small vertical space (8px)
  const VerticalSpace.sm({super.key}) : height = AppSpacing.sm;

  /// Medium vertical space (12px)
  const VerticalSpace.md({super.key}) : height = AppSpacing.md;

  /// Large vertical space (16px)
  const VerticalSpace.lg({super.key}) : height = AppSpacing.lg;

  /// Extra large vertical space (24px)
  const VerticalSpace.xl({super.key}) : height = AppSpacing.xl;

  /// Extra extra large vertical space (32px)
  const VerticalSpace.xxl({super.key}) : height = AppSpacing.xxl;

  /// Extra extra extra large vertical space (48px)
  const VerticalSpace.xxxl({super.key}) : height = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: height);
  }
}

/// Horizontal spacing widget for consistent spacing.
///
/// Use the named constructors for predefined spacing values:
/// - `HorizontalSpace.xs()` - 4px
/// - `HorizontalSpace.sm()` - 8px
/// - `HorizontalSpace.md()` - 12px
/// - `HorizontalSpace.lg()` - 16px
/// - `HorizontalSpace.xl()` - 24px
/// - `HorizontalSpace.xxl()` - 32px
/// - `HorizontalSpace.xxxl()` - 48px
class HorizontalSpace extends StatelessWidget {
  /// The width of the horizontal space
  final double width;

  /// Creates a horizontal space with custom width
  const HorizontalSpace(this.width, {super.key});

  /// Extra small horizontal space (4px)
  const HorizontalSpace.xs({super.key}) : width = AppSpacing.xs;

  /// Small horizontal space (8px)
  const HorizontalSpace.sm({super.key}) : width = AppSpacing.sm;

  /// Medium horizontal space (12px)
  const HorizontalSpace.md({super.key}) : width = AppSpacing.md;

  /// Large horizontal space (16px)
  const HorizontalSpace.lg({super.key}) : width = AppSpacing.lg;

  /// Extra large horizontal space (24px)
  const HorizontalSpace.xl({super.key}) : width = AppSpacing.xl;

  /// Extra extra large horizontal space (32px)
  const HorizontalSpace.xxl({super.key}) : width = AppSpacing.xxl;

  /// Extra extra extra large horizontal space (48px)
  const HorizontalSpace.xxxl({super.key}) : width = AppSpacing.xxxl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width);
  }
}
