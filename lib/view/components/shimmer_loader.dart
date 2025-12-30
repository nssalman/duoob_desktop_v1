import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final String title;
  final String subtitle;
  const ShimmerLoader(
      {super.key, required this.title, this.subtitle = 'Please wait...'});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: 5,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.lightGrey.withValues(alpha: 0.3),
          highlightColor: Colors.white70,
          child: Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: ListTile(
              title: Text('$title Loading...'),
              subtitle: Text(subtitle),
            ),
          ),
        );
      },
      separatorBuilder: (context, index) => SizedBox(
        height: 10,
      ),
    );
  }
}
