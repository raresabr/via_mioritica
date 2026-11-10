import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/models/about_content_model.dart';
import 'package:via_mioritica/src/models/photo_model.dart';
import 'package:via_mioritica/src/models/poi_model.dart';
import 'package:via_mioritica/src/models/recommendation_model.dart';
import 'package:via_mioritica/src/models/stage_model.dart';

void main() {
  test('StageModel parses nested POIs and defaults', () {
    final s = StageModel.fromJson({
      'id': 's1',
      'name': 'Stage 1',
      'gpxFile': 'assets/gpx/stage.gpx',
      'distanceKm': 12.5,
      'elevationGainM': 400,
      'elevationLossM': 350,
      'pois': [
        {
          'id': 'p1',
          'stageId': 's1',
          'type': 'popas',
          'name': 'Popas',
          'lat': 46.1,
          'lon': 23.2,
          'photos': [],
        },
      ],
    }, fallbackOrder: 3);
    expect(s.order, 3);
    expect(s.description, isEmpty);
    expect(s.pois.single.type, PoiType.popas);
  });
  test('unknown enum values use safe defaults', () {
    final p = PoiModel.fromJson({
      'id': 'p1',
      'stageId': 's1',
      'type': 'unknown',
      'name': 'Unknown',
      'lat': 1,
      'lon': 2,
    });
    final r = RecommendationModel.fromJson({
      'id': 'r1',
      'category': 'unknown',
      'title': 'Title',
    });
    expect(p.type, PoiType.recomandare);
    expect(r.category, RecommendationCategory.general);
    expect(r.body, isEmpty);
  });
  test('optional fields are preserved', () {
    final photo = PhotoModel.fromJson({
      'id': 'photo-1',
      'assetPath': 'assets/images/main.jpg',
    });
    final about = AboutContentModel.fromJson({});
    expect(photo.stageId, isNull);
    expect(photo.caption, isEmpty);
    expect(about.title, isEmpty);
    expect(about.footerUrl, isEmpty);
  });
}
