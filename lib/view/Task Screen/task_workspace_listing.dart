import 'dart:ui';

import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
import 'package:duoob_desktop_app_v1/controller/theme_provider.dart';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:duoob_desktop_app_v1/model/task_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/utils/size_config.dart';
import 'package:duoob_desktop_app_v1/view/components/d365_task_tile.dart';
import 'package:duoob_desktop_app_v1/view/components/no_data_warning.dart';
import 'package:duoob_desktop_app_v1/view/components/shimmer_loader.dart';
import 'package:duoob_desktop_app_v1/view/components/task_tile.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key, this.suspendWebView = false});

  final bool suspendWebView;

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> with SingleTickerProviderStateMixin {
  D365TaskListModel? _selectedTask;
  String? _activeUrl;

  final double _webViewMinHeight = 400.0;
  late TabController _tabController;

  late MultiSplitViewController _multiSplitController;

  final List<String> tabs = [
    'ERP Tasks',
    'Employee Tasks',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _multiSplitController = MultiSplitViewController(
      areas: [
        Area(size: 350, min: 300, max: 600), // Sidebar: initial 350px
        Area(flex: 1), // WebView: takes remaining space
      ],
    );   
    // Initial fetch using addPostFrameCallback to avoid calling 
    // notifyListeners() during the build phase.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().getTaskListPermission();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(TaskWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.suspendWebView && widget.suspendWebView) {
      _activeUrl = null;
      _selectedTask = null;
    }
  }

  
 @override
