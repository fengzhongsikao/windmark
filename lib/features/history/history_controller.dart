import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/core/models/reading_record.dart';
import 'package:windmark/core/storage/history_store.dart';

class ReadingHistoryController extends AsyncNotifier<List<ReadingRecord>> {
  @override
  Future<List<ReadingRecord>> build() {
    return ref.watch(historyStoreProvider).load();
  }

  Future<void> add(ReadingRecord record) async {
    final current = await future;
    final next = [record, ...current].take(100).toList();
    await ref.read(historyStoreProvider).save(next);
    state = AsyncData(next);
  }

  Future<void> remove(String id) async {
    await removeIds([id]);
  }

  Future<void> removeIds(Iterable<String> ids) async {
    final drop = ids.toSet();
    if (drop.isEmpty) {
      return;
    }
    final current = await future;
    final next = current.where((record) => !drop.contains(record.id)).toList();
    await ref.read(historyStoreProvider).save(next);
    state = AsyncData(next);
  }

  Future<void> clear() async {
    await ref.read(historyStoreProvider).save(const []);
    state = const AsyncData([]);
  }

  Future<void> clearKind(ReadingKind kind) async {
    final current = await future;
    final next = current.where((record) => record.kind != kind).toList();
    await ref.read(historyStoreProvider).save(next);
    state = AsyncData(next);
  }
}

final readingHistoryProvider =
    AsyncNotifierProvider<ReadingHistoryController, List<ReadingRecord>>(
      ReadingHistoryController.new,
    );
