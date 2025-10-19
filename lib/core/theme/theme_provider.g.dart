// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Theme notifier that persists theme selection

@ProviderFor(Theme)
const themeProvider = ThemeProvider._();

/// Theme notifier that persists theme selection
final class ThemeProvider extends $NotifierProvider<Theme, AppThemeType> {
  /// Theme notifier that persists theme selection
  const ThemeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeHash();

  @$internal
  @override
  Theme create() => Theme();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeType value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeType>(value),
    );
  }
}

String _$themeHash() => r'53daa3fc386c0cec8df11755321acd0b211003a4';

/// Theme notifier that persists theme selection

abstract class _$Theme extends $Notifier<AppThemeType> {
  AppThemeType build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AppThemeType, AppThemeType>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AppThemeType, AppThemeType>,
              AppThemeType,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Provider for current theme data

@ProviderFor(currentThemeData)
const currentThemeDataProvider = CurrentThemeDataProvider._();

/// Provider for current theme data

final class CurrentThemeDataProvider
    extends $FunctionalProvider<AppThemeData, AppThemeData, AppThemeData>
    with $Provider<AppThemeData> {
  /// Provider for current theme data
  const CurrentThemeDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentThemeDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentThemeDataHash();

  @$internal
  @override
  $ProviderElement<AppThemeData> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppThemeData create(Ref ref) {
    return currentThemeData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppThemeData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppThemeData>(value),
    );
  }
}

String _$currentThemeDataHash() => r'393ad9e47a06e55134332dac6a937715c12106cd';
