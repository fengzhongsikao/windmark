import 'dart:convert';

import 'package:flutter/services.dart';

class WingSection {
  const WingSection({required this.heading, required this.paragraphs});

  final String heading;
  final List<String> paragraphs;
}

class WingChapter {
  const WingChapter({required this.title, required this.sections});

  final String title;
  final List<WingSection> sections;
}

class YiWingBook {
  YiWingBook(this.chapters);

  final List<WingChapter> chapters;

  static Future<YiWingBook>? _loading;

  static Future<YiWingBook> load() {
    return _loading ??= _read();
  }

  static Future<YiWingBook> _read() async {
    final raw = await rootBundle.loadString('assets/wings.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final chapters = json['chapters'] as List<dynamic>;
    return YiWingBook([
      for (final chapter in chapters.cast<Map<String, dynamic>>())
        WingChapter(
          title: chapter['title'] as String,
          sections: [
            for (final section
                in (chapter['sections'] as List<dynamic>)
                    .cast<Map<String, dynamic>>())
              WingSection(
                heading: section['heading'] as String,
                paragraphs: [
                  for (final paragraph
                      in section['paragraphs'] as List<dynamic>)
                    paragraph as String,
                ],
              ),
          ],
        ),
    ]);
  }
}
