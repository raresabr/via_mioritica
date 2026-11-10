// lib/src/services/crashlytics_service.dart
import 'dart:async';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Faza 16 — crash reporting via Firebase Crashlytics.
///
/// Wires Flutter framework errors and any uncaught async/platform errors to
/// Crashlytics so real-world crashes on tester devices are visible in the
/// Firebase console without needing physical access to the device or logs.
///
/// Disabled in debug builds (`kDebugMode`) — local `flutter run` sessions
/// shouldn't pollute the crash-free-users metric with expected debugger
/// interruptions/hot-reload noise; only release/profile builds (the ones
/// distributed via `make release-android` / TestFlight) report crashes.
class CrashlyticsService {
  CrashlyticsService._();

  /// Registers the global error handlers. Call once, on app start, after
  /// `Firebase.initializeApp()`. Never throws: if Crashlytics itself fails
  /// to initialise (e.g. offline on first launch), the app continues
  /// normally, it just won't have crash reporting for that session.
  static Future<void> init() async {
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        !kDebugMode,
      );

      // Flutter framework errors (widget build/layout/paint errors).
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Anything else uncaught (async errors, platform channel errors)
      // outside the Flutter framework's own error zone.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (_) {
      // Non-fatal: app still works normally without crash reporting.
    }
  }

  /// Records a caught (non-fatal) error/exception, e.g. a repository fetch
  /// that failed but was handled gracefully — still useful signal in the
  /// Firebase console without crashing the app.
  static Future<void> recordNonFatal(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: false,
      );
    } catch (_) {
      // Best-effort only.
    }
  }
}
