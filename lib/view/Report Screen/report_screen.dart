import 'package:duoob_desktop_app_v1/controller/report_provider.dart';
import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/size_config.dart';
import 'package:duoob_desktop_app_v1/view/components/d365_task_tile.dart';
import 'package:duoob_desktop_app_v1/view/components/no_data_warning.dart';
import 'package:duoob_desktop_app_v1/view/components/shimmer_loader.dart';
import 'package:duoob_desktop_app_v1/view/components/task_tile.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:provider/provider.dart';

class ReportWorkspace extends StatefulWidget {
  const ReportWorkspace({super.key});

  @override
  State<ReportWorkspace> createState() => _ReportWorkspaceState();
}

class _ReportWorkspaceState extends State<ReportWorkspace> {
  D365TaskListModel? _selectedTask;
  String? _activeUrl;

  final double _webViewMinHeight = 400.0;

  @override
  void initState() {
    super.initState();
    // Initial fetch of reports
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReportProvider>(context, listen: false).fetchReports();
    });
  }


  
  @override
  Widget build(BuildContext context) {
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        return ResizableContainer(
            direction: Axis.horizontal,
          children: [
            // A. Task List Sidebar (Middle Pane)
            ResizableChild(
              divider: ResizableDivider(color: Colors.white),
              size: ResizableSize.ratio(0.2,min: 300,max: MediaQuery.of(context).size.width * 0.4),
              child: Container(
                margin: EdgeInsets.fromLTRB(10,10,0,10),
                child: Card(
                  shadowColor: AppColors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(20)),
                  color: Theme.of(context).colorScheme.surface,
                  elevation: 5,
                  child: Column(
                    children: [
                      _buildHeader(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                      gapH12,
                      Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Expanded(
                      child: provider.isReportListLoading
                          ? const ShimmerLoader(title: 'BI Reports')
                          : provider.reports.isEmpty
                              ? NoDataWarning(
                                  message: 'No Reports found',
                                  onRefresh:null,
                                )
                              : RefreshIndicator(
                                  onRefresh: (){
                                    return provider.fetchReports();
                                  },
                                  child: ListView.builder(
                                    padding: EdgeInsets.only(
                                        bottom: 120),
                                    itemCount: provider.reports.length,
                                    itemBuilder: (context, index) {
                                      final task = provider.reports[index];
                                      return ListTile(
                                        leading: Image.asset(task.icon,width: 30,height: 30,),
                                        title: Text(task.title),
                                        subtitle: Text(task.url ?? ''),
                                        onTap: () {
                                          setState(() {
                                            _activeUrl = task.url;
                                          });
                                        },
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
                    ],
                  ),
                ),
              ),
            ),
        
            // B. Detail View (Right Pane)
           ResizableChild(
  child: _activeUrl == null
      ? _buildEmptyState()
      : TaskWebViewWindows(
      // THIS KEY IS CRITICAL:
      // It forces a clean native window re-init every time the URL changes.
      key: ValueKey(_activeUrl), 
      url: _activeUrl!,
    ),
),
          ],
        );
      }
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      alignment: Alignment.centerLeft,
      child: Text(
        'BI Reports',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }



    Widget _buildTaskList() {

    return ListView.builder(
      itemCount: 10,
      padding: EdgeInsets.symmetric(horizontal: 10),
      itemBuilder: (context, index) {
        final task = D365TaskListModel();
        final isSelected = _selectedTask?.notificationId == task.notificationId;

        return D365tasktile(task: task, onChanged: (val){});
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_outlined, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'Select a report to view details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }

}
