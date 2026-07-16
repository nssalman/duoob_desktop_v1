import 'package:duoob_desktop_app_v1/utils/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoader extends StatelessWidget {
  final String title;
  final String subtitle;
  const ShimmerLoader(
      {super.key, required this.title, this.subtitle = 'Please wait...'});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ListView.separated(
      itemCount: 5,
      padding: EdgeInsets.zero,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: c.shimmerBase,
          highlightColor: c.shimmerHighlight,
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
