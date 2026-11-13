import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/core/models/reading_record.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/history/open_reading.dart';
import 'package:windmark/features/shell/app_tab.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/hexagram_figure.dart';
import 'package:windmark/widgets/reading_tile.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final lunar = LunarCalendar.fromSolar(now);
    final daily = HexagramBook.daily(now);
    final history = ref.watch(readingHistoryProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                const SealMark(text: '风'),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(now.hour),
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatSolar(now),
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                      if (lunar != null)
                        Text(
                          lunar.labelWithHour(now.hour),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.bronze,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: InkWell(
                onTap: () => _showDaily(context, daily),
                borderRadius: BorderRadius.circular(18),
                child: Row(
                  children: [
                    HexagramFigure(lines: daily.hexagram.lines, width: 78),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今日卦',
                            style: TextStyle(
                              color: AppColors.bronze,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            daily.title,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            daily.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.inkSoft,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '开始占问',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            _MethodCard(
              title: '梅花易数',
              detail: '用时间、数字或随缘起卦，看本卦、互卦、变卦和体用生克。',
              icon: Icons.filter_vintage_outlined,
              onTap: () => ref.read(appTabProvider.notifier).select(AppTab.meihua),
            ),
            const SizedBox(height: 10),
            _MethodCard(
              title: '六爻纳甲',
              detail: '铜钱摇六次，装世应、六亲、纳甲和当月旺衰。',
              icon: Icons.toll_outlined,
              onTap: () => ref.read(appTabProvider.notifier).select(AppTab.liuyao),
            ),
            const SizedBox(height: 22),
            Text(
              '最近占问',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            history.when(
              data: (records) {
                if (records.isEmpty) {
                  return const Text(
                    '还没有记录。起过卦之后，会留在这里和「我的」。',
                    style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                  );
                }
                return Column(
                  children: [
                    for (final record in records.take(3)) ...[
                      ReadingTile(
                        record: record,
                        onTap: () => _open(context, record),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => const Text(
                '记录暂时读不出来',
                style: TextStyle(color: AppColors.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, ReadingRecord record) {
    try {
      openReading(context, record);
    } on Object {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这条记录读不出来了')),
      );
    }
  }

  void _showDaily(BuildContext context, HexagramEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HexagramFigure(lines: entry.hexagram.lines, width: 132),
                const SizedBox(height: 12),
                Text(
                  '第 ${entry.number} 卦 · ${entry.title}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(height: 1.6, color: AppColors.ink),
                ),
                const SizedBox(height: 12),
                const Text(
                  '按公历日期排定，同一天不会变化。',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const DisclaimerNote(),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _greeting(int hour) {
  if (hour < 5) {
    return '夜深了';
  }
  if (hour < 11) {
    return '早安';
  }
  if (hour < 14) {
    return '午安';
  }
  if (hour < 18) {
    return '下午好';
  }
  return '晚上好';
}

class _MethodCard extends StatelessWidget {
  const _MethodCard({
    required this.title,
    required this.detail,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String detail;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.cinnabar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: AppColors.inkSoft,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
