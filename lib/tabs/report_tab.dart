import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/user_storage.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  Map<String, dynamic>? _userData;
  Set<String> _activeDays = {};
  DateTime? _ftueDate;
  int _currentWeekPage = 0;
  late final PageController _weekController;

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  List<({DateTime date, int consumed, int burned})> _dailyKcal = [];
  bool _todayCompleted = false;

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

    final ftueDate =
        ftueDateStr != null ? DateTime.parse(ftueDateStr) : DateTime.now();
    final weekCount = _weekCount(ftueDate);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<({DateTime date, int consumed, int burned})> daily = [];
    for (int i = 6; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      daily.add((
        date: d,
        consumed: await UserStorage.getKcalConsumed(d),
        burned: await UserStorage.getKcalBurned(d),
      ));
    }
    final todayCompleted = await UserStorage.wasCelebrated(today);

    setState(() {
      _userData = userData;
      _activeDays = activeDays;
      _ftueDate = ftueDate;
      _currentWeekPage = weekCount - 1;
      _dailyKcal = daily;
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
    final startingWeight = _userData!['weight'] as int? ?? 0;
    final currentWeight = startingWeight;
    final lost = 0;
    final lostPct = '0.00';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Sky.png', fit: BoxFit.cover),
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset('assets/Hill.png',
                fit: BoxFit.fitWidth, width: double.infinity),
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
                      itemBuilder: (_, page) =>
                          _buildWeek(_mondayForPage(page)),
                    ),
                  ),
                  if (weekCount > 1) ...[
                    const SizedBox(height: 8),
                    Center(child: _buildDots(weekCount)),
                  ],
                  const SizedBox(height: 20),
                  // Weight Progress header
                  Center(
                    child: Text(
                      'Weight Progress',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Pebble + stats row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 140,
                        height: 160,
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildWeightStat(
                                  '$startingWeight', 'kg', 'Starting',
                                  Colors.white),
                              const SizedBox(height: 10),
                              _buildWeightStat(
                                  lost.toString().padLeft(2, '0'), 'kg',
                                  'Lost', Colors.white),
                              const SizedBox(height: 10),
                              _buildWeightStat(
                                  '$currentWeight', 'kg', 'Current',
                                  const Color(0xFFF5A623)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      "You've lost $lostPct% of your starting weight!",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Weight Trend placeholder
                  _buildCard(
                    title: 'Weight Trend',
                    icon: null,
                    child: SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Weight log not started.\nTrend appears after multiple weigh-ins.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                              fontSize: 12, color: Colors.black45),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Weekly Calorie Summary chart
                  _buildCard(
                    title: 'Weekly Calorie Summary',
                    icon: Icons.calendar_today_rounded,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 180,
                          child: _buildCalorieChart(),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildLegend(
                                const Color(0xFF5BA3D9), 'Consumed'),
                            const SizedBox(width: 20),
                            _buildLegend(
                                const Color(0xFFF5A623), 'Burned'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Daily Details
                  Center(
                    child: Text(
                      'Daily Details',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildDailyRows(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Weight stat row ───────────────────────────────────────────────────────

  Widget _buildWeightStat(
      String value, String unit, String label, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.jersey20(
            fontSize: 40,
            color: color,
            height: 1.0,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 4, left: 3),
          child: Text(
            unit,
            style: GoogleFonts.inter(
                fontSize: 13, color: color.withValues(alpha: 0.8)),
          ),
        ),
        const Spacer(),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      ],
    );
  }

  // ── Charts ────────────────────────────────────────────────────────────────

  Widget _buildCalorieChart() {
    final consumedSpots = <FlSpot>[];
    final burnedSpots = <FlSpot>[];
    final weekDays = <String>[];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    for (int i = 0; i < _dailyKcal.length; i++) {
      final d = _dailyKcal[i];
      consumedSpots.add(FlSpot(i.toDouble(), d.consumed.toDouble()));
      burnedSpots.add(FlSpot(i.toDouble(), d.burned.toDouble()));
      weekDays.add('${months[d.date.month - 1]} ${d.date.day}');
    }
    final maxValue = [
      ...consumedSpots.map((s) => s.y),
      ...burnedSpots.map((s) => s.y),
      1000.0,
    ].reduce((a, b) => a > b ? a : b);
    final interval = (maxValue / 4).ceilToDouble().clamp(200.0, 2000.0);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (_) => FlLine(
            color: Colors.black.withValues(alpha: 0.06),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toInt().toString(),
                style: GoogleFonts.inter(
                    fontSize: 9, color: Colors.black38),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= weekDays.length) {
                  return const SizedBox();
                }
                return Text(
                  weekDays[i],
                  style: GoogleFonts.inter(
                      fontSize: 8, color: Colors.black38),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: consumedSpots,
            isCurved: true,
            color: const Color(0xFF5BA3D9),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFF5BA3D9),
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
          LineChartBarData(
            spots: burnedSpots,
            isCurved: true,
            color: const Color(0xFFF5A623),
            barWidth: 2.5,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: const Color(0xFFF5A623),
              ),
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
      ],
    );
  }

  // ── Daily detail row ──────────────────────────────────────────────────────

  List<Widget> _buildDailyRows() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final recent = _dailyKcal.reversed
        .where((d) => d.consumed > 0 || d.burned > 0)
        .take(3)
        .toList();
    if (recent.isEmpty) {
      return [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'No activity logged yet',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      ];
    }
    return recent.map((d) {
      final net = d.consumed - d.burned;
      final netStr = (net >= 0 ? '+' : '') + net.toString();
      final dateLabel = '${months[d.date.month - 1]} ${d.date.day}';
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
                  Text(
                    dateLabel,
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Net: $netStr kcal',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: net > 0
                          ? const Color(0xFFD9534F)
                          : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.arrow_upward_rounded,
                    color: Color(0xFFF5A623), size: 16),
                Text(
                  '${d.consumed}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF5A623),
                  ),
                ),
                Text(' kcal',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.black45)),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_downward_rounded,
                    color: Colors.black54, size: 16),
                Text(
                  '${d.burned}',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(' kcal',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.black45)),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  // ── Shared card wrapper ───────────────────────────────────────────────────

  Widget _buildCard(
      {required String title, IconData? icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: Colors.black54),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
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
          Text(label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              )),
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
                        child: Text('$date',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color:
                                  isActive ? Colors.white : Colors.white70,
                            )),
                      ),
                    ],
                  )
                : Center(
                    child: Text('$date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w400,
                          color: isFuture || isBeforeFtue
                              ? Colors.white38
                              : Colors.white,
                        )),
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
