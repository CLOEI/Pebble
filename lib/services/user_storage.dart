import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const _keyName = 'name';
  static const _keyPebble = 'pebble_index';
  static const _keyExpression = 'expression_index';
  static const _keyGender = 'gender';
  static const _keyAge = 'age';
  static const _keyWeight = 'weight';
  static const _keyHeight = 'height';
  static const _keySurvey = 'survey_selections';
  static const _keyOnboardingDone = 'onboarding_complete';

  static Future<void> saveCharacter({
    required String name,
    required int pebbleIndex,
    required int expressionIndex,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setInt(_keyPebble, pebbleIndex);
    await prefs.setInt(_keyExpression, expressionIndex);
  }

  static Future<void> saveProfile({
    required int gender,
    required int age,
    required int weight,
    required int height,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyGender, gender);
    await prefs.setInt(_keyAge, age);
    await prefs.setInt(_keyWeight, weight);
    await prefs.setInt(_keyHeight, height);
  }

  static Future<void> saveSurvey(List<int> selections) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keySurvey,
      selections.map((e) => e.toString()).join(','),
    );
    await prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<bool> isOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final surveyRaw = prefs.getString(_keySurvey) ?? '';
    return {
      'name': prefs.getString(_keyName) ?? '',
      'pebbleIndex': prefs.getInt(_keyPebble) ?? 0,
      'expressionIndex': prefs.getInt(_keyExpression) ?? 0,
      'gender': prefs.getInt(_keyGender) ?? 1,
      'age': prefs.getInt(_keyAge) ?? 24,
      'weight': prefs.getInt(_keyWeight) ?? 70,
      'height': prefs.getInt(_keyHeight) ?? 170,
      'surveySelections': surveyRaw.isEmpty
          ? <int>[]
          : surveyRaw.split(',').map(int.parse).toList(),
    };
  }
}
