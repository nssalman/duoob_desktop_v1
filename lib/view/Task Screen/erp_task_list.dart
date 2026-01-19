// import 'package:duoob_desktop_app_v1/controller/task_provider.dart';
// import 'package:duoob_desktop_app_v1/view/components/d365_task_tile.dart';
// import 'package:duoob_desktop_app_v1/view/components/shimmer_loader.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';

// class ERPTaskListSection extends StatefulWidget {
//   const ERPTaskListSection({super.key});

//   @override
//   State<ERPTaskListSection> createState() => _ERPTaskListSectionState();
// }

// class _ERPTaskListSectionState extends State<ERPTaskListSection> with AutomaticKeepAliveClientMixin {
//   @override
//   bool get wantKeepAlive => true; // Prevents the list from disposing

//   @override
//   Widget build(BuildContext context) {
//     super.build(context); // Required for KeepAlive
//     return Consumer<TaskProvider>(
//       builder: (context, provider, child) {
//         if (provider.isDD365Loading) return const ShimmerLoader(title: 'ERP Task');
        
//         return ListView.builder(
//           key: const PageStorageKey('erp_list'), // Helps preserve scroll position
//           itemCount: provider.d365TaskList.length,
//           itemBuilder: (context, index) {
//             final task = provider.d365TaskList[index];
//             return D365tasktile(
//               task: task,
//               // Use the parent's logic via context if needed, 
//               // or pass the callback down.
//               onTapLink: () => context.findAncestorStateOfType<_TaskWorkspaceState>()?._handleERPWebRedirect(context, provider, index),
//               // ... other props
//             );
//           },
//         );
//       },
//     );
//   }
// }