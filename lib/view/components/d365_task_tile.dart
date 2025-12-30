import 'package:auto_size_text/auto_size_text.dart';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:readmore/readmore.dart';

class D365tasktile extends StatelessWidget {
  final D365TaskListModel task;
  final Function()? onTapLink;
  final Function(bool?) onChanged;
  final bool isSelected;
  const D365tasktile(
      {Key? key,
      required this.task,
      this.onTapLink,
      required this.onChanged,
      this.isSelected = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: InkWell(
        onTap: onTapLink,
        child: Card(
          shadowColor: Colors.blue.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.blueGrey, width: 0.05),
          ),
          elevation: 3,
          color: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              // border: Border.all(color: Colors.grey[300]!, width: 1)
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.5),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blueGrey,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 5),
                              child: Text(
                                (task.subject != null)
                                    ? task.subject.toString().contains(':')
                                        ? task.subject
                                            .toString()
                                            .split(':')
                                            .first
                                            .split(' ')
                                            .first
                                        : task.subject.toString()
                                    : task.notificationId != null
                                        ? task.notificationId.toString()
                                        : '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Spacer(),
                          Icon(
                            Icons.calendar_month,
                            color: Colors.blueGrey,
                            size: 18,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            (task.createdDateTimeWorkItem != null)
                                ? DateFormat('MMM dd,yyyy')
                                    .format(task.createdDateTimeWorkItem!)
                                : '',
                            style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      if (task.amount != null)
                        Row(
                          children: [
                            Text(
                              'Amount : ',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                            Expanded(
                              child: AutoSizeText(
                                task.amount.toStringAsFixed(2),
                                maxFontSize: 14,
                                minFontSize: 6,
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      // if (task.amount != null)
                      //   const SizedBox(
                      //     height: 5,
                      //   ),
                      Row(
                        children: [
                          if (onTapLink != null)
                            Expanded(
                              child: Text(
                                ' ${task.description != null && extractRequester(task.description!).isNotEmpty ? ' By : ${extractRequester(task.description!)}' : '${extractDescription(task.subject.toString())}'}',
                                // task.subject.toString(),
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          if (onTapLink == null)
                            Expanded(
                              child: Text(
                                extractDescription(task.subject.toString()),
                                // task.subject.toString(),
                                style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          Checkbox(
                            value: isSelected,
                            onChanged: onChanged,
                            materialTapTargetSize: MaterialTapTargetSize.padded,
                            checkColor: Colors.white,
                            activeColor: Colors.blue,
                          ),
                        ],
                      ),

                      // if (task.description != null &&
                      //     extractRequester(task.description!).isNotEmpty)
                      //   Row(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Text(
                      //         'Requester : ',
                      //         style: AppTextStyles.blackHead
                      //             .copyWith(color: Colors.blueGrey),
                      //       ),
                      //       Expanded(
                      //           child: Text(extractRequester(task.description!),
                      //               style: const TextStyle(
                      //                 color: Colors.black,
                      //                 fontSize: 14,
                      //               ))),
                      //     ],
                      //   ),
                      // if (task.description != null &&
                      //     extractRequester(task.description!).isNotEmpty)
                      //   const SizedBox(
                      //     height: 5,
                      //   ),
                      if (task.description != null &&
                          extractGeneralDescription(task.description!)
                              .isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Description : ',
                              style: TextStyle(color: Colors.blueGrey),
                            ),
                            Expanded(
                              child: ReadMoreText(
                                extractGeneralDescription(task.description!),
                                trimLines: 2,
                                colorClickableText: Colors.blue,
                                trimMode: TrimMode.Line,
                                trimCollapsedText: '... Read more',
                                trimExpandedText: ' Read less',
                                style: TextStyle(fontSize: 14),
                                moreStyle: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                lessStyle: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String extractDescription(String input) {
    // This regex handles variations like "PR : RP-...", "PR No : RP-...", "SRN: RP-..."
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
      // Capture the description line and everything that follows, until the next field (e.g., "ERP:", "Requester:", etc.)
      String rest = input.substring(match.start);
      final endRegex =
          RegExp(r'\r?\n\r?\n[A-Z][^:]{1,50}:\s*', multiLine: true);
      final endMatch = endRegex.firstMatch(rest);
      if (endMatch != null) {
        return rest
            .substring(0, endMatch.start)
            .replaceFirst(
                RegExp(r'General description\s*:\s*', caseSensitive: false), '')
            .trim();
      } else {
        // No ending field matched, so return everything after General description
        return rest
            .replaceFirst(
                RegExp(r'General description\s*:\s*', caseSensitive: false), '')
            .trim();
      }
    }
    return '';
  }

  String extractRequester(String input) {
    final regex = RegExp(r'Requester\s*:\s*(.*)', caseSensitive: false);
    final match = regex.firstMatch(input);
    if (match != null) {
      // Capture the description line and everything that follows, until the next field (e.g., "ERP:", "Requester:", etc.)
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
        // No ending field matched, so return everything after Requester
        return rest
            .replaceFirst(RegExp(r'Requester\s*:\s*', caseSensitive: false), '')
            .trim();
      }
    }
    return '';
  }
}