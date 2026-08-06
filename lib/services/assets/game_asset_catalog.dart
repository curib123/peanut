import 'package:flutter/services.dart';

abstract final class GameAssetCatalog {
  static const homeBackground =
      'assets/images/backgrounds/peanut_kisses_island.png';
  static const mascot = 'assets/svg/characters/peanut_baker.svg';

  static const svgDirectories = <String>[
    'pieces',
    'specials',
    'blockers',
    'boosters',
    'ui',
    'goals',
    'backgrounds',
    'characters',
  ];

  static Future<String> loadSvg(String path) async {
    try {
      return await rootBundle.loadString(path);
    } catch (_) {
      return fallbackSvg;
    }
  }

  static const fallbackSvg =
      '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect x="4" y="4" width="56" height="56" rx="18" fill="#F7E2A3"/><path d="M20 36c8-20 16 20 24 0" fill="none" stroke="#784421" stroke-width="6" stroke-linecap="round"/></svg>''';
}
