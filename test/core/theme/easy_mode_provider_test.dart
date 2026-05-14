import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pathio/core/theme/easy_mode_provider.dart';

/// Tests for [EasyModeNotifier] and the helpers + extensions exported
/// from `easy_mode_provider.dart`.
///
/// We use [SharedPreferences.setMockInitialValues] so the notifier's
/// async load from prefs resolves predictably.

void main() {
  group('EasyModeConfig helpers', () {
    test('scaleTextStyle scales fontSize by textScaleFactor', () {
      const config = EasyModeConfig(textScaleFactor: 2.0);
      final styled = config.scaleTextStyle(const TextStyle(fontSize: 14));
      expect(styled.fontSize, 28);
    });

    test('scaleTextStyle defaults fontSize to 14 when null', () {
      const config = EasyModeConfig(textScaleFactor: 2.0);
      final styled = config.scaleTextStyle(const TextStyle());
      expect(styled.fontSize, 28);
    });

    test('scaleIconSize multiplies', () {
      const config = EasyModeConfig(iconSizeMultiplier: 1.5);
      expect(config.scaleIconSize(24), 36);
    });

    test('scaleSpacing multiplies', () {
      const config = EasyModeConfig(spacingMultiplier: 1.3);
      expect(config.scaleSpacing(16), closeTo(20.8, 0.01));
    });

    test('scaleBorderRadius multiplies', () {
      const config = EasyModeConfig(borderRadiusMultiplier: 2.0);
      expect(config.scaleBorderRadius(8), 16);
    });

    test('ensureMinTouchTarget enforces the minimum', () {
      const config = EasyModeConfig(minTouchTargetSize: 72);
      expect(config.ensureMinTouchTarget(40), 72);
    });

    test('ensureMinTouchTarget passes through when already large enough', () {
      const config = EasyModeConfig(minTouchTargetSize: 72);
      expect(config.ensureMinTouchTarget(100), 100);
    });
  });

  group('EasyModeNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts in disabled state', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(easyModeEnabledProvider), isFalse);
    });

    test('loads saved true value from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'easy_mode_enabled': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Subscribe so build() is called.
      container.listen(easyModeEnabledProvider, (_, __) {});
      // Wait for the async _loadPreference to resolve.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(easyModeEnabledProvider), isTrue);
    });

    test('toggle flips the state and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger build.
      container.listen(easyModeEnabledProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final notifier = container.read(easyModeEnabledProvider.notifier);
      await notifier.toggle();
      expect(container.read(easyModeEnabledProvider), isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('easy_mode_enabled'), isTrue);

      await notifier.toggle();
      expect(container.read(easyModeEnabledProvider), isFalse);
      expect(prefs.getBool('easy_mode_enabled'), isFalse);
    });

    test('setEnabled assigns and persists', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.listen(easyModeEnabledProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final notifier = container.read(easyModeEnabledProvider.notifier);
      await notifier.setEnabled(true);
      expect(container.read(easyModeEnabledProvider), isTrue);

      await notifier.setEnabled(false);
      expect(container.read(easyModeEnabledProvider), isFalse);
    });
  });

  group('easyModeConfigProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('returns EasyModeConfig.normal when easy mode disabled', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(easyModeConfigProvider), EasyModeConfig.normal);
    });

    test('returns EasyModeConfig.easy when easy mode enabled', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.listen(easyModeEnabledProvider, (_, __) {});
      await Future<void>.delayed(const Duration(milliseconds: 10));

      await container
          .read(easyModeEnabledProvider.notifier)
          .setEnabled(true);

      expect(container.read(easyModeConfigProvider), EasyModeConfig.easy);
    });
  });

  group('EasyModeContext extension', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('context.easyMode returns config from nearest ProviderScope',
        (tester) async {
      EasyModeConfig? captured;
      bool? captureEnabled;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                captured = context.easyMode;
                captureEnabled = context.isEasyModeEnabled;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(captured, EasyModeConfig.normal);
      expect(captureEnabled, isFalse);
    });

    testWidgets('context.easyMode falls back to normal without ProviderScope',
        (tester) async {
      EasyModeConfig? captured;
      bool? captureEnabled;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context.easyMode;
              captureEnabled = context.isEasyModeEnabled;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, EasyModeConfig.normal);
      expect(captureEnabled, isFalse);
    });
  });
}
