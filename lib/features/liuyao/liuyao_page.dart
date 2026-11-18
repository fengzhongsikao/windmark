import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/random_provider.dart';
import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/features/liuyao/liuyao_result_page.dart';
import 'package:windmark/widgets/common.dart';

enum _CastMode {
  manual('手动指定'),
  shake('在线摇卦'),
  auto('自动起卦');

  const _CastMode(this.label);

  final String label;
}

const _yaoOptions = [
  YaoKind.youngYin,
  YaoKind.youngYang,
  YaoKind.oldYin,
  YaoKind.oldYang,
];

class LiuyaoPage extends ConsumerStatefulWidget {
  const LiuyaoPage({super.key});

  @override
  ConsumerState<LiuyaoPage> createState() => _LiuyaoPageState();
}

class _LiuyaoPageState extends ConsumerState<LiuyaoPage> {
  final _question = TextEditingController();
  final List<YaoKind> _shaken = [];
  final List<YaoKind> _autoLines = [];
  final List<YaoKind?> _picked = List<YaoKind?>.filled(6, null);

  _CastMode _mode = _CastMode.auto;
  DivinationTopic _topic = DivinationTopic.general;
  List<bool> _faces = const [true, false, true];
  bool _shaking = false;
  bool _saving = false;
  int _shakeToken = 0;
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
          _CastModeField(
            mode: _mode,
            onChanged: (mode) {
              if (mode == _mode) {
                return;
              }
              _shakeToken++;
              _timer?.cancel();
              setState(() {
                _mode = mode;
                _shaking = false;
              });
            },
          ),
          const SizedBox(height: 14),
          Text(switch (_mode) {
            _CastMode.manual => '少阳、少阴不变，老阳、老阴为变爻。',
            _CastMode.shake => '自己摇铜钱。背为阳、字为阴。一背二字是少阳，两背一字是少阴，三背是老阳，三字是老阴。',
            _CastMode.auto => '一次起出六爻，不用逐爻手摇。',
          }, style: const TextStyle(color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('liuyao-question'),
            controller: _question,
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: '所问',
              hintText: '写下所问之事',
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
          if (_mode == _CastMode.manual)
            ..._manualCasting()
          else if (_mode == _CastMode.shake)
            ..._shakeCasting()
          else
            ..._autoCasting(),
        ],
      ),
    );
  }

  List<Widget> _manualCasting() {
    final ready = _picked.every((line) => line != null);
    return [
      const Text(
        '逐爻选择阴阳',
        style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      for (var visual = 0; visual < 6; visual++) ...[
        _ManualYaoRow(
          key: ValueKey('manual-yao-${5 - visual}'),
          index: 5 - visual,
          value: _picked[5 - visual],
          onChanged: _saving
              ? null
              : (kind) => setState(() => _picked[5 - visual] = kind),
        ),
        const SizedBox(height: 10),
      ],
      if (_picked.any((line) => line != null))
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _saving
                ? null
                : () => setState(() => _picked.fillRange(0, 6, null)),
            child: const Text('清空'),
          ),
        ),
      FillQuestionTap(
        blocked: !_saving && !_hasQuestion,
        onBlocked: _promptQuestion,
        child: FilledButton(
          onPressed: _saving || !ready || !_hasQuestion
              ? null
              : () => _finish([for (final line in _picked) line!]),
          child: const Text('解卦'),
        ),
      ),
    ];
  }

  List<Widget> _shakeCasting() {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [for (final back in _faces) _Coin(back: back)],
      ),
      const SizedBox(height: 8),
      Text(
        _shaking ? '摇卦中' : '已得 ${_shaken.length} / 6 爻',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.inkSoft),
      ),
      const SizedBox(height: 16),
      Center(child: _CastingTablet(lines: _shaken)),
      const SizedBox(height: 16),
      if (_shaken.length < 6)
        FillQuestionTap(
          blocked: !_shaking && !_hasQuestion,
          onBlocked: _promptQuestion,
          child: FilledButton(
            onPressed: _shaking || !_hasQuestion ? null : _shakeOne,
            child: const Text('摇一爻'),
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(_shaken.clear),
                child: const Text('重新摇'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FillQuestionTap(
                blocked: !_saving && !_hasQuestion,
                onBlocked: _promptQuestion,
                child: FilledButton(
                  onPressed: _saving || !_hasQuestion
                      ? null
                      : () => _finish(_shaken),
                  child: const Text('解卦'),
                ),
              ),
            ),
          ],
        ),
    ];
  }

  List<Widget> _autoCasting() {
    return [
      Center(child: _CastingTablet(lines: _autoLines)),
      const SizedBox(height: 16),
      if (_autoLines.length < 6)
        FillQuestionTap(
          blocked: !_hasQuestion,
          onBlocked: _promptQuestion,
          child: FilledButton(
            onPressed: !_hasQuestion ? null : _fillAll,
            child: const Text('一键起卦'),
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => setState(_autoLines.clear),
                child: const Text('重新起卦'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FillQuestionTap(
                blocked: !_saving && !_hasQuestion,
                onBlocked: _promptQuestion,
                child: FilledButton(
                  onPressed: _saving || !_hasQuestion
                      ? null
                      : () => _finish(_autoLines),
                  child: const Text('解卦'),
                ),
              ),
            ),
          ],
        ),
    ];
  }

  Future<void> _shakeOne() async {
    if (_shaking || _shaken.length >= 6 || !_hasQuestion) {
      return;
    }
    final token = ++_shakeToken;
    setState(() => _shaking = true);
    final random = ref.read(randomProvider);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (_) {
      if (!mounted || _mode != _CastMode.shake) {
        return;
      }
      setState(() {
        _faces = [random.nextBool(), random.nextBool(), random.nextBool()];
      });
    });
    await Future<void>.delayed(const Duration(milliseconds: 640));
    _timer?.cancel();
    final cast = LiuyaoEngine.throwCoins(random);
    if (!mounted || _mode != _CastMode.shake || token != _shakeToken) {
      return;
    }
    setState(() {
      _shaken.add(cast.kind);
      _faces = cast.backs;
      _shaking = false;
    });
  }

  void _fillAll() {
    if (!_hasQuestion) {
      return;
    }
    final random = ref.read(randomProvider);
    final casts = [for (var i = 0; i < 6; i++) LiuyaoEngine.throwCoins(random)];
    setState(() {
      _autoLines
        ..clear()
        ..addAll(casts.map((cast) => cast.kind));
    });
  }

  bool get _hasQuestion => _question.text.trim().isNotEmpty;

  void _promptQuestion() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(const SnackBar(content: Text('请填写所问之事')));
  }

  Future<void> _finish(List<YaoKind> lines) async {
    if (_saving || lines.length != 6 || !_hasQuestion) {
      return;
    }
    setState(() => _saving = true);
    try {
      final reading = LiuyaoEngine.interpret(
        lines: List<YaoKind>.of(lines),
        topic: _topic,
        question: _question.text.trim(),
        method: _mode.label,
        at: DateTime.now(),
      );
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('这个日期无法换算农历')));
    }
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

