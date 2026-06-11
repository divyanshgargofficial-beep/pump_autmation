import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.destructive = false,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = destructive ? colors.error : colors.primary;
    final foreground = destructive ? colors.onError : colors.onPrimary;

    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: background,
        foregroundColor: foreground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
