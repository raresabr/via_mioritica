import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/providers/progress_providers.dart';
import 'package:via_mioritica/src/repositories/local_progress_repository.dart';
class _FakeProgressRepository implements LocalProgressRepository {
  Set<String> completed={}; final List<(String,bool)> writes=[];
  @override Future<Set<String>> loadCompletedStageIds() async=>{...completed};
  @override Future<void> setStageCompleted(String id,bool value) async { writes.add((id,value)); value?completed.add(id):completed.remove(id); }
}
void main() {
  test('loads persisted progress and updates it', () async {
    final repo=_FakeProgressRepository()..completed={'s1'}; final c=ProgressController(repo); await Future<void>.delayed(Duration.zero);
    expect(c.state,{'s1'}); await c.setCompleted('s2',true); expect(c.state,{'s1','s2'}); expect(repo.writes.single,('s2',true)); c.dispose();
  });
  test('toggle changes state and persists both changes', () async {
    final repo=_FakeProgressRepository(); final c=ProgressController(repo); await Future<void>.delayed(Duration.zero);
    await c.toggle('s1'); await c.toggle('s1'); expect(c.isCompleted('s1'),isFalse); expect(repo.writes,[('s1',true),('s1',false)]); c.dispose();
  });
}

