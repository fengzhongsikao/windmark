import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/random_provider.dart';
import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/trigram.dart';
import 'package:windmark/features/meihua/meihua_engine.dart';
import 'package:windmark/features/meihua/meihua_result_page.dart';
import 'package:windmark/widgets/common.dart';

enum _MeihuaMode {
  time('时间起卦'),
  manual('手动指定'),
  numberGroup('数字起卦1'),
  numberTriple('数字起卦2'),
  auto('自动起卦');

  const _MeihuaMode(this.label);

  final String label;
}

class MeihuaPage extends ConsumerStatefulWidget {
  const MeihuaPage({super.key});

  @override
  ConsumerState<MeihuaPage> createState() => _MeihuaPageState();
}

class _MeihuaPageState extends ConsumerState<MeihuaPage> {
  final _question = TextEditingController();
  final _number = TextEditingController();

  _MeihuaMode _mode = _MeihuaMode.time;
  DateTime _moment = DateTime.now();
  Trigram? _upperTrigram;
  Trigram? _lowerTrigram;
  int? _movingLine;
  String? _error;
  bool _addHour = false;
  bool _saving = false;

  @override
  void dispose() {
    _question.dispose();
    _number.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = MeihuaEngine.timeCast(_moment);
    return Scaffold(
      appBar: AppBar(title: const Text('梅花易数')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          _ModeField(
            mode: _mode,
            onChanged: (mode) {
              if (mode == _mode) {
                return;
              }
              setState(() {
                _mode = mode;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 14),
          Text(switch (_mode) {
            _MeihuaMode.time => '按农历年月日与时辰起卦。上卦取年、月、日之和除以 8，下卦再加时辰，动爻除以 6。',
            _MeihuaMode.manual => '自己选定上卦、下卦和动爻。',
            _MeihuaMode.numberGroup => '报一组数字。偶数平分，奇数时前半比后半少一位。',
            _MeihuaMode.numberTriple => '报一个三位数。',
            _MeihuaMode.auto => '不看时辰、不报数，直接取上卦、下卦和动爻。',
          }, style: const TextStyle(color: AppColors.inkSoft, height: 1.5)),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('meihua-question'),
            controller: _question,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: '所问',
              hintText: '选填',
            ),
          ),
          const SizedBox(height: 16),
          if (_mode == _MeihuaMode.time) ...[
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preview?.detail ?? '这个日期不在可换算的农历范围内。',
                    style: const TextStyle(height: 1.5),
                  ),
                  if (preview != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '上卦 ${preview.upper.name}${preview.upper.nature} · 下卦 ${preview.lower.name}${preview.lower.nature} · ${YaoPosition.names[preview.movingLine - 1]}动',
                      style: const TextStyle(
                        color: AppColors.cinnabar,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _pickMoment,
                      child: const Text('调整时间'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: preview == null || _saving ? null : () => _open(preview),
              child: const Text('起卦'),
            ),
          ],
          if (_mode == _MeihuaMode.manual) ..._manualFields(),
          if (_mode == _MeihuaMode.numberGroup ||
              _mode == _MeihuaMode.numberTriple)
            ..._numberFields(_mode == _MeihuaMode.numberTriple),
          if (_mode == _MeihuaMode.auto)
            FilledButton(
              onPressed: _saving ? null : _submitAuto,
              child: const Text('起卦'),
            ),
        ],
      ),
    );
  }

  List<Widget> _manualFields() {
    final ready =
        _upperTrigram != null && _lowerTrigram != null && _movingLine != null;
    final started =
        _upperTrigram != null || _lowerTrigram != null || _movingLine != null;
    return [
      _ChoiceRow<Trigram>(
        key: const ValueKey('meihua-upper'),
        label: '上卦:',
        value: _upperTrigram,
        hint: '选择卦',
        options: Trigram.values,
        labelOf: (trigram) => '${trigram.name}${trigram.nature}',
        onChanged: _saving
            ? null
            : (value) => setState(() => _upperTrigram = value),
      ),
      const SizedBox(height: 10),
      _ChoiceRow<Trigram>(
        key: const ValueKey('meihua-lower'),
        label: '下卦:',
        value: _lowerTrigram,
        hint: '选择卦',
        options: Trigram.values,
        labelOf: (trigram) => '${trigram.name}${trigram.nature}',
        onChanged: _saving
            ? null
            : (value) => setState(() => _lowerTrigram = value),
      ),
      const SizedBox(height: 10),
      _ChoiceRow<int>(
        key: const ValueKey('meihua-moving'),
        label: '动爻:',
        value: _movingLine,
        hint: '选择动爻',
        options: const [1, 2, 3, 4, 5, 6],
        labelOf: (line) => YaoPosition.names[line - 1],
        onChanged: _saving
            ? null
            : (value) => setState(() => _movingLine = value),
      ),
      if (started)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _saving
                ? null
                : () => setState(() {
                    _upperTrigram = null;
                    _lowerTrigram = null;
                    _movingLine = null;
                  }),
            child: const Text('清空'),
          ),
        )
      else
        const SizedBox(height: 16),
      FilledButton(
        onPressed: _saving || !ready ? null : _submitManual,
        child: const Text('起卦'),
      ),
    ];
  }

  Future<void> _pickMoment() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _moment,
      firstDate: DateTime(1901),
      lastDate: DateTime(2099),
    );
    if (date == null || !mounted) {
      return;
    }
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_moment),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _moment = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _moment.hour,
        time?.minute ?? _moment.minute,
      );
    });
  }

  List<Widget> _numberFields(bool triple) {
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _NumberField(
              controller: _number,
              label: triple ? '请输入一个三位的数字' : '请输入起卦数字',
              hint: triple ? '例如 986' : '例如 1234',
              maxLength: triple ? 3 : 32,
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            onTap: _saving ? null : () => setState(() => _addHour = !_addHour),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _addHour ? Icons.check_circle : Icons.circle_outlined,
                    color: AppColors.cinnabar,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  const Text('动爻加时辰', style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        triple ? _tripleRule : _groupRule,
        style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        Text(_error!, style: const TextStyle(color: AppColors.cinnabar)),
      ],
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _saving ? null : _submitNumbers,
        child: const Text('起卦'),
      ),
    ];
  }

  void _submitNumbers() {
    final text = _number.text;
    final at = DateTime.now();
    final cast = _mode == _MeihuaMode.numberGroup
        ? MeihuaEngine.numberGroupCast(
            digits: text,
            at: at,
            addHour: _addHour,
          )
        : MeihuaEngine.numberTripleCast(
            digits: text,
            at: at,
            addHour: _addHour,
          );
    if (cast == null) {
      setState(
        () => _error = _mode == _MeihuaMode.numberGroup
            ? '请输入起卦数字'
            : '请输入一个三位的数字',
      );
      return;
    }
    setState(() => _error = null);
    _open(cast);
  }

  void _submitManual() {
    final upper = _upperTrigram;
    final lower = _lowerTrigram;
    final moving = _movingLine;
    if (upper == null || lower == null || moving == null) {
      return;
    }
    _open(
      MeihuaEngine.manualCast(
        upper: upper,
        lower: lower,
        movingLine: moving,
        at: DateTime.now(),
      ),
    );
  }

  void _submitAuto() {
    final cast = MeihuaEngine.randomCast(
      ref.read(randomProvider),
      DateTime.now(),
    );
    _open(cast);
  }

  Future<void> _open(MeihuaCast cast) async {
    if (_saving) {
      return;
    }
    final question = _question.text.trim();
    setState(() => _saving = true);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeihuaResultPage(cast: cast.withQuestion(question)),
      ),
    );
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

