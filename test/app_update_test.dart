import 'package:flutter_test/flutter_test.dart';
import 'package:windmark/features/profile/app_update.dart';

void main() {
  test('版本号按数字和构建号比较', () {
    final current = AppVersion.parseTag('v1.0.6+6')!;
    expect(current.label, '1.0.6+6');
    expect(current.fileToken, '1.0.6-6');
    expect(AppVersion.parseTag('1.0.10+1')!.compareTo(current), greaterThan(0));
    expect(AppVersion.parseTag('v1.0.6+7')!.compareTo(current), greaterThan(0));
    expect(AppVersion.parseTag('1.0.6+6')!.compareTo(current), 0);
    expect(AppVersion.parseTag('1.0.5+99')!.compareTo(current), lessThan(0));
    expect(AppVersion.pubspecBuildNumber('2006'), 6);
    expect(AppVersion.pubspecBuildNumber('6'), 6);
  });

  test('按手机架构挑选 APK，不选 AAB', () {
    final release = {
      'tag_name': 'v1.0.7+8',
      'assets': [
        {
          'name': 'windmark-1.0.7-8.aab',
          'browser_download_url': 'https://example.com/app.aab',
        },
        {
          'name': 'windmark-1.0.7-8-armeabi-v7a.apk',
          'browser_download_url': 'https://example.com/v7a.apk',
        },
        {
          'name': 'windmark-1.0.7-8-arm64-v8a.apk',
          'browser_download_url': 'https://example.com/arm64.apk',
        },
      ],
    };

    final matched = matchRelease(release, const ['arm64-v8a', 'armeabi-v7a']);
    expect(matched?.apkUrl, 'https://example.com/arm64.apk');
    expect(matched?.version.label, '1.0.7+8');
    expect(matchRelease(release, const ['x86_64']), isNull);
  });

  test('镜像地址加在 GitHub 链接前面', () {
    const url =
        'https://github.com/fengzhongsikao/windmark/releases/download/v1.0.7+8/a.apk';
    expect(
      downloadMirrors.map((mirror) => mirror.apply(url)),
      [
        'https://ghfast.top/$url',
        'https://gh-proxy.com/$url',
        'https://ghproxy.net/$url',
      ],
    );
  });
}
