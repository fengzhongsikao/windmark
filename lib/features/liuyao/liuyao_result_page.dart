import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/calendar/lunar_calendar.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/hexagram_figure.dart';

class LiuyaoResultPage extends StatelessWidget {
  const LiuyaoResultPage({super.key, required this.reading});

  final LiuyaoReading reading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final changed = reading.changed;
    return Scaffold(
      appBar: AppBar(title: const Text('六爻纳甲')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            reading.topic.label,
            style: const TextStyle(
              color: AppColors.bronze,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            reading.original.title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${reading.palace.label}${changed == null ? '' : ' → ${changed.title}'}',
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          if (reading.question.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('所问：${reading.question}'),
          ],
          const SizedBox(height: 8),
          Text(
            '${reading.lunar.dateLabel} · ${formatSolar(reading.createdAt)}',
            style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '装卦',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ToneBadge(
                      label: reading.tone.label,
                      color: _toneColor(reading.tone),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final line in reading.lines.reversed) ...[
                  Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.spirit,
                              style: const TextStyle(
                                color: AppColors.bronze,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '${line.relative}${line.branch}${line.element.label}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: YaoStroke(
                          yang: line.kind.yang,
                          changing: line.kind.changing,
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          line.isShi
                              ? '世'
                              : line.isYing
                              ? '应'
                              : '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.cinnabar,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          line.strength,
                          style: const TextStyle(color: AppColors.inkSoft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final paragraph in reading.paragraphs) ...[
            SectionCard(
              child: Text(
                paragraph,
                style: const TextStyle(height: 1.65, fontSize: 15),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const Text(
            '已留在「我的」。',
            style: TextStyle(color: AppColors.inkSoft, fontSize: 13),
          ),
          const SizedBox(height: 8),
          const DisclaimerNote(),
        ],
      ),
    );
  }
}

Color _toneColor(ReadingTone tone) {
  return switch (tone) {
    ReadingTone.smooth => AppColors.moss,
    ReadingTone.steady => AppColors.bronze,
    ReadingTone.slow => AppColors.cinnabar,
    ReadingTone.unclear => AppColors.inkSoft,
  };
}
