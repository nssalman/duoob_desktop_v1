import 'dart:convert';
import 'dart:developer';

import 'package:duoob_desktop_app_v1/config/copilot_secrets.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:http/http.dart' as http;

class CopilotAuthService {
  Future<String?> getServiceAccountCopilotToken() {
    return getTokenForScope(Constants.copilotScope);
  }

  /// Mint a token for a specific scope/resource (used by Copilot OAuth cards).
  Future<String?> getTokenForScope(String scopeOrResource) async {
    final scope = _normalizeScope(scopeOrResource);

    final response = await http.post(
      Uri.parse(
        'https://login.microsoftonline.com/${CopilotSecrets.tenantId}/oauth2/v2.0/token',
      ),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': CopilotSecrets.clientId,
        'client_secret': CopilotSecrets.clientSecret,
        'scope': scope,
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
      'Copilot token failed scope=$scope status=${response.statusCode}',
      name: 'CopilotAuthService',
    );
    return null;
  }

  String _normalizeScope(String scopeOrResource) {
    final trimmed = scopeOrResource.trim();
    if (trimmed.isEmpty) return Constants.copilotScope;
    if (trimmed.contains(' ')) return trimmed;
    if (trimmed.startsWith('api://') &&
        !trimmed.contains('access_as_user') &&
        !trimmed.endsWith('/.default')) {
      return '$trimmed/.default';
    }
    if (trimmed.startsWith('https://') && !trimmed.endsWith('/.default')) {
      return '$trimmed/.default';
    }
    return trimmed;
  }
}
