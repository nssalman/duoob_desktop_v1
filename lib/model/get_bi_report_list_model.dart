import 'dart:convert';

GetBiReportListModel getBiReportListModelFromJson(String str) => GetBiReportListModel.fromJson(json.decode(str));

String getBiReportListModelToJson(GetBiReportListModel data) => json.encode(data.toJson());

class GetBiReportListModel {
    int? status;
    String? message;
    List<BiReportListModel>? data;

    GetBiReportListModel({
        this.status,
        this.message,
        this.data,
    });

    factory GetBiReportListModel.fromJson(Map<String, dynamic> json) => GetBiReportListModel(
        status: json["status"],
        message: json["message"],
        data: json["data"] == null ? [] : List<BiReportListModel>.from(json["data"]!.map((x) => BiReportListModel.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "data": data == null ? [] : List<dynamic>.from(data!.map((x) => x.toJson())),
    };
}

class BiReportListModel {
    int? userTypeId;
    int? fileId;
    String? description;
    String? fileName;
    String? folder;
    String? type;
    int? isMaster;

    BiReportListModel({
        this.userTypeId,
        this.fileId,
        this.description,
        this.fileName,
        this.folder,
        this.type,
        this.isMaster,
    });

    factory BiReportListModel.fromJson(Map<String, dynamic> json) => BiReportListModel(
        userTypeId: json["userTypeID"],
        fileId: json["fileID"],
        description: json["description"],
        fileName: json["fileName"],
        folder: json["folder"],
        type: json["type"],
        isMaster: json["isMaster"],
    );

    Map<String, dynamic> toJson() => {
        "userTypeID": userTypeId,
        "fileID": fileId,
        "description": description,
        "fileName": fileName,
        "folder": folder,
        "type": type,
        "isMaster": isMaster,
    };
}

