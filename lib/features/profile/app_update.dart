import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_update/azhon_app_update.dart';
import 'package:flutter_app_update/result_model.dart';
import 'package:flutter_app_update/update_model.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package:windmark/app/theme.dart';

class AppVersion implements Comparable<AppVersion> {
  const AppVersion(this.numbers, this.build);

  final List<int> numbers;
  final int build;

  String get label {
    final dotted = numbers.join('.');
    return build == 0 ? dotted : '$dotted+$build';
  }

  /// `1.0.6+6` 在安装包文件名里写成 `1.0.6-6`。
  String get fileToken => '${numbers.join('.')}-$build';

  static AppVersion? parseTag(String raw) {
    var text = raw.trim();
    if (text.startsWith('v') || text.startsWith('V')) {
      text = text.substring(1);
    }
    final pieces = text.split('+');
    if (pieces.isEmpty || pieces.first.isEmpty) {
      return null;
    }
    final numbers = <int>[];
    for (final part in pieces.first.split('.')) {
      final number = int.tryParse(part);
      if (number == null) {
        return null;
      }
      numbers.add(number);
    }
    final build = pieces.length == 1 ? 0 : int.tryParse(pieces[1]);
    if (build == null || pieces.length > 2) {
      return null;
    }
    return AppVersion(numbers, build);
  }

  factory AppVersion.installed(PackageInfo info) {
    final parsed = parseTag(info.version) ?? const AppVersion([0], 0);
    return AppVersion(parsed.numbers, pubspecBuildNumber(info.buildNumber));
  }

  /// 分包 APK 的 versionCode 是 pubspec 构建号再加上 1000 乘架构序号。
  static int pubspecBuildNumber(String buildNumber) {
    final raw = int.tryParse(buildNumber) ?? 0;
    if (raw >= 1000) {
      return raw % 1000;
    }
    return raw;
  }

  @override
  int compareTo(AppVersion other) {
    final length = numbers.length > other.numbers.length
        ? numbers.length
        : other.numbers.length;
    for (var i = 0; i < length; i++) {
      final left = i < numbers.length ? numbers[i] : 0;
      final right = i < other.numbers.length ? other.numbers[i] : 0;
      if (left != right) {
        return left.compareTo(right);
      }
    }
    return build.compareTo(other.build);
  }
}

class PublishedRelease {
  const PublishedRelease({required this.version, required this.apkUrl});

  final AppVersion version;
  final String apkUrl;
}

class DownloadMirror {
  const DownloadMirror(this.label, this.prefix);

  final String label;
  final String prefix;

  String apply(String url) => '$prefix$url';
}

const downloadMirrors = [
  DownloadMirror('ghfast.top', 'https://ghfast.top/'),
  DownloadMirror('gh-proxy.com', 'https://gh-proxy.com/'),
  DownloadMirror('ghproxy.net', 'https://ghproxy.net/'),
];

/// 从 GitHub Release 里挑出当前手机架构的 APK。没有对应包时返回空。
PublishedRelease? matchRelease(Map json, List<String> abis) {
  final tag = json['tag_name'];
  final version = tag is String ? AppVersion.parseTag(tag) : null;
  final assets = json['assets'];
  if (version == null || assets is! List) {
    return null;
  }
  final byName = <String, String>{};
  for (final item in assets) {
    if (item is! Map) {
      continue;
    }
    final name = item['name'];
    final url = item['browser_download_url'];
    if (name is String && url is String && url.isNotEmpty) {
      byName[name] = url;
    }
  }
  for (final abi in abis) {
    final url = byName['windmark-${version.fileToken}-$abi.apk'];
    if (url != null) {
      return PublishedRelease(version: version, apkUrl: url);
    }
  }
  return null;
}

sealed class UpdateLookup {
  const UpdateLookup();
}

class UpdateUpToDate extends UpdateLookup {
  const UpdateUpToDate();
}

class UpdateAvailable extends UpdateLookup {
  const UpdateAvailable(this.release);

  final PublishedRelease release;
}

class UpdateUnavailable extends UpdateLookup {
  const UpdateUnavailable(this.message);

  final String message;
}

