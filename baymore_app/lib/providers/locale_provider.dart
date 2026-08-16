import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Langue de l'app (FR/EN) — persistée sur l'appareil et appliquée
/// immédiatement partout via Provider dès que l'utilisateur la change dans
/// les Paramètres (aucun redémarrage de l'app nécessaire).
class LocaleProvider extends ChangeNotifier {
  static const _storageKey = 'baymore_locale';
  static const supportedLocales = [Locale('fr'), Locale('en')];

  Locale _locale = const Locale('fr');
  Locale get locale => _locale;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_storageKey);
    if (saved != null && supportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
    } else {
      // Pas de préférence enregistrée : on part de la langue de l'appareil
      // si elle est supportée, sinon français par défaut.
      final deviceCode = PlatformDispatcher.instance.locale.languageCode;
      _locale = supportedLocales.any((l) => l.languageCode == deviceCode) ? Locale(deviceCode) : const Locale('fr');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, locale.languageCode);
  }
}
