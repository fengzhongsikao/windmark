import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/random_provider.dart';
import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/meihua/meihua_engine.dart';
import 'package:windmark/features/meihua/meihua_result_page.dart';
import 'package:windmark/widgets/common.dart';

enum MeihuaMethod { time, number, random }

class MeihuaPage extends ConsumerStatefulWidget {
  const MeihuaPage({super.key});

  @override
  ConsumerState<MeihuaPage> createState() => _MeihuaPageState();
}

class _MeihuaPageState extends ConsumerState<MeihuaPage> {
  final _upper = TextEditingController();
  final _lower = TextEditingController();
  final _moving = TextEditingController();

  MeihuaMethod _method = MeihuaMethod.time;
  DateTime _moment = DateTime.now();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _upper.dispose();
    _lower.dispose();
    _moving.dispose();
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
          SegmentedButton<MeihuaMethod>(
            segments: const [
              ButtonSegment(value: MeihuaMethod.time, label: Text('时间')),
              ButtonSegment(value: MeihuaMethod.number, label: Text('数字')),
              ButtonSegment(value: MeihuaMethod.random, label: Text('随缘')),
            ],
            selected: {_method},
            onSelectionChanged: (selection) {
              setState(() {
                _method = selection.first;
                _error = null;
              });
            },
          ),
          const SizedBox(height: 16),
          Text(
            switch (_method) {
              MeihuaMethod.time => '按农历年月日与时辰起卦。上卦取年、月、日之和除以 8，下卦再加时辰，动爻除以 6。',
              MeihuaMethod.number => '报三个正整数。前两个除以 8 取余，余 0 当作 8；第三个除以 6 取余，余 0 当作 6。',
              MeihuaMethod.random => '不看时辰、不报数，直接取上卦、下卦和动爻。',
            },
            style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
          ),
          const SizedBox(height: 16),
          if (_method == MeihuaMethod.time) ...[
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
          if (_method == MeihuaMethod.number) ...[
            _NumberField(controller: _upper, label: '上卦数'),
            const SizedBox(height: 10),
            _NumberField(controller: _lower, label: '下卦数'),
            const SizedBox(height: 10),
            _NumberField(controller: _moving, label: '动爻数'),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.cinnabar)),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submitNumbers,
              child: const Text('起卦'),
            ),
          ],
          if (_method == MeihuaMethod.random)
            FilledButton(
              onPressed: _saving ? null : _submitRandom,
              child: const Text('随缘起卦'),
            ),
        ],
      ),
    );
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

  void _submitNumbers() {
    final upper = int.tryParse(_upper.text);
    final lower = int.tryParse(_lower.text);
    final moving = int.tryParse(_moving.text);
    final cast = upper == null || lower == null || moving == null
        ? null
        : MeihuaEngine.numberCast(
            upper: upper,
            lower: lower,
            moving: moving,
            at: DateTime.now(),
          );
    if (cast == null) {
      setState(() => _error = '请输入大于 0 的整数');
      return;
    }
    setState(() => _error = null);
    _open(cast);
  }

  void _submitRandom() {
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
    setState(() => _saving = true);
    await ref.read(readingHistoryProvider.notifier).add(cast.toRecord());
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MeihuaResultPage(cast: cast),
      ),
    );
    if (mounted) {
      setState(() => _saving = false);
    }
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label),
    );
  }
}
