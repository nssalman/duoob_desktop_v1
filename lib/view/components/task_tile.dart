import 'package:duoob_desktop_app_v1/model/task_model.dart';
import 'package:duoob_desktop_app_v1/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  final Function() onPressed;
  const TaskTile({Key? key, required this.task, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: InkWell(
        onTap: () {
          onPressed();
        },
        child: Card(
          shadowColor: AppColors.blue.withValues(alpha: 0.3),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      child: Text(
                        (task.ticketNo != null) ? task.ticketNo.toString() : '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Colors.green,
                    //     borderRadius: BorderRadius.circular(3),
                    //   ),
                    //   padding: const EdgeInsets.symmetric(horizontal: 8,vertical: 5),
                    //   child: Text(
                    //     (task.ticketNo != null) ? task.ticketNo.toString() : '',
                    //     style: const TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.normal
                    //     ),
                    //   ),
                    // ),

                    Spacer(),
                    Icon(
                      Icons.calendar_month,
                      color: Colors.blueGrey,
                      size: 18,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      (task.reqDate != null)
                          ? DateFormat('MMM dd,yyyy').format(task.reqDate)
                          : '',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.normal),
                    ),
                    // Container(
                    //   decoration: BoxDecoration(
                    //     color: Colors.grey,
                    //     borderRadius: BorderRadius.circular(3),
                    //   ),
                    //   padding:
                    //       const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    //   child: Text(
                    //     (task.reqDate != null)
                    //         ? DateFormat('MMM dd,yyyy').format(task.reqDate)
                    //         : '',
                    //     style: const TextStyle(
                    //         color: Colors.white,
                    //         fontSize: 14,
                    //         fontWeight: FontWeight.normal),
                    //   ),
                    // ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${(task.taskDisplay != null) ? task.taskDisplay! : ''} ${(task.empName == null || task.empName == "") ? '' : "  -  ${task.empName!}"}",
                        style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(
                  task.rType.toString() == "8"
                      ? "CS-Ticket"
                      : (task.rType != null)
                          ? task.rType.toString()
                          : '',
                  style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
