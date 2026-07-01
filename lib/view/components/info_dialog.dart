import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:flutter/material.dart';

class InfoDialog extends StatelessWidget {
  final String message;
  final String? subtext;
  final VoidCallback ok;
  final IconData? icon;
  final Color? accentColor;

  const InfoDialog({
    super.key,
    required this.message,
    required this.ok,
    this.subtext,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accentColor ?? AppColors.finalRed;

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: ok,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.error_outline_rounded,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue,
                ),
              ),
              if (subtext != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtext!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.4,
                    color: AppColors.iconGrey,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: ok,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
