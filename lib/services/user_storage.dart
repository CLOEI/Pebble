import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  static const _keyUnlockedPebbles = 'unlocked_pebbles';

  static const _defaultUnlockedPebbles = {0, 1, 2, 3, 4};

  static final _prefs = SharedPreferencesAsync();

  static final ValueNotifier<int> changes = ValueNotifier<int>(0);
  static void _notifyChanged() => changes.value++;

  // ── Onboarding ──────────────────────────────────────────────────────────

  static Future<void> saveCharacter({
    required String name,
    required int pebbleIndex,
    required int expressionIndex,
  }) async {
    await _prefs.setString(_keyName, name);
    await _prefs.setInt(_keyPebble, pebbleIndex);
    await _prefs.setInt(_keyExpression, expressionIndex);
    _notifyChanged();
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
    _notifyChanged();
  }

  static Future<void> saveSurvey(List<int> selections) async {
    await _prefs.setString(
      _keySurvey,
      selections.map((e) => e.toString()).join(','),
    );
    await _saveFtueDate();
    await _prefs.setBool(_keyOnboardingDone, true);
    _notifyChanged();
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
    if (days.contains(dateStr)) return;
    days.add(dateStr);
    await _prefs.setString(_keyActiveDays, days.join(','));
    _notifyChanged();
  }

  // ── Daily kcal + history ────────────────────────────────────────────────

  static String _kcalKey(DateTime d) => 'kcal_consumed_${_dateKey(d)}';
  static String _historyKey(DateTime d) => 'history_${_dateKey(d)}';

  static Future<int> getKcalConsumed(DateTime day) async {
    return await _prefs.getInt(_kcalKey(day)) ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getHistory(DateTime day) async {
    final raw = await _prefs.getString(_historyKey(day)) ?? '';
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> addConsumption({
    required String name,
    required int kcal,
    DateTime? when,
  }) async {
    final day = when ?? DateTime.now();
    final current = await getKcalConsumed(day);
    await _prefs.setInt(_kcalKey(day), current + kcal);

    final history = await getHistory(day);
    history.insert(0, {
      'name': name,
      'kcal': kcal,
      'ts': day.toIso8601String(),
    });
    await _prefs.setString(_historyKey(day), jsonEncode(history));
    _notifyChanged();
  }

  // ── Daily workout log + kcal burned ─────────────────────────────────────

  static String _burnedKey(DateTime d) => 'kcal_burned_${_dateKey(d)}';
  static String _workoutKey(DateTime d) => 'workout_log_${_dateKey(d)}';

  static Future<int> getKcalBurned(DateTime day) async {
    return await _prefs.getInt(_burnedKey(day)) ?? 0;
  }

  static Future<List<Map<String, dynamic>>> getWorkoutLog(DateTime day) async {
    final raw = await _prefs.getString(_workoutKey(day)) ?? '';
    if (raw.isEmpty) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> addWorkout({
    required String exerciseId,
    required String name,
    required int durationSec,
    required int kcal,
    int expGain = 0,
    DateTime? when,
  }) async {
    final day = when ?? DateTime.now();
    final current = await getKcalBurned(day);
    await _prefs.setInt(_burnedKey(day), current + kcal);

    final log = await getWorkoutLog(day);
    log.insert(0, {
      'exerciseId': exerciseId,
      'name': name,
      'durationSec': durationSec,
      'kcal': kcal,
      'exp': expGain,
      'ts': day.toIso8601String(),
    });
    await _prefs.setString(_workoutKey(day), jsonEncode(log));

    if (expGain > 0) {
      final currentExp = await getExp();
      await _prefs.setInt(_keyExp, currentExp + expGain);
    }

    final dayKey = _dateKey(day);
    final days = await getActiveDays();
    if (!days.contains(dayKey)) {
      days.add(dayKey);
      await _prefs.setString(_keyActiveDays, days.join(','));
    }

    _notifyChanged();
  }

  static Future<Map<String, dynamic>?> removeConsumptionAt(
    int index, {
    DateTime? when,
  }) async {
    final day = when ?? DateTime.now();
    final history = await getHistory(day);
    if (index < 0 || index >= history.length) return null;
    final removed = history.removeAt(index);
    final kcal = (removed['kcal'] as num).toInt();
    final current = await getKcalConsumed(day);
    await _prefs.setInt(_kcalKey(day), (current - kcal).clamp(0, 1 << 30));
    await _prefs.setString(_historyKey(day), jsonEncode(history));
    _notifyChanged();
    return removed;
  }

  // ── Unlocked pebbles ────────────────────────────────────────────────────

  static Future<Set<int>> getUnlockedPebbles() async {
    final raw = await _prefs.getString(_keyUnlockedPebbles);
    if (raw == null || raw.isEmpty) return {..._defaultUnlockedPebbles};
    return raw.split(',').map(int.parse).toSet();
  }

  // ── Daily celebration flag ──────────────────────────────────────────────

  static String _celebratedKey(DateTime d) => 'celebrated_${_dateKey(d)}';

  static Future<bool> wasCelebrated(DateTime day) async {
    return await _prefs.getBool(_celebratedKey(day)) ?? false;
  }

  static Future<void> markCelebrated(DateTime day) async {
    await _prefs.setBool(_celebratedKey(day), true);
  }

  static Future<void> unlockPebble(int index) async {
    final set = await getUnlockedPebbles();
    if (set.contains(index)) return;
    set.add(index);
    await _prefs.setString(_keyUnlockedPebbles, set.join(','));
    _notifyChanged();
  }

  // ── EXP ──────────────────────────────────────────────────────────────────

  static Future<int> getExp() async {
    return await _prefs.getInt(_keyExp) ?? 0;
  }

  static Future<void> addExp(int amount) async {
    if (amount <= 0) return;
    final current = await getExp();
    await _prefs.setInt(_keyExp, current + amount);
    _notifyChanged();
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
