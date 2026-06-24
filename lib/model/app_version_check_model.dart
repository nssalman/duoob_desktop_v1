class AppVersionCheckResult {
  const AppVersionCheckResult({
    required this.updateRequired,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.platform,
    this.forceUpdate = false,
    this.latestVersion,
    this.latestBuildNumber,
    this.message,
  });

  final bool updateRequired;
  final bool forceUpdate;
  final String currentVersion;
  final int currentBuildNumber;
  final String platform;
  final String? latestVersion;
  final int? latestBuildNumber;
  final String? message;

  String get platformLabel => switch (platform) {
        'macos' => 'macOS',
        'windows' => 'Windows',
        _ => platform,
      };

  String get displayMessage =>
      message ??
      'A newer version of Duoob is available for $platformLabel. Please contact your administrator to update the app.';

  factory AppVersionCheckResult.upToDate({
    required String currentVersion,
    required int currentBuildNumber,
    required String platform,
  }) {
    return AppVersionCheckResult(
      updateRequired: false,
      currentVersion: currentVersion,
      currentBuildNumber: currentBuildNumber,
      platform: platform,
    );
  }
}

class AppVersionApiResponse {
  const AppVersionApiResponse({
    required this.status,
    this.message,
    required this.platforms,
  });

  final int status;
  final String? message;
  final List<RemoteAppVersionInfo> platforms;

  bool get isSuccess => status == 1;

  factory AppVersionApiResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    final items = data is List ? data : const [];

    return AppVersionApiResponse(
      status: json['status'] is int
          ? json['status'] as int
          : int.tryParse(json['status']?.toString() ?? '') ?? 0,
      message: json['message']?.toString(),
      platforms: items
          .whereType<Map>()
          .map(
            (item) => RemoteAppVersionInfo.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
    );
  }

  RemoteAppVersionInfo? platformPolicy(String platform) {
    final normalized = platform.toLowerCase();
    for (final policy in platforms) {
      if (policy.platform.toLowerCase() == normalized) {
        return policy;
      }
    }
    return null;
  }
}

class RemoteAppVersionInfo {
  const RemoteAppVersionInfo({
    required this.platform,
    required this.minimumBuildNumber,
    this.minimumVersion,
    this.latestVersion,
    this.latestBuildNumber,
    this.forceUpdate = false,
    this.message,
  });

  final String platform;
  final String? minimumVersion;
  final int minimumBuildNumber;
  final String? latestVersion;
  final int? latestBuildNumber;
  final bool forceUpdate;
  final String? message;

  factory RemoteAppVersionInfo.fromJson(Map<String, dynamic> json) {
    return RemoteAppVersionInfo(
      platform: json['platform']?.toString() ?? '',
      minimumVersion: _readString(json, const [
        'minimumVersion',
        'minVersion',
        'requiredVersion',
      ]),
      minimumBuildNumber: _readInt(json, const [
            'minimumBuildNumber',
            'minBuildNumber',
            'requiredBuildNumber',
            'buildNumber',
          ]) ??
          0,
      latestVersion: _readString(json, const [
        'latestVersion',
        'version',
      ]),
      latestBuildNumber: _readInt(json, const [
        'latestBuildNumber',
        'latestBuild',
      ]),
      forceUpdate:
          _readBool(json, const ['forceUpdate', 'isForceUpdate']) ?? false,
      message: _readString(json, const ['message', 'updateMessage']),
    );
  }

  static String? _readString(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
    }
    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is String) {
        if (value.toLowerCase() == 'true') return true;
        if (value.toLowerCase() == 'false') return false;
      }
    }
    return null;
  }
}
