import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/core/models/reading_record.dart';
import 'package:windmark/features/history/history_controller.dart';
import 'package:windmark/features/profile/history_list_page.dart';
import 'package:windmark/features/profile/user_profile.dart';
import 'package:windmark/widgets/common.dart';
import 'package:windmark/widgets/user_avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(readingHistoryProvider);
    final profile =
        ref.watch(userProfileProvider).asData?.value ?? UserProfile.fallback;
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
                    UserAvatar(
                      profile: profile,
                      onTap: () => _chooseAvatar(context, ref, profile),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            key: const ValueKey('display-name'),
                            onTap: () => _editName(context, ref, profile.name),
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.name,
                                    style: textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.inkSoft,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '共 ${records.length} 次排盘',
                            style: const TextStyle(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '排盘记录',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _RecordLink(
                title: '梅花排盘记录',
                count: records
                    .where((record) => record.kind == ReadingKind.meihua)
                    .length,
                onTap: () => _openList(context, ReadingKind.meihua),
              ),
              const SizedBox(height: 8),
              _RecordLink(
                title: '六爻排盘记录',
                count: records
                    .where((record) => record.kind == ReadingKind.liuyao)
                    .length,
                onTap: () => _openList(context, ReadingKind.liuyao),
              ),
              const SizedBox(height: 12),
              const _AboutTile(
                title: '梅花易数',
                body: '以先天八卦数起卦。可以按时间、手动指定上卦下卦和动爻、报一个三位数，或自动起卦。成卦后看本卦、互卦、变卦，再以不动的一卦为体、发动的一卦为用，看五行生克。',
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

  void _openList(BuildContext context, ReadingKind kind) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => HistoryListPage(kind: kind)),
    );
  }
}

class _RecordLink extends StatelessWidget {
  const _RecordLink({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                '$count 条',
                style: const TextStyle(color: AppColors.inkSoft),
              ),
              const Icon(Icons.chevron_right, color: AppColors.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}

enum _AvatarChoice { pick, reset }

Future<void> _chooseAvatar(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  final choice = await showModalBottomSheet<_AvatarChoice>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, _AvatarChoice.pick),
            ),
            if (profile.avatarFile != null)
              ListTile(
                title: const Text('恢复默认头像'),
                onTap: () => Navigator.pop(context, _AvatarChoice.reset),
              ),
          ],
        ),
      );
    },
  );
  if (!context.mounted || choice == null) {
    return;
  }
  if (choice == _AvatarChoice.reset) {
    try {
      await ref.read(userProfileProvider.notifier).clearAvatar();
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('头像没有保存成功')));
    }
    return;
  }
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    imageQuality: 85,
  );
  if (image == null || !context.mounted) {
    return;
  }
  try {
    await ref
        .read(userProfileProvider.notifier)
        .saveAvatar(await image.readAsBytes());
  } on Object {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('头像没有保存成功')));
  }
}

Future<void> _editName(
  BuildContext context,
  WidgetRef ref,
  String current,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(initial: current),
  );
  if (name == null || !context.mounted) {
    return;
  }
  try {
    await ref.read(userProfileProvider.notifier).saveName(name);
  } on Object {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('用户名没有保存成功')));
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      return;
    }
    Navigator.pop(context, name);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _name.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('用户名'),
      content: TextField(
        key: const ValueKey('display-name-field'),
        controller: _name,
        autofocus: true,
        maxLength: 20,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(labelText: '用户名'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          key: const ValueKey('display-name-save'),
          onPressed: ready ? _submit : null,
          child: const Text('保存'),
        ),
      ],
    );
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
