import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class NewTaskViewScreen extends StatefulWidget {
  const NewTaskViewScreen({super.key, required this.createWindowRequest});
  final CreateWindowAction createWindowRequest;

  @override
  State<NewTaskViewScreen> createState() => _NewTaskViewScreenState();
}

class _NewTaskViewScreenState extends State<NewTaskViewScreen> {
  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(backgroundColor: AppColors.blue, title: Text('Task Details')),
      body: InAppWebView(
        windowId: widget.createWindowRequest.windowId,
        onWebViewCreated: (controller) {
        },
        onCloseWindow: (controller) async {
          Navigator.pop(context);
        },
      ),
    );
  }
}
