import 'dart:convert';

List<TaskModel> taskModelFromJson(String str) =>
    List<TaskModel>.from(json.decode(str).map((x) => TaskModel.fromJson(x)));

String taskModelToJson(List<TaskModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TaskModel {
  TaskModel(
      {this.refKey,
      this.refNo,
      this.type,
      this.reqSendId,
      this.reqId,
      this.empName,
      this.reqDate,
      this.sendTo,
      this.sendToUserId,
      this.sendToEmpNo,
      this.isCurrent,
      this.saveDate,
      this.savedBy,
      this.remarkDate,
      this.remarkTime,
      this.secCode,
      this.taskDisplay,
      this.approveLevel,
      this.rType,
      this.taskOfUid,
      this.approval,
      this.employeeId,
      this.ticketNo});

  // int? refKey;
  // int? refNo;
  // int? type;
  // int? reqSendId;
  // int? reqId;
  // String? empName;
  // DateTime? reqDate;
  // String? sendTo;
  // String? sendToUserId;
  // dynamic sendToEmpNo;
  // int? isCurrent;
  // DateTime? saveDate;
  // String? savedBy;
  // DateTime? remarkDate;
  // String? remarkTime;
  // String? secCode;
  // String? taskDisplay;
  // int? approveLevel;
  // String? rType;
  // String? taskOfUid;
  // String? approval;
  // int? employeeId;

  dynamic refKey;
  dynamic refNo;
  dynamic type;
  dynamic reqSendId;
  dynamic reqId;
  dynamic empName;
  dynamic reqDate;
  dynamic sendTo;
  dynamic sendToUserId;
  dynamic sendToEmpNo;
  dynamic isCurrent;
  dynamic saveDate;
  dynamic savedBy;
  dynamic remarkDate;
  dynamic remarkTime;
  dynamic secCode;
  dynamic taskDisplay;
  dynamic approveLevel;
  dynamic rType;
  dynamic taskOfUid;
  dynamic approval;
  dynamic employeeId;
  dynamic ticketNo;

  factory TaskModel.fromJson(Map<String, dynamic> json) => TaskModel(
        refKey: json["refkey"] == null ? null : json["refkey"],
        refNo: json["refNo"] == null ? null : json["refNo"],
        type: json["type"] == null ? null : json["type"],
        reqSendId: json["reqSendID"] == null ? null : json["reqSendID"],
        reqId: json["reqID"] == null ? null : json["reqID"],
        empName: json["empName"] == null ? null : json["empName"],
        reqDate:
            json["reqDate"] == null ? null : DateTime.parse(json["reqDate"]),
        sendTo: json["sendTO"] == null ? null : json["sendTO"],
        sendToUserId:
            json["sendToUserID"] == null ? null : json["sendToUserID"],
        sendToEmpNo: json["sendtoEmpNO"] == null ? null : json["sendtoEmpNO"],
        isCurrent: json["iscurrent"] == null ? null : json["iscurrent"],
        saveDate:
            json["saveDate"] == null ? null : DateTime.parse(json["saveDate"]),
        savedBy: json["savedBy"] == null ? null : json["savedBy"],
        remarkDate: json["remarkDate"] == null
            ? null
            : DateTime.parse(json["remarkDate"]),
        remarkTime: json["remarkTime"] == null ? null : json["remarkTime"],
        secCode: json["secCode"] == null ? null : json["secCode"],
        taskDisplay: json["taskDisplay"] == null ? null : json["taskDisplay"],
        approveLevel:
            json["approveLevel"] == null ? null : json["approveLevel"],
        rType: json["rType"] == null ? null : json["rType"],
        taskOfUid: json["taskofuid"] == null ? null : json["taskofuid"],
        approval: json["approval"] == null ? null : json["approval"],
        employeeId: json["employeeID"] == null ? null : json["employeeID"],
        ticketNo: json["refNo"] == null ? null : json["refNo"],
      );

  Map<String, dynamic> toJson() => {
        "refkey": refKey,
        "refNo": refNo,
        "type": type,
        "reqSendID": reqSendId,
        "reqID": reqId,
        "empName": empName,
        "reqDate": reqDate!.toIso8601String(),
        "sendTO": sendTo,
        "sendToUserID": sendToUserId,
        "sendtoEmpNO": sendToEmpNo,
        "iscurrent": isCurrent,
        "saveDate": saveDate!.toIso8601String(),
        "savedBy": savedBy,
        "remarkDate": remarkDate!.toIso8601String(),
        "remarkTime": remarkTime,
        "secCode": secCode,
        "taskDisplay": taskDisplay,
        "approveLevel": approveLevel,
        "rType": rType,
        "taskofuid": taskOfUid,
        "approval": approval,
        "employeeID": employeeId,
        "ticketNo": ticketNo
      };
}

class UsrModel {
  String? user;
  List<TaskModel>? list;

  UsrModel({this.user, this.list});

  UsrModel.fromJson(Map<String, dynamic> json) {
    user = json['user'];
    list = json['list'].cast<TaskModel>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user'] = user;
    data['list'] = list;
    return data;
  }
}
