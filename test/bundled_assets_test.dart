import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/models/about_content_model.dart';
import 'package:via_mioritica/src/models/photo_model.dart';
import 'package:via_mioritica/src/models/recommendation_model.dart';
import 'package:via_mioritica/src/models/stage_model.dart';
import 'package:via_mioritica/src/repositories/local_gpx_repository.dart';
import 'package:via_mioritica/src/utils/json_utils.dart';

/// Validates the real content shipped with the app (the same files that are
/// served as hosted JSON from `main`), so a broken edit is caught in CI
/// before it reaches users.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<dynamic> asset(String path) async =>
      json.decode(await rootBundle.loadString(path));

  group('stages.json', () {
    late List<StageModel> stages;

    setUpAll(() async {
      final raw = await asset('assets/data/stages.json') as List;
      stages = [
        for (var i = 0; i < raw.length; i++)
          StageModel.fromJson(asStringKeyedMap(raw[i]), fallbackOrder: i),
      ];
    });

    test('is non-empty with unique ids', () {
      expect(stages, isNotEmpty);
      expect(stages.map((s) => s.id).toSet().length, stages.length);
    });

    test('every stage has sane numbers', () {
      for (final s in stages) {
        expect(s.distanceKm, greaterThan(0), reason: s.id);
        expect(s.name, isNotEmpty, reason: s.id);
      }
    });

    test('every referenced GPX file exists and has track points', () async {
      final repo = LocalGpxRepository();
      for (final s in stages) {
        final points = await repo.getTrackPoints(s.gpxFile);
        expect(points.length, greaterThan(10), reason: s.gpxFile);
        for (final p in points) {
          expect(p.latitude, inInclusiveRange(-90, 90));
          expect(p.longitude, inInclusiveRange(-180, 180));
        }
      }
    });

    test('every cover image and POI belongs to a real asset/stage', () {
      for (final s in stages) {
        if (s.coverImage.startsWith('assets/')) {
          expect(File(s.coverImage).existsSync(), isTrue, reason: s.coverImage);
        }
        for (final poi in s.pois) {
          expect(poi.stageId, s.id, reason: poi.id);
        }
      }
    });

    test('every GPX file on disk is referenced by a stage', () {
      final referenced = stages.map((s) => s.gpxFile).toSet();
      final onDisk = Directory(
        'assets/gpx',
      ).listSync().whereType<File>().map((f) => f.path).toSet();
      expect(onDisk.difference(referenced), isEmpty);
    });
  });

  test('recommendations.json parses', () async {
    final raw = await asset('assets/data/recommendations.json') as List;
    expect(raw, isNotEmpty);
    for (final r in raw) {
      RecommendationModel.fromJson(asStringKeyedMap(r));
    }
  });

  test('photos.json parses and referenced images exist', () async {
    final raw = await asset('assets/data/photos.json') as List;
    for (final p in raw) {
      final photo = PhotoModel.fromJson(asStringKeyedMap(p));
      if (photo.assetPath.startsWith('assets/')) {
        expect(
          File(photo.assetPath).existsSync(),
          isTrue,
          reason: photo.assetPath,
        );
      }
    }
  });

  test('about.json parses', () async {
    final raw = await asset('assets/data/about.json');
    final about = AboutContentModel.fromJson(asStringKeyedMap(raw));
    expect(about.title, isNotEmpty);
  });
}
