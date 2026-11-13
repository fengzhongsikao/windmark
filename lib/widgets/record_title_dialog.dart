import 'package:flutter/material.dart';

Future<String?> askRecordTitle(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _RecordTitleDialog(),
  );
}

class _RecordTitleDialog extends StatefulWidget {
  const _RecordTitleDialog();

  @override
  State<_RecordTitleDialog> createState() => _RecordTitleDialogState();
}

class _RecordTitleDialogState extends State<_RecordTitleDialog> {
  final _title = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _title.text.trim();
    if (title.isEmpty) {
      return;
    }
    Navigator.pop(context, title);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _title.text.trim().isNotEmpty;
    return AlertDialog(
      title: const Text('记录标题'),
      content: TextField(
        key: const ValueKey('record-title'),
        controller: _title,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(
          labelText: '标题',
          hintText: '给这条排盘起个名字',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          key: const ValueKey('record-title-save'),
          onPressed: ready ? _submit : null,
          child: const Text('保存'),
        ),
      ],
    );
  }
}
