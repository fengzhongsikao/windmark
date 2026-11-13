import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/calendar/four_pillars.dart';
import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/iching/palace.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/meihua/meihua_engine.dart';
import 'package:windmark/widgets/classic_texts.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/record_title_dialog.dart';

const _pureRed = Color(0xFFFF0000);

class MeihuaResultPage extends ConsumerStatefulWidget {
  const MeihuaResultPage({super.key, required this.cast, this.canSave = true});

  final MeihuaCast cast;
  final bool canSave;

  @override
  ConsumerState<MeihuaResultPage> createState() => _MeihuaResultPageState();
}

class _MeihuaResultPageState extends ConsumerState<MeihuaResultPage> {
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
        .add(widget.cast.toRecord(title: title));
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
    final cast = widget.cast;
    final pillars = PillarSet.of(cast.createdAt);
    final lunar = LunarCalendar.fromSolar(cast.createdAt);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('梅花易数'),
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
          _InfoTable(cast: cast, pillars: pillars, lunar: lunar),
          const SizedBox(height: 12),
          _Plate(cast: cast),
          const SizedBox(height: 12),
          ClassicTexts(
            sections: [
              ClassicSection(
                heading: '本卦 ${cast.originalEntry.title}',
                number: cast.originalEntry.number,
                lines: {cast.movingLine},
              ),
            ],
          ),
          for (final paragraph in cast.paragraphs) ...[
            SectionCard(
              color: Colors.white,
              child: Text(
                paragraph,
                style: const TextStyle(height: 1.65, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const DisclaimerNote(),
        ],
      ),
    );
  }
}

class _InfoTable extends StatelessWidget {
  const _InfoTable({
    required this.cast,
    required this.pillars,
    required this.lunar,
  });

  final MeihuaCast cast;
  final PillarSet pillars;
  final LunarDate? lunar;

  @override
  Widget build(BuildContext context) {
    final at = cast.createdAt;
    final hour = at.hour.toString().padLeft(2, '0');
    final minute = at.minute.toString().padLeft(2, '0');
    final lunarText = lunar == null
        ? ''
        : ' (${lunar!.monthText}${lunar!.dayText})';
    final date = '${at.year}年${at.month}月${at.day}日 $hour:$minute$lunarText';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          _line('事项', cast.question),
          _line('日期', date),
          _line('卦式', _guaStyle(cast)),
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
          _split(
            '空亡',
            [
              pillars.year.kongwang,
              pillars.month.kongwang,
              pillars.day.kongwang,
              pillars.hour.kongwang,
            ],
            const [false, false, false, false],
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
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, height: 1.35),
                ),
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 2,
                    ),
                    child: Text(
                      suffixes[i] == null
                          ? values[i]
                          : '${values[i]}${suffixes[i]}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
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
      width: 48,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

String _guaStyle(MeihuaCast cast) {
  final number = RegExp(r'^数字 (\d{3})').firstMatch(cast.detail);
  if (number == null) {
    return '【${cast.method}】';
  }
  return '【${cast.method}】${number.group(1)}';
}

class _Plate extends StatelessWidget {
  const _Plate({required this.cast});

  final MeihuaCast cast;

  @override
  Widget build(BuildContext context) {
    final columns = [
      _GuaView('本卦', cast.original, moving: cast.movingLine - 1),
      _GuaView('互卦', cast.mutual),
      _GuaView('变卦', cast.changed, moving: cast.movingLine - 1),
      _GuaView('错卦', cast.original.opposite),
      _GuaView('综卦', cast.original.inverted),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 12, 4, 12),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 18),
                for (final column in columns)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '【${column.label}】',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _pureRed,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          column.entry.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, height: 1.2),
                        ),
                        Text(
                          '(${column.palace.name})',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, height: 1.2),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BodyUseMark(useOnTop: cast.movingInUpper),
                for (final column in columns)
                  Expanded(child: _GuaBars(view: column)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuaView {
  _GuaView(this.label, this.hexagram, {this.moving});

  final String label;
  final Hexagram hexagram;
  final int? moving;

  HexagramEntry get entry => HexagramBook.of(hexagram);

  PalacePlacement get palace => Palaces.of(entry);
}

class _BodyUseMark extends StatelessWidget {
  const _BodyUseMark({required this.useOnTop});

  final bool useOnTop;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        children: [_slot(useOnTop ? '用' : '体'), _slot(useOnTop ? '体' : '用')],
      ),
    );
  }

  Widget _slot(String text) {
    return SizedBox(
      height: _barRowHeight * 3,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _GuaBars extends StatelessWidget {
  const _GuaBars({required this.view});

  final _GuaView view;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var visual = 0; visual < 6; visual++)
          SizedBox(
            height: _barRowHeight,
            child: Center(
              child: _Bar(
                yang: view.hexagram.lines[5 - visual],
                marked: view.moving == 5 - visual,
              ),
            ),
          ),
      ],
    );
  }
}

const _barRowHeight = 16.0;

class _Bar extends StatelessWidget {
  const _Bar({required this.yang, required this.marked});

  final bool yang;
  final bool marked;

  static const width = 28.0;
  static const thickness = 4.0;

  @override
  Widget build(BuildContext context) {
    final color = marked ? _pureRed : const Color(0xFF2C2C2C);
    return SizedBox(
      width: width,
      height: thickness,
      child: yang
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(Radius.circular(1)),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _segment(color)),
                const SizedBox(width: 3),
                Expanded(child: _segment(color)),
              ],
            ),
    );
  }

  Widget _segment(Color color) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
