import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/theme/easy_mode_provider.dart';

void main() {
  group('EasyModeConfig', () {
    test('default values are normal mode', () {
      const cfg = EasyModeConfig();
      expect(cfg.textScaleFactor, 1.0);
      expect(cfg.minTouchTargetSize, 48.0);
      expect(cfg.showIconLabels, false);
      expect(cfg.highContrast, false);
      expect(cfg.simplifyForms, false);
      expect(cfg.spacingMultiplier, 1.0);
      expect(cfg.iconSizeMultiplier, 1.0);
      expect(cfg.borderRadiusMultiplier, 1.0);
    });

    test('normal preset matches default', () {
      const normal = EasyModeConfig.normal;
      expect(normal.textScaleFactor, 1.0);
      expect(normal.minTouchTargetSize, 48.0);
      expect(normal.showIconLabels, false);
    });

    test('easy preset enables larger sizes & accessibility flags', () {
      const easy = EasyModeConfig.easy;
      expect(easy.textScaleFactor, greaterThan(1.0));
      expect(easy.minTouchTargetSize, greaterThan(48.0));
      expect(easy.showIconLabels, true);
      expect(easy.highContrast, true);
      expect(easy.simplifyForms, true);
      expect(easy.spacingMultiplier, greaterThan(1.0));
      expect(easy.iconSizeMultiplier, greaterThan(1.0));
      expect(easy.borderRadiusMultiplier, greaterThan(1.0));
    });

    test('scaleTextStyle scales fontSize by textScaleFactor', () {
      const cfg = EasyModeConfig(textScaleFactor: 1.5);
      final scaled = cfg.scaleTextStyle(const TextStyle(fontSize: 10));
      expect(scaled.fontSize, 15);
    });

    test('scaleTextStyle uses default 14 when fontSize is null', () {
      const cfg = EasyModeConfig(textScaleFactor: 2.0);
      final scaled = cfg.scaleTextStyle(const TextStyle());
      expect(scaled.fontSize, 28);
    });

    test('scaleIconSize uses iconSizeMultiplier', () {
      const cfg = EasyModeConfig(iconSizeMultiplier: 2.0);
      expect(cfg.scaleIconSize(10), 20);
    });

    test('scaleSpacing uses spacingMultiplier', () {
      const cfg = EasyModeConfig(spacingMultiplier: 1.5);
      expect(cfg.scaleSpacing(8), 12);
    });

    test('scaleBorderRadius uses borderRadiusMultiplier', () {
      const cfg = EasyModeConfig(borderRadiusMultiplier: 1.25);
      expect(cfg.scaleBorderRadius(8), 10);
    });

    test('ensureMinTouchTarget bumps small values up', () {
      const cfg = EasyModeConfig(minTouchTargetSize: 48);
      expect(cfg.ensureMinTouchTarget(20), 48);
    });

    test('ensureMinTouchTarget keeps values >= min', () {
      const cfg = EasyModeConfig(minTouchTargetSize: 48);
      expect(cfg.ensureMinTouchTarget(60), 60);
    });
  });
}
