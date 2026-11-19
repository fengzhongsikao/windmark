import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/calendar/four_pillars.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/hexagram_relation.dart';
import 'package:windmark/core/iching/palace.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/widgets/classic_texts.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/record_title_dialog.dart';

class LiuyaoResultPage extends ConsumerStatefulWidget {
  const LiuyaoResultPage({
    super.key,
    required this.reading,
    this.canSave = true,
  });

  final LiuyaoReading reading;
  final bool canSave;

  @override
  ConsumerState<LiuyaoResultPage> createState() => _LiuyaoResultPageState();
}

class _LiuyaoResultPageState extends ConsumerState<LiuyaoResultPage> {
  bool _saved = false;
  bool _saving = false;

  Future<void> _save() async {
    if (_saved || _saving) {
      return;
    }
    final title = await askRecordTitle(context);
    if (title == null || !mounted) {
      return;
    }
    setState(() => _saving = true);
    await ref
        .read(readingHistoryProvider.notifier)
        .add(widget.reading.toRecord(title: title));
    if (!mounted) {
      return;
    }
    setState(() {
      _saving = false;
      _saved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reading = widget.reading;
    final pillars = PillarSet.of(reading.createdAt);
    final changed = reading.changed;
    final changedLines = changed == null
        ? null
        : LiuyaoEngine.najiaLines(changed.hexagram, reading.palace.element);
    final hidden = _hiddenLines();
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('六爻纳甲'),
        backgroundColor: Colors.white,
        actions: [
          if (widget.canSave)
            TextButton(
              onPressed: _saved || _saving ? null : _save,
              child: Text(_saved ? '已保存' : '保存'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: _InfoTable(reading: reading, pillars: pillars),
          ),
          const SizedBox(height: 12),
          _Plate(
            reading: reading,
            changedLines: changedLines,
            hidden: hidden,
            kongwang: pillars.day.kongwang,
          ),
          const SizedBox(height: 12),
          ClassicTexts(
            sections: [
              ClassicSection(
                heading: '本卦 ${reading.original.title}',
                number: reading.original.number,
                lines: {
                  for (final line in reading.lines)
                    if (line.kind.changing) line.index + 1,
                },
              ),
              if (reading.changed != null)
                ClassicSection(
                  heading: '变卦 ${reading.changed!.title}',
                  number: reading.changed!.number,
                  lines: {
                    for (final line in reading.lines)
                      if (line.kind.changing) line.index + 1,
                  },
                ),
            ],
          ),
          for (final paragraph in reading.paragraphs) ...[
            SectionCard(
              color: Colors.white,
              child: Text(
                paragraph,
                style: const TextStyle(height: 1.65, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          const DisclaimerNote(),
        ],
      ),
    );
  }

  List<NajiaLine?> _hiddenLines() {
    final reading = widget.reading;
    final present = LiuyaoEngine.najiaLines(
      reading.original.hexagram,
      reading.palace.element,
    ).map((line) => line.relative).toSet();
    final base = HexagramBook.entries.firstWhere(
      (entry) => entry.name == reading.palace.name,
    );
    return [
      for (final line in LiuyaoEngine.najiaLines(
        base.hexagram,
        reading.palace.element,
      ))
        present.contains(line.relative) ? null : line,
    ];
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({required this.reading, required this.pillars});

  final LiuyaoReading reading;
  final PillarSet pillars;

  @override
  Widget build(BuildContext context) {
    final at = reading.createdAt;
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    final date =
        '${at.year}年${at.month}月${at.day}日 $hour:$minute (${reading.lunar.monthText}${reading.lunar.dayText})';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _line('事项', reading.question.isEmpty ? '' : reading.question),
          _line('日期', date),
          _line('起卦方式', reading.method.isEmpty ? '' : '【${reading.method}】'),
          _line('节气', pillars.termLabel),
          _split(
            '干支',
            [
              pillars.year.name,
              pillars.month.name,
              pillars.day.name,
              pillars.hour.name,
            ],
            const [false, true, true, false],
            '年',
            '月',
            '日',
            '时',
          ),
        ],
      ),
    );
  }

  Widget _line(String label, String value) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label(label),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: _valueText(label, value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _split(
    String label,
    List<String> values,
    List<bool> emphasis, [
    String? a,
    String? b,
    String? c,
    String? d,
  ]) {
    final suffixes = [a, b, c, d];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label(label),
            for (var i = 0; i < values.length; i++)
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      left: i == 0
                          ? BorderSide.none
                          : const BorderSide(color: AppColors.line),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      suffixes[i] == null
                          ? values[i]
                          : '${values[i]}${suffixes[i]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: emphasis[i] ? _pureRed : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Container(
      width: 72,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }

  Widget _valueText(String label, String value) {
    const style = TextStyle(fontSize: 13, height: 1.35);
    if (label == '节气') {
      return SizedBox(
        height: 18,
        width: double.infinity,
        child: _fitText(value, style),
      );
    }
    return Text(value, style: style);
  }
}

Widget _fitText(
  String text,
  TextStyle style, {
  Alignment align = Alignment.centerLeft,
}) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: align,
    child: Text(text, maxLines: 1, softWrap: false, style: style),
  );
}

class _Plate extends StatelessWidget {
  const _Plate({
    required this.reading,
    required this.changedLines,
    required this.hidden,
    required this.kongwang,
  });

  final LiuyaoReading reading;
  final List<NajiaLine>? changedLines;
  final List<NajiaLine?> hidden;
  final String kongwang;

  @override
  Widget build(BuildContext context) {
    final changed = reading.changed;
    final changedPalace = changed == null ? null : Palaces.of(changed);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _GuaColumn(
                    title: '${reading.original.title}(${reading.palace.name})',
                    footer: _guaFooter('本卦', reading.original.name),
                    rows: [
                      for (var visual = 0; visual < 6; visual++)
                        _YaoRow(line: reading.lines[5 - visual]),
                    ],
                  ),
                ),
                if (changed != null &&
                    changedPalace != null &&
                    changedLines != null)
                  Expanded(
                    child: _GuaColumn(
                      title: '${changed.title}(${_palaceTag(changedPalace)})',
                      footer: _guaFooter('变卦', changed.name),
                      rows: [
                        for (var visual = 0; visual < 6; visual++)
                          _ChangedYaoRow(
                            line: reading.lines[5 - visual],
                            changed: changedLines![5 - visual],
                            yang: changed.hexagram.lines[5 - visual],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            for (final note in _hiddenNotes(hidden))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  note,
                  style: const TextStyle(
                    color: _pureRed,
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '旬空：$kongwang',
                style: const TextStyle(fontSize: 13, height: 1.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuaColumn extends StatelessWidget {
  const _GuaColumn({
    required this.title,
    required this.footer,
    required this.rows,
  });

  final String title;
  final String footer;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _fitText(
          title,
          const TextStyle(fontWeight: FontWeight.w700),
          align: Alignment.center,
        ),
        const SizedBox(height: 8),
        for (final row in rows) row,
        const SizedBox(height: 6),
        _fitText(
          footer,
          const TextStyle(color: AppColors.moss, fontWeight: FontWeight.w700),
          align: Alignment.center,
        ),
      ],
    );
  }
}

class _YaoRow extends StatelessWidget {
  const _YaoRow({required this.line});

  final InstalledLine line;

  @override
  Widget build(BuildContext context) {
    return _FitYaoRow(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            line.spirit,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: _pureRed,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            _yaoText(line.relative, line.branch, line.element.label),
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontSize: 12, height: 1),
          ),
        ),
        _Bar(yang: line.kind.yang),
        SizedBox(
          width: 16,
          child: Text(
            line.isShi
                ? '世'
                : line.isYing
                ? '应'
                : '',
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: _pureRed,
              fontSize: 12,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChangedYaoRow extends StatelessWidget {
  const _ChangedYaoRow({
    required this.line,
    required this.changed,
    required this.yang,
  });

  final InstalledLine line;
  final NajiaLine changed;
  final bool yang;

  @override
  Widget build(BuildContext context) {
    final mark = !line.kind.changing
        ? ''
        : line.kind.yang
        ? '○→'
        : '×→';
    return _FitYaoRow(
      children: [
        SizedBox(
          width: 32,
          child: Text(
            mark,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontSize: 12, height: 1),
          ),
        ),
        _Bar(yang: yang),
        const SizedBox(width: 4),
        SizedBox(
          width: 64,
          child: Text(
            _yaoText(changed.relative, changed.branch, changed.element.label),
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(fontSize: 12, height: 1),
          ),
        ),
      ],
    );
  }
}

class _FitYaoRow extends StatelessWidget {
  const _FitYaoRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _yaoRowHeight,
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: SizedBox(
            width: _plateRowWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.yang});

  final bool yang;

  static const width = 56.0;
  static const thickness = 8.0;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2C2C2C);
    return SizedBox(
      width: width,
      height: thickness,
      child: yang
          ? const DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.all(Radius.circular(2)),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _segment(color)),
                const SizedBox(width: 4),
                Expanded(child: _segment(color)),
              ],
            ),
    );
  }

  Widget _segment(Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

const _pureRed = Color(0xFFFF0000);
const _yaoRowHeight = 28.0;

/// 六神 30、六亲 64、爻画 56、世应 16。按系统字号 1 排好，再整行缩小。
const _plateRowWidth = 30.0 + 64.0 + _Bar.width + 16.0;

String _yaoText(String relative, String branch, String element) {
  return '$relative$branch$element';
}

List<String> _hiddenNotes(List<NajiaLine?> hidden) {
  return [
    for (var index = 5; index >= 0; index--)
      if (hidden[index] != null)
        '${YaoPosition.names[index]}伏神：${hidden[index]!.relative}${hidden[index]!.branch}${hidden[index]!.element.label}',
  ];
}

String _guaFooter(String role, String name) {
  final relation = HexagramRelations.of(name);
  if (relation == null) {
    return role;
  }
  return '$role：$relation';
}

String _palaceTag(PalacePlacement palace) {
  if (palace.generationLabel == '游魂' || palace.generationLabel == '归魂') {
    return '${palace.name}/${palace.generationLabel}';
  }
  return palace.name;
}
