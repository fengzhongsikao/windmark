import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/app_copy.dart';
import 'package:windmark/app/theme.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/history/open_reading.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/reading_tile.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(readingHistoryProvider);
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const Center(child: Text('记录暂时读不出来')),
        data: (records) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              SectionCard(
                child: Row(
                  children: [
                    const SealMark(text: '问', size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppCopy.name,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '共 ${records.length} 次占问',
                            style: const TextStyle(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '占问记录',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  if (records.isNotEmpty)
                    TextButton(
                      onPressed: () => _clear(context, ref),
                      child: const Text('清空'),
                    ),
                ],
              ),
              if (records.isEmpty)
                const Text(
                  '还没有占问。首页可以进入梅花或六爻。',
                  style: TextStyle(color: AppColors.inkSoft, height: 1.5),
                )
              else
                for (final record in records) ...[
                  Dismissible(
                    key: ValueKey(record.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 18),
                      decoration: BoxDecoration(
                        color: AppColors.cinnabar,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.delete_outline, color: Colors.white),
                    ),
                    onDismissed: (_) {
                      ref.read(readingHistoryProvider.notifier).remove(record.id);
                    },
                    child: ReadingTile(
                      record: record,
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
              const SizedBox(height: 12),
              const _AboutTile(
                title: '梅花易数',
                body: '以先天八卦数起卦。时间起卦用农历的年支、月、日和时辰；也可以报数，或随缘取数。成卦后看本卦、互卦、变卦，再以不动的一卦为体、发动的一卦为用，看五行生克。',
              ),
              const _AboutTile(
                title: '六爻纳甲',
                body: '三枚铜钱摇六次，从初爻装到上爻。背为阳、字为阴：一背二字为少阳，两背一字为少阴，三背为老阳，三字为老阴。老阳、老阴是变爻。再按卦宫装世应，按上下卦纳甲，配六亲、六神和月令旺衰。',
              ),
              const SizedBox(height: 8),
              const DisclaimerNote(),
            ],
          );
        },
      ),
    );
  }

  Future<void> _clear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('清空记录'),
          content: const Text('本地的占问记录会全部删除。'),
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
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(readingHistoryProvider.notifier).clear();
  }
}

class _AboutTile extends StatelessWidget {
  const _AboutTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              body,
              style: const TextStyle(color: AppColors.inkSoft, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
