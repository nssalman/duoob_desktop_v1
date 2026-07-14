import 'package:auto_size_text/auto_size_text.dart';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

class D365tasktile extends StatelessWidget {
  final D365TaskListModel task;
  final VoidCallback? onTapLink;
  final ValueChanged<bool?> onChanged;
  final bool isSelected;
  final bool selectionMode;

  const D365tasktile({
    super.key,
    required this.task,
    this.onTapLink,
    required this.onChanged,
    this.isSelected = false,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.blue
        : Colors.blueGrey.withValues(alpha: 0.2);
    final backgroundColor =
        isSelected ? AppColors.blue.withValues(alpha: 0.06) : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        elevation: isSelected ? 2 : 1,
        shadowColor: AppColors.blue.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: borderColor,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: selectionMode ? () => onChanged(!isSelected) : onTapLink,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectionMode) ...[
                  Checkbox(
                    value: isSelected,
                    onChanged: onChanged,
                    activeColor: AppColors.blue,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(child: _buildContent(context)),
                if (!selectionMode && onTapLink != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Text(
                  _badgeLabel(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const Spacer(),
            Icon(Icons.calendar_month, color: Colors.blueGrey, size: 16),
            const SizedBox(width: 4),
            Text(
              task.createdDateTimeWorkItem != null
                  ? DateFormat('MMM dd, yyyy')
                      .format(task.createdDateTimeWorkItem!)
                  : '',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ],
        ),
        if (task.amount != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Amount : ', style: TextStyle(color: Colors.blueGrey.shade400)),
              Expanded(
                child: AutoSizeText(
                  task.amount.toStringAsFixed(2),
                  maxFontSize: 14,
                  minFontSize: 10,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 6),
        Text(
          task.description != null &&
                  extractRequester(task.description!).isNotEmpty
              ? 'By : ${extractRequester(task.description!)}'
              : extractDescription(task.subject.toString()),
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (task.description != null &&
            extractGeneralDescription(task.description!).isNotEmpty) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Description : ', style: TextStyle(color: Colors.blueGrey.shade400)),
              Expanded(
                child: ReadMoreText(
                  extractGeneralDescription(task.description!),
                  trimLines: 2,
                  colorClickableText: Colors.blue,
                  trimMode: TrimMode.Line,
                  trimCollapsedText: '... Read more',
                  trimExpandedText: ' Read less',
                  style: const TextStyle(fontSize: 14),
                  moreStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  lessStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _badgeLabel() {
    if (task.subject != null) {
      final subject = task.subject.toString();
      if (subject.contains(':')) {
        return subject.split(':').first.split(' ').first;
      }
      return subject;
    }
    return task.notificationId ?? '';
  }

  String extractDescription(String input) {
    final pattern = RegExp(
      r'^(PR\s*(No)?\s*:?|SRN\s*:)\s*\S+\s*(/)?\s*',
      caseSensitive: false,
    );
    return input.replaceFirst(pattern, '').trim();
  }

  String extractGeneralDescription(String input) {
    final regex =
        RegExp(r'General description\s*:\s*(.*)', caseSensitive: false);
    final match = regex.firstMatch(input);
    if (match != null) {
      String rest = input.substring(match.start);
      final endRegex =
          RegExp(r'\r?\n\r?\n[A-Z][^:]{1,50}:\s*', multiLine: true);
      final endMatch = endRegex.firstMatch(rest);
      if (endMatch != null) {
        return rest
            .substring(0, endMatch.start)
            .replaceFirst(
                RegExp(r'General description\s*:\s*', caseSensitive: false),
                '')
            .trim();
      } else {
        return rest
            .replaceFirst(
                RegExp(r'General description\s*:\s*', caseSensitive: false),
                '')
            .trim();
      }
    }
    return '';
  }

  String extractRequester(String input) {
    final regex = RegExp(r'Requester\s*:\s*(.*)', caseSensitive: false);
    final match = regex.firstMatch(input);
    if (match != null) {
      String rest = input.substring(match.start);
      final endRegex =
          RegExp(r'\r?\n\r?\n[A-Z][^:]{1,50}:\s*', multiLine: true);
      final endMatch = endRegex.firstMatch(rest);
      if (endMatch != null) {
        return rest
            .substring(0, endMatch.start)
            .replaceFirst(RegExp(r'Requester\s*:\s*', caseSensitive: false), '')
            .trim();
      } else {
        return rest
            .replaceFirst(RegExp(r'Requester\s*:\s*', caseSensitive: false), '')
            .trim();
      }
    }
    return '';
  }
}
