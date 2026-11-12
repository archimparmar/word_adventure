// Guards the AdMob runtime configuration: production IDs only, no test IDs,
// no simulated "test ad" on the mobile path.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:word_puzzle/services/ad_service.dart';

const _appId = 'ca-app-pub-5873612031869970~7973233013';
const _googleTestPublisher = 'ca-app-pub-3940256099942544';

void main() {
  test('AdService hands the production unit IDs to the SDK', () {
    final ads = AdService();
    expect(ads.appId, _appId);
    expect(ads.bannerAdUnitId, 'ca-app-pub-5873612031869970/5683158742');
    expect(ads.interstitialAdUnitId, 'ca-app-pub-5873612031869970/3236958805');
    expect(ads.rewardedAdUnitId, 'ca-app-pub-5873612031869970/9455152297');
  });

  test('No Google test IDs or test-device configuration anywhere in app source', () {
    final files = [
      ...Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart')),
      ...Directory('android/app/src').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.xml')),
    ];
    for (final f in files) {
      final src = f.readAsStringSync();
      expect(src.contains(_googleTestPublisher), isFalse, reason: f.path);
      expect(src.contains('testDeviceIds'), isFalse, reason: f.path);
      // every ad unit / app ID in source belongs to the production publisher
      for (final m in RegExp(r'ca-app-pub-\d+').allMatches(src)) {
        expect(m.group(0), 'ca-app-pub-5873612031869970', reason: f.path);
      }
    }
  });

  test('AndroidManifest declares the production App ID exactly once', () {
    final main = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect('com.google.android.gms.ads.APPLICATION_ID'.allMatches(main).length, 1);
    expect(main.contains('android:value="$_appId"'), isTrue);
    for (final variant in ['debug', 'profile']) {
      final f = File('android/app/src/$variant/AndroidManifest.xml');
      if (f.existsSync()) {
        expect(f.readAsStringSync().contains('APPLICATION_ID'), isFalse, reason: '$variant manifest must not override the App ID');
      }
    }
  });

  test('Simulated test-ad dialog is reachable only in debug on non-mobile platforms', () {
    final src = File('lib/services/ad_service.dart').readAsStringSync();
    final calls = RegExp(r'_showSimulatedAdDialog\(context').allMatches(src).toList();
    expect(calls.length, 1, reason: 'only the non-mobile debug branch may show the simulated ad');
    final before = src.substring(0, calls.first.start);
    final platformGuard = before.lastIndexOf('if (!isSupportedPlatform)');
    expect(platformGuard > 0, isTrue);
    expect(before.substring(platformGuard).contains('if (kDebugMode)'), isTrue);
    expect(before.substring(platformGuard).contains('return;'), isFalse);
  });
}
