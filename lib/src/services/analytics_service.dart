// lib/src/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Faza 16 — usage analytics via Firebase Analytics.
///
/// Deliberately minimal: automatic screen-view tracking (via
/// [FirebaseAnalyticsObserver], no manual per-screen calls needed) plus a
/// small set of explicit product events. No PII is ever logged (no names,
/// emails, GPS coordinates) — only anonymous, aggregate usage signals
/// (which stage/screen, whether a stage was marked complete), consistent
/// with the "no account" design of Faza 15's local progress tracking.
class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics instance = FirebaseAnalytics.instance;

  /// Returns the Firebase observer when Firebase is initialized; otherwise
  /// returns a no-op observer so the UI remains renderable in tests and
  /// during a failed/offline startup.
  static NavigatorObserver get observer {
    try {
      return FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
    } catch (_) {
      return NavigatorObserver();
    }
  }

  /// Disabled in debug builds for the same reason as Crashlytics (Faza
  /// 16): local dev/hot-reload sessions shouldn't skew real usage data.
  static Future<void> init() async {
    try {
      await instance.setAnalyticsCollectionEnabled(!kDebugMode);
    } catch (_) {
      // Non-fatal: app still works normally without analytics.
    }
  }

  /// Logged when the user toggles a stage's "completed" checkbox on
  /// (Faza 15). Stage id only (no user identity) — helps understand which
  /// stages get finished vs. abandoned.
  static Future<void> logStageCompleted(String stageId) async {
    try {
      await instance.logEvent(
        name: 'stage_completed',
        parameters: {'stage_id': stageId},
      );
    } catch (_) {
      // Best-effort only.
    }
  }

  /// Logged when the non-dismissible force-update gate (Faza 14) is shown
  /// — helps confirm a Remote Config force-update push actually reaches
  /// real devices.
  static Future<void> logForceUpdateShown() async {
    try {
      await instance.logEvent(name: 'force_update_shown');
    } catch (_) {
      // Best-effort only.
    }
  }
}
