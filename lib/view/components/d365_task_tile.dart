import 'package:auto_size_text/auto_size_text.dart';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:duoob_desktop_app_v1/utils/theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

class D365tasktile extends StatelessWidget {
  final D365TaskListModel task;
  final VoidCallback? onTapLink;
  final ValueChanged<bool?> onChanged;
  final bool isSelected;
  final bool selectionMode;
  final bool isActive;

  const D365tasktile({
    super.key,
    required this.task,
    this.onTapLink,
    required this.onChanged,
    this.isSelected = false,
    this.selectionMode = false,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final highlighted = isSelected || isActive;
    final borderColor = isSelected
        ? c.brand
        : isActive
            ? c.brand.withValues(alpha: 0.45)
            : c.border;
    final backgroundColor = isSelected
        ? c.brand.withValues(alpha: 0.07)
        : c.cardFill;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        elevation: highlighted ? 2 : 0,
        shadowColor: c.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: borderColor,
            width: highlighted ? 1.4 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: selectionMode ? () => onChanged(!isSelected) : onTapLink,
          child: Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 4),
                  if (selectionMode) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onChanged,
                        activeColor: c.brand,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        selectionMode ? 4 : 12,
                        12,
                        10,
                        12,
                      ),
                      child: _buildContent(context),
                    ),
                  ),
                  if (!selectionMode)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: highlighted ? c.brand : c.iconMuted,
                      ),
                    ),
                ],
              ),
              if (highlighted)
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

  Widget _buildContent(BuildContext context) {
    final c = context.colors;
    final requester = task.description != null
        ? extractRequester(task.description!)
        : '';
    final description = task.description != null
        ? extractGeneralDescription(task.description!)
        : '';
    final title = requester.isNotEmpty
        ? requester
        : extractDescription(task.subject?.toString() ?? '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: _Chip(
                label: _badgeLabel(),
                background: c.brand,
                foreground: c.onBrand,
              ),
            ),
            const SizedBox(width: 8),
            if (task.amount != null)
              _Chip(
                label: _formatAmount(task.amount),
                background: AppColors.green.withValues(alpha: 0.12),
                foreground: AppColors.green,
                icon: Icons.payments_outlined,
              ),
            const Spacer(),
            Icon(Icons.schedule_rounded, size: 14, color: c.iconMuted),
            const SizedBox(width: 4),
            Text(
              task.createdDateTimeWorkItem != null
                  ? DateFormat('MMM dd, yyyy')
                      .format(task.createdDateTimeWorkItem!)
                  : '—',
              style: TextStyle(
                fontSize: 12,
                color: c.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title.isEmpty ? 'ERP workflow item' : title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          ReadMoreText(
            description,
            trimLines: 2,
            colorClickableText: c.brand,
            trimMode: TrimMode.Line,
            trimCollapsedText: ' more',
            trimExpandedText: ' less',
            style: TextStyle(
              fontSize: 12.5,
              color: c.textMuted,
              height: 1.35,
            ),
            moreStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c.brand,
            ),
            lessStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c.brand,
            ),
          ),
        ],
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return NumberFormat.currency(symbol: '', decimalDigits: 2).format(amount);
    }
    return amount.toString();
  }

  String _badgeLabel() {
    if (task.subject != null) {
      final subject = task.subject.toString();
      if (subject.contains(':')) {
        return subject.split(':').first.split(' ').first;
      }
      return subject;
    }
    return task.notificationId ?? 'ERP';
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

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: AutoSizeText(
              label,
              maxLines: 1,
              minFontSize: 9,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
