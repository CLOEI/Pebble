import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_storage.dart';
import '../services/workout_repository.dart';
import '../workout_detail_page.dart';

class TodoTab extends StatefulWidget {
  const TodoTab({super.key});

  @override
  State<TodoTab> createState() => _TodoTabState();
}

class _TodoTabState extends State<TodoTab> {
  Map<String, dynamic>? _userData;
  Set<String> _activeDays = {};
  DateTime? _ftueDate;
  int _exp = 0;
  int _currentWeekPage = 0;
  late final PageController _weekController;

  int _kcalBurned = 0;
  int _burnGoal = 200;
  List<Map<String, dynamic>> _workoutLog = [];
  WeekPlan? _weekPlan;
  List<Exercise> _todayExercises = [];

  static const _expPerLevel = 500;
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int get _level => (_exp ~/ _expPerLevel) + 1;
  int get _expInLevel => _exp % _expPerLevel;

  int _computeBurnGoal(
    List<Exercise> exercises,
    Map<String, dynamic> userData,
  ) {
    final weight = userData['weight'] as int? ?? 70;
    if (exercises.isEmpty) return 200;
    final total = exercises.fold<int>(
      0,
      (sum, e) => sum + e.kcalForWeight(weight),
    );
    return total.clamp(100, 5000);
  }

  bool _isCompleted(String exerciseId) =>
      _workoutLog.any((w) => w['exerciseId'] == exerciseId);

