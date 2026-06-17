import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TagChip extends StatelessWidget {
  final String label;

  const TagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = theme.extension<AppColorsExtension>()!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: appColors.borderSubtle),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
          fontSize: 11,
        ),
      ),
    );
  }
}