class _ModeField extends StatelessWidget {
  const _ModeField({required this.mode, required this.onChanged});

  final _MeihuaMode mode;
  final ValueChanged<_MeihuaMode> onChanged;

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
              PopupMenuButton<_MeihuaMode>(
                key: const ValueKey('meihua-mode'),
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
                  for (final option in _MeihuaMode.values)
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

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    super.key,
    required this.label,
    required this.value,
    required this.hint,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T? value;
  final String hint;
  final List<T> options;
  final String Function(T value) labelOf;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PopupMenuButton<T>(
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
              for (final option in options)
                PopupMenuItem(
                  value: option,
                  height: 44,
                  child: Text(
                    labelOf(option),
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
                    child: Text(
                      value == null ? hint : labelOf(value as T),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: value == null
                            ? AppColors.inkSoft
                            : AppColors.ink,
                      ),
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
        ),
      ],
    );
  }
}

const _groupRule =
    '起卦算法：一组数字个数为偶数，则平分为二，以前一半数字之和除以 8 取余数得上卦，以后一半数字之和除以 8 取余数得下卦，上下卦数相加除以 6 取余数为动爻。若数字个数为奇，划分时前半比后半少一位。余数 0，卦当作 8，动爻当作 6。';

const _tripleRule =
    '起卦算法：第 1 数除以 8 的余数为上卦，第 2 数除以 8 的余数为下卦，第 3 数除以 6 的余数为动爻。余数 0，卦当作 8，动爻当作 6。';

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(maxLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
      ),
    );
  }
}