class _CastModeField extends StatelessWidget {
  const _CastModeField({required this.mode, required this.onChanged});

  final _CastMode mode;
  final ValueChanged<_CastMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1, thickness: 1, color: AppColors.line),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const Text(
                '起卦方式',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const Spacer(),
              PopupMenuButton<_CastMode>(
                key: const ValueKey('cast-mode'),
                initialValue: mode,
                position: PopupMenuPosition.under,
                popUpAnimationStyle: AnimationStyle.noAnimation,
                tooltip: '',
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                elevation: 4,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                onSelected: onChanged,
                itemBuilder: (context) => [
                  for (final option in _CastMode.values)
                    PopupMenuItem(
                      value: option,
                      height: 44,
                      child: Text(
                        option.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                ],
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  padding: const EdgeInsets.only(left: 14, right: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        mode.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.inkSoft,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: AppColors.line),
      ],
    );
  }
}

const _slotHeight = 18.0;

class _CastingTablet extends StatelessWidget {
  const _CastingTablet({required this.lines});

  final List<YaoKind> lines;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 292,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var visual = 0; visual < 6; visual++)
                  _LineCaption(index: 5 - visual, line: _lineAt(5 - visual)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 148,
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var visual = 0; visual < 6; visual++)
                  _TabletStroke(line: _lineAt(5 - visual)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var visual = 0; visual < 6; visual++)
                  _ChangeMark(line: _lineAt(5 - visual)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  YaoKind? _lineAt(int index) {
    if (index < 0 || index >= lines.length) {
      return null;
    }
    return lines[index];
  }
}

class _LineCaption extends StatelessWidget {
  const _LineCaption({required this.index, required this.line});

