import 'dart:ui';

import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:duoob_desktop_app_v1/model/task_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/theme_colors.dart';
import 'package:duoob_desktop_app_v1/view/components/custom_dialogue.dart';
import 'package:duoob_desktop_app_v1/view/components/d365_task_tile.dart';
import 'package:duoob_desktop_app_v1/view/components/task_tile.dart';
import 'package:duoob_desktop_app_v1/view/Task%20Screen/task_web_view_windows.dart';
import 'package:flutter/material.dart';
import 'package:multi_split_view/multi_split_view.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class TaskWorkspace extends StatefulWidget {
  const TaskWorkspace({super.key, this.suspendWebView = false});

  final bool suspendWebView;

  @override
  State<TaskWorkspace> createState() => _TaskWorkspaceState();
}

class _TaskWorkspaceState extends State<TaskWorkspace>
    with SingleTickerProviderStateMixin {
  D365TaskListModel? _selectedErpTask;
  String? _selectedEmployeeKey;
  String? _activeUrl;

  late TabController _tabController;
  late MultiSplitViewController _multiSplitController;

  final List<String> tabs = ['ERP Tasks', 'Employee Tasks'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
    _multiSplitController = MultiSplitViewController(
      areas: [
        Area(size: 420, min: 340, max: 560),
        Area(flex: 1),
      ],
    );
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
      _selectedErpTask = null;
      _selectedEmployeeKey = null;
    }

    if (oldWidget.suspendWebView && !widget.suspendWebView) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TaskProvider>().getTaskListPermission();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: MultiSplitViewTheme(
            data: MultiSplitViewThemeData(
              dividerThickness: 8,
              dividerPainter: DividerPainters.grooved1(
                color: c.border,
                highlightedColor: c.brand.withValues(alpha: 0.45),
              ),
            ),
            child: MultiSplitView(
              controller: _multiSplitController,
              axis: Axis.horizontal,
              builder: (context, area) {
                if (area.index == 0) {
                  return _buildSidebarContent(provider);
                }
                return _buildDetailPane();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarContent(TaskProvider provider) {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.brand.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            _buildHeader(context, provider),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: _buildSegmentedTabs(provider),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ERPTaskListSection(
                      activeNotificationId: _selectedErpTask?.notificationId,
                    ),
                    EmployeeTaskListSection(
                      activeTaskKey: _selectedEmployeeKey,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPane() {
    final c = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
        boxShadow: [
          BoxShadow(
            color: c.brand.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TaskWebViewWindows(
          key: ValueKey(_activeUrl ?? 'empty'),
          url: widget.suspendWebView ? null : _activeUrl,
          onSubmissionSuccess: _handleTaskSubmissionSuccess,
        ),
      ),
    );
  }

  void _handleERPWebRedirect(
    BuildContext context,
    TaskProvider provider,
    int index,
  ) {
    final task = provider.d365TaskList[index];
    if (task.notificationId != null) {
      setState(() {
        _activeUrl =
            'https://rakp.rpsmart.com/d365emailnotifications/D365FnOWorkflowsubmission.aspx?NotificationID=${task.notificationId}';
        _selectedErpTask = task;
        _selectedEmployeeKey = null;
      });
    }
  }

  void _openErpBulkUrl(String url) {
    setState(() {
      _activeUrl = url;
      _selectedEmployeeKey = null;
    });
  }

  void _suspendBulkWebViewIfOpen() {
    final isBulkOpen = _activeUrl?.contains(
          'D365FnoWorkflowMultiSubmission',
        ) ==
        true;
    if (!isBulkOpen) return;
    setState(() {
      _activeUrl = null;
      _selectedErpTask = null;
    });
  }

  Future<void> _handleEmployeeWebRedirect(
    BuildContext context,
    TaskProvider provider,
    TaskModel task,
  ) async {
    final url = await provider.redirectToWeb(task);

    if (url != null) {
      setState(() {
        _activeUrl = url;
        _selectedEmployeeKey = _employeeTaskKey(task);
        _selectedErpTask = null;
      });
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not generate task link.')),
      );
    }
  }

  void _handleTaskSubmissionSuccess() {
    if (!mounted) return;
    final provider = context.read<TaskProvider>();
    provider.clearSelection();
    if (_tabController.index == 0) {
      provider.getd365TaskList();
    } else {
      provider.getTaskListPermission();
    }
    setState(() {
      _activeUrl = null;
      _selectedErpTask = null;
      _selectedEmployeeKey = null;
    });
  }

  Widget _buildHeader(BuildContext context, TaskProvider provider) {
    final c = context.colors;
    final isErpTab = _tabController.index == 0;
    final isLoading =
        isErpTab ? provider.isDD365Loading : provider.isTaskListLoading;
    final erpCount = provider.d365TaskList.length;
    final employeeCount = provider.userTaskMap.values
        .fold<int>(0, (sum, list) => sum + list.length);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 10, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            c.brand.withValues(alpha: 0.06),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment_turned_in_outlined,
              color: c.brand,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tasks',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  isErpTab
                      ? '$erpCount ERP · $employeeCount Employee'
                      : '$employeeCount Employee · $erpCount ERP',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }

  void _refreshActiveTab() {
    final provider = context.read<TaskProvider>();
    if (_tabController.index == 0) {
      provider.getd365TaskList();
    } else {
      provider.getTaskListPermission();
    }
  }

  Widget _buildSegmentedTabs(TaskProvider provider) {
    final c = context.colors;
    final erpCount = provider.d365TaskList.length;
    final employeeCount = provider.userTaskMap.values
        .fold<int>(0, (sum, list) => sum + list.length);
    final counts = [erpCount, employeeCount];

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: c.brand.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.brand.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: List.generate(tabs.length, (tabIndex) {
              final isSelected = _tabController.index == tabIndex;
              return Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    if (_tabController.index == tabIndex) return;
                    setState(() => _tabController.index = tabIndex);
                    _tabController.animateTo(tabIndex);
                    _refreshActiveTab();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? c.brand : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: c.brand.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tabs[tabIndex],
                          style: TextStyle(
                            color: isSelected ? c.onBrand : c.iconMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? c.onBrand.withValues(alpha: 0.2)
                                : c.brand.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${counts[tabIndex]}',
                            style: TextStyle(
                              color: isSelected ? c.onBrand : c.brand,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

String _employeeTaskKey(TaskModel task) {
  return '${task.ticketNo}_${task.refKey}_${task.reqSendId}';
}

class ERPTaskListSection extends StatefulWidget {
  const ERPTaskListSection({super.key, this.activeNotificationId});

  final String? activeNotificationId;

  @override
  State<ERPTaskListSection> createState() => _ERPTaskListSectionState();
}

class _ERPTaskListSectionState extends State<ERPTaskListSection>
    with AutomaticKeepAliveClientMixin {
  bool _selectionMode = false;

  @override
  bool get wantKeepAlive => true;

  void _enterSelectionMode() => setState(() => _selectionMode = true);

  void _exitSelectionMode(TaskProvider provider) {
    provider.clearSelection();
    setState(() => _selectionMode = false);
    context
        .findAncestorStateOfType<_TaskWorkspaceState>()
        ?._suspendBulkWebViewIfOpen();
  }

  void _onSelectionChanged(
    TaskProvider provider,
    VoidCallback changeSelection,
  ) {
    changeSelection();
    context
        .findAncestorStateOfType<_TaskWorkspaceState>()
        ?._suspendBulkWebViewIfOpen();
  }

  Future<void> _confirmBulkAction(
    BuildContext context,
    TaskProvider provider, {
    required bool isApprove,
  }) async {
    final ids =
        D365TaskListModel.getSelectedNotificationIds(provider.d365TaskList);
    if (ids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select any work items!')),
      );
      return;
    }

    final action = isApprove ? 'approve' : 'reject';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => CustomDialog(
        icon: isApprove ? Icons.check_circle_outline : Icons.cancel_outlined,
        destructive: !isApprove,
        title: isApprove ? 'Approve selected tasks?' : 'Reject selected tasks?',
        subtitle:
            'You are about to $action ${ids.length} item${ids.length == 1 ? '' : 's'}. This will open the submission page.',
        yesTitle: isApprove ? 'Approve' : 'Reject',
        noTitle: 'Cancel',
        yes: () => Navigator.pop(context, true),
        no: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final urlAction = isApprove ? 'Approve' : 'Reject';
    final url =
        'https://rakp.rpsmart.com/d365emailnotifications/D365FnoWorkflowMultiSubmission.aspx?NotificationId=${ids.join(',')}&Action=$urlAction';

    context
        .findAncestorStateOfType<_TaskWorkspaceState>()
        ?._openErpBulkUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isDD365Loading) {
          return const _TaskListSkeleton();
        }

        if (provider.d365TaskList.isEmpty) {
          return _TaskEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No ERP tasks',
            subtitle: 'You’re all caught up on ERP workflow items.',
            onRefresh: () => provider.getd365TaskList(),
          );
        }

        final hasSelection = provider.checkForSelection();
        final selectedCount =
            provider.d365TaskList.where((task) => task.isSelected).length;
        final showSelectionUi = _selectionMode || hasSelection;

        return Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: showSelectionUi
                  ? _ErpSelectionBar(
                      key: const ValueKey('selection-bar'),
                      selectedCount: selectedCount,
                      totalCount: provider.d365TaskList.length,
                      isAllSelected: provider.isAllSelect,
                      onSelectAll: () => _onSelectionChanged(
                        provider,
                        provider.selectAll,
                      ),
                      onClear: () => _exitSelectionMode(provider),
                      onToggleAll: () => _onSelectionChanged(
                        provider,
                        provider.isAllSelect
                            ? provider.clearSelection
                            : provider.selectAll,
                      ),
                    )
                  : _ErpSelectPrompt(
                      key: const ValueKey('select-prompt'),
                      onStart: _enterSelectionMode,
                    ),
            ),
            Expanded(
              child: Stack(
                children: [
                  RefreshIndicator(
                    onRefresh: () => provider.getd365TaskList(),
                    child: ListView.builder(
                      key: const PageStorageKey('erp_list'),
                      padding: EdgeInsets.only(
                        top: 4,
                        bottom: hasSelection ? 84 : 8,
                      ),
                      itemCount: provider.d365TaskList.length,
                      itemBuilder: (context, index) {
                        final task = provider.d365TaskList[index];
                        return D365tasktile(
                          task: task,
                          isSelected: task.isSelected,
                          selectionMode: showSelectionUi,
                          isActive: !showSelectionUi &&
                              widget.activeNotificationId != null &&
                              widget.activeNotificationId ==
                                  task.notificationId,
                          onChanged: (_) {
                            if (!_selectionMode) _enterSelectionMode();
                            _onSelectionChanged(
                              provider,
                              () => provider.toggleSelection(index),
                            );
                          },
                          onTapLink: showSelectionUi
                              ? null
                              : () => context
                                  .findAncestorStateOfType<
                                      _TaskWorkspaceState>()
                                  ?._handleERPWebRedirect(
                                      context, provider, index),
                        );
                      },
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedSlide(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      offset:
                          hasSelection ? Offset.zero : const Offset(0, 1.2),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: hasSelection ? 1 : 0,
                        child: IgnorePointer(
                          ignoring: !hasSelection,
                          child: _ErpBulkActionBar(
                            selectedCount: selectedCount,
                            onApprove: () => _confirmBulkAction(
                              context,
                              provider,
                              isApprove: true,
                            ),
                            onReject: () => _confirmBulkAction(
                              context,
                              provider,
                              isApprove: false,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErpSelectPrompt extends StatelessWidget {
  const _ErpSelectPrompt({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.checklist_rounded, size: 18),
          label: const Text('Bulk select'),
          style: TextButton.styleFrom(
            foregroundColor: c.brand,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: c.brand.withValues(alpha: 0.2)),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErpSelectionBar extends StatelessWidget {
  const _ErpSelectionBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.isAllSelected,
    required this.onSelectAll,
    required this.onClear,
    required this.onToggleAll,
  });

  final int selectedCount;
  final int totalCount;
  final bool isAllSelected;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.brand.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.brand.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$selectedCount selected',
              style: TextStyle(
                color: c.onBrand,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: isAllSelected ? onToggleAll : onSelectAll,
            style: TextButton.styleFrom(
              foregroundColor: c.brand,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: Text(isAllSelected ? 'Deselect all' : 'Select all'),
          ),
          const Spacer(),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: c.iconMuted,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _ErpBulkActionBar extends StatelessWidget {
  const _ErpBulkActionBar({
    required this.selectedCount,
    required this.onApprove,
    required this.onReject,
  });

  final int selectedCount;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.fromLTRB(2, 8, 2, 2),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: c.cardFill.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text('Approve ($selectedCount)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green.withValues(alpha: 0.14),
                    foregroundColor: AppColors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text('Reject ($selectedCount)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.finalRed.withValues(alpha: 0.12),
                    foregroundColor: AppColors.finalRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmployeeTaskListSection extends StatefulWidget {
  const EmployeeTaskListSection({super.key, this.activeTaskKey});

  final String? activeTaskKey;

  @override
  State<EmployeeTaskListSection> createState() =>
      _EmployeeTaskListSectionState();
}

class _EmployeeTaskListSectionState extends State<EmployeeTaskListSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isTaskListLoading) {
          return const _TaskListSkeleton();
        }

        if (provider.userTaskMap.isEmpty) {
          return _TaskEmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No employee tasks',
            subtitle: 'No assigned employee workflow items right now.',
            onRefresh: () => provider.getTaskListPermission(),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.getTaskListPermission(),
          child: ListView.builder(
            key: const PageStorageKey('employee_task_list'),
            padding: const EdgeInsets.only(bottom: 16, top: 4),
            itemCount: provider.userTaskMap.length,
            itemBuilder: (context, index) {
              final user = provider.userTaskMap.keys.elementAt(index);
              final tasks = provider.userTaskMap[user]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tasks.isNotEmpty)
                    _EmployeeGroupHeader(name: user.taskOf ?? 'Employee'),
                  ...tasks.map(
                    (task) => TaskTile(
                      task: task,
                      isActive:
                          widget.activeTaskKey == _employeeTaskKey(task),
                      onPressed: () {
                        final parentState = context
                            .findAncestorStateOfType<_TaskWorkspaceState>();
                        parentState?._handleEmployeeWebRedirect(
                          context,
                          provider,
                          task,
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _EmployeeGroupHeader extends StatelessWidget {
  const _EmployeeGroupHeader({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 8),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: c.brand,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: c.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskEmptyState extends StatelessWidget {
  const _TaskEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onRefresh,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: c.brand.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: c.brand),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: FilledButton.styleFrom(
                foregroundColor: c.brand,
                backgroundColor: c.brand.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskListSkeleton extends StatelessWidget {
  const _TaskListSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListView.separated(
      padding: const EdgeInsets.only(top: 4),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: c.shimmerBase,
          highlightColor: c.shimmerHighlight,
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              color: c.cardFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
          ),
        );
      },
    );
  }
}
