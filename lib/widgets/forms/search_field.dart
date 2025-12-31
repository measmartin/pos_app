import 'package:flutter/material.dart';

/// A search field widget with consistent styling.
///
/// This widget provides a search input field with a search icon prefix
/// and an optional clear button.
///
/// Example:
/// ```dart
/// SearchField(
///   controller: searchController,
///   hintText: 'Search products...',
///   onChanged: (value) => setState(() {}),
/// )
/// ```
class SearchField extends StatelessWidget {
  /// The controller for the text field
  final TextEditingController controller;

  /// The hint text displayed when field is empty
  final String hintText;

  /// Callback when text changes
  final void Function(String) onChanged;

  /// Optional callback when clear button is pressed
  final VoidCallback? onClear;

  /// Whether to show the clear button
  final bool showClearButton;

  /// Optional prefix icon (defaults to search icon)
  final IconData prefixIcon;

  /// Creates a search field
  const SearchField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    required this.onChanged,
    this.onClear,
    this.showClearButton = true,
    this.prefixIcon = Icons.search,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: showClearButton && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                  if (onClear != null) onClear!();
                },
              )
            : null,
      ),
      onChanged: onChanged,
    );
  }
}
