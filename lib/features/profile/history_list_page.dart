import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/models/reading_record.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/history/open_reading.dart';
import 'package:windmark/widgets/reading_tile.dart';

class HistoryListPage extends ConsumerStatefulWidget {
  const HistoryListPage({super.key, required this.kind});

  final ReadingKind kind;

  @override
  ConsumerState<HistoryListPage> createState() => _HistoryListPageState();
}

class _HistoryListPageState extends ConsumerState<HistoryListPage> {
  final _query = TextEditingController();
  final _selected = <String>{};
  bool _editing = false;

  String get _title => widget.kind == ReadingKind.meihua ? '梅花排盘记录' : '六爻排盘记录';

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(ReadingRecord record) {
    final query = _query.text.trim();
    if (query.isEmpty) {
      return true;
    }
    final question = record.payload['question'];
    return record.title.contains(query) ||
        record.summary.contains(query) ||
        (question is String && question.contains(query));
  }

  void _exitEditing() {
    setState(() {
      _editing = false;
      _selected.clear();
    });
  }

  void _toggle(String id) {
    setState(() {
      if (!_selected.add(id)) {
        _selected.remove(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final ids = Set<String>.of(_selected);
    if (ids.isEmpty) {
      return;
    }
    await ref.read(readingHistoryProvider.notifier).removeIds(ids);
    if (!mounted) {
      return;
    }
    _exitEditing();
  }

  Future<void> _clear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('清空$_title'),
          content: Text('本地的$_title会全部删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清空'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await ref.read(readingHistoryProvider.notifier).clearKind(widget.kind);
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(readingHistoryProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        actions: [
          history.maybeWhen(
            data: (records) {
              final hasMine = records.any(
                (record) => record.kind == widget.kind,
              );
              if (!hasMine) {
                return const SizedBox.shrink();
              }
              return TextButton(
                onPressed: _editing
                    ? _exitEditing
                    : () => setState(() => _editing = true),
                child: Text(_editing ? '完成' : '编辑'),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      bottomNavigationBar: _editing
          ? Material(
              color: AppColors.card,
              child: SafeArea(
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          key: const ValueKey('history-delete-selected'),
                          onPressed: _selected.isEmpty ? null : _deleteSelected,
                          child: const Text('删除'),
                        ),
                      ),
                      const SizedBox(
                        width: 1,
                        height: 24,
                        child: ColoredBox(color: AppColors.line),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: _exitEditing,
                          child: const Text('取消'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('记录暂时读不出来')),
        data: (records) {
          final mine = records
              .where((record) => record.kind == widget.kind)
              .toList();
          final shown = mine.where(_matches).toList();
          final searching = _query.text.trim().isNotEmpty;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: TextField(
                  key: const ValueKey('history-search'),
                  controller: _query,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '搜索',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  children: [
                    if (mine.isNotEmpty && !_editing)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _clear,
                          child: const Text('清空'),
                        ),
                      ),
                    if (shown.isEmpty)
                      Text(
                        searching ? '没有匹配的排盘记录。' : '还没有排盘记录。',
                        style: const TextStyle(
                          color: AppColors.inkSoft,
                          height: 1.5,
                        ),
                      )
                    else
                      for (final record in shown) ...[
                        if (_editing)
                          ReadingTile(
                            record: record,
                            showKind: false,
                            selected: _selected.contains(record.id),
                            onTap: () => _toggle(record.id),
                          )
                        else
                          Dismissible(
                            key: ValueKey(record.id),
                            direction: DismissDirection.endToStart,
                            background: const _DeleteBackground(),
                            secondaryBackground: const _DeleteBackground(),
                            onDismissed: (_) {
                              ref
                                  .read(readingHistoryProvider.notifier)
                                  .remove(record.id);
                            },
                            child: ReadingTile(
                              record: record,
                              showKind: false,
                              onTap: () {
                                try {
                                  openReading(context, record);
                                } on Object {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('这条记录读不出来了')),
                                  );
                                }
                              },
                            ),
                          ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.cinnabar,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        '删除',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
