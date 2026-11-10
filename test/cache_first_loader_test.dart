import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:via_mioritica/src/services/content_cache_box.dart';
import 'package:via_mioritica/src/utils/cache_first_loader.dart';

import 'helpers/hive_test_env.dart';

const _url = 'https://example.test/stages.json';

void main() {
  useTempHive();

  Future<dynamic> load(
    http.Client client, {
    required Future<dynamic> Function() bundled,
  }) {
    return http.runWithClient(
      () => CacheFirstLoader.load(
        cacheKey: 'k',
        hostedUrl: _url,
        loadFromBundledAsset: bundled,
      ),
      () => client,
    );
  }

  test('cache miss: fetches hosted JSON and stores data with ETag', () async {
    final client = MockClient(
      (_) async =>
          http.Response(json.encode(['hosted']), 200, headers: {'etag': 'v1'}),
    );

    final data = await load(client, bundled: () async => ['bundled']);

    expect(data, ['hosted']);
    final entry = ContentCacheBox.instance.get('k') as Map;
    expect(entry['data'], ['hosted']);
    expect(entry['etag'], 'v1');
  });

  test('cache miss + network failure: falls back to bundled asset', () async {
    final client = MockClient((_) async => throw http.ClientException('off'));

    final data = await load(client, bundled: () async => ['bundled']);

    expect(data, ['bundled']);
    expect((ContentCacheBox.instance.get('k') as Map)['data'], ['bundled']);
  });

  test('cache miss + non-200: falls back to bundled asset', () async {
    final client = MockClient((_) async => http.Response('nope', 503));

    expect(await load(client, bundled: () async => ['bundled']), ['bundled']);
  });

  test(
    'cache hit: returns cached data and revalidates with If-None-Match',
    () async {
      await ContentCacheBox.instance.put('k', {
        'data': ['cached'],
        'etag': 'v1',
        'fetchedAt': '2026-01-01T00:00:00.000',
      });
      final seenHeaders = <Map<String, String>>[];
      final client = MockClient((request) async {
        seenHeaders.add(request.headers);
        return http.Response('', 304);
      });

      final data = await load(client, bundled: () async => ['bundled']);
      await Future<void>.delayed(Duration.zero);

      expect(data, ['cached']);
      expect(seenHeaders.single['If-None-Match'], 'v1');
      expect((ContentCacheBox.instance.get('k') as Map)['data'], ['cached']);
    },
  );

  test('cache hit: background revalidation updates the cache on 200', () async {
    await ContentCacheBox.instance.put('k', {
      'data': ['old'],
      'etag': 'v1',
    });
    final client = MockClient(
      (_) async =>
          http.Response(json.encode(['new']), 200, headers: {'etag': 'v2'}),
    );

    final data = await load(client, bundled: () async => ['bundled']);
    expect(data, ['old']);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    final entry = ContentCacheBox.instance.get('k') as Map;
    expect(entry['data'], ['new']);
    expect(entry['etag'], 'v2');
  });

  test('cache hit + offline revalidation keeps existing cache', () async {
    await ContentCacheBox.instance.put('k', {
      'data': ['old'],
      'etag': 'v1',
    });
    final client = MockClient((_) async => throw http.ClientException('off'));

    expect(await load(client, bundled: () async => ['b']), ['old']);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect((ContentCacheBox.instance.get('k') as Map)['data'], ['old']);
  });

  test('invalidate removes the cached entry', () async {
    await ContentCacheBox.instance.put('k', {'data': 1});
    await CacheFirstLoader.invalidate('k');
    expect(ContentCacheBox.instance.get('k'), isNull);
  });

  group('validation', () {
    Future<dynamic> loadValidated(http.Client client) {
      return http.runWithClient(
        () => CacheFirstLoader.load(
          cacheKey: 'k',
          hostedUrl: _url,
          loadFromBundledAsset: () async => ['bundled'],
          validate: (d) => (d as List).cast<String>(),
        ),
        () => client,
      );
    }

    test(
      'malformed hosted JSON is rejected and bundled asset is used',
      () async {
        final client = MockClient(
          (_) async => http.Response(json.encode({'not': 'a list'}), 200),
        );

        expect(await loadValidated(client), ['bundled']);
      },
    );

    test('corrupt cache entry is dropped in favour of a fresh load', () async {
      await ContentCacheBox.instance.put('k', {'data': 42, 'etag': 'v1'});
      final client = MockClient(
        (_) async => http.Response(json.encode(['fresh']), 200),
      );

      expect(await loadValidated(client), ['fresh']);
    });

    test(
      'malformed revalidation payload does not overwrite a good cache',
      () async {
        await ContentCacheBox.instance.put('k', {
          'data': ['good'],
          'etag': 'v1',
        });
        final client = MockClient(
          (_) async => http.Response(json.encode({'bad': true}), 200),
        );

        expect(await loadValidated(client), ['good']);
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect((ContentCacheBox.instance.get('k') as Map)['data'], ['good']);
      },
    );
  });
}
