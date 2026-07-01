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

      if (response == null) {
        _showErrorDialog(
          context,
          'Authentication failed',
          'Unable to connect. Please try again.',
        );
        return;
      }

      if (response is Map && _isLoginErrorResponse(response)) {
        _showErrorDialog(
          context,
          'Authentication failed',
          _loginErrorMessage(response),
        );
        return;
      }

      final loginResponse = LoginResponseModel.fromJson(response);

      if (!_hasValidAccessToken(loginResponse)) {
        _showErrorDialog(
          context,
          'Authentication failed',
          _loginErrorMessage(response),
        );
        return;
      }

        await userRepository.storeLoginResponse(loginResponse);
        await userRepository.storeUserToken(loginResponse.accessToken!);
        await userRepository.setUserLoggedIn(true);

        final responseModel = await userRepository.getLoginResponse();
        final token = responseModel?.accessToken;
        final userId = responseModel?.userId;

        if (token == null || userId == null || userId.isEmpty || userId == 'null') {
          _showErrorDialog(
            context,
            'Authentication failed',
            'Unable to load user details. Please try again.',
          );
          return;
        }

        final profileRes = await ApiServices.execute(
          method: apiMethod.get,
          url: '${Constants.apiGetUserInfo}?UID=$userId',
          accessToken: token,
        );
        if (profileRes != null) {
          UserProfileModel profile = UserProfileModel.fromJson(profileRes);
          await userRepository.storeUserProfile(profile);
        }

        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainScreen()),
            (route) => false,
          );
        }
    } catch (e) {
      _showErrorDialog(
        context,
        'Authentication failed',
        'Something went wrong. Please try again.',
      );
    } finally {
      isLoading = false;
    }
  }

  bool _isLoginErrorResponse(Map response) {
    final error = response['error'];
    if (error != null) {
      final text = error.toString().trim();
      if (text.isNotEmpty && text != 'null') {
        return true;
      }
    }

    final token = response['access_token'];
    return token == null || token.toString().isEmpty || token.toString() == 'null';
  }

  bool _hasValidAccessToken(LoginResponseModel response) {
    final token = response.accessToken;
    return token != null && token.isNotEmpty && token != 'null';
  }

  String _loginErrorMessage(dynamic response) {
    if (response is Map) {
      for (final key in [
        'error_description',
        'ErrorDescription',
        'error',
        'message',
        'Message',
      ]) {
        final value = response[key];
        if (value != null) {
          final text = value.toString().trim();
          if (text.isNotEmpty && text != 'null') {
            if (key == 'error' &&
                (text == 'invalid_grant' || text == 'invalid_client')) {
              continue;
            }
            return text;
          }
        }
      }
    }
    return 'Invalid username or password. Please try again.';
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (_) => InfoDialog(
        message: title,
        subtext: message,
        ok: () => Navigator.pop(context),
      ),
    );
  }
}