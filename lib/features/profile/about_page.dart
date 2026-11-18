import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:windmark/app/app_copy.dart';
import 'package:windmark/app/theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('关于我们')),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  child: Image.asset(
                    'assets/icon/icon.png',
                    key: const ValueKey('about-icon'),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '梅花易数 · 六爻纳甲',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.white,
            child: InkWell(
              key: const ValueKey('about-github'),
              onTap: () => _openGithub(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const _GithubMark(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GitHub',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            AppCopy.githubUrl,
                            style: TextStyle(
                              color: AppColors.cinnabar,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Color(0xFFC4C4C4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openGithub(BuildContext context) async {
  try {
    final opened = await launchUrl(
      Uri.parse(AppCopy.githubUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      _showOpenFailed(context);
    }
  } on Object {
    if (context.mounted) {
      _showOpenFailed(context);
    }
  }
}

void _showOpenFailed(BuildContext context) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('暂时打不开这个链接')));
}

class _GithubMark extends StatelessWidget {
  const _GithubMark();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      key: ValueKey('about-github-icon'),
      size: Size.square(22),
      painter: _GithubMarkPainter(),
    );
  }
}

class _GithubMarkPainter extends CustomPainter {
  const _GithubMarkPainter();

  static final Path _logo = _githubLogo();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24;
    canvas.scale(scale);
    canvas.drawPath(
      _logo,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _GithubMarkPainter oldDelegate) => false;
}

const _githubPath =
    'M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61C4.422 18.07 3.633 17.7 3.633 17.7c-1.087-.744.084-.729.084-.729 1.205.084 1.838 1.236 1.838 1.236 1.07 1.835 2.809 1.305 3.495.998.108-.776.417-1.305.76-1.605-2.665-.3-5.466-1.332-5.466-5.93 0-1.31.465-2.38 1.235-3.22-.135-.303-.54-1.523.105-3.176 0 0 1.005-.322 3.3 1.23.96-.267 1.98-.399 3-.405 1.02.006 2.04.138 3 .405 2.28-1.552 3.285-1.23 3.285-1.23.645 1.653.24 2.873.12 3.176.765.84 1.23 1.91 1.23 3.22 0 4.61-2.805 5.625-5.475 5.92.42.36.81 1.096.81 2.22 0 1.606-.015 2.896-.015 3.286 0 .315.21.69.825.57C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12';

Path _githubLogo() {
  final path = Path();
  final tokens = <Object>[];
  final number = RegExp(r'[+-]?(?:\d*\.\d+|\d+)(?:[eE][+-]?\d+)?');
  var index = 0;
  while (index < _githubPath.length) {
    final char = _githubPath[index];
    if ('MmCcZz'.contains(char)) {
      tokens.add(char);
      index++;
      continue;
    }
    if (char == ',' || char.trim().isEmpty) {
      index++;
      continue;
    }
    final match = number.matchAsPrefix(_githubPath, index);
    if (match == null) {
      index++;
      continue;
    }
    tokens.add(double.parse(match.group(0)!));
    index = match.end;
  }

  String? command;
  var cursor = 0;
  var point = Offset.zero;
  while (cursor < tokens.length) {
    if (tokens[cursor] is String) {
      command = tokens[cursor] as String;
      cursor++;
      if (command == 'Z' || command == 'z') {
        path.close();
        command = null;
        continue;
      }
    }
    switch (command) {
      case 'M':
        point = Offset(tokens[cursor++] as double, tokens[cursor++] as double);
        path.moveTo(point.dx, point.dy);
        command = 'L';
      case 'm':
        point += Offset(tokens[cursor++] as double, tokens[cursor++] as double);
        path.moveTo(point.dx, point.dy);
        command = 'l';
      case 'C':
        final x1 = tokens[cursor++] as double;
        final y1 = tokens[cursor++] as double;
        final x2 = tokens[cursor++] as double;
        final y2 = tokens[cursor++] as double;
        final x = tokens[cursor++] as double;
        final y = tokens[cursor++] as double;
        point = Offset(x, y);
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 'c':
        final x1 = point.dx + (tokens[cursor++] as double);
        final y1 = point.dy + (tokens[cursor++] as double);
        final x2 = point.dx + (tokens[cursor++] as double);
        final y2 = point.dy + (tokens[cursor++] as double);
        final x = point.dx + (tokens[cursor++] as double);
        final y = point.dy + (tokens[cursor++] as double);
        point = Offset(x, y);
        path.cubicTo(x1, y1, x2, y2, x, y);
      default:
        cursor = tokens.length;
    }
  }
  return path;
}
