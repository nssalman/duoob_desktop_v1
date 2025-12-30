import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/model/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'api_query.dart';

class UserRepository {
  // Session session = Session();

  // ignore: constant_identifier_names
  static const String IS_LOGGED_IN = "IS_LOGGED_IN";

  // ignore: constant_identifier_names
  static const String IS_NOT_NEW_USER = "IS_NOT_NEW_USER";

  // ignore: constant_identifier_names
  static const String USER_RESPONSE = "USER_RESPONSE";

  // ignore: constant_identifier_names
  static const String USER_DETAILS = "USER_DETAILS";

  // ignore: constant_identifier_names
  static const String USER_PROFILE = "USER_PROFILE";

  // ignore: constant_identifier_names
  static const String DEEP_LINK_CODE = "DEEP_LINK_CODE";

  // ignore: constant_identifier_names
  static const String SUCCESS_CODE = "SUCCESS_CODE";

  // ignore: constant_identifier_names
  static const String UAE_PASS_LOGGING = "UAE_PASS_LOGGING";

  // ignore: constant_identifier_names
  static const String UAE_PASS_ACTIVE = "UAE_PASS_ACTIVE";

  // ignore: constant_identifier_names
  static const String USER_TOKEN = "USER_TOKEN";

  // ignore: constant_identifier_names
  static const String LANGUAGE_CODE = "LANGUAGE_CODE";

  // ignore: constant_identifier_names
  static const String COMMUNITY_LIST = "COMMUNITY_LIST";

  // ignore: constant_identifier_names
  static const String PROFILE_DETAILS = "PROFILE_DETAILS";

  // ignore: constant_identifier_names
  static const String IS_OWNER = "IS_OWNER";

  // ignore: constant_identifier_names
  static const String DEVICE_NAME = "DEVICE_NAME";

  // ignore: constant_identifier_names
  static const String DEVICE_PLATFORM = "DEVICE_PLATFORM";

  // ignore: constant_identifier_names
  static const String DEVICE_MAN = "DEVICE_MAN";

  // ignore: constant_identifier_names
  static const String DEVICE_ID = "DEVICE_ID";

  // ignore: constant_identifier_names
  static const String DEVICE_VERSION = "DEVICE_VERSION";

