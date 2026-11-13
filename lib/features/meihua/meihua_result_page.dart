import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/hexagram.dart';
import 'package:windmark/core/iching/hexagram_book.dart';
import 'package:windmark/features/meihua/meihua_engine.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/hexagram_figure.dart';

class MeihuaResultPage extends StatelessWidget {
  const MeihuaResultPage({super.key, required this.cast});

  final MeihuaCast cast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final mutual = HexagramBook.of(cast.mutual);
    final changed = HexagramBook.of(cast.changed);
    return Scaffold(
      appBar: AppBar(title: const Text('梅花易数')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            cast.method,
            style: const TextStyle(
              color: AppColors.bronze,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cast.originalEntry.title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '第 ${cast.originalEntry.number} 卦',
            style: const TextStyle(color: AppColors.inkSoft),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Row(
              children: [
                _MiniHexagram(
                  label: '本卦',
                  title: cast.originalEntry.title,
                  lines: cast.original.lines,
                  changing: {cast.movingLine - 1},
                ),
                _MiniHexagram(
                  label: '互卦',
                  title: mutual.title,
                  lines: cast.mutual.lines,
                ),
                _MiniHexagram(
                  label: '变卦',
                  title: changed.title,
                  lines: cast.changed.lines,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '体用',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    ToneBadge(
                      label: cast.relation.tone,
                      color: _relationColor(cast.relation),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  '体卦 ${cast.body.name}${cast.body.nature} · ${cast.body.element.label}',
                ),
                const SizedBox(height: 4),
                Text(
                  '用卦 ${cast.function.name}${cast.function.nature} · ${cast.function.element.label}',
                ),
                const SizedBox(height: 4),
                Text(
                  '动爻 ${YaoPosition.names[cast.movingLine - 1]} · ${cast.relation.classicName}',
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final paragraph in cast.paragraphs) ...[
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

Color _relationColor(BodyUseRelation relation) {
  return switch (relation) {
    BodyUseRelation.useGeneratesBody ||
    BodyUseRelation.bodyOvercomesUse => AppColors.moss,
    BodyUseRelation.same || BodyUseRelation.bodyGeneratesUse => AppColors.bronze,
    BodyUseRelation.useOvercomesBody => AppColors.cinnabar,
  };
}

class _MiniHexagram extends StatelessWidget {
  const _MiniHexagram({
    required this.label,
    required this.title,
    required this.lines,
    this.changing = const <int>{},
  });

  final String label;
  final String title;
  final List<bool> lines;
  final Set<int> changing;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.bronze,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          HexagramFigure(lines: lines, changingIndexes: changing, width: 72),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}
