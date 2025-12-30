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
import 'package:flutter_resizable_container/flutter_resizable_container.dart';
import 'package:provider/provider.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key});

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace> with SingleTickerProviderStateMixin {
  D365TaskListModel? _selectedTask;
  String? _activeUrl;
  TaskType _selectedFilter = TaskType.administrative;

  final double _webViewMinHeight = 400.0;
  late TabController _tabController;

  final List<String> tabs = [
    'ERP Tasks',
    'Employee Tasks',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    
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
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
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
                        child: _buildGlassmorphicTabBar(),
                      ),
                      gapH12,
                      Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Stack(
                  children: [
                    TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // --- ERP Tasks Tab ---
                        Column(
                          children: [
                            _buildSelectAllHeader(provider),
                            const SizedBox(height: 10),
                            Expanded(
                              child: provider.isDD365Loading
                                  ? const ShimmerLoader(title: 'ERP Task')
                                  : provider.d365TaskList.isEmpty
                                      ? NoDataWarning(
                                          message: 'No ERP Task found',
                                          onRefresh: () => provider.getTaskListPermission(),
                                        )
                                      : RefreshIndicator(
                                          onRefresh: () => provider.getTaskListPermission(),
                                          child: ListView.builder(
                                            padding: EdgeInsets.only(
                                                bottom: provider.checkForSelection() ? 20 : 120),
                                            itemCount: provider.d365TaskList.length,
                                            itemBuilder: (context, index) {
                                              final task = provider.d365TaskList[index];
                                              return D365tasktile(
                                                task: task,
                                                onChanged: (value) => provider.toggleSelection(index),
                                                isSelected: task.isSelected,
                                                onTapLink: () => _handleERPWebRedirect(context, provider, index),
                                              );
                                            },
                                          ),
                                        ),
                            ),
                            // if (provider.checkForSelection())
                            //   _buildBulkActionButtons(provider, context),
                          ],
                        ),
                
                        // --- Employee Tasks Tab ---
                        Column(children: [
                          Expanded(
                            child: provider.isTaskListLoading
                                ? const ShimmerLoader(title: 'Employee Task')
                                : provider.userTaskMap.isEmpty
                                    ? NoDataWarning(
                                        message: 'No Employee Task found',
                                        onRefresh: () => provider.getTaskListPermission(),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: () => provider.getTaskListPermission(),
                                        child: ListView.builder(
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
                                                      onPressed: () => _handleEmployeeWebRedirect(context, provider, task),
                                                    )),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                          )
                        ])
                      ],
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

  // --- Navigation Logic ---

 void _handleERPWebRedirect(BuildContext context, TaskProvider provider, int index) {
  final task = provider.d365TaskList[index];
  if (task.linkToWeb != null) {
    setState(() {
      _activeUrl = task.linkToWeb;
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      alignment: Alignment.centerLeft,
      child: Text(
        'My Tasks',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  // Widget _buildFilterTabs() {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     child: SizedBox(
  //       width: double.infinity,
  //       child: SegmentedButton<TaskType>(
  //         style: ButtonStyle(
            
  //         ),
  //         segments: const [
  //           ButtonSegment(
  //             value: TaskType.administrative,
  //             label: Text('ERP'),
  //             icon: Icon(Icons.folder_shared_outlined, size: 16),
  //           ),
  //           ButtonSegment(
  //             value: TaskType.technical,
  //             label: Text('Employee'),
  //             icon: Icon(Icons.terminal_outlined, size: 16),
  //           ),
  //         ],
  //         selected: {_selectedFilter},
  //         onSelectionChanged: (Set<TaskType> newSelection) {
  //           setState(() {
  //             _selectedFilter = newSelection.first;
  //             _selectedTask = null;
  //           });
  //         },
  //       ),
  //     ),
  //   );
  // }


// Widget _buildGlassmorphicFilterTabs(BuildContext context) {
//   final themeProvider = Provider.of<ThemeProvider>(context);
//   final isDark = themeProvider.isDarkMode;

//   return Padding(
//     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//     child: ClipRRect(
//       borderRadius: BorderRadius.circular(12),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           decoration: BoxDecoration(
//             color: isDark 
//                 ? Colors.white.withOpacity(0.05) 
//                 : const Color(0xFF102849).withOpacity(0.05),
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: Colors.white.withOpacity(0.1),
//               width: 1,
//             ),
//           ),
//           child: SegmentedButton<TaskType>(
//             // --- Styling to achieve the look ---
//             style: ButtonStyle(
//               backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
//                 if (states.contains(WidgetState.selected)) {
//                   return const Color(0xFF102849); // Your Primary Navy
//                 }
//                 return Colors.transparent;
//               }),
//               foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
//                 if (states.contains(WidgetState.selected)) {
//                   return Colors.white;
//                 }
//                 return isDark ? Colors.white70 : const Color(0xFF102849);
//               }),
//               side: WidgetStateProperty.all(BorderSide.none), // Removes divider lines
//               shape: WidgetStateProperty.all(
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//               ),
//               padding: WidgetStateProperty.all(
//                 const EdgeInsets.symmetric(vertical: 16),
//               ),
//             ),
//             // --- Logic and Content ---
//             showSelectedIcon: false, // Cleaner glass look
//             segments: const [
//               ButtonSegment(
//                 value: TaskType.administrative,
//                 label: Text('ERP', style: TextStyle(fontWeight: FontWeight.w600)),
//                 icon: Icon(Icons.folder_shared_outlined, size: 18),
//               ),
//               ButtonSegment(
//                 value: TaskType.technical,
//                 label: Text('Employee', style: TextStyle(fontWeight: FontWeight.w600)),
//                 icon: Icon(Icons.terminal_outlined, size: 18),
//               ),
//             ],
//             selected: {_selectedFilter},
//             onSelectionChanged: (Set<TaskType> newSelection) {
//               setState(() {
//                 _selectedFilter = newSelection.first;
//                 _selectedTask = null;
//               });
//             },
//           ),
//         ),
//       ),
//     ),
//   );
// }

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
            'Select a task to view details',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }

}

enum TaskType { administrative, technical }