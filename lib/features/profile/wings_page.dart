import 'package:flutter/material.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/iching/gua_classic.dart';
import 'package:windmark/core/iching/yi_wings.dart';
import 'package:windmark/widgets/common.dart';

class WingsPage extends StatelessWidget {
  const WingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('易传')),
      body: FutureBuilder<List<WingChapter>>(
        future: _chapters(),
        builder: (context, snapshot) {
          final chapters = snapshot.data;
          if (chapters == null) {
            if (snapshot.hasError) {
              return const Center(child: Text('暂时读不出来'));
            }
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Material(
                color: Colors.white,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < chapters.length; i++) ...[
                      if (i > 0)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.line,
                        ),
                      _WingRow(
                        title: chapters[i].title,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  WingReadingPage(chapter: chapters[i]),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class WingReadingPage extends StatelessWidget {
  const WingReadingPage({super.key, required this.chapter});

  final WingChapter chapter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(chapter.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          for (final section in chapter.sections) ...[
            SectionCard(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section.heading.isNotEmpty) ...[
                    Text(
                      section.heading,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  for (var i = 0; i < section.paragraphs.length; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    Text(
                      section.paragraphs[i],
                      style: const TextStyle(height: 1.7, fontSize: 15),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _WingRow extends StatelessWidget {
  const _WingRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.inkSoft),
          ],
        ),
      ),
    );
  }
}

Future<List<WingChapter>>? _chaptersFuture;

Future<List<WingChapter>> _chapters() {
  return _chaptersFuture ??= _readChapters();
}

Future<List<WingChapter>> _readChapters() async {
  final book = await GuaTextBook.load();
  final wings = await YiWingBook.load();
  WingChapter wenyan(int number, String name) {
    return WingChapter(
      title: '文言 · $name',
      sections: [
        WingSection(heading: '', paragraphs: book.byNumber(number)!.wenyan),
      ],
    );
  }

  return [wenyan(1, '乾'), wenyan(2, '坤'), ...wings.chapters];
}
