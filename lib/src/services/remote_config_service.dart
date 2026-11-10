// lib/src/services/remote_config_service.dart
import 'dart:io';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Faza 14 — force-update via Firebase Remote Config.
///
/// Compares the app's own build number (`versionCode`/`CFBundleVersion`,
/// from `pubspec.yaml`'s `version: x.y.z+<buildNumber>`) against a
/// `minSupportedBuildNumber` value fetched from Remote Config. If the
/// installed build is older, the app blocks with [ForceUpdateScreen]
/// instead of the normal home screen — used to kill a build with a critical
/// bug (e.g. a broken map/GPX parser) without waiting for users to update
/// on their own.
///
/// Build-number comparison (not semver string comparison) is deliberate: a
/// plain integer compare can't be thrown off by inconsistent version
/// formatting, and `versionCode`/`CFBundleVersion` already increments on
/// every release by construction (`flutter build ... --build-number`).
class RemoteConfigService {
  RemoteConfigService._();

  static late final FirebaseRemoteConfig _remoteConfig;
  static late final int _currentBuildNumber;
  static bool _initialised = false;

  // Remote Config keys.
  static const _keyMinBuildNumber = 'min_supported_build_number';
  static const _keyForceUpdateMessage = 'force_update_message';
  static const _keyAndroidStoreUrl = 'android_store_url';
  static const _keyIosStoreUrl = 'ios_store_url';

  static const _defaultForceUpdateMessage =
      'A apărut o versiune nouă a aplicației Via Mioritica. Te rugăm să '
      'actualizezi pentru a continua.';

  // Placeholder store URLs — update once the app is actually published.
  static const _defaultAndroidStoreUrl =
      'https://play.google.com/store/apps/details?id=ro.viamioritica.via_mioritica';
  static const _defaultIosStoreUrl = 'https://apps.apple.com/app/id0000000000';

  /// Fetches and activates Remote Config. Safe to call once, on app start,
  /// before the first screen decides whether to show the force-update gate.
  ///
  /// Never throws: any Remote Config/network failure just means the
  /// defaults (declared below, `min_supported_build_number` = current
  /// build) are used — the app never force-blocks itself just because the
  /// fetch failed offline on first launch.
  static Future<void> init() async {
    final info = await PackageInfo.fromPlatform();
    _currentBuildNumber = int.tryParse(info.buildNumber) ?? 1;

    _remoteConfig = FirebaseRemoteConfig.instance;
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          // Force-update decisions should propagate fast; a short min
          // fetch interval keeps `fetchAndActivate()` from serving a stale
          // cached value for hours after being explicitly pushed.
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(minutes: 15),
        ),
      );
      await _remoteConfig.setDefaults({
        _keyMinBuildNumber: _currentBuildNumber.toString(),
        _keyForceUpdateMessage: _defaultForceUpdateMessage,
        _keyAndroidStoreUrl: _defaultAndroidStoreUrl,
        _keyIosStoreUrl: _defaultIosStoreUrl,
      });
      await _remoteConfig.fetchAndActivate();
    } catch (_) {
      // Offline/first-launch/misconfigured project: defaults above already
      // guarantee `isForceUpdateRequired == false`.
    }
    _initialised = true;
  }

  /// True if the running build is older than the minimum the backend
  /// currently allows. `init()` must have been called first; returns
  /// `false` if it wasn't (fail open, never fail closed).
  static bool get isForceUpdateRequired {
    if (!_initialised) return false;
    final minBuild =
        int.tryParse(_remoteConfig.getString(_keyMinBuildNumber)) ??
        _currentBuildNumber;
    return _currentBuildNumber < minBuild;
  }

  static String get forceUpdateMessage =>
      _initialised && _remoteConfig.getString(_keyForceUpdateMessage).isNotEmpty
      ? _remoteConfig.getString(_keyForceUpdateMessage)
      : _defaultForceUpdateMessage;

  /// Store URL for the current platform — used by the "Actualizează acum"
  /// button on [ForceUpdateScreen].
  static String get storeUrl {
    if (!_initialised) {
      return Platform.isIOS ? _defaultIosStoreUrl : _defaultAndroidStoreUrl;
    }
    final url = Platform.isIOS
        ? _remoteConfig.getString(_keyIosStoreUrl)
        : _remoteConfig.getString(_keyAndroidStoreUrl);
    return url.isNotEmpty
        ? url
        : (Platform.isIOS ? _defaultIosStoreUrl : _defaultAndroidStoreUrl);
  }
}
