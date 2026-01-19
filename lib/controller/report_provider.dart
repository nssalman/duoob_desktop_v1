
import 'dart:convert';

import 'package:duoob_desktop_app_v1/model/get_bi_report_list_model.dart';
import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/model/user_profile_model.dart';
import 'package:duoob_desktop_app_v1/services/api_services.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:flutter/material.dart';

class ReportProvider extends ChangeNotifier {
  final UserRepository userRepository = UserRepository();
  List<BiReportListModel> reports = [];
  bool isReportListLoading = false;


  Future<void> fetchReports() async {
  // Prevent duplicate calls if already loading
  if (isReportListLoading) return;

  try {
    isReportListLoading = true;
    reports.clear();
    notifyListeners(); // Equivalent to update() in Provider

  
    UserProfileModel? userModel = await userRepository.getUserProfileLocal();
    
    if (userModel == null) {
      return;
    }
    String userId = userModel.userId ??'';

    // 2. Execute API Call
    var response = await ApiServices.execute(
      method: apiMethod.get,
      isCoreApi: true,
      url: '${Constants.apiGetBiReport}?Username=$userId',
    );

    // 3. Parse and Store Data
    if (response != null) {
     var result = GetBiReportListModel.fromJson(response);
      if (result.status == 1 && result.data != null && result.data!.isNotEmpty) {
        reports = result.data ?? [];
      }
      notifyListeners(); // Refresh UI with new data
    }
  } catch (e) {
  } finally {
    isReportListLoading = false;
    notifyListeners(); // Refresh UI to show data or hide loader
  }
}

}

class Report {
  final String id;
  final String title;
  final String icon;
  final String url;

  Report({required this.id, required this.title, required this.icon, required this.url});
}