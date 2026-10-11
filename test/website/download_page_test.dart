import 'package:citizen_app/features/website/presentation/download_release_metadata.dart';
import 'package:citizen_app/features/website/presentation/website_download_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final _verifiedRelease = DownloadReleaseMetadata(
  isVerified: true,
  androidUrl: 'https://downloads.example.test/releases/samadhanai.apk',
  versionName: '1.2.3',
  versionCode: '12',
  fileSizeBytes: '12000000',
  minimumAndroidApi: '24',
  releaseDate: '2026-10-11',
  sha256: 'a' * 64,
  signingCertificateSha256: 'b' * 64,
);

void main() {
  testWidgets('download page presents unavailable release and iOS state', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(MaterialApp(home: const WebsiteDownloadPage()));
    await tester.pumpAndSettle();

    expect(find.text('SamadhanAI,\nin Your Pocket'), findsOneWidget);
    expect(find.text('Download for Android'), findsOneWidget);
    expect(find.text('Download APK (Direct)'), findsOneWidget);
    expect(
      find.textContaining(
        'links will be enabled once the official release artifact is verified',
      ),
      findsOneWidget,
    );
    expect(find.text('How to install (Android)'), findsOneWidget);
    expect(
      find.textContaining('No verified App Store listing is configured.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('verified HTTPS metadata enables the Android download options', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    Uri? launchedUri;
    String? launchedFileName;
    await tester.pumpWidget(
      MaterialApp(
        home: WebsiteDownloadPage(
          release: _verifiedRelease,
          downloadLauncher: (uri, fileName) async {
            launchedUri = uri;
            launchedFileName = fileName;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Verified official release'), findsOneWidget);
    expect(find.textContaining('1.2.3'), findsOneWidget);
    await tester.tap(find.text('Download for Android'));
    await tester.pumpAndSettle();
    expect(launchedUri, Uri.parse(_verifiedRelease.androidUrl));
    expect(launchedFileName, 'samadhanai-1.2.3+12.apk');
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('failed browser launch reports failure without success state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WebsiteDownloadPage(
          release: _verifiedRelease,
          downloadLauncher: (_, _) async => false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download for Android'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'The download could not be opened. Check your connection and try again.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('page lays out without overflow at reference viewport widths', (
    tester,
  ) async {
    for (final width in [320, 375, 430, 768, 1280, 1440]) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width.toDouble(), 900);
      await tester.pumpWidget(const MaterialApp(home: WebsiteDownloadPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'viewport width $width');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  test('metadata cannot enable an insecure or incomplete artifact', () {
    expect(DownloadReleaseMetadata.current.isAndroidAvailable, isFalse);
    expect(
      DownloadReleaseMetadata(
        isVerified: true,
        androidUrl: 'http://downloads.example.test/app.apk',
        versionName: '1.2.3',
        versionCode: '12',
        fileSizeBytes: '12000000',
        minimumAndroidApi: '24',
        releaseDate: '',
        sha256: 'a' * 64,
        signingCertificateSha256: 'b' * 64,
      ).isAndroidAvailable,
      isFalse,
    );
  });
}
