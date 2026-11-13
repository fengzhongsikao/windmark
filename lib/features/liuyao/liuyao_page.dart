import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/random_provider.dart';
import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/features/liuyao/liuyao_result_page.dart';
import 'package:windmark/widgets/common.dart';

class LiuyaoPage extends ConsumerStatefulWidget {
  const LiuyaoPage({super.key});

  @override
  ConsumerState<LiuyaoPage> createState() => _LiuyaoPageState();
}

class _LiuyaoPageState extends ConsumerState<LiuyaoPage> {
  final _question = TextEditingController();
  final List<YaoKind> _lines = [];

  DivinationTopic _topic = DivinationTopic.general;
  List<bool> _faces = const [true, false, true];
  bool _shaking = false;
  bool _saving = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _question.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('六爻纳甲')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Text(
            '背为阳、字为阴。一背二字是少阳，两背一字是少阴，三背是老阳，三字是老阴。老阳和老阴是变爻。',
            style: TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _question,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '所问',
              hintText: '可以不写',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final topic in DivinationTopic.values)
                ChoiceChip(
                  label: Text(topic.label),
                  selected: _topic == topic,
                  showCheckmark: false,
                  selectedColor: AppColors.cinnabar,
                  labelStyle: TextStyle(
                    color: _topic == topic ? Colors.white : AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: _shaking
                      ? null
                      : (_) => setState(() => _topic = topic),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final back in _faces) _Coin(back: back, spinning: _shaking),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _shaking ? '摇卦中' : '已得 ${_lines.length} / 6 爻',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 12),
          if (_lines.isNotEmpty)
            SectionCard(
              child: Column(
                children: [
                  for (var i = 0; i < _lines.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 48,
                            child: Text(YaoPosition.names[i]),
                          ),
                          Text(
                            _lines[i].label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _lines[i].changing
                                  ? AppColors.cinnabar
                                  : AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (_lines.length < 6)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _shaking ? null : _fillAll,
                    child: const Text('一键起卦'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _shaking ? null : _shakeOne,
                    child: const Text('摇一爻'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : _reset,
                    child: const Text('重新摇'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _saving ? null : _finish,
                    child: const Text('解卦'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _shakeOne() async {
    if (_shaking || _lines.length >= 6) {
      return;
    }
    setState(() => _shaking = true);
    final random = ref.read(randomProvider);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _faces = [random.nextBool(), random.nextBool(), random.nextBool()];
      });
    });
    await Future<void>.delayed(const Duration(milliseconds: 640));
    _timer?.cancel();
    final cast = LiuyaoEngine.throwCoins(random);
    if (!mounted) {
      return;
    }
    setState(() {
      _lines.add(cast.kind);
      _faces = cast.backs;
      _shaking = false;
    });
  }

  void _fillAll() {
    final random = ref.read(randomProvider);
    final casts = [
      for (var i = 0; i < 6; i++) LiuyaoEngine.throwCoins(random),
    ];
    setState(() {
      _lines
        ..clear()
        ..addAll(casts.map((cast) => cast.kind));
      _faces = casts.last.backs;
      _shaking = false;
    });
  }

  void _reset() {
    setState(_lines.clear);
  }

  Future<void> _finish() async {
    if (_saving || _lines.length != 6) {
      return;
    }
    setState(() => _saving = true);
    try {
      final reading = LiuyaoEngine.interpret(
        lines: List<YaoKind>.of(_lines),
        topic: _topic,
        question: _question.text.trim(),
        at: DateTime.now(),
      );
      await ref.read(readingHistoryProvider.notifier).add(reading.toRecord());
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => LiuyaoResultPage(reading: reading),
        ),
      );
    } on StateError {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这个日期无法换算农历')),
      );
    }
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.back, required this.spinning});

  final bool back;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 72,
      height: 72,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: spinning ? AppColors.paper : const Color(0xFFF3E2C4),
        border: Border.all(color: AppColors.bronze, width: 2),
      ),
      child: Text(
        back ? '背' : '字',
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.bronze,
        ),
      ),
    );
  }
}
