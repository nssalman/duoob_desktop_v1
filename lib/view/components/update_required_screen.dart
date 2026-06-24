import 'package:duoob_desktop_app_v1/model/app_version_check_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';

class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, required this.result});

  final AppVersionCheckResult result;

  @override
  Widget build(BuildContext context) {
    final latestLabel = result.latestVersion != null
        ? '${result.latestVersion}'
            '${result.latestBuildNumber != null ? ' (${result.latestBuildNumber})' : ''}'
        : null;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.finalRed.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.system_update_alt,
                      size: 36,
                      color: AppColors.finalRed,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Update Required',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    result.platformLabel,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.iconGrey,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    result.displayMessage,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                          color: AppColors.iconGrey,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _InfoRow(
                    label: 'Your version',
                    value:
                        '${result.currentVersion} (${result.currentBuildNumber})',
                  ),
                  if (latestLabel != null) ...[
                    const SizedBox(height: 8),
                    _InfoRow(label: 'Latest version', value: latestLabel),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.iconGrey,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
