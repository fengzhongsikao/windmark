import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';

class DivinationExplainPage extends StatelessWidget {
  const DivinationExplainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('占卜解释')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: const [
          _ExplainBlock(
            title: '梅花易数',
            body:
                '以先天八卦数起卦。可以按时间、手动指定上卦下卦和动爻、数字起卦，或自动起卦。成卦后看本卦、互卦、变卦，再以不动的一卦为体、发动的一卦为用，看五行生克。',
          ),
          SizedBox(height: 12),
          _ExplainBlock(
            title: '六爻纳甲',
            body:
                '可以摇铜钱、手动指定，或按时间、数字起卦。背为阳、字为阴：一背二字为少阳，两背一字为少阴，三背为老阳，三字为老阴。老阳、老阴是变爻。再按卦宫装世应，按上下卦纳甲，配六亲、六神和月令旺衰。',
          ),
        ],
      ),
    );
  }
}

class _ExplainBlock extends StatelessWidget {
  const _ExplainBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.inkSoft,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
