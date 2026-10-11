import 'dart:ui' as ui;

import 'package:citizen_app/features/website/presentation/website_landing_page.dart';
import 'package:citizen_app/features/website/presentation/website_root_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app() {
  return MaterialApp(
    home: const WebsiteLandingPage(),
    onGenerateRoute: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => Scaffold(body: Text('Route ${settings.name}')),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final storedValues = <String, String>{};
  const secureStorage = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(secureStorage, (call) async {
        if (call.method == 'read') {
          final arguments = call.arguments as Map<Object?, Object?>;
          final key = arguments['key'];
          if (key is String) return storedValues[key];
        }
        return null;
      });

  setUp(() async {
    storedValues.clear();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('root router shows public page for a logged-out visitor', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: WebsiteRootRouter(
          authenticatedBuilder: (_, _) => const Text('Protected dashboard'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your Voice.\nBetter Communities.'), findsOneWidget);
    expect(find.text('Protected dashboard'), findsNothing);
  });

  testWidgets('root router sends a restored user to the role entry', (
    tester,
  ) async {
    storedValues.addAll({
      'accessToken': 'test-token',
      'userId': 'test-user',
      'userRole': 'nodalOfficer',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: WebsiteRootRouter(
          authenticatedBuilder: (_, result) => Text(
            'Authenticated role ${result.role.name}; ${result.initialRoute}',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Authenticated role nodalOfficer; /officer-dashboard'),
      findsOneWidget,
    );
    expect(find.text('Your Voice.\nBetter Communities.'), findsNothing);
  });

  testWidgets('shows the public page and working FAQ accordion', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Your Voice.\nBetter Communities.'), findsOneWidget);
    expect(find.text('Report an Issue'), findsOneWidget);
    expect(find.text('What is SamadhanAI?'), findsOneWidget);
    expect(find.text('Citizen services & updates'), findsOneWidget);
    expect(find.text('What’s new'), findsOneWidget);
    expect(find.text('What’s happening'), findsOneWidget);

    const question = 'What kinds of issues can I report?';
    await tester.ensureVisible(find.text(question));
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('You can describe a local public-service issue'),
      findsOneWidget,
    );
    await tester.tap(find.text(question));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(question))
          .flagsCollection
          .isExpanded,
      ui.Tristate.isFalse,
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('mobile menu scrolls to sections and reaches auth routes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    expect(find.text('Features'), findsNWidgets(2));
    await tester.tap(find.text('Features').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Key Features'), findsOneWidget);

    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign in').hitTestable().last);
    await tester.pumpAndSettle();
    expect(find.text('Route /login'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('primary action enters the existing registration route', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Open navigation menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started').hitTestable().last);
    await tester.pumpAndSettle();
    expect(find.text('Route /register'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('landing page download entry opens /download', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 900);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download App').hitTestable().last);
    await tester.pumpAndSettle();
    expect(find.text('Route /download'), findsOneWidget);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('page renders without overflow on a narrow viewport', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  testWidgets('reference layout fits desktop, tablet, and mobile widths', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    const viewports = <Size>[
      Size(1440, 900),
      Size(1280, 800),
      Size(768, 1024),
      Size(430, 932),
      Size(375, 812),
      Size(320, 740),
    ];
    for (final viewport in viewports) {
      tester.view.physicalSize = viewport;
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'viewport $viewport');
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
