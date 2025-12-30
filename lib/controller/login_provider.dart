import 'dart:convert';
import 'dart:developer';

import 'package:duoob_desktop_app_v1/model/login_response_model.dart';
import 'package:duoob_desktop_app_v1/model/user_profile_model.dart';
import 'package:duoob_desktop_app_v1/services/api_services.dart';
import 'package:duoob_desktop_app_v1/services/user_repository.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:duoob_desktop_app_v1/view/components/info_dialog.dart';
import 'package:duoob_desktop_app_v1/view/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

class LoginProvider with ChangeNotifier {
  final UserRepository userRepository = UserRepository();
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Handles both Standard and Microsoft Login
  Future<void> login({
    required BuildContext context,
    String? username,
    String? password,
    String? microsoftCode,
  }) async {
    try {
      isLoading = true;

      // Close keyboard
      FocusScope.of(context).requestFocus(FocusNode());

      var response;
      if (microsoftCode != null) {
        response = await ApiServices.execute(method: apiMethod.get, url:  Constants.apiMicrosoftLogin + '?code=$microsoftCode');
      } else {
        var bytes = utf8.encode(password!);
      var passEncyp = base64Encode(bytes);
      print(passEncyp);

      Map<String, String> data = {
        "Username": username!,
        "grant_type": 'password',
        "client_id": 'RAKP',
        "scope": 'StaffMobileApp'
      };

      if (password != "") {
        data['password'] = passEncyp;
      }

      Map<String, String> headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': '~@#\$%^&()_+|}{P:"?><-=/-+."}',
      };
        response = await ApiServices.execute(method: apiMethod.post, url: Constants.apiLogin,data: data);
      }

      if (response != null ) {
        // 1. Process Login Data
        LoginResponseModel loginResponse = LoginResponseModel.fromJson(response);
        await userRepository.storeLoginResponse(loginResponse);
        await userRepository.storeUserToken(loginResponse.accessToken!);
        await userRepository.setUserLoggedIn(true);

        // 2. Fetch and Store Profile
         String token, userId;
      LoginResponseModel? responseModel = await userRepository.getLoginResponse();
      token = responseModel!.accessToken!;
      userId = responseModel.userId!;

      Map<String, String> data = {
        "UID": userId,
      };
        var profileRes = await ApiServices.execute(method: apiMethod.get, url: Constants.apiGetUserInfo + '?UID=$userId',accessToken: token);
        if (profileRes != null) {
          UserProfileModel profile = UserProfileModel.fromJson(profileRes);
          await userRepository.storeUserProfile(profile);
        }

        // 3. Navigate to Main App
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
      } else {
        // Handle 400 or other errors
        String errorMsg = response?.data['error_description'] ?? 'Please try again';
        _showErrorDialog(context, 'Authentication failed!', errorMsg);
      }
    } catch (e) {
      _showErrorDialog(context, 'Error!', e.toString());
    } finally {
      isLoading = false;
    }
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => InfoDialog(
        message: title,
        subtext: message,
        ok: () {
          Navigator.pop(context);
          return true;
        },
      ),
    );
  }
}