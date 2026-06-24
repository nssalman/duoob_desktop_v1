import 'package:flutter/material.dart';

class Constants{

    static const primaryColor = Color.fromRGBO(44, 174, 252, 1);
  static const buttonColor = Color.fromRGBO(86, 190, 253, 1);

  static const String baseUrl = 'https://api.rpsmart.com/';
    static const String coreBaseUrl = 'https://apiv2.rpsmart.com/'; // http://151.253.74.102/
  static const String domain = 'api.rpsmart.com';

  //api names
  static const String apiLogin = 'token';
  static const String apiLogout = 'auth/logout/';
  static const String apiChangePassword = 'api/user/changePassword';
  static const String apiGetAttendanceList = 'api/punching/getpunchingdetails';
  static const String apiGetUserInfo = 'api/user/GetUserInfo';
  static const String apiGetD365Task = 'api/tasks/getMyD365Tasks';
  static const String apiGetMyTask = 'api/tasks/getMyTasks';
  static const String apiGetHrTask = 'api/tasks/getRakpHrTasks';
  static const String apiGetAssetTask = 'api/tasks/getRakpAssetsTasks';
  static const String apiOneTimeKey = 'api/tasks/getOneTimeKey';
  static const String apiGetTaskDetailsLink = 'api/tasks/getTaskDetailsLink';
  static const String apiGetTaskPermission = 'api/tasks/getTasksListPermission';
  static const String apiGetUserTaskRights = 'api/tasks/getUserTaskRights';
  static const String apiMicrosoftLogin = 'api/user/getAccessTokenMS';

  static const String appBundleId = 'io.rak.rakpmsmart';
  static const String apiGetAppVersionByBundleId =
      'api/AppData/GetAppVersionByBundleId';

  static const String apiGetBiReport = 'api/Dashboard/getBIReportList';

  static const String kD365Url = 'https://rakp-prod.operations.uae.dynamics.com/';

  static const String reportsDashboardUrl =
      'https://rakp.rpsmart.com/version2/mydashboard.aspx';

  static const String myRakpUrl =
      'https://rakp.rpsmart.com/version2/index.aspx';

  static const String copilotBackendBaseUrl = 'https://apiv2.rpsmart.com';
  static const String copilotScope =
      'api://4ea53c57-1ea0-4fe6-b8e8-317b05a6cb1e/access_as_user';

  static const String apiUploadImg = 'api/account/user/PostPunchingUserImage';
  static const String apiPunchIn = 'api/punching/savepunchingdetails';
  static const String apiPunchInImages = 'PunchingFiles/';
}