  final int index;
  final YaoKind? line;

  @override
  Widget build(BuildContext context) {
    final kind = line?.label;
    return SizedBox(
      height: _slotHeight,
      child: Align(
        alignment: Alignment.centerRight,
        child: Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 13,
              height: 1,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: kind == null
                    ? YaoPosition.names[index]
                    : '${YaoPosition.names[index]}: ',
                style: TextStyle(
                  color: line == null ? AppColors.inkSoft : AppColors.ink,
                ),
              ),
              if (kind != null)
                TextSpan(
                  text: kind,
                  style: TextStyle(
                    color: line!.changing ? AppColors.cinnabar : AppColors.ink,
                  ),
                ),
            ],
          ),
          textAlign: TextAlign.right,
        ),
      ),
    );
  }
}

class _TabletStroke extends StatelessWidget {
  const _TabletStroke({required this.line});

  final YaoKind? line;

  @override
  Widget build(BuildContext context) {
    final color = line == null
        ? const Color(0xFFE4DFD6)
        : line!.changing
        ? AppColors.cinnabar
        : const Color(0xFF2C2C2C);
    final stroke = line?.yang ?? false
        ? _bar(color)
        : Row(
            children: [
              Expanded(child: _bar(color)),
              const SizedBox(width: 16),
              Expanded(child: _bar(color)),
            ],
          );
    return SizedBox(
      height: _slotHeight,
      child: Center(child: stroke),
    );
  }

  Widget _bar(Color color) {
    return Container(
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _ChangeMark extends StatelessWidget {
  const _ChangeMark({required this.line});

  final YaoKind? line;

  @override
  Widget build(BuildContext context) {
    final mark = line == null || !line!.changing
        ? ''
        : line!.yang
        ? '○'
        : '×';
    return SizedBox(
      width: 16,
      height: _slotHeight,
      child: Align(
        alignment: Alignment.center,
        child: Text(
          mark,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.cinnabar,
            fontSize: 12,
            height: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ManualYaoRow extends StatelessWidget {
  const _ManualYaoRow({
    super.key,
    required this.index,
    required this.value,
    required this.onChanged,
  });

  final int index;
  final YaoKind? value;
  final ValueChanged<YaoKind>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            '${YaoPosition.names[index]}:',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _YaoPicker(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

class _YaoPicker extends StatelessWidget {
  const _YaoPicker({required this.value, required this.onChanged});

  final YaoKind? value;
  final ValueChanged<YaoKind>? onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<YaoKind>(
      initialValue: value,
      enabled: onChanged != null,
      position: PopupMenuPosition.under,
      popUpAnimationStyle: AnimationStyle.noAnimation,
      tooltip: '',
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final option in _yaoOptions)
          PopupMenuItem(
            value: option,
            height: 48,
            child: _YaoChoice(kind: option, highlighted: option == value),
          ),
      ],
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Expanded(
              child: value == null
                  ? const Text(
                      '选择阴阳',
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
                    )
                  : _YaoChoice(kind: value!),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

class _YaoChoice extends StatelessWidget {
  const _YaoChoice({required this.kind, this.highlighted = false});

  final YaoKind kind;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final mark = !kind.changing
        ? ''
        : kind.yang
        ? '○'
        : '×';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF6E8E6) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: highlighted ? 8 : 0),
        child: Row(
          children: [
            SizedBox(
              width: 36,
              child: Text(
                kind.label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 78, child: _MiniStroke(yang: kind.yang)),
            const SizedBox(width: 6),
            SizedBox(
              width: 14,
              child: Text(
                mark,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2C2C2C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStroke extends StatelessWidget {
  const _MiniStroke({required this.yang});

  final bool yang;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF2C2C2C);
    if (yang) {
      return _capsule(color);
    }
    return Row(
      children: [
        Expanded(child: _capsule(color)),
        const SizedBox(width: 8),
        Expanded(child: _capsule(color)),
      ],
    );
  }

  Widget _capsule(Color color) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.back});

  final bool back;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: back ? '背' : '字',
      child: ClipOval(
        child: Transform.scale(
          scale: 1.34,
          alignment: back
              ? const Alignment(-0.06, -0.01)
              : const Alignment(0.02, -0.01),
          child: Image.asset(
            back ? 'assets/images/rev.png' : 'assets/images/word.png',
            width: 88,
            height: 88,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
