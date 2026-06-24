import 'dart:developer';
import 'dart:io';

import 'package:duoob_desktop_app_v1/model/app_version_check_model.dart';
import 'package:duoob_desktop_app_v1/services/api_services.dart';
import 'package:duoob_desktop_app_v1/utils/constants.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  String get currentPlatformKey {
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    return Platform.operatingSystem;
  }

  Future<AppVersionCheckResult> checkForUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentBuild = int.tryParse(packageInfo.buildNumber) ?? 0;
    final platform = currentPlatformKey;
    final bundleId = packageInfo.packageName.isNotEmpty
        ? packageInfo.packageName
        : Constants.appBundleId;

    try {
      final response = await ApiServices.execute(
        method: apiMethod.get,
        url: Constants.apiGetAppVersionByBundleId,
        data: {'BundleId': bundleId},
      );

      if (response == null) {
        return AppVersionCheckResult.upToDate(
          currentVersion: packageInfo.version,
          currentBuildNumber: currentBuild,
          platform: platform,
        );
      }

      final apiResponse = AppVersionApiResponse.fromJson(
        Map<String, dynamic>.from(response as Map),
      );

      if (!apiResponse.isSuccess) {
        log(
          'Version check returned status ${apiResponse.status}: ${apiResponse.message}',
          name: 'AppVersionService',
        );
        return AppVersionCheckResult.upToDate(
          currentVersion: packageInfo.version,
          currentBuildNumber: currentBuild,
          platform: platform,
        );
      }

      final remote = apiResponse.platformPolicy(platform);
      if (remote == null) {
        log(
          'No version policy found for platform: $platform',
          name: 'AppVersionService',
        );
        return AppVersionCheckResult.upToDate(
          currentVersion: packageInfo.version,
          currentBuildNumber: currentBuild,
          platform: platform,
        );
      }

      final updateRequired = currentBuild < remote.minimumBuildNumber;

      return AppVersionCheckResult(
        updateRequired: updateRequired,
        forceUpdate: remote.forceUpdate,
        currentVersion: packageInfo.version,
        currentBuildNumber: currentBuild,
        platform: platform,
        latestVersion: remote.latestVersion,
        latestBuildNumber: remote.latestBuildNumber,
        message: remote.message,
      );
    } catch (error, stackTrace) {
      log(
        'Version check skipped for $platform: $error',
        name: 'AppVersionService',
        stackTrace: stackTrace,
      );
      return AppVersionCheckResult.upToDate(
        currentVersion: packageInfo.version,
        currentBuildNumber: currentBuild,
        platform: platform,
      );
    }
  }
}
