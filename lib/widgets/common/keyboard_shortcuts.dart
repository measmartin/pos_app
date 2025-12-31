import 'package:flutter/material.dart';

/// Widget that wraps a screen with keyboard shortcuts
class KeyboardShortcuts extends StatelessWidget {
  final Widget child;
  final Map<LogicalKeySet, VoidCallback> shortcuts;
  final bool enabled;

  const KeyboardShortcuts({
    super.key,
    required this.child,
    required this.shortcuts,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shortcuts(
      shortcuts: shortcuts.map(
        (keySet, callback) => MapEntry(keySet, _ShortcutIntent(callback)),
      ),
      child: Actions(
        actions: {
          _ShortcutIntent: CallbackAction<_ShortcutIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

class _ShortcutIntent extends Intent {
  final VoidCallback callback;

  const _ShortcutIntent(this.callback);
}

/// Dialog to display available keyboard shortcuts
class KeyboardShortcutsDialog extends StatelessWidget {
  final List<KeyboardShortcutInfo> shortcuts;

  const KeyboardShortcutsDialog({
    super.key,
    required this.shortcuts,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.keyboard),
          SizedBox(width: 8),
          Text('Keyboard Shortcuts'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: shortcuts.length,
          separatorBuilder: (context, index) => const Divider(),
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            return ListTile(
              dense: true,
              title: Text(shortcut.description),
              trailing: _buildShortcutChip(shortcut.keys),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildShortcutChip(String keys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Text(
        keys,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
      ),
    );
  }

  static void show(BuildContext context, List<KeyboardShortcutInfo> shortcuts) {
    showDialog(
      context: context,
      builder: (context) => KeyboardShortcutsDialog(shortcuts: shortcuts),
    );
  }
}

/// Information about a keyboard shortcut
class KeyboardShortcutInfo {
  final String keys;
  final String description;

  const KeyboardShortcutInfo({
    required this.keys,
    required this.description,
  });
}
