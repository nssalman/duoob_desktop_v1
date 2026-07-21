import 'dart:convert';
import 'dart:developer';
import 'package:duoob_desktop_app_v1/model/d365_task_model.dart';
import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/model/task_model.dart';
import 'package:duoob_desktop_app_v1/model/task_rights_model.dart';
import 'package:duoob_desktop_app_v1/model/user_profile_model.dart';
import 'package:duoob_desktop_app_v1/services/api_services.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

class TaskProvider with ChangeNotifier {
  // --- Repository ---
  final UserRepository userRepository = UserRepository();

  // --- State Variables ---
  bool isDD365Loading = false;
  bool isTaskListLoading = false;
  bool isTaskLinkLoading = false;
  bool isAllSelect = false;
  bool isD365TaskListShowing = true;

  // --- Lists & Models ---
  List<D365TaskListModel> d365TaskList = [];
  List<TaskModel> tasksOfGetMyTask = [];
  List<TaskModel> myTaskList = [];
  List<TaskModel> hrTaskList = [];
  List<TaskModel> assetTaskList = [];
  List<UsrModel> userList = [];

  final List<TaskModel> _tasksOfGetMyTask = [];
  TaskModel? _mytask;
  Map<TaskRightsModel, List<TaskModel>> userTaskMap = {};
  UserProfileModel? userProfileModelView;

  // --- Device Info ---
  String? _deviceId, _manufacturer, _platform, _version, _model;

  // --- UI Actions ---
  void switchView() {
    isD365TaskListShowing = !isD365TaskListShowing;
    notifyListeners();
  }

  // --- Device Logic ---
  Future<void> getDeviceInfo() async {
    try {
      _deviceId = await userRepository.getDeviceID();
      _manufacturer = await userRepository.getDeviceMan();
      _platform = await userRepository.getDevicePlatform();
      _version = await userRepository.getDeviceVersion();
      _model = await userRepository.getDeviceName();
      // No notifyListeners here as this is usually called during init
    } catch (e) {
      log("Error getting device info: ${e.toString()}");
    }
  }

  // --- Main Fetching Logic ---

  Future<void> fetchUsersAndTasks() async {
    try {
      isTaskListLoading = true;
      notifyListeners();

      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      UserProfileModel? userProfileModel = await userRepository
          .getUserProfileLocal();
      userProfileModelView = userProfileModel;

      String token = responseModel!.accessToken!;
      String userId = userProfileModel!.uid!.toString();
      String userName = userProfileModel.userName!;
      String deviceId = await userRepository.getDeviceID();

      Map<String, String> taskPermisionData = {
        "UDID": userId,
        "deviceID": deviceId,
      };

      var response = await ApiServices.execute(
        method: apiMethod.get,
        accessToken: token,
        data: taskPermisionData,
        url: Constants.apiGetTaskPermission,
      );

      if (response != null && (response == 'true' || response == 'false')) {
        await getd365TaskList();

        Map<String, String> taskRightData = {"usersid": userName};
        var userTaskRightsResponse = await ApiServices.execute(
          method: apiMethod.get,
          accessToken: token,
          data: taskRightData,
          url: Constants.apiGetUserTaskRights,
        );

        if (userTaskRightsResponse != null) {
          var rightsJson = json.encode(userTaskRightsResponse);
          List<TaskRightsModel> taskRightsList = taskRightsModelFromJson(
            rightsJson,
          );
          Map<TaskRightsModel, List<TaskModel>> tempMap = {};

          for (TaskRightsModel user in taskRightsList) {
            Map<String, String> hrTaskData = {"usersid": user.taskOf ?? ""};
            var rakpHrTaskResponse = await ApiServices.execute(
              method: apiMethod.get,
              accessToken: token,
              data: hrTaskData,
              url: Constants.apiGetHrTask,
            );

            if (rakpHrTaskResponse != null) {
              var hrTaskJson = json.encode(rakpHrTaskResponse);
              tempMap[user] = taskModelFromJson(hrTaskJson);
            }
          }
          userTaskMap = tempMap;
        }
      }
    } catch (e) {
      log("Fetch Error: $e");
    } finally {
      isTaskListLoading = false;
      notifyListeners();
    }
  }

