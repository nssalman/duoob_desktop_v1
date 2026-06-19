import 'dart:convert';
import 'dart:developer';

import 'package:duoob_desktop_app_v1/config/copilot_secrets.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:http/http.dart' as http;

class CopilotAuthService {
  Future<String?> getServiceAccountCopilotToken() async {
    final response = await http.post(
      Uri.parse(
        'https://login.microsoftonline.com/${CopilotSecrets.tenantId}/oauth2/v2.0/token',
      ),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': CopilotSecrets.clientId,
        'client_secret': CopilotSecrets.clientSecret,
        'scope': Constants.copilotScope,
        'username': CopilotSecrets.username,
        'password': CopilotSecrets.serviceAccountPassword,
        'grant_type': 'password',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['access_token'] as String?;
    }

    log(
      'Copilot service account token failed: ${response.body}',
      name: 'CopilotAuthService',
    );
    return null;
  }
}
