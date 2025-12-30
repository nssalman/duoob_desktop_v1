import 'dart:convert';

UserProfileModel userProfileModelFromJson(String str) => UserProfileModel.fromJson(json.decode(str));

String userProfileModelToJson(UserProfileModel data) => json.encode(data.toJson());

class UserProfileModel {
  UserProfileModel({
    this.uid,
    this.imgUrl,
    this.isCompany,
    this.employeeId,
    this.repName,
    this.userId,
    this.address,
    this.email,
    this.userName,
    this.isActive,
    this.isPunchingAllowed,
    this.fullName,
  });

  int? uid;
  dynamic imgUrl;
  int? isCompany;
  int? employeeId;
  String? repName;
  String? userId;
  String? address;
  String? email;
  String? userName;
  int? isActive;
  int? isPunchingAllowed;
  String? fullName;

  factory UserProfileModel
      .fromJson(
      Map<String, dynamic> json) =>

      UserProfileModel(
    uid: json["uid"],
    imgUrl: json["imgUrl"],
    isCompany: json["isCompany"],
    employeeId: json["employeeID"],
    repName: json["repName"],
    userId: json["userID"],
    address: json["address"],
    email: json["email"],
    userName: json["userName"],
    isActive: json["isActive"],
    isPunchingAllowed: json["is_punching_allowed"],
    fullName: json["fullName"],
  );

  Map<String, dynamic> toJson() =>

      {
    "uid": uid,
    "imgUrl": imgUrl,
    "isCompany": isCompany,
    "employeeID": employeeId,
    "repName": repName,
    "userID": userId,
    "address": address,
    "email": email,
    "userName": userName,
    "isActive": isActive,
    "is_punching_allowed": isPunchingAllowed,
    "fullName": fullName,
  };

}
