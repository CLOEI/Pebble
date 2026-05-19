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
  static const _keyFtueDate = 'ftue_date';
  static const _keyActiveDays = 'active_days';
  static const _keyExp = 'exp';

  static final _prefs = SharedPreferencesAsync();

  // ── Onboarding ──────────────────────────────────────────────────────────

  static Future<void> saveCharacter({
    required String name,
    required int pebbleIndex,
    required int expressionIndex,
  }) async {
    await _prefs.setString(_keyName, name);
    await _prefs.setInt(_keyPebble, pebbleIndex);
    await _prefs.setInt(_keyExpression, expressionIndex);
  }

  static Future<void> saveProfile({
    required int gender,
    required int age,
    required int weight,
    required int height,
  }) async {
    await _prefs.setInt(_keyGender, gender);
    await _prefs.setInt(_keyAge, age);
    await _prefs.setInt(_keyWeight, weight);
    await _prefs.setInt(_keyHeight, height);
  }

  static Future<void> saveSurvey(List<int> selections) async {
    await _prefs.setString(
      _keySurvey,
      selections.map((e) => e.toString()).join(','),
    );
    await _saveFtueDate();
    await _prefs.setBool(_keyOnboardingDone, true);
  }

  static Future<void> _saveFtueDate() async {
    await _prefs.setString(_keyFtueDate, _dateKey(DateTime.now()));
  }

  static Future<bool> isOnboardingComplete() async {
    return await _prefs.getBool(_keyOnboardingDone) ?? false;
  }

  // ── Streak ───────────────────────────────────────────────────────────────

  static Future<String?> getFtueDate() async {
    return _prefs.getString(_keyFtueDate);
  }

  static Future<Set<String>> getActiveDays() async {
    final raw = await _prefs.getString(_keyActiveDays) ?? '';
    if (raw.isEmpty) return {};
    return raw.split(',').toSet();
  }

  static Future<void> markDayActive(String dateStr) async {
    final days = await getActiveDays();
    days.add(dateStr);
    await _prefs.setString(_keyActiveDays, days.join(','));
  }

  // ── EXP ──────────────────────────────────────────────────────────────────

  static Future<int> getExp() async {
    return await _prefs.getInt(_keyExp) ?? 0;
  }

  static Future<void> addExp(int amount) async {
    final current = await getExp();
    await _prefs.setInt(_keyExp, current + amount);
  }

  // ── Full load ────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> load() async {
    final surveyRaw = await _prefs.getString(_keySurvey) ?? '';
    return {
      'name': await _prefs.getString(_keyName) ?? '',
      'pebbleIndex': await _prefs.getInt(_keyPebble) ?? 0,
      'expressionIndex': await _prefs.getInt(_keyExpression) ?? 0,
      'gender': await _prefs.getInt(_keyGender) ?? 1,
      'age': await _prefs.getInt(_keyAge) ?? 24,
      'weight': await _prefs.getInt(_keyWeight) ?? 70,
      'height': await _prefs.getInt(_keyHeight) ?? 170,
      'surveySelections': surveyRaw.isEmpty
          ? <int>[]
          : surveyRaw.split(',').map(int.parse).toList(),
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
