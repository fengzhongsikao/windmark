import 'package:flutter/material.dart';

import 'package:windmark/core/models/reading_record.dart';
import 'package:windmark/features/liuyao/liuyao_engine.dart';
import 'package:windmark/features/liuyao/liuyao_result_page.dart';
import 'package:windmark/features/meihua/meihua_engine.dart';
import 'package:windmark/features/meihua/meihua_result_page.dart';

void openReading(BuildContext context, ReadingRecord record) {
  final Widget page = switch (record.kind) {
    ReadingKind.meihua => MeihuaResultPage(
      cast: MeihuaCast.fromPayload(record.payload, record.createdAt),
      canSave: false,
    ),
    ReadingKind.liuyao => LiuyaoResultPage(
      reading: LiuyaoReading.fromPayload(record.payload, record.createdAt),
      canSave: false,
    ),
  };
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}
