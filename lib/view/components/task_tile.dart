import 'package:duoob_desktop_app_v1/model/task_model.dart';
import 'package:duoob_desktop_app_v1/utils/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onPressed;
  final bool isActive;

  const TaskTile({
    super.key,
    required this.task,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final typeLabel = task.rType.toString() == '8'
        ? 'CS-Ticket'
        : (task.rType != null ? task.rType.toString() : '');
    final title = [
      if (task.taskDisplay != null && '${task.taskDisplay}'.isNotEmpty)
        '${task.taskDisplay}',
      if (task.empName != null && '${task.empName}'.isNotEmpty) '${task.empName}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: c.cardFill,
        elevation: isActive ? 2 : 0,
        shadowColor: c.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: isActive
                ? c.brand.withValues(alpha: 0.45)
                : c.border,
            width: isActive ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.brand,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    task.ticketNo?.toString() ?? '—',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: c.onBrand,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              if (typeLabel.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.brandSoft,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    typeLabel,
                                    style: TextStyle(
                                      color: c.brand,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                              const Spacer(),
                              Icon(
                                Icons.schedule_rounded,
                                size: 14,
                                color: c.iconMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                task.reqDate != null
                                    ? DateFormat('MMM dd, yyyy')
                                        .format(task.reqDate as DateTime)
                                    : '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          if (title.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: isActive ? c.brand : c.iconMuted,
                    ),
                  ),
                ],
              ),
              if (isActive)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: c.brand,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
