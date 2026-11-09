import 'dart:async';
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
import 'package:shared_preferences/shared_preferences.dart';

class TaskProvider with ChangeNotifier {
  TaskProvider() {
    _restoreHiddenErpTasks();
  }

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

  // --- ERP hidden tasks ---
  // notificationId -> epoch ms it should stay hidden until. Set right after a
  // successful multi Approve/Reject so the just-processed items disappear
  // from the ERP list immediately instead of waiting for D365 to catch up.
  static const String _hiddenErpPrefsKey = 'erp_hidden_notification_until';
  final Map<String, int> _hiddenErpUntil = {};
  Timer? _hiddenErpTimer;

  // --- Device Info ---
  // ignore: unused_field
  String? _deviceId, _manufacturer, _platform, _version, _model;

  @override
  void dispose() {
    _hiddenErpTimer?.cancel();
    super.dispose();
  }

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

      String userId = userModel.userId ?? '';
      log("Fetching D365 tasks for User: $userId");

      // UAT hits the sandbox list with no bearer token.
      final response = Constants.isUat
          ? await ApiServices.execute(
              method: apiMethod.get,
              url: Constants.uatD365TaskListUrl,
              absoluteUrl: true,
            )
          : await ApiServices.execute(
              method: apiMethod.get,
              accessToken: responseModel.accessToken!,
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

  /// [d365TaskList] with any notification currently hidden (just processed
  /// via a multi Approve/Reject, see [hideErpTasks]) filtered out.
  List<D365TaskListModel> get visibleD365TaskList {
    if (_hiddenErpUntil.isEmpty) return d365TaskList;
    return d365TaskList
        .where((task) => !_hiddenErpUntil.containsKey(task.notificationId))
        .toList();
  }

  void toggleSelection(D365TaskListModel task) {
    task.isSelected = !task.isSelected;
    final visible = visibleD365TaskList;
    isAllSelect = visible.isNotEmpty && visible.every((e) => e.isSelected);
    notifyListeners();
  }

  void selectAll() {
    for (var element in visibleD365TaskList) {
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

  /// Clears in-memory task data so a newly logged-in user never sees the
  /// previous account's lists.
  void resetForLogout() {
    isDD365Loading = false;
    isTaskListLoading = false;
    isTaskLinkLoading = false;
    isAllSelect = false;
    isD365TaskListShowing = true;
    d365TaskList.clear();
    tasksOfGetMyTask.clear();
    myTaskList.clear();
    hrTaskList.clear();
    assetTaskList.clear();
    userList.clear();
    _tasksOfGetMyTask.clear();
    _mytask = null;
    userTaskMap.clear();
    userProfileModelView = null;
    _hiddenErpTimer?.cancel();
    _hiddenErpUntil.clear();
    unawaited(_persistHiddenErpTasks());
    notifyListeners();
  }

  bool checkForSelection() {
    return visibleD365TaskList.any((e) => e.isSelected);
  }

  /// Hides [notificationIds] from the ERP list right after a successful
  /// multi Approve/Reject, instead of blocking on a long wait screen while
  /// D365 processes them. Each id stays hidden until
  /// `now + 5s * notificationIds.length + 20s`, then [_onHiddenErpExpiry]
  /// refreshes the list from the API — an id D365 still returns becomes
  /// visible again.
  void hideErpTasks(List<String> notificationIds) {
    if (notificationIds.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiry = now + (5000 * notificationIds.length) + 20000;
    for (final id in notificationIds) {
      final existing = _hiddenErpUntil[id];
      _hiddenErpUntil[id] = (existing == null || existing < expiry)
          ? expiry
          : existing;
    }
    notifyListeners();
    _logHiddenErpTasks('after hide');
    unawaited(_persistHiddenErpTasks());
    _scheduleHiddenErpTimer();
  }

  Future<void> _restoreHiddenErpTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_hiddenErpPrefsKey);
      if (raw == null || raw.isEmpty) return;

      final decoded = json.decode(raw) as Map<String, dynamic>;
      final now = DateTime.now().millisecondsSinceEpoch;
      _hiddenErpUntil
        ..clear()
        ..addEntries(
          decoded.entries
              .map((e) => MapEntry(e.key, (e.value as num).toInt()))
              .where((e) => e.value > now),
        );

      if (_hiddenErpUntil.isEmpty) {
        await prefs.remove(_hiddenErpPrefsKey);
      } else {
        await _persistHiddenErpTasks(prefs: prefs);
      }
      _logHiddenErpTasks('after restore');
      notifyListeners();
      _scheduleHiddenErpTimer();
    } catch (e) {
      log('Error restoring hidden ERP tasks: $e', name: 'HiddenTasks');
    }
  }

  void _scheduleHiddenErpTimer() {
    _hiddenErpTimer?.cancel();
    if (_hiddenErpUntil.isEmpty) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final soonest = _hiddenErpUntil.values.reduce((a, b) => a < b ? a : b);
    final delayMs = soonest - now;
    _hiddenErpTimer = Timer(
      Duration(milliseconds: delayMs > 0 ? delayMs : 0),
      _onHiddenErpExpiry,
    );
  }

  Future<void> _onHiddenErpExpiry() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _hiddenErpUntil.removeWhere((_, expiry) => expiry <= now);
    await _persistHiddenErpTasks();
    _logHiddenErpTasks('after expiry clear');
    notifyListeners();
    await getd365TaskList();
    _scheduleHiddenErpTimer();
  }

  Future<void> _persistHiddenErpTasks({SharedPreferences? prefs}) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    if (_hiddenErpUntil.isEmpty) {
      await p.remove(_hiddenErpPrefsKey);
    } else {
      await p.setString(_hiddenErpPrefsKey, json.encode(_hiddenErpUntil));
    }
    log(
      'Preference "$_hiddenErpPrefsKey" now: '
      '${p.getString(_hiddenErpPrefsKey) ?? '(empty)'}',
      name: 'HiddenTasks',
    );
  }

  void _logHiddenErpTasks(String stage) {
    if (_hiddenErpUntil.isEmpty) {
      log('Hidden ERP tasks ($stage): none', name: 'HiddenTasks');
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final summary = _hiddenErpUntil.entries
        .map((e) => '${e.key} (${((e.value - now) / 1000).ceil()}s left)')
        .join(', ');
    log('Hidden ERP tasks ($stage): $summary', name: 'HiddenTasks');
  }
}
