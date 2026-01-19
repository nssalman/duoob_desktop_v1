import 'package:duoob_desktop_app_v1/utils/size_config.dart';
import 'package:flutter/material.dart';

class NoDataWarning extends StatelessWidget {
  final Function()? onRefresh;
  final String? message;
  const NoDataWarning({super.key, this.onRefresh, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message ?? 'No data found',
            // style: AppTextStyles.blackHead,
          ),
          if (onRefresh != null) gapH20,
          if (onRefresh != null)
            ElevatedButton(
                onPressed: onRefresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Refresh',
                    style: TextStyle(color: Colors.white))),
          gapH120
        ],
      ),
    );
  }
}
