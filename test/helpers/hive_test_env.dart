import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:via_mioritica/src/services/content_cache_box.dart';
import 'package:via_mioritica/src/services/progress_box.dart';

/// Opens the app's Hive boxes in a throw-away directory for the duration of
/// one test and cleans everything up afterwards.
void useTempHive() {
  late Directory dir;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('via_mioritica_hive_');
    await ContentCacheBox.init(path: dir.path);
    await ProgressBox.init(path: dir.path);
  });

  tearDown(() async {
    await ContentCacheBox.resetForTest();
    await ProgressBox.resetForTest();
    await Hive.close();
    await dir.delete(recursive: true);
  });
}