  Future<void> getTaskListPermission() async {
    try {
      isTaskListLoading = true;
      // isDD365Loading = true;
      notifyListeners();

      // 1. Get credentials
      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      String token = responseModel!.accessToken!;
      String userName = responseModel.userName!;

      // 2. Fetch User Rights (Who can this user see tasks for?)
      Map<String, String> data = {"usersid": userName};
      var rightsResponse = await ApiServices.execute(
        method: apiMethod.get,
        accessToken: token,
        data: data,
        url: Constants.apiGetUserTaskRights,
      );

      if (rightsResponse != null) {
        List<TaskRightsModel> taskRightsList = taskRightsModelFromJson(
          json.encode(rightsResponse),
        );

        // We will fill this map and then assign it to the provider variable
        Map<TaskRightsModel, List<TaskModel>> tempMap = {};

        for (var right in taskRightsList) {
          // 3. Fetch tasks for each specific user right
          Map<String, String> hrData = {"usersid": right.taskOf ?? ""};
          var taskRes = await ApiServices.execute(
            method: apiMethod.get,
            accessToken: token,
            data: hrData,
            url: Constants.apiGetHrTask,
          );

          if (taskRes != null) {
            List<TaskModel> tasks = taskModelFromJson(json.encode(taskRes));
            // Attach the sendToUserId to each task so the redirect logic works later
            for (var t in tasks) {
              t.sendToUserId = right.taskOf;
            }

            tempMap[right] = tasks;
          }
        }

        // Update the main map used by the UI
        userTaskMap = tempMap;
      }

      // 4. Fetch ERP/D365 Data (Optional placeholder fix)
      await getd365TaskList();
    } catch (e) {
      log("Error in getTaskListPermission: $e");
    } finally {
      isTaskListLoading = false;
      // isDD365Loading = false;
      notifyListeners(); // THIS triggers the UI rebuild
    }
  }

  Future<void> getRakpTaskList() async {
    try {
      userList.clear();
      myTaskList.clear();
      hrTaskList.clear();
      assetTaskList.clear();
      isTaskListLoading = true;
      notifyListeners();

      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      String token = responseModel!.accessToken!;
      String userId = responseModel.userName!;

      Map<String, String> data = {"usersid": userId};
      var userTaskRightsResponse = await ApiServices.execute(
        method: apiMethod.get,
        accessToken: token,
        data: data,
        url: Constants.apiGetUserTaskRights,
      );

      if (userTaskRightsResponse != null) {
        var rights = json.encode(userTaskRightsResponse);
        List<TaskRightsModel> taskRightsList = taskRightsModelFromJson(rights);

        for (TaskRightsModel element in taskRightsList) {
          await getRakpHrTaskList(userId: element.taskOf);
          await Future.delayed(const Duration(milliseconds: 100));

          // Improved async loop
          List<TaskModel> currentHrTasks = List.from(hrTaskList);
          for (var ar in currentHrTasks) {
            if (element.taskOf == ar.sendToUserId) {
              TaskModel tk = TaskModel(
                type: ar.type,
                reqId: ar.reqId,
                reqDate: ar.reqDate,
                sendToUserId: element.taskOf,
                taskDisplay: ar.taskDisplay,
                rType: ar.rType,
                ticketNo: ar.refNo,
              );

              _tasksOfGetMyTask.add(tk);

              await addToCustomerTaskList(
                tasks: _tasksOfGetMyTask,
                newTasks: [tk],
                prioritize: element.taskOf == userId,
              );

              hrTaskList.removeWhere((t) => t.reqId == tk.reqId);
            }
          }
        }

        // Cleanup and Grouping logic
        for (var hrl in myTaskList) {
          hrTaskList.removeWhere((e) => e.sendToUserId == hrl.sendToUserId);
        }

        hrTaskList = hrTaskList.toSet().toList();
        userList.clear();

        var groupedMap = groupBy(
          {for (var item in myTaskList) item.ticketNo: item}.values.toList(),
          (TaskModel obj) => obj.sendToUserId,
        );

        groupedMap.forEach((key, value) {
          userList.add(UsrModel.fromJson({'user': key, 'list': value}));
        });
      }
    } catch (e) {
      log(e.toString());
    } finally {
      isTaskListLoading = false;
      notifyListeners();
    }
  }

  // --- List Management ---

  List<TaskModel> addToTaskList({
    required List<TaskModel> tasks,
    required List<TaskModel> newTasks,
    required bool prioritize,
  }) {
    prioritize ? tasks.insertAll(0, newTasks) : tasks.addAll(newTasks);
    return tasks;
  }

  Future<void> addToCustomerTaskList({
    required List<TaskModel> tasks,
    required List<TaskModel> newTasks,
    required bool prioritize,
  }) async {
    prioritize
        ? myTaskList.insertAll(0, newTasks)
        : myTaskList.addAll(newTasks);
  }

  Future<void> addToHrTaskList({
    required List<TaskModel> tasks,
    required List<TaskModel> newTasks,
    required bool prioritize,
  }) async {
    prioritize
        ? hrTaskList.insertAll(0, newTasks)
        : hrTaskList.addAll(newTasks);
    hrTaskList = hrTaskList.toSet().toList();
  }

  // --- Individual Task Fetches ---

