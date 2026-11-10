import 'package:flutter_test/flutter_test.dart';
import 'package:via_mioritica/src/repositories/hive_progress_repository.dart';
import 'package:via_mioritica/src/services/progress_box.dart';

import 'helpers/hive_test_env.dart';

void main() {
  useTempHive();

  test('starts empty', () async {
    expect(await HiveProgressRepository().loadCompletedStageIds(), isEmpty);
  });

  test('persists completion and removal', () async {
    final repo = HiveProgressRepository();
    await repo.setStageCompleted('a', true);
    await repo.setStageCompleted('b', true);
    await repo.setStageCompleted('a', false);

    expect(await repo.loadCompletedStageIds(), {'b'});
  });

  test('marking the same stage twice does not duplicate it', () async {
    final repo = HiveProgressRepository();
    await repo.setStageCompleted('a', true);
    await repo.setStageCompleted('a', true);

    expect(ProgressBox.instance.get('completed_stage_ids'), ['a']);
  });

  test('ignores corrupt (non-list) stored value', () async {
    await ProgressBox.instance.put('completed_stage_ids', 'garbage');
    expect(await HiveProgressRepository().loadCompletedStageIds(), isEmpty);
  });
}
