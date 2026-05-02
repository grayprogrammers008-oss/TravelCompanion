import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_crew/core/animations/animation_constants.dart';

void main() {
  group('AppAnimations durations', () {
    test('all duration values are positive', () {
      final ds = [
        AppAnimations.instant,
        AppAnimations.quick,
        AppAnimations.fast,
        AppAnimations.normal,
        AppAnimations.medium,
        AppAnimations.slow,
        AppAnimations.leisurely,
        AppAnimations.verySlow,
        AppAnimations.staggerTiny,
        AppAnimations.staggerSmall,
        AppAnimations.staggerMedium,
        AppAnimations.staggerLarge,
        AppAnimations.shimmerDuration,
        AppAnimations.shimmerPause,
        AppAnimations.heroDuration,
        AppAnimations.pageTransition,
      ];
      for (final d in ds) {
        expect(d.inMilliseconds, greaterThan(0));
      }
    });

    test('durations are ordered correctly (fast < slow)', () {
      expect(AppAnimations.instant < AppAnimations.quick, true);
      expect(AppAnimations.quick < AppAnimations.fast, true);
      expect(AppAnimations.fast < AppAnimations.normal, true);
      expect(AppAnimations.normal < AppAnimations.medium, true);
      expect(AppAnimations.medium < AppAnimations.slow, true);
      expect(AppAnimations.slow < AppAnimations.leisurely, true);
      expect(AppAnimations.leisurely < AppAnimations.verySlow, true);
    });

    test('stagger delays are monotonically increasing', () {
      expect(AppAnimations.staggerTiny < AppAnimations.staggerSmall, true);
      expect(AppAnimations.staggerSmall < AppAnimations.staggerMedium, true);
      expect(AppAnimations.staggerMedium < AppAnimations.staggerLarge, true);
    });
  });

  group('AppAnimations curves', () {
    test('all curves are non-null Curve instances', () {
      expect(AppAnimations.entrance, isA<Curve>());
      expect(AppAnimations.exit, isA<Curve>());
      expect(AppAnimations.bouncy, isA<Curve>());
      expect(AppAnimations.spring, isA<Curve>());
      expect(AppAnimations.emphasized, isA<Curve>());
      expect(AppAnimations.decelerate, isA<Curve>());
      expect(AppAnimations.anticipate, isA<Curve>());
      expect(AppAnimations.heroCurve, isA<Curve>());
      expect(AppAnimations.pageTransitionCurve, isA<Curve>());
    });

    test('curves transform 0 -> 0 and 1 -> 1 (well-formed)', () {
      final curves = [
        AppAnimations.entrance,
        AppAnimations.exit,
        AppAnimations.decelerate,
        AppAnimations.heroCurve,
      ];
      for (final c in curves) {
        expect(c.transform(0.0), closeTo(0.0, 0.001));
        expect(c.transform(1.0), closeTo(1.0, 0.001));
      }
    });
  });

  group('AppAnimations scale & offset values', () {
    test('scale values follow expected ordering', () {
      expect(AppAnimations.scaleMedium, lessThan(AppAnimations.scaleSmall));
      expect(AppAnimations.scaleSmall, lessThan(AppAnimations.scaleSubtle));
      expect(AppAnimations.scaleSubtle, lessThan(1.0));
      expect(AppAnimations.scaleLarge, greaterThan(1.0));
      expect(AppAnimations.scaleEmphasis, greaterThan(AppAnimations.scaleLarge));
    });

    test('slide distances are positive and ordered', () {
      expect(AppAnimations.slideSmall, greaterThan(0));
      expect(AppAnimations.slideMedium, greaterThan(AppAnimations.slideSmall));
      expect(AppAnimations.slideLarge, greaterThan(AppAnimations.slideMedium));
      expect(AppAnimations.slideFull, 1.0);
    });

    test('rotation values are positive radians', () {
      expect(AppAnimations.rotationSlight, greaterThan(0));
      expect(AppAnimations.rotationSmall, greaterThan(AppAnimations.rotationSlight));
      expect(AppAnimations.rotationMedium, greaterThan(AppAnimations.rotationSmall));
      expect(AppAnimations.rotationFull, greaterThan(AppAnimations.rotationMedium));
    });

    test('opacity values are within [0,1]', () {
      expect(AppAnimations.opacityInvisible, 0.0);
      expect(AppAnimations.opacitySubtle, inInclusiveRange(0.0, 1.0));
      expect(AppAnimations.opacitySemi, inInclusiveRange(0.0, 1.0));
      expect(AppAnimations.opacityMostly, inInclusiveRange(0.0, 1.0));
      expect(AppAnimations.opacityFull, 1.0);
    });
  });

  group('AnimationPresets / AnimationConfig', () {
    test('AnimationConfig holds duration and curve', () {
      const cfg = AnimationConfig(
        duration: Duration(milliseconds: 100),
        curve: Curves.linear,
      );
      expect(cfg.duration, const Duration(milliseconds: 100));
      expect(cfg.curve, Curves.linear);
    });

    test('all presets are valid AnimationConfig instances', () {
      final presets = [
        AnimationPresets.fadeIn,
        AnimationPresets.fadeOut,
        AnimationPresets.slideUp,
        AnimationPresets.slideDown,
        AnimationPresets.scaleUp,
        AnimationPresets.bounce,
        AnimationPresets.spring,
      ];
      for (final p in presets) {
        expect(p, isA<AnimationConfig>());
        expect(p.duration.inMilliseconds, greaterThan(0));
      }
    });

    test('fadeIn uses entrance, fadeOut uses exit curve', () {
      expect(AnimationPresets.fadeIn.curve, AppAnimations.entrance);
      expect(AnimationPresets.fadeOut.curve, AppAnimations.exit);
    });
  });
}