  // Future<Response?> logOut() async {
  //   try {
  //     Response? response =
  //         await session.logoutQuery(Constants.apiLogout, 'LogoutApi');
  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> loginUser(String username, String password) async {
  //   try {
  //     var bytes = utf8.encode(password);
  //     var passEncyp = base64Encode(bytes);
  //     print(passEncyp);

  //     Map<String, String> data = {
  //       "Username": username,
  //       "grant_type": 'password',
  //       "client_id": 'RAKP',
  //       "scope": 'StaffMobileApp'
  //     };

  //     if (password != "") {
  //       data['password'] = passEncyp;
  //     }

  //     Map<String, String> headers = {
  //       'Content-Type': 'application/x-www-form-urlencoded',
  //       'Authorization': '~@#\$%^&()_+|}{P:"?><-=/-+."}',
  //     };

  //     //print(data);

  //     Response? response = await session.postQuery2(
  //         Constants.apiLogin, headers, data, 'LoginApi');

  //     /*print(response!.data);
  //     print(response.statusMessage);
  //     print(response.statusCode);*/

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> loginWithMicrosoft(String code) async {
  //   try {
  //     //print(data);
  //     Map<String, String> headers = {
  //       'Content-Type': 'application/json',
  //     };
  //     Response? response = await session.getQuery2(
  //         Constants.apiMicrosoftLogin + '?code=$code',
  //         headers,
  //         null,
  //         'getMicrosoftLoginApi',
  //         true,
  //         true,
  //         true);

  //     /*print(response!.data);
  //     print(response.statusMessage);
  //     print(response.statusCode);*/

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> checkIn(String status, String imgUrl, String location,
  //     double lat, double long) async {
  //   try {
  //     String token, userName, userId, employeeId;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     UserProfileModel? responseModel2 = await getUserProfileLocal();

  //     token = responseModel!.accessToken!;
  //     userName = responseModel.userName!;
  //     userId = responseModel.userId!;
  //     employeeId = responseModel2!.employeeId!.toString();

  //     Map<String, dynamic> data = {
  //       "transCardNO": employeeId,
  //       "transFunctionKey": status,
  //       "importedBy": userName,
  //       "punchingLocation": location,
  //       "imgUrl": imgUrl,
  //       "latitude": lat,
  //       "longitude": long,
  //       "UserID": userId
  //     };

  //     Map<String, String> headers = {};

  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     //print(data);

  //     Response? response = await session.postQuery3(
  //         Constants.apiPunchIn, headers, data, 'checkUSerApi');
  //     //print(response!.data);
  //     //print(response.statusMessage);
  //     //print(response.statusCode);
  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> uploadFileImage(File file) async {
  //   try {
  //     var image = File(file.path);
  //     String token, userName;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userName = responseModel.userName!;

  //     final bytes = File(image.path).readAsBytesSync();
  //     String img64 = base64Encode(bytes);

  //     String img2 =
  //         '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';

  //     Map<String, String> headers = {
  //       'Authorization': 'Bearer ' + token,
  //     };

  //     Map<String, String> extra = {
  //       'fileName': '$userName${DateTime.now()}.jpg',
  //       'fileKey': 'file',
  //     };

  //     //print('base 64 img');
  //     //print('data:image/jpeg;base64,' + img64);

  //     Response? response = await session.postQuery4(Constants.apiUploadImg,
  //         headers, 'data:image/png;base64,' + img64, extra, 'UploadImageApi');
  //     //print(response!.data);
  //     //print(response.statusMessage);
  //     //print(response.statusCode);
  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> changePassword(
  //     String oldPassword, String newPassword) async {
  //   try {
  //     String token, userName;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userName = responseModel.userName!;

  //     Map<String, String> data = {
  //       "OldPassword": oldPassword,
  //       "Password": newPassword,
  //       "UserName": userName,
  //     };

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     //print(data);

  //     Response? response = await session.postQuery3(
  //         Constants.apiChangePassword, headers, data, 'changePasswordApi');

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getAttendanceList() async {
  //   try {
  //     String token, employeeId;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     UserProfileModel? responseModel2 = await getUserProfileLocal();

  //     token = responseModel!.accessToken!;
  //     employeeId = responseModel2!.employeeId!.toString();

  //     Map<String, String> data = {
  //       //"OldPassword" : oldPassword,
  //       //"Password" : newPassword,
  //       "transCardNO": employeeId,
  //     };
  //     print(data);

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     //print(data);

  //     Response? response = await session.getQuery2(
  //         Constants.apiGetAttendanceList,
  //         headers,
  //         data,
  //         'getAttendanceListApi',
  //         true,
  //         true,
  //         true);

  //     //print(response!.statusCode);
  //     //print(response.data);
  //     //print(response.statusMessage);

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getUserProfile() async {
  //   try {
  //     String token, userId;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userId = responseModel.userId!;

  //     Map<String, String> data = {
  //       "UID": userId,
  //     };

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     //print(data);

  //     Response? response = await session.getQuery2(
  //         Constants.apiGetUserInfo + '?UID=$userId',
  //         headers,
  //         null,
  //         'getUserProfileApi',
  //         true,
  //         true,
  //         true);
  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getTaskPermission() async {
  //   try {
  //     String token, userId;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     UserProfileModel? userProfileModel = await getUserProfileLocal();
  //     token = responseModel!.accessToken!;

  //     userId = userProfileModel!.uid!.toString();
  //     String deviceId = await getDeviceID();

  //     Map<String, String> data = {
  //       "UDID": userId,
  //       "deviceID": deviceId,
  //     };
  //     print("324 The data is :${data} ....${token}");

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     print('getTaskPermission');

  //     print(data);

  //     Response? response = await session.getQuery2(
  //         Constants.apiGetTaskPermission,
  //         headers,
  //         data,
  //         'apiGetMyTaskPermission',
  //         true,
  //         true,
  //         true);
  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getUserTaskRights() async {
  //   try {
  //     String token, userId;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userId = responseModel.userName!;

  //     Map<String, String> data = {
  //       "usersid": userId,
  //     };

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     print(data);

  //     Response? response = await session.getQuery2(
  //         Constants.apiGetUserTaskRights,
  //         headers,
  //         data,
  //         'apiGetUserTaskRights',
  //         true,
  //         true,
  //         true);

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getD365Task({String? userId}) async {
  //   try {
  //     String token;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     UserProfileModel? userModel = await getUserProfileLocal();
  //     token = responseModel!.accessToken!;
  //     userId = userModel!.userId;
  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     log(Constants.apiGetD365Task + '?usersid=$userId');
  //     log(token.toString());
  //     Response? response = await session.getQuery2(
  //         Constants.apiGetD365Task + '?usersid=$userId', 
  //         headers,
  //         null,
  //         'apiGetD365TaskApi',
  //         true,
  //         true,
  //         true);

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getMyTask({String? userId}) async {
  //   try {
  //     String token;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;

  //     userId ??= responseModel.userName!;

  //     Map<String, String> data = {
  //       "usersid": userId,
  //     };

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     print(data);

  //     Response? response = await session.getQuery2(Constants.apiGetMyTask,
  //         headers, data, 'apiGetMyTaskApi', true, true, true);

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getRakpHrTask({String? userId}) async {
  //   try {
  //     String token;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userId ??= responseModel.userName!;

  //     Map<String, String> data = {
  //       "usersid": userId,
  //     };
  //     print("Line 424..");
  //     print(data);

  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     //print(data);

  //     Response? response = await session.getQuery2(Constants.apiGetHrTask,
  //         headers, data, 'apiGetHrTaskApi', true, true, true);
  //     print(response!.data);
  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getRakpAssetsTask({String? userId}) async {
  //   try {
  //     String token;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userId ??= responseModel.userName!;

  //     Map<String, String> data = {
  //       "usersid": userId,
  //     };

  //     print(data);
  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     //print(data);

  //     Response? response = await session.getQuery2(Constants.apiGetAssetTask,
  //         headers, data, 'apiGetAssetTaskApi', true, true, true);

  //     print(" 468 The user res is:");
  //     print(response!.data);
  //     print(response.statusCode);
  //     return response;
  //   } catch (exception) {
  //     print("The expection is 472:");
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getOneTimeKey() async {
  //   try {
  //     String token, userId, refreshToken;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userId = responseModel.userName!;
  //     refreshToken = responseModel.refreshToken!;

  //     Map<String, String> data = {
  //       "refreshToken": refreshToken,
  //     };

  //     print(data);
  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     print(data);

  //     Response? response = await session.getQuery2(Constants.apiOneTimeKey,
  //         headers, data, 'apiGetOneTimeKey', true, true, true);

  //     return response;
  //   } catch (exception) {
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  // Future<Response?> getRedirectUrl(String key, TaskModel task) async {
  //   try {
  //     // var  d = {
  //     //     "SendToUserID": task.sendToUserId??0 ,
  //     //     "ApproveLevel": task.approveLevel??0,
  //     //     "ReqType": task.type!,
  //     //     "ReqID": task.reqId!,
  //     //     "Seccode": task.secCode??0 ,
  //     //     "ReqSendID": task.reqSendId??0
  //     //   };
  //     //   print("api res 519 ${d['SendToUserID']}");
  //     print("api res 528");
  //     // print(task.toJson().toString());
  //     print(task.type.runtimeType);
  //     print(task.approveLevel);
  //     print(task.reqId);
  //     print(task.rType);
  //     print(task.secCode);
  //     print(task.reqSendId);
  //     print("api res");

  //     //   print("api res 526");
  //     //   print(task.sendToUserId.runtimeType ==Null );
  //     //   print(task.approveLevel);
  //     //   print("api res 526");
  //     String token, userId, refreshToken;
  //     LoginResponseModel? responseModel = await getLoginResponse();
  //     token = responseModel!.accessToken!;
  //     userId = responseModel.userName!;
  //     refreshToken = responseModel.refreshToken!;
  //     //  print("The key is : ${key}");
  //     //  print("The token is: ${token}");
  //     // print("api res 526");
  //     // // print(task.toJson());
  //     // print(task.approveLevel);
  //     print(task.reqId.runtimeType);
  //     print(task.rType.runtimeType);
  //     // print(task.secCode);
  //     // print(task.reqSendId);
  //     // print("api res");
  //     Map<String, dynamic> data = {
  //       "SendToUserID": task.sendToUserId ?? "",
  //       "ApproveLevel": task.approveLevel ?? 0,
  //       "ReqType": int.parse(task.type.toString()),
  //       "ReqID": int.parse(task.reqId.toString()),
  //       "Seccode": task.secCode ?? 0,
  //       "ReqSendID": task.reqSendId ?? 0
  //     };

  //     print("The given Line is 533");
  //     print(data);
  //     Map<String, String> headers = {};
  //     headers = {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'Bearer $token',
  //     };

  //     print(data);

  //     Response? response = await session.getQuery2(
  //         Constants.apiGetTaskDetailsLink,
  //         headers,
  //         data,
  //         'apiGetRedirectUrl',
  //         true,
  //         true,
  //         true);

  //     return response!;
  //   } catch (exception) {
  //     print("The eception is : line 549");
  //     print(exception.toString());
  //     return null;
  //   }
  // }

  ////////////////// shared pref //////////////////

  Future<LoginResponseModel?> getLoginResponse() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(USER_DETAILS) == null) {
      return null;
    } else {
      String? userResponse = prefs.getString(USER_DETAILS);
      return LoginResponseModel.fromJson(json.decode(userResponse!));
    }
  }

  storeLoginResponse(LoginResponseModel userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userProfileJson = json.encode(userData);
    prefs.setString(USER_DETAILS, userProfileJson);
    print("The user preference is : ${await prefs.getString(USER_DETAILS)}");
  }

  Future<UserProfileModel?> getUserProfileLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getString(USER_PROFILE) == null) {
      return null;
    } else {
      String? userResponse = prefs.getString(USER_PROFILE);
      return UserProfileModel.fromJson(json.decode(userResponse!));
    }
  }

  storeUserProfile(UserProfileModel userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userProfileJson = json.encode(userData);
    prefs.setString(USER_PROFILE, userProfileJson);
  }

  //user login
  Future<bool> isUserLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IS_LOGGED_IN) ?? false;
  }

  setUserLoggedIn(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(IS_LOGGED_IN, isLoggedIn);
  }

  // to know whether its a first time user
  Future<bool?> isNotNewUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IS_NOT_NEW_USER) ?? false;
  }

  setNotNewUser(bool isNotNewUser) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setBool(IS_NOT_NEW_USER, isNotNewUser);
  }

  // to store user token
  Future<String?> getUserToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_TOKEN);
  }

  storeUserToken(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(USER_TOKEN, code);
  }

  Future<String?> getLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(LANGUAGE_CODE);
  }

  setLanguage(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(LANGUAGE_CODE, code);
  }

  /////////// DEVICE INFO /////////////
  //NAME
  Future<String> getDeviceName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(DEVICE_NAME) ?? '';
  }

  setDeviceName(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(DEVICE_NAME, code);
  }

  //MANUFACTURER
  Future<String> getDeviceMan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(DEVICE_MAN) ?? '';
  }

  setDeviceMan(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(DEVICE_MAN, code);
  }

  //VERSION
  Future<String> getDeviceVersion() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(DEVICE_VERSION) ?? '';
  }

  setDeviceVersion(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(DEVICE_VERSION, code);
  }

  //PLATFORM
  Future<String> getDevicePlatform() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(DEVICE_PLATFORM) ?? '';
  }

  setDevicePlatform(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(DEVICE_PLATFORM, code);
  }

  //DEVICE ID
  Future<String> getDeviceID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    //return "7eda5e723ec6f0e5";
    return prefs.getString(DEVICE_ID) ?? '';
  }

  setDeviceID(String code) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.setString(DEVICE_ID, code);
  }

  Future<void> clear() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }
}
