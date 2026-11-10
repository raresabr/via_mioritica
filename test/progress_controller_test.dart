import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/providers/progress_providers.dart';
import 'package:via_mioritica/src/repositories/local_progress_repository.dart';

class _FakeProgressRepository implements LocalProgressRepository {
  Set<String> completed = {};
  final List<(String, bool)> writes = [];

  @override
  Future<Set<String>> loadCompletedStageIds() async => {...completed};

  @override
  Future<void> setStageCompleted(String id, bool value) async {
    writes.add((id, value));
    value ? completed.add(id) : completed.remove(id);
  }
}

ProviderContainer _container(_FakeProgressRepository repo) {
  final container = ProviderContainer(
    overrides: [localProgressRepositoryProvider.overrideWithValue(repo)],
  );
  addTearDown(container.dispose);
  container.listen(progressProvider, (_, _) {});
  return container;
}

void main() {
  test('loads persisted progress and updates it', () async {
    final repo = _FakeProgressRepository()..completed = {'s1'};
    final c = _container(repo);
    await Future<void>.delayed(Duration.zero);
    final notifier = c.read(progressProvider.notifier);

    expect(c.read(progressProvider), {'s1'});
    await notifier.setCompleted('s2', true);

    expect(c.read(progressProvider), {'s1', 's2'});
    expect(repo.writes.single, ('s2', true));
  });

  test('toggle changes state and persists both changes', () async {
    final repo = _FakeProgressRepository();
    final c = _container(repo);
    await Future<void>.delayed(Duration.zero);
    final notifier = c.read(progressProvider.notifier);

    await notifier.toggle('s1');
    await notifier.toggle('s1');

    expect(notifier.isCompleted('s1'), isFalse);
    expect(repo.writes, [('s1', true), ('s1', false)]);
  });
}