  Future<void> _openExercise(Exercise ex) async {
    final weight = (_userData?['weight'] as int?) ?? 70;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            WorkoutDetailPage(exercise: ex, weightKg: weight),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  @override
  void initState() {
    super.initState();
    _weekController = PageController();
    _loadData();
    UserStorage.changes.addListener(_onStorageChanged);
  }

  void _onStorageChanged() => _loadData();

  @override
  void dispose() {
    UserStorage.changes.removeListener(_onStorageChanged);
    _weekController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userData = await UserStorage.load();
    final activeDays = await UserStorage.getActiveDays();
    final ftueDateStr = await UserStorage.getFtueDate();
    final exp = await UserStorage.getExp();
    final exercises = await WorkoutRepository.loadExercises();
    final plans = await WorkoutRepository.loadPlan();
    final today = DateTime.now();
    final kcalBurned = await UserStorage.getKcalBurned(today);
    final log = await UserStorage.getWorkoutLog(today);

    final ftueDate =
        ftueDateStr != null ? DateTime.parse(ftueDateStr) : DateTime.now();
    final weekCount = _weekCount(ftueDate);

    final workoutWeek = WorkoutRepository.currentWeek(ftueDate);
    final plan = WorkoutRepository.planForWeek(plans, workoutWeek);
    final todayExercises =
        WorkoutRepository.exercisesByIds(exercises, plan.exerciseIds);

    setState(() {
      _userData = userData;
      _activeDays = activeDays;
      _ftueDate = ftueDate;
      _exp = exp;
      _currentWeekPage = weekCount - 1;
      _kcalBurned = kcalBurned;
      _workoutLog = log;
      _weekPlan = plan;
      _todayExercises = todayExercises;
      _burnGoal = _computeBurnGoal(todayExercises, userData);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_weekController.hasClients && weekCount > 1) {
        _weekController.jumpToPage(weekCount - 1);
      }
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime _mondayOf(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  int _weekCount(DateTime ftueDate) {
    final ftueMonday = _mondayOf(ftueDate);
    final currentMonday = _mondayOf(DateTime.now());
    return (currentMonday.difference(ftueMonday).inDays ~/ 7) + 1;
  }

  DateTime _mondayForPage(int page) {
    if (_ftueDate == null) return _mondayOf(DateTime.now());
    return _mondayOf(_ftueDate!).add(Duration(days: page * 7));
  }

  String _formatDate(DateTime d) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]} ${d.year}';
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF5BA3D9),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final weekCount = _weekCount(_ftueDate!);
    final pebble = _userData!['pebbleIndex'] as int? ?? 0;
    final expression = _userData!['expressionIndex'] as int? ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Sky.png', fit: BoxFit.cover),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/Hill.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Week calendar
                  SizedBox(
                    height: 100,
                    child: PageView.builder(
                      controller: _weekController,
                      itemCount: weekCount,
                      onPageChanged: (p) =>
                          setState(() => _currentWeekPage = p),
                      itemBuilder: (context, page) =>
                          _buildWeek(_mondayForPage(page)),
                    ),
                  ),
                  if (weekCount > 1) ...[
                    const SizedBox(height: 8),
                    Center(child: _buildDots(weekCount)),
                  ],
                  const SizedBox(height: 24),
                  // Character + kcal burned
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'lvl $_level',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            SizedBox(
                              width: 110,
                              height: 120,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Image.asset(
                                    'assets/Pebbles with Leg/${pebble + 1}.png',
                                    fit: BoxFit.contain,
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: 0.6,
                                    heightFactor: 0.6,
                                    child: Image.asset(
                                      'assets/Expression/${expression + 1}.png',
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(DateTime.now()),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  '$_kcalBurned',
                                  style: GoogleFonts.jersey20(
                                    fontSize: 72,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '/ $_burnGoal',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                    Text(
                                      'kcal burned',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // Completed tasks
                  _buildCompletedSection(),
                  const SizedBox(height: 28),
                  // Challenge section
                  _buildChallengeSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Completed tasks ───────────────────────────────────────────────────────

  Widget _buildCompletedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'Completed task',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 18),
          ],
        ),
        const SizedBox(height: 12),
        if (_workoutLog.isEmpty)
          Text(
            'No workouts logged today',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _workoutLog.map((task) {
                final name = task['name'] as String;
                final kcal = (task['kcal'] as num).toInt();
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          decoration: TextDecoration.lineThrough,
                          decorationColor:
                              Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+$kcal',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFFF5A623),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ── Challenge section ─────────────────────────────────────────────────────

  Widget _buildChallengeSection() {
    final progress = (_expInLevel / _expPerLevel).clamp(0.0, 1.0);

    return Column(
      children: [
        // Title
        Text(
          'Challenge',
          style: GoogleFonts.jersey20(
            fontSize: 36,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 2),
        // Level badge
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white, width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Level $_level',
            style: GoogleFonts.jersey20(
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // EXP bar
        LayoutBuilder(builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final filledWidth = totalWidth * progress;
          return SizedBox(
            height: 32,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF5BA3D9),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                Container(
                  width: filledWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5A623),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '$_expInLevel Exp',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_expPerLevel Exp',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.card_giftcard_rounded,
                            color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 12),
        if (_weekPlan != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week ${_weekPlan!.week} · ${_weekPlan!.level}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_weekPlan!.focus} · ${_weekPlan!.dailyTargetMin} min/day',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
        // Exercise cards
        ..._todayExercises.map((e) => _buildExerciseCard(e)),
      ],
    );
  }

  Widget _buildExerciseCard(Exercise e) {
    final weight = (_userData?['weight'] as int?) ?? 70;
    final kcal = e.kcalForWeight(weight);
    final done = _isCompleted(e.id);
    final (sensorLabel, sensorIcon) = switch (e.sensor) {
      SensorType.step => ('Step', Icons.directions_walk_rounded),
      SensorType.jump => ('Jump', Icons.fitness_center_rounded),
      SensorType.timer => ('Timer', Icons.timer_rounded),
    };
    final categoryColor = e.category == 'high'
        ? const Color(0xFFD9534F)
        : const Color(0xFF2E7D32);

    return GestureDetector(
      onTap: done ? null : () => _openExercise(e),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: done ? Colors.white.withValues(alpha: 0.7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (done)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(Icons.check_circle_rounded,
                              size: 18, color: Color(0xFF2E7D32)),
                        ),
                      Flexible(
                        child: Text(
                          e.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: categoryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          e.category == 'high' ? 'High' : 'Low',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: categoryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(sensorIcon, size: 12, color: Colors.black45),
                      const SizedBox(width: 3),
                      Text(
                        sensorLabel,
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.black45,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e.detail,
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5A623),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    '$kcal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Week calendar ─────────────────────────────────────────────────────────

  Widget _buildWeek(DateTime monday) {
    final today = DateTime.now();
    final todayKey = _dateKey(today);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (i) {
        final day = monday.add(Duration(days: i));
        final key = _dateKey(day);
        final isToday = key == todayKey;
        final isFuture = day.isAfter(today);
        final isBeforeFtue =
            _ftueDate != null && day.isBefore(_ftueDate!) && !isToday;
        final isActive = _activeDays.contains(key);

        return _buildDayCell(
          label: _dayLabels[i],
          date: day.day,
          isToday: isToday,
          isFuture: isFuture,
          isBeforeFtue: isBeforeFtue,
          isActive: isActive,
        );
      }),
    );
  }

  Widget _buildDayCell({
    required String label,
    required int date,
    required bool isToday,
    required bool isFuture,
    required bool isBeforeFtue,
    required bool isActive,
  }) {
    final showPebble = !isToday && !isFuture && !isBeforeFtue;

    return SizedBox(
      width: 44,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 44,
            height: 76,
            decoration: isToday
                ? BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1.5),
                  )
                : null,
            child: showPebble
                ? Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        bottom: 0,
                        child: Image.asset(
                          isActive
                              ? 'assets/streak-continue.png'
                              : 'assets/streak-lose.png',
                          width: 44,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '$date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isActive ? Colors.white : Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Text(
                      '$date',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.bold : FontWeight.w400,
                        color: isFuture || isBeforeFtue
                            ? Colors.white38
                            : Colors.white,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDots(int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == _currentWeekPage;
        return Container(
          width: active ? 16 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(50),
          ),
        );
      }),
    );
  }
}
