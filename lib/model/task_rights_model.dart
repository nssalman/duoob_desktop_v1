import 'dart:convert';
List<TaskRightsModel> taskRightsModelFromJson(String str) => List<TaskRightsModel>.from(json.decode(str).map((x) => TaskRightsModel.fromJson(x)));

String taskModelToJson(List<TaskRightsModel> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TaskRightsModel {
  TaskRightsModel({
    this.userName,
    this.taskOf
  });

  String? userName;
  String? taskOf;

  factory TaskRightsModel.fromJson(Map<String, dynamic> json)=> TaskRightsModel(
      userName: json["userName"] == null ? null : json["userName"],
      taskOf: json["taskof"] == null ? null : json["taskof"]
  );

  Map<String, dynamic> toJson() =>
      {
    "userName": userName,
    "taskof": taskOf,
  };

}
