import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionLabel extends StatelessWidget {
  const AppVersionLabel({super.key, this.alignment = Alignment.center});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final info = snapshot.data!;
        return Align(
          alignment: alignment,
          child: Text(
            'Version ${info.version} (${info.buildNumber})',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.iconGrey,
                  letterSpacing: 0.2,
                ),
          ),
        );
      },
    );
  }
}
