import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_app/theme/app_theme.dart';
import 'package:pos_app/theme/app_spacing.dart';
import 'package:pos_app/theme/app_radius.dart';
import 'package:pos_app/theme/app_elevation.dart';

void main() {
  group('AppSpacing Tests', () {
    test('spacing constants have correct values', () {
      expect(AppSpacing.xs, 4.0);
      expect(AppSpacing.sm, 8.0);
      expect(AppSpacing.md, 12.0);
      expect(AppSpacing.lg, 16.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.xxl, 32.0);
      expect(AppSpacing.xxxl, 48.0);
    });
  });

  group('AppRadius Tests', () {
    test('radius constants have correct values', () {
      expect(AppRadius.none, 0.0);
      expect(AppRadius.sm, 8.0);
      expect(AppRadius.md, 12.0);
      expect(AppRadius.lg, 16.0);
      expect(AppRadius.circular, 100.0);
    });
  });

  group('AppElevation Tests', () {
    test('elevation constants have correct values', () {
      expect(AppElevation.none, 0.0);
      expect(AppElevation.low, 2.0);
      expect(AppElevation.medium, 4.0);
      expect(AppElevation.high, 8.0);
      expect(AppElevation.xHigh, 12.0);
    });
  });

  group('AppTheme Tests', () {
    test('light theme is configured correctly', () {
      final theme = AppTheme.light();
      
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme is configured correctly', () {
      final theme = AppTheme.dark();
      
      expect(theme.useMaterial3, true);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('card theme uses design system constants', () {
      final theme = AppTheme.light();
      
      expect(theme.cardTheme.elevation, AppElevation.low);
      expect(
        (theme.cardTheme.shape as RoundedRectangleBorder).borderRadius,
        BorderRadius.circular(AppRadius.md),
      );
    });

    test('input decoration theme uses design system constants', () {
      final theme = AppTheme.light();
      
      expect(theme.inputDecorationTheme.filled, true);
      expect(
        (theme.inputDecorationTheme.border as OutlineInputBorder).borderRadius,
        BorderRadius.circular(AppRadius.sm),
      );
    });
  });
}
