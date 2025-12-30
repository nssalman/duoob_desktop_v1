import 'dart:convert';
import 'dart:developer';

List<D365TaskListModel> d365TaskListModelFromJson(String str) => List<D365TaskListModel>.from(json.decode(str).map((x) => D365TaskListModel.fromJson(x)));

String d365TaskListModelToJson(List<D365TaskListModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class D365TaskListModel {
    String? notificationId;
    String? linkToWeb;
    String? subject;
    String? description;
    dynamic amount;
    DateTime? createdDateTimeWorkItem;
    bool isSelected;
    

    D365TaskListModel({
        this.notificationId,
        this.linkToWeb,
        this.subject,
        this.description,
        this.amount,
        this.createdDateTimeWorkItem,
        this.isSelected = false
    });

    factory D365TaskListModel.fromJson(Map<String, dynamic> json) => D365TaskListModel(
        notificationId: json["notificationId"],
        linkToWeb: json["linkToWeb"],
        subject: json["subject"],
        description: json["description"],
        amount: json["amount"],
        createdDateTimeWorkItem: json["createdDateTimeWorkItem"] == null ? null : DateTime.parse(json["createdDateTimeWorkItem"]),
    );

    Map<String, dynamic> toJson() => {
        "notificationId": notificationId,
        "linkToWeb": linkToWeb,
        "subject": subject,
        "description": description,
        "amount": amount,
        "createdDateTimeWorkItem": createdDateTimeWorkItem?.toIso8601String(),
    };

   static List<String> getSelectedNotificationIds(List<D365TaskListModel> taskList) {
    log(taskList.toString(),name: 'Task list');
  return taskList
      .where((task) => task.isSelected && task.notificationId != null) // Filter selected tasks
      .map((task) => task.notificationId!) // Extract notificationId
      .toList(); // Convert to a list
}
}
