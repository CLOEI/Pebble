import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_storage.dart';
import '../customize_page.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userData;
  Set<String> _activeDays = {};
  DateTime? _ftueDate;
  int _exp = 0;
  int _currentWeekPage = 0;
  bool _todayCompleted = false;
  late final PageController _weekController;

  static const _expPerLevel = 500;
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int get _level => (_exp ~/ _expPerLevel) + 1;
  int get _expInLevel => _exp % _expPerLevel;
  int get _daysActive => _activeDays.length;

  int get _currentStreak {
    int streak = 0;
    DateTime d = DateTime.now();
    while (_activeDays.contains(_dateKey(d))) {
      streak++;
      d = d.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get _longestStreak {
    if (_activeDays.isEmpty) return 0;
    final sorted = _activeDays.toList()..sort();
    int longest = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
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

  Future<void> _openCustomize() async {
    if (_userData == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CustomizePage(
          initialPebble: _userData!['pebbleIndex'] as int? ?? 0,
          initialExpression: _userData!['expressionIndex'] as int? ?? 0,
          name: _userData!['name'] as String? ?? '',
        ),
      ),
    );
    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _loadData() async {
    final userData = await UserStorage.load();
    final activeDays = await UserStorage.getActiveDays();
    final ftueDateStr = await UserStorage.getFtueDate();
    final exp = await UserStorage.getExp();
    final todayCompleted = await UserStorage.wasCelebrated(DateTime.now());

    final ftueDate =
        ftueDateStr != null ? DateTime.parse(ftueDateStr) : DateTime.now();
    final weekCount = _weekCount(ftueDate);

    setState(() {
      _userData = userData;
      _activeDays = activeDays;
      _ftueDate = ftueDate;
      _exp = exp;
      _currentWeekPage = weekCount - 1;
      _todayCompleted = todayCompleted;
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
    final name = _userData!['name'] as String? ?? 'Rocky';
    final age = _userData!['age'] as int? ?? 0;
    final weight = _userData!['weight'] as int? ?? 0;

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
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
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
                        _buildDots(weekCount),
                      ],
                      const SizedBox(height: 24),
                      // Pebble + info card
                      _buildProfileCard(
                          pebble, expression, name, age, weight),
                      const SizedBox(height: 16),
                      // Stat cards row
                      Row(
                        children: [
                          Expanded(child: _buildStreakCard()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildDaysActiveCard()),
                        ],
                      ),
                    ],
                  ),
                ),
                // Settings icon — top right overlay
                Positioned(
                  top: 16,
                  right: 16,
                  child: GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Profile card ──────────────────────────────────────────────────────────

  Widget _buildProfileCard(
      int pebble, int expression, String name, int age, int weight) {
    final progress = (_expInLevel / _expPerLevel).clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        // White card
        Container(
          margin: const EdgeInsets.only(top: 40),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Top area: icons in corners, center reserved for character body
              SizedBox(
                height: 155,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: _openCustomize,
                      behavior: HitTestBehavior.opaque,
                      child: const Icon(Icons.checkroom_rounded,
                          color: Colors.black54, size: 26),
                    ),
                  ),
                ),
              ),
              // Age | Name | Weight
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Age
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$age',
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            'age',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Name (centered, largest)
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Text(
                          name.isEmpty ? 'Rocky' : name,
                          style: GoogleFonts.jersey20(
                            fontSize: 40,
                            color: Colors.black,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                    // Weight
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$weight',
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  'kg',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.black38,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'weight',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: Colors.black38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Level + EXP bar section
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF5BA3D9),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Level ${_level.toString().padLeft(2, '0')}',
                      style: GoogleFonts.jersey20(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(builder: (context, constraints) {
                      final totalWidth = constraints.maxWidth;
                      final filledWidth = totalWidth * progress;
                      return SizedBox(
                        height: 32,
                        child: Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.3),
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
                  ],
                ),
              ),
            ],
          ),
        ),
        // Pebble — overflows above card
        Positioned(
          top: 0,
          child: GestureDetector(
            onTap: _openCustomize,
            child: SizedBox(
              width: 180,
              height: 190,
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
          ),
        ),
      ],
    );
  }

  // ── Stat cards ────────────────────────────────────────────────────────────

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streak',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_longestStreak days',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5A623),
                      ),
                    ),
                    Text(
                      'Longest',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
              Container(
                  width: 1, height: 32, color: Colors.black12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_currentStreak days',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFF5A623),
                      ),
                    ),
                    Text(
                      'Current',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysActiveCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Days Active',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_bottom_rounded,
                  color: Color(0xFFF5A623), size: 28),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$_daysActive',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFF5A623),
                    ),
                  ),
                  Text(
                    'days',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
        ],
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
        final isActive =
            _activeDays.contains(key) || (isToday && _todayCompleted);

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
    final showPebble =
        !isFuture && !isBeforeFtue && (!isToday || isActive);

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
