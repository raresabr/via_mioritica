import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:via_mioritica/src/utils/trail_geo.dart';

void main() {
  group('TrailGeo', () {
    test('boundsOf returns null for no points', () {
      expect(TrailGeo.boundsOf(const []), isNull);
      expect(TrailGeo.boundsOfAll(const [[], []]), isNull);
    });

    test('boundsOf / boundsOfAll cover every point', () {
      final b = TrailGeo.boundsOfAll(const [
        [LatLng(46, 22), LatLng(46.5, 22.5)],
        [LatLng(45.9, 23)],
      ])!;
      expect(b.south, 45.9);
      expect(b.north, 46.5);
      expect(b.west, 22);
      expect(b.east, 23);
    });

    test('Romania lies inside the pan limit', () {
      expect(TrailGeo.panLimit.containsBounds(TrailGeo.romania), isTrue);
    });

    test('metersPerPixel halves per zoom level', () {
      final z6 = TrailGeo.metersPerPixel(46, 6);
      final z7 = TrailGeo.metersPerPixel(46, 7);
      expect(z6 / z7, closeTo(2, 1e-9));
    });

    test('niceScaleMeters picks a round value that fits', () {
      final meters = TrailGeo.niceScaleMeters(
        latitude: 46,
        zoom: 6,
        maxWidthPx: 110,
      );
      expect(meters, 100000);
      expect(meters / TrailGeo.metersPerPixel(46, 6), lessThanOrEqualTo(110));
    });

    test('niceScaleMeters never goes below the smallest step', () {
      expect(
        TrailGeo.niceScaleMeters(latitude: 46, zoom: 20, maxWidthPx: 10),
        10,
      );
    });

    test('formatMeters', () {
      expect(TrailGeo.formatMeters(500), '500 m');
      expect(TrailGeo.formatMeters(20000), '20 km');
    });
  });
}
