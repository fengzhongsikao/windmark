import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:windmark/app/theme.dart';
import 'package:windmark/app/windmark_app.dart';
import 'package:windmark/core/storage/history_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlay);
  final history = await FileHistoryStore.open();
  runApp(
    ProviderScope(
      overrides: [
        historyStoreProvider.overrideWithValue(history),
      ],
      child: const WindmarkApp(),
    ),
  );
}