Widget build(BuildContext context) {
  return Consumer<TaskProvider>(
    builder: (context, provider, child) {
      return MultiSplitView(
        controller: _multiSplitController,
        axis: Axis.horizontal,
        // Use the builder to prevent children from rebuilding unnecessarily
        builder: (context, area) {
          if (area.index == 0) {
            // SIDEBAR PANE
            return _buildSidebarContent(provider);
          } else {
            return TaskWebViewWindows(
              key: ValueKey(_activeUrl ?? 'empty'),
              url: widget.suspendWebView ? null : _activeUrl,
              onSubmissionSuccess: _handleTaskSubmissionSuccess,
            );
          }
        },
      );
    },
  );
}
Widget _buildSidebarContent(TaskProvider provider) {
  return Container(
    margin: const EdgeInsets.fromLTRB(10, 10, 0, 10),
    child: Card(
      shadowColor: AppColors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: Theme.of(context).colorScheme.surface,
      elevation: 5,
      child: Column(
        children: [
          // 1. Header (Search/Profile etc)
          _buildHeader(context, provider),
          
          // 2. Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: _buildGlassmorphicTabBar(),
          ),
          
          const SizedBox(height: 12),
          
          // 3. The Task Lists (Inside TabBarView)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  // Using the scoped widgets we created to preserve scroll state
                  ERPTaskListSection(), 
                  EmployeeTaskListSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildSelectAllHeader(TaskProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Select All',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          InkWell(
            onTap: provider.isAllSelect ? provider.clearSelection : provider.selectAll,
            child: const Icon(Icons.select_all, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildUserHeader(String userName) {
    return Container(
      height: 30,
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        'Tasks of $userName',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget _buildBulkActionButtons(TaskProvider provider, BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.only(
  //         left: 15, right: 15, bottom: kBottomNavigationBarHeight + kToolbarHeight),
  //     child: Row(
  //       children: [
  //         Expanded(child: _buildActionButton(provider, context, isApprove: true)),
  //         const SizedBox(width: 10),
  //         Expanded(child: _buildActionButton(provider, context)),
  //       ],
  //     ),
  //   );
  // }

 void _handleERPWebRedirect(BuildContext context, TaskProvider provider, int index) {
  final task = provider.d365TaskList[index];
  if (task.notificationId != null) {
    setState(() {
      _activeUrl = 'https://rakp.rpsmart.com/d365emailnotifications/D365FnOWorkflowsubmission.aspx?NotificationID=${task.notificationId}';
      // Also update _selectedTask if you use it for other UI highlights
      _selectedTask = task; 
    });
  }
}

// Handler for Employee Tasks (TaskModel)
Future<void> _handleEmployeeWebRedirect(BuildContext context, TaskProvider provider, TaskModel task) async {
  // Use the provider logic you already wrote to get the one-time key and URL
  String? url = await provider.redirectToWeb(task);
  
  if (url != null) {
    setState(() {
      _activeUrl = url;
    });
  } else {
    // Optional: Show an error if the link couldn't be generated
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not generate task link.")),
    );
  }
}

 void _handleTaskSubmissionSuccess() {
  if (!mounted) return;
  final provider = context.read<TaskProvider>();
  if (_tabController.index == 0) {
    provider.getd365TaskList();
  } else {
    provider.getTaskListPermission();
  }
  setState(() {
    _activeUrl = null;
    _selectedTask = null;
  });
}

  Widget _buildHeader(BuildContext context, TaskProvider provider) {
    final isErpTab = _tabController.index == 0;
    final isLoading =
        isErpTab ? provider.isDD365Loading : provider.isTaskListLoading;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'My Tasks',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading
                ? null
                : () {
                    if (isErpTab) {
                      provider.getd365TaskList();
                    } else {
                      provider.getTaskListPermission();
                    }
                  },
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }


Widget _buildGlassmorphicTabBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.blue.withOpacity(0.1),
          ),
          // width: MediaQuery.of(context).size.width * 0.96,
          child: Row(
            children: List.generate(tabs.length * 2 - 1, (i) {
              if (i.isOdd) {
                // Separator between tabs
                return Container(height: 30, width: 4, color: AppColors.blue);
              } else {
                int tabIndex = i ~/ 2;
                bool isSelected = _tabController.index == tabIndex;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _tabController.index = tabIndex;
                      });
                      _tabController.animateTo(tabIndex);
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  AppColors.blue,
                                  AppColors.blue,
                                  Constants.primaryColor.withValues(alpha: 0.5),
                                  // Constants.primaryColor.withValues(alpha: 0.5),
                                  // Colors.white70
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        // color: isSelected
                        //     ? Colors.black.withOpacity(0.25)
                        //     : Colors.transparent,
                      ),
                      child: Center(
                        child: Text(
                          tabs[tabIndex],
                          style: TextStyle(
                            color:
                                isSelected ? Colors.white : AppColors.iconGrey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
            }),
          ),
        ),
      ),
    );
  }

}

class ERPTaskListSection extends StatefulWidget {
  const ERPTaskListSection({super.key});

  @override
  State<ERPTaskListSection> createState() => _ERPTaskListSectionState();
}

class _ERPTaskListSectionState extends State<ERPTaskListSection> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // Prevents the list from disposing

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for KeepAlive
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isDD365Loading) return const ShimmerLoader(title: 'ERP Task');

        if (provider.d365TaskList.isEmpty) {
          return NoDataWarning(
            message: 'No ERP Task found',
            onRefresh: () => provider.getd365TaskList(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.getd365TaskList(),
          child: ListView.builder(
            key: const PageStorageKey('erp_list'), // Helps preserve scroll position
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: provider.d365TaskList.length,
            itemBuilder: (context, index) {
              final task = provider.d365TaskList[index];
              return D365tasktile(
                task: task,
                onChanged: (value) => provider.toggleSelection(index),
                onTapLink: () => context.findAncestorStateOfType<_TaskWorkspaceState>()?._handleERPWebRedirect(context, provider, index),
              );
            },
          ),
        );
      },
    );
  }
}
class EmployeeTaskListSection extends StatefulWidget {
  const EmployeeTaskListSection({super.key});

  @override
  State<EmployeeTaskListSection> createState() => _EmployeeTaskListSectionState();
}

class _EmployeeTaskListSectionState extends State<EmployeeTaskListSection> 
    with AutomaticKeepAliveClientMixin {
  
  // This ensures the tab doesn't dispose when you switch to 'ERP Tasks'
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isTaskListLoading) {
          return const ShimmerLoader(title: 'Employee Task');
        }

        if (provider.userTaskMap.isEmpty) {
          return NoDataWarning(
            message: 'No Employee Task found',
            onRefresh: () => provider.getTaskListPermission(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.getTaskListPermission(),
          child: ListView.builder(
            // The PageStorageKey is CRITICAL for keeping the scroll position
            key: const PageStorageKey('employee_task_list'),
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: provider.userTaskMap.length,
            itemBuilder: (context, index) {
              final user = provider.userTaskMap.keys.elementAt(index);
              final tasks = provider.userTaskMap[user]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tasks.isNotEmpty)
                    _buildUserHeader(user.taskOf ?? ''),
                  ...tasks.map((task) => TaskTile(
                        task: task,
                        onPressed: () {
                          // Access the parent state to call the redirect logic
                          final parentState = context.findAncestorStateOfType<_TaskWorkspaceState>();
                          if (parentState != null) {
                            parentState._handleEmployeeWebRedirect(context, provider, task);
                          }
                        },
                      )),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // Extracted helper from your original code to maintain consistency
  Widget _buildUserHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }
}