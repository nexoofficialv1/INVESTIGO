import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../core/app_language.dart';

/// Bengali <-> English on-device translation used by official document
/// previews. Language models are downloaded once; subsequent translations are
/// processed on the device.
class BilingualTranslationService {
  BilingualTranslationService._();

  static final BilingualTranslationService instance =
      BilingualTranslationService._();

  final OnDeviceTranslatorModelManager _modelManager =
      OnDeviceTranslatorModelManager();

  bool _modelsReady = false;
  Future<void>? _modelPreparation;
  DateTime? _modelRetryAfter;

  bool get modelsReady => _modelsReady;

  bool get _platformSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool containsBengali(String value) =>
      RegExp(r'[\u0980-\u09FF]').hasMatch(value);

  bool _sourceLanguageIsBengali(String value) {
    final bengaliCount =
        RegExp(r'[\u0980-\u09FF]').allMatches(value).length;
    final latinCount = RegExp(r'[A-Za-z]').allMatches(value).length;
    if (bengaliCount == 0) return false;
    if (latinCount == 0) return true;
    return bengaliCount >= latinCount;
  }

  Future<void> prepareModels() async {
    if (_modelsReady) return;
    if (!_platformSupported) {
      throw StateError(
        'On-device Bengali/English translation is supported on Android and iOS only.',
      );
    }

    final retryAfter = _modelRetryAfter;
    if (retryAfter != null && DateTime.now().isBefore(retryAfter)) {
      throw StateError(
        'Translation model is temporarily unavailable. Preview/export will use the original text.',
      );
    }

    final active = _modelPreparation;
    if (active != null) {
      await active;
      return;
    }

    final preparation = _prepareModelsOnce();
    _modelPreparation = preparation;
    try {
      await preparation;
    } finally {
      _modelPreparation = null;
    }
  }

  Future<void> _prepareModelsOnce() async {
    try {
      final bengaliCode = TranslateLanguage.bengali.bcpCode;
      final englishCode = TranslateLanguage.english.bcpCode;
      final bnReady = await _ensureModel(bengaliCode);
      final enReady = await _ensureModel(englishCode);
      if (!bnReady || !enReady) {
        throw StateError(
          'Bengali/English translation model download failed. Connect to the internet once and try again.',
        );
      }
      _modelsReady = true;
      _modelRetryAfter = null;
    } catch (_) {
      _modelRetryAfter = DateTime.now().add(const Duration(minutes: 1));
      rethrow;
    }
  }

  Future<bool> _ensureModel(String languageCode) async {
    if (await _modelManager.isModelDownloaded(languageCode)) return true;
    return _modelManager
        .downloadModel(languageCode)
        .timeout(const Duration(seconds: 20));
  }

  bool needsTranslation(
    String source, {
    required AppLanguage targetLanguage,
  }) {
    final value = source.trim();
    if (value.isEmpty) return false;
    final sourceIsBengali = _sourceLanguageIsBengali(value);
    final targetIsBengali = targetLanguage == AppLanguage.bengali;
    return sourceIsBengali != targetIsBengali;
  }

  Future<void> prepareForTexts(
    Iterable<String> values, {
    AppLanguage? targetLanguage,
  }) async {
    final target = targetLanguage ?? AppLanguageController.instance.current;
    if (values.any(
      (value) => needsTranslation(value, targetLanguage: target),
    )) {
      await prepareModels();
    }
  }

  Future<String> translateToCurrentLanguage(String source) async {
    return translate(
      source,
      targetLanguage: AppLanguageController.instance.current,
    );
  }

  Future<String> translate(
    String source, {
    required AppLanguage targetLanguage,
  }) async {
    final value = source.trim();
    if (value.isEmpty) return source;

    final sourceIsBengali = _sourceLanguageIsBengali(value);
    final targetIsBengali = targetLanguage == AppLanguage.bengali;
    if (sourceIsBengali == targetIsBengali) return source;

    try {
      await prepareModels();
      final translator = OnDeviceTranslator(
        sourceLanguage: sourceIsBengali
            ? TranslateLanguage.bengali
            : TranslateLanguage.english,
        targetLanguage: targetIsBengali
            ? TranslateLanguage.bengali
            : TranslateLanguage.english,
      );
      try {
        return await translator.translateText(source);
      } finally {
        await translator.close();
      }
    } catch (_) {
      // PDF/DOC generation must remain available even if a model is not ready.
      // Preserve the original officer-entered text instead of aborting.
      return source;
    }
  }

  Future<List<String>> translateListToCurrentLanguage(
    Iterable<String> values,
  ) async {
    final translated = <String>[];
    for (final value in values) {
      translated.add(await translateToCurrentLanguage(value));
    }
    return translated;
  }
}