  Future<void> getMyTaskList({required userId}) async {
    try {
      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      String token = responseModel!.accessToken!;
      userId ??= responseModel.userName!;

      Map<String, String> data = {"usersid": userId};
      var myTaskResponse = await ApiServices.execute(
        method: apiMethod.get,
        accessToken: token,
        data: data,
        url: Constants.apiGetMyTask,
      );

      if (myTaskResponse != null && myTaskResponse is List) {
        for (var eldt in myTaskResponse) {
          _mytask = TaskModel(
            type: eldt['rType'],
            reqId: eldt['communLogID'],
            empName: eldt['clientName'],
            reqDate: DateTime.tryParse(eldt['communDate'].toString()),
            sendToUserId: userId,
            taskDisplay: eldt['remark'],
            rType: eldt['rType'].toString(),
            ticketNo: eldt['ticketNo'],
          );

          if (!myTaskList.contains(_mytask)) _tasksOfGetMyTask.add(_mytask!);
        }
        await addToCustomerTaskList(
          tasks: _tasksOfGetMyTask,
          newTasks: _tasksOfGetMyTask,
          prioritize: userId == responseModel.userName!,
        );
      }
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> getRakpHrTaskList({required userId}) async {
    try {
      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      String token = responseModel!.accessToken!;
      userId ??= responseModel.userName!;

      Map<String, String> data = {"usersid": userId};
      var rakpHrTaskResponse = await ApiServices.execute(
        method: apiMethod.get,
        accessToken: token,
        data: data,
        url: Constants.apiGetHrTask,
      );

      if (rakpHrTaskResponse != null) {
        var encodedData = json.encode(rakpHrTaskResponse);
        await addToHrTaskList(
          tasks: [],
          newTasks: taskModelFromJson(encodedData),
          prioritize: userId == responseModel.userName!,
        );
      }
    } catch (e) {
      log(e.toString());
    }
  }

  // --- External Redirect Logic ---

  Future<String?> redirectToWeb(TaskModel task) async {
    try {
      isTaskLinkLoading = true;
      notifyListeners();

      String? oneTimeKey = await getOneTimeKey();
      if (oneTimeKey != null) {
        String? redirectUrl = await getRedirectUrl(oneTimeKey, task);
        if (redirectUrl != null) {
          return '$redirectUrl&Key=$oneTimeKey&DID=$_deviceId';
        }
      }
      return null;
    } finally {
      isTaskLinkLoading = false;
      notifyListeners();
    }
  }

  Future<String?> getOneTimeKey() async {
    try {
      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      Map<String, String> data = {"refreshToken": responseModel!.refreshToken!};

      return await ApiServices.execute(
        method: apiMethod.get,
        accessToken: responseModel.accessToken!,
        data: data,
        url: Constants.apiOneTimeKey,
      );
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRedirectUrl(String key, TaskModel task) async {
    try {
      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      Map<String, String> data = {
        "SendToUserID": task.sendToUserId ?? "",
        "ApproveLevel": (task.approveLevel ?? 0).toString(),
        "ReqType": task.type.toString(),
        "ReqID": task.reqId.toString(),
        "Seccode": (task.secCode ?? 0).toString(),
        "ReqSendID": (task.reqSendId ?? 0).toString(),
      };

      return await ApiServices.execute(
        method: apiMethod.get,
        accessToken: responseModel!.accessToken!,
        data: data,
        url: Constants.apiGetTaskDetailsLink,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> getd365TaskList() async {
    // Prevent duplicate calls if already loading
    log('Fetching D365 Task loading');
    if (isDD365Loading) return;

    try {
      log('Fetching D365 Task');
      isDD365Loading = true;
      d365TaskList.clear();
      notifyListeners(); // Equivalent to update() in Provider

      // 1. Fetch Credentials
      LoginResponseModel? responseModel = await userRepository
          .getLoginResponse();
      UserProfileModel? userModel = await userRepository.getUserProfileLocal();

      if (responseModel == null || userModel == null) {
        log("Credentials not found");
        return;
      }

      String token = responseModel.accessToken!;
      // Use userId or uid based on your model's field name
      String userId = userModel.userId ?? '';

      log("Fetching D365 tasks for User: $userId");

      // 2. Execute API Call
      var response = await ApiServices.execute(
        method: apiMethod.get,
        accessToken: token,
        url: '${Constants.apiGetD365Task}?usersid=$userId',
      );

      // 3. Parse and Store Data
      if (response != null) {
        var parsedJson = json.encode(response);
        d365TaskList = d365TaskListModelFromJson(parsedJson);
      }
    } catch (e) {
      log("Error fetching D365 tasks: ${e.toString()}");
    } finally {
      isDD365Loading = false;
      notifyListeners(); // Refresh UI to show data or hide loader
    }
  }

  void toggleSelection(int index) {
    d365TaskList[index].isSelected = !d365TaskList[index].isSelected;
    isAllSelect = d365TaskList.every((e) => e.isSelected);
    notifyListeners();
  }

  void selectAll() {
    for (var element in d365TaskList) {
      element.isSelected = true;
    }
    isAllSelect = true;
    notifyListeners();
  }

  void clearSelection() {
    for (var element in d365TaskList) {
      element.isSelected = false;
    }
    isAllSelect = false;
    notifyListeners();
  }

  bool checkForSelection() {
    return d365TaskList.any((e) => e.isSelected);
  }
}
