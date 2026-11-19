import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/gua_classic.dart';
import 'package:windmark/widgets/common.dart';

const _mark = Color(0xFFFF0000);
const _jing = TextStyle(height: 1.65, fontSize: 15);

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
    final hasYongLine = classic.yaoCi.any((line) => line.startsWith('用'));
    final trailingYong = classic.xiaoXiang.length > 6 && !hasYongLine
        ? classic.xiaoXiang[6]
        : null;
    final wingTitle = classic.wenyan.isEmpty ? '序卦、杂卦' : '文言、序卦、杂卦';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.heading,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(classic.guaCi, style: _jing),
        const SizedBox(height: 8),
        _Comment('彖曰${classic.tuan}'),
        const SizedBox(height: 4),
        _Comment('象曰${classic.daXiang}'),
        const SizedBox(height: 8),
        for (final line in classic.yaoCi)
          _YaoBlock(
            line: line,
            image: _xiaoOf(classic, line),
            marked: section.lines.contains(yaoLineOf(line)),
          ),
        if (trailingYong != null) _Comment('象曰$trailingYong'),
        const Divider(height: 20, color: AppColors.line),
        Material(
          color: Colors.white,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              iconColor: AppColors.inkSoft,
              collapsedIconColor: AppColors.inkSoft,
              title: Text(
                wingTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.ink,
                ),
              ),
              children: [
                if (classic.wenyan.isNotEmpty) ...[
                  const _WingLabel('文言'),
                  for (final paragraph in classic.wenyan) ...[
                    Text(paragraph, style: _jing),
                    const SizedBox(height: 8),
                  ],
                ],
                const _WingLabel('序卦'),
                Text(classic.xu, style: _jing),
                const SizedBox(height: 8),
                const _WingLabel('杂卦'),
                Text(classic.za, style: _jing),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String? _xiaoOf(GuaClassic classic, String line) {
    final number = yaoLineOf(line);
    if (number != null && number <= classic.xiaoXiang.length) {
      return classic.xiaoXiang[number - 1];
    }
    if (line.startsWith('用') && classic.xiaoXiang.length > 6) {
      return classic.xiaoXiang[6];
    }
    return null;
  }
}

class _YaoBlock extends StatelessWidget {
  const _YaoBlock({
    required this.line,
    required this.image,
    required this.marked,
  });

  final String line;
  final String? image;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            line,
            style: TextStyle(
              height: 1.65,
              fontSize: 15,
              color: marked ? _mark : null,
              fontWeight: marked ? FontWeight.w700 : null,
            ),
          ),
          if (image != null) _Comment('象曰$image', marked: marked),
        ],
      ),
    );
  }
}

class _Comment extends StatelessWidget {
  const _Comment(this.text, {this.marked = false});

  final String text;
  final bool marked;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        height: 1.65,
        fontSize: 14,
        color: marked ? _mark : AppColors.inkSoft,
        fontWeight: marked ? FontWeight.w700 : null,
      ),
    );
  }
}

class _WingLabel extends StatelessWidget {
  const _WingLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}
