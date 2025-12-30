import 'dart:convert';

LoginResponseModel loginResponseModelFromJson(String str) => LoginResponseModel.fromJson(json.decode(str));

String loginResponseModelToJson(LoginResponseModel data) => json.encode(data.toJson());

class LoginResponseModel {

  LoginResponseModel({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.userName,
    this.userId,
    this.language,
    this.clientId,
    this.refreshToken,
    this.issued,
    this.expires,
  });

  String? accessToken;
  String? tokenType;
  String? expiresIn;
  String? userName;
  String? userId;
  String? language;
  String? clientId;
  String? refreshToken;
  String? issued;
  String? expires;

  factory LoginResponseModel
      .fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
    accessToken: json["access_token"],
    tokenType: json["token_type"],
    expiresIn: json["expires_in"].toString(),
    userName: json["userName"],
    userId: json["UserID"].toString(),
    language: json["language"],
    clientId: json["ClientID"].toString(),
    refreshToken: json["refreshToken"],
    issued: json[".issued"],
    expires: json[".expires"],
  );

  Map<String, dynamic> toJson() => {
    "access_token": accessToken,
    "token_type": tokenType,
    "expires_in": expiresIn,
    "userName": userName,
    "UserID": userId,
    "language": language,
    "ClientID": clientId,
    "refreshToken": refreshToken,
    ".issued": issued,
    ".expires": expires,
  };


}
