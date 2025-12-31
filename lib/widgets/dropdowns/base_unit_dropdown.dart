import 'package:flutter/material.dart';

/// A dropdown menu for selecting base units.
///
/// This widget provides a searchable dropdown for selecting from available base units.
///
/// Example:
/// ```dart
/// BaseUnitDropdown(
///   selectedUnit: currentUnit,
///   availableUnits: ['kg', 'g', 'lb', 'oz'],
///   onChanged: (unit) => setState(() => currentUnit = unit),
/// )
/// ```
class BaseUnitDropdown extends StatelessWidget {
  /// The currently selected unit
  final String? selectedUnit;

  /// List of available base units to choose from
  final List<String> availableUnits;

  /// Callback when unit selection changes
  final ValueChanged<String?> onChanged;

  /// Label text for the dropdown
  final String labelText;

  /// Whether the dropdown is enabled
  final bool enabled;

  /// Optional initial selection (overrides selectedUnit on first build)
  final String? initialSelection;

  /// Width of the dropdown menu
  final double? width;

  /// Whether to enable search functionality
  final bool enableSearch;

  /// Creates a base unit dropdown
  const BaseUnitDropdown({
    super.key,
    this.selectedUnit,
    required this.availableUnits,
    required this.onChanged,
    this.labelText = 'Unit',
    this.enabled = true,
    this.initialSelection,
    this.width = 150,
    this.enableSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: initialSelection ?? selectedUnit,
      label: Text(labelText),
      width: width,
      enabled: enabled,
      enableSearch: enableSearch,
      requestFocusOnTap: true,
      dropdownMenuEntries: availableUnits.map((String unit) {
        return DropdownMenuEntry<String>(
          value: unit,
          label: unit,
        );
      }).toList(),
      onSelected: onChanged,
    );
  }
}
