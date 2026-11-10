import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/utils/map_config.dart';

void main() {
  test('tile URL embeds the key from .env when no dart-define is set', () {
    dotenv.loadFromString(envString: 'MAPTILER_KEY=abc123');
    expect(MapConfig.maptilerKey, 'abc123');
    expect(MapConfig.tileUrl, contains('key=abc123'));
    expect(MapConfig.tileUrl, contains('{z}/{x}/{y}'));
  });

  test('missing key yields an empty (but well-formed) URL', () {
    dotenv.loadFromString(envString: 'OTHER=1');
    expect(MapConfig.maptilerKey, isEmpty);
    expect(MapConfig.tileUrl, endsWith('key='));
  });

  test('offline zoom range is inside the map zoom range', () {
    expect(MapConfig.offlineMinZoom, greaterThanOrEqualTo(MapConfig.minZoom));
    expect(MapConfig.offlineMaxZoom, lessThanOrEqualTo(MapConfig.maxZoom));
  });
}
