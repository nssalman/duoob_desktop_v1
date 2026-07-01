import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:flutter/material.dart';

class MyRakpWorkspace extends StatelessWidget {
  const MyRakpWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: TaskWebViewWindows(
        key: const ValueKey(Constants.myRakpUrl),
        url: Constants.myRakpUrl,
        refreshUrlOnSuccess: true,
      ),
    );
  }
}
