import 'package:flutter/material.dart';

import 'package:windmark/core/iching/gua_classic.dart';
import 'package:windmark/widgets/common.dart';

const _mark = Color(0xFFFF0000);

class ClassicSection {
  const ClassicSection({
    required this.heading,
    required this.number,
    this.lines = const {},
  });

  final String heading;
  final int number;

  /// 需要标出的爻，1 为初爻，6 为上爻。
  final Set<int> lines;
}

class ClassicTexts extends StatelessWidget {
  const ClassicTexts({super.key, required this.sections});

  final List<ClassicSection> sections;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GuaTextBook>(
      future: GuaTextBook.load(),
      builder: (context, snapshot) {
        final book = snapshot.data;
        if (book == null) {
          return const SizedBox.shrink();
        }
        return Column(
          children: [
            for (final section in sections) ...[
              SectionCard(
                color: Colors.white,
                child: _SectionBody(book: book, section: section),
              ),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _SectionBody extends StatelessWidget {
  const _SectionBody({required this.book, required this.section});

  final GuaTextBook book;
  final ClassicSection section;

  @override
  Widget build(BuildContext context) {
    final classic = book.byNumber(section.number);
    if (classic == null) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(classic.guaCi, style: const TextStyle(height: 1.65, fontSize: 15)),
        const SizedBox(height: 8),
        for (final line in classic.yaoCi)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              line,
              style: TextStyle(
                height: 1.65,
                fontSize: 15,
                color: section.lines.contains(yaoLineOf(line)) ? _mark : null,
                fontWeight: section.lines.contains(yaoLineOf(line))
                    ? FontWeight.w700
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
