import 'package:duoob_desktop_app_v1/controller/report_provider.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/view/components/no_data_warning.dart';
import 'package:duoob_desktop_app_v1/view/components/shimmer_loader.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';

class ReportWorkspace extends StatefulWidget {
  const ReportWorkspace({super.key});

  @override
  State<ReportWorkspace> createState() => ReportWorkspaceState(); // Removed underscore
}

class ReportWorkspaceState extends State<ReportWorkspace> {
  String? _activeUrl;
  late MultiSplitViewController _multiSplitController;

  @override
  void initState() {
    super.initState();
    // Initialize the layout controller with persistence
    _multiSplitController = MultiSplitViewController(
      areas: [
        Area(size: 350, min: 300, max: 600), // Sidebar Area
        Area(flex: 1), // WebView Area
      ],
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportProvider>().fetchReports();
    });
  }

  @override
  void dispose() {
    _multiSplitController.dispose();
    super.dispose();
  }

  // Public method to be called by the list items
  void setActiveUrl(String url) {
    setState(() {
      _activeUrl = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiSplitView(
      controller: _multiSplitController,
      axis: Axis.horizontal,
      builder: (context, area) {
        if (area.index == 0) {
          // Area 0: Sidebar
          return _buildSidebar();
        } else {
          // Area 1: Detail View
          return _activeUrl == null
              ? _buildEmptyState()
              : TaskWebViewWindows(
                  key: ValueKey(_activeUrl), // Re-init WebView on URL change
                  url: _activeUrl!,
                );
        }
      },
    );
  }

  Widget _buildSidebar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
      child: Card(
        shadowColor: AppColors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Theme.of(context).colorScheme.surface,
        elevation: 5,
        child: Column(
          children: [
            _buildHeader(context),
            const Expanded(
              child: ReportListSection(), // Decoupled List
            ),
          ],
        ),
      ),
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

class ReportListSection extends StatefulWidget {
  const ReportListSection({super.key});

  @override
  State<ReportListSection> createState() => _ReportListSectionState();
}

class _ReportListSectionState extends State<ReportListSection> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Keeps the list alive during parent rebuilds

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<ReportProvider>(
      builder: (context, provider, child) {
        if (provider.isReportListLoading) {
          return const ShimmerLoader(title: 'BI Reports');
        }

        if (provider.reports.isEmpty) {
          return NoDataWarning(
            message: 'No Reports found',
            onRefresh: () => provider.fetchReports(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.fetchReports(),
          child: ListView.builder(
            key: const PageStorageKey('bi_report_list'), // Preserves scroll position
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 100),
            itemCount: provider.reports.length,
            itemBuilder: (context, index) {
              final report = provider.reports[index];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                leading: Image.asset(
                  'assets/icons/document.png',
                  width: 30,
                  height: 30,
                  errorBuilder: (_, __, ___) => const Icon(Icons.description, color: Colors.blue),
                ),
                title: Text(
                  report.description ?? 'Untitled Report',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  report.fileName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  // Notify the parent workspace to load the URL
                  final parent = context.findAncestorStateOfType<ReportWorkspaceState>();
                  if (report.fileName != null) {
                    parent?.setActiveUrl(report.fileName!);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
