import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:windmark/core/models/reading_record.dart';

final historyStoreProvider = Provider<HistoryStore>((ref) {
  throw StateError('占问记录尚未初始化');
});

abstract interface class HistoryStore {
  Future<List<ReadingRecord>> load();

  Future<void> save(List<ReadingRecord> records);
}

final class MemoryHistoryStore implements HistoryStore {
  MemoryHistoryStore([List<ReadingRecord>? seed]) : _records = [...?seed];

  List<ReadingRecord> _records;

  @override
  Future<List<ReadingRecord>> load() async => List.unmodifiable(_records);

  @override
  Future<void> save(List<ReadingRecord> records) async {
    _records = List.of(records);
  }
}

final class FileHistoryStore implements HistoryStore {
  FileHistoryStore(this._file);

  static const _fileName = 'readings.json';

  final File _file;

  static Future<FileHistoryStore> open() async {
    final directory = await getApplicationDocumentsDirectory();
    return FileHistoryStore(File('${directory.path}/$_fileName'));
  }

  @override
  Future<List<ReadingRecord>> load() async {
    if (!await _file.exists()) {
      return const [];
    }
    final raw = await _file.readAsString();
    if (raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }
    final records = <ReadingRecord>[];
    for (final item in decoded) {
      if (item is Map) {
        try {
          records.add(ReadingRecord.fromJson(Map<String, dynamic>.from(item)));
        } on FormatException {
          continue;
        } on TypeError {
          continue;
        } on ArgumentError {
          continue;
        }
      }
    }
    return records;
  }

  @override
  Future<void> save(List<ReadingRecord> records) {
    final encoded = jsonEncode(records.map((record) => record.toJson()).toList());
    return _file.writeAsString(encoded);
  }
}
