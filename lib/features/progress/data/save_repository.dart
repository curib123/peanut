import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/game_save_data.dart';

abstract interface class SaveRepository {
  Future<GameSaveData> load();
  Future<void> save(GameSaveData data);
  Future<void> clear();
}

class SharedPreferencesSaveRepository implements SaveRepository {
  static const saveKey = 'puff_and_crunch_save';

  @override
  Future<GameSaveData> load() async {
    final preferences = await SharedPreferences.getInstance();
    final source = preferences.getString(saveKey);
    if (source == null) return const GameSaveData();
    try {
      final decoded = jsonDecode(source);
      if (decoded is! Map) return const GameSaveData();
      return GameSaveData.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on FormatException {
      return const GameSaveData();
    }
  }

  @override
  Future<void> save(GameSaveData data) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(saveKey, jsonEncode(data.toJson()));
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(saveKey);
  }
}