Future<UpdateLookup> lookForUpdate({
  http.Client? client,
  Future<List<String>> Function()? abis,
  Future<PackageInfo> Function()? packageInfo,
}) async {
  final http.Client httpClient = client ?? http.Client();
  final closeClient = client == null;
  try {
    final supported = await (abis ?? deviceAbis)();
    if (supported.isEmpty) {
      return const UpdateUnavailable('只能在 Android 上安装更新');
    }
    final info = await (packageInfo ?? PackageInfo.fromPlatform)();
    final local = AppVersion.installed(info);
    final response = await httpClient.get(
      Uri.parse(
        'https://api.github.com/repos/fengzhongsikao/windmark/releases/latest',
      ),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'windmark',
      },
    );
    if (response.statusCode == 404) {
      return const UpdateUnavailable('还没有发布的版本');
    }
    if (response.statusCode != 200) {
      return const UpdateUnavailable('暂时无法检查更新');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      return const UpdateUnavailable('暂时无法检查更新');
    }
    final release = matchRelease(decoded, supported);
    if (release == null) {
      final remote = AppVersion.parseTag('${decoded['tag_name'] ?? ''}');
      if (remote != null && remote.compareTo(local) <= 0) {
        return const UpdateUpToDate();
      }
      return const UpdateUnavailable('没有适合这台手机的安装包');
    }
    if (release.version.compareTo(local) <= 0) {
      return const UpdateUpToDate();
    }
    return UpdateAvailable(release);
  } on SocketException {
    return const UpdateUnavailable('暂时无法检查更新');
  } on http.ClientException {
    return const UpdateUnavailable('暂时无法检查更新');
  } finally {
    if (closeClient) {
      httpClient.close();
    }
  }
}

Future<List<String>> deviceAbis() async {
  if (!Platform.isAndroid) {
    return const [];
  }
  final info = await DeviceInfoPlugin().androidInfo;
  return info.supportedAbis;
}

Future<void> checkForUpdate(BuildContext context) async {
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            SizedBox(width: 16),
            Expanded(child: Text('正在检查更新')),
          ],
        ),
      ),
    ),
  );
  final lookup = await lookForUpdate();
  if (!context.mounted) {
    return;
  }
  navigator.pop();
  switch (lookup) {
    case UpdateUpToDate():
      _snack(messenger, '当前已是最新版本');
    case UpdateUnavailable(:final message):
      _snack(messenger, message);
    case UpdateAvailable(:final release):
      final direct = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('发现新版本'),
          content: Text('新版本是 ${release.version.label}。可以直接下载，也可以选一个镜像。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('镜像下载'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('直接下载'),
            ),
          ],
        ),
      );
      if (!context.mounted || direct == null) {
        return;
      }
      final url = direct
          ? release.apkUrl
          : await _pickMirrorUrl(context, release.apkUrl);
      if (url != null && context.mounted) {
        await _downloadAndInstall(context, url);
      }
  }
}

Future<String?> _pickMirrorUrl(BuildContext context, String apkUrl) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('选择镜像'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final mirror in downloadMirrors)
            TextButton(
              onPressed: () => Navigator.pop(context, mirror.apply(apkUrl)),
              child: Text(mirror.label),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    ),
  );
}

Future<void> _downloadAndInstall(BuildContext context, String url) async {
  final messenger = ScaffoldMessenger.of(context);
  final progress = ValueNotifier<double?>(null);
  var closed = false;
  var cancelled = false;

  void closeDialog() {
    if (closed || !context.mounted) {
      return;
    }
    closed = true;
    Navigator.of(context).pop();
  }

  AzhonAppUpdate.dispose();
  AzhonAppUpdate.listener((model) {
    switch (model.type) {
      case ResultType.start:
        progress.value = 0;
      case ResultType.downloading:
        final max = model.max ?? 0;
        final current = model.progress ?? 0;
        progress.value = max <= 0 ? null : (current / max).clamp(0, 1);
      case ResultType.done:
        closeDialog();
      case ResultType.cancel:
        closeDialog();
      case ResultType.error:
        closeDialog();
        if (!cancelled) {
          _snack(messenger, '下载没有完成');
        }
      default:
        break;
    }
  });

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('正在下载'),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (context, value, _) {
            final percent = value == null ? null : (value * 100).round();
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: value),
                const SizedBox(height: 12),
                Text(
                  percent == null ? '正在连接' : '已完成 $percent%',
                  style: const TextStyle(color: AppColors.inkSoft),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              cancelled = true;
              AzhonAppUpdate.cancel();
              closeDialog();
            },
            child: const Text('取消'),
          ),
        ],
      ),
    ),
  );

  try {
    await AzhonAppUpdate.update(
      UpdateModel(
        url,
        'windmark-update.apk',
        'launcher_icon',
        '',
        showNotification: false,
        jumpInstallPage: true,
        showBgdToast: false,
      ),
    );
  } on MissingPluginException {
    closeDialog();
    _snack(messenger, '只能在 Android 上安装更新');
  } on PlatformException {
    closeDialog();
    if (!cancelled) {
      _snack(messenger, '下载没有完成');
    }
  }
}

void _snack(ScaffoldMessengerState messenger, String message) {
  messenger.clearSnackBars();
  messenger.showSnackBar(SnackBar(content: Text(message)));
}
