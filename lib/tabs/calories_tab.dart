import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';
import '../services/user_storage.dart';
import '../services/snack_repository.dart';

class _DragScrollBehavior extends MaterialScrollBehavior {
  const _DragScrollBehavior();
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class CaloriesTab extends StatefulWidget {
  const CaloriesTab({super.key});

  @override
  State<CaloriesTab> createState() => _CaloriesTabState();
}

class _CaloriesTabState extends State<CaloriesTab> {
  Map<String, dynamic>? _userData;
  Set<String> _activeDays = {};
  DateTime? _ftueDate;
  int _exp = 0;
  int _currentWeekPage = 0;
  late final PageController _weekController;
  late final TextEditingController _searchController;

  int _kcalConsumed = 0;
  int _kcalBurned = 0;
  List<Map<String, dynamic>> _history = [];

  List<Snack> _allSnacks = [];
  String? _selectedCategory;
  int? _maxKcal = 400;

  static const _kcalLimit = 3000;
  static const _expPerLevel = 500;
  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  int get _kcalLeft => _kcalLimit - _kcalConsumed;
  int get _level => (_exp ~/ _expPerLevel) + 1;

  @override
  void initState() {
    super.initState();
    _weekController = PageController();
    _searchController = TextEditingController(text: '400');
    _loadData();
    UserStorage.changes.addListener(_onStorageChanged);
  }

  void _onStorageChanged() => _loadData();

  @override
  void dispose() {
    UserStorage.changes.removeListener(_onStorageChanged);
    _weekController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userData = await UserStorage.load();
    final activeDays = await UserStorage.getActiveDays();
    final ftueDateStr = await UserStorage.getFtueDate();
    final exp = await UserStorage.getExp();
    final snacks = await SnackRepository.loadAll();
    final today = DateTime.now();
    final kcalConsumed = await UserStorage.getKcalConsumed(today);
    final history = await UserStorage.getHistory(today);
    final kcalBurned = await UserStorage.getKcalBurned(today);

    final ftueDate =
        ftueDateStr != null ? DateTime.parse(ftueDateStr) : DateTime.now();
    final weekCount = _weekCount(ftueDate);

    setState(() {
      _userData = userData;
      _activeDays = activeDays;
      _ftueDate = ftueDate;
      _exp = exp;
      _currentWeekPage = weekCount - 1;
      _allSnacks = snacks;
      _kcalConsumed = kcalConsumed;
      _kcalBurned = kcalBurned;
      _history = history;
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
      return const ColoredBox(
        color: Color(0xFF5BA3D9),
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final weekCount = _weekCount(_ftueDate!);
    final pebble = _userData!['pebbleIndex'] as int? ?? 0;
    final expression = _userData!['expressionIndex'] as int? ?? 0;

    return Stack(
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
                  // Character + kcal left
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pebble with level badge
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
                      // Date + kcal info
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
                                  '$_kcalLeft',
                                  style: GoogleFonts.jersey20(
                                    fontSize: 72,
                                    color: _kcalLeft < 0
                                        ? const Color(0xFFFF6B6B)
                                        : Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '/ $_kcalLimit',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color:
                                            Colors.white.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    Text(
                                      'kcal left',
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
                            if (_kcalBurned > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_fire_department_rounded,
                                    color: Color(0xFFF5A623),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$_kcalBurned kcal burned today',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white
                                          .withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  // History
                  _buildHistorySection(),
                  const SizedBox(height: 24),
                  // Suggestions
                  _buildSuggestionSection(),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── History ───────────────────────────────────────────────────────────────

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'History',
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
        if (_history.isEmpty)
          Text(
            'No meals logged yet',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          )
        else
          ScrollConfiguration(
            behavior: const _DragScrollBehavior(),
            child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _history.asMap().entries.map((e) {
                final i = e.key;
                final item = e.value;
                final name = item['name'] as String;
                final kcal = (item['kcal'] as num).toInt();
                return _HistoryPill(
                  name: name,
                  kcal: kcal,
                  onDelete: () => _deleteHistoryAt(i, name, kcal),
                );
              }).toList(),
            ),
          ),
          ),
      ],
    );
  }

  // ── Suggestions ───────────────────────────────────────────────────────────

  Widget _buildSuggestionSection() {
    final filtered = SnackRepository.filter(
      _allSnacks,
      category: _selectedCategory,
      maxKcal: _maxKcal,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.person_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'Suggestion',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // Kcal filter
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search, size: 16, color: Colors.black45),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 40,
                    child: TextField(
                      controller: _searchController,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() {
                        _maxKcal = int.tryParse(v);
                      }),
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.black87),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Text(
                    'kcal',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.black45),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Category chips
        SizedBox(
          height: 36,
          child: ScrollConfiguration(
            behavior: const _DragScrollBehavior(),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildCategoryChip(null, 'All'),
                for (final cat in SnackRepository.categories)
                  _buildCategoryChip(cat, cat),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No snacks match the filter',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.85,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, i) => _buildFoodCard(filtered[i]),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(String? value, String label) {
    final selected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFFF5A623)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logSnack(Snack snack) async {
    HapticFeedback.mediumImpact();
    await UserStorage.addConsumption(name: snack.name, kcal: snack.kcal);
    final today = DateTime.now();
    final kcal = await UserStorage.getKcalConsumed(today);
    final history = await UserStorage.getHistory(today);
    if (!mounted) return;
    setState(() {
      _kcalConsumed = kcal;
      _history = history;
    });
    final remaining = _kcalLimit - kcal;
    final over = remaining < 0;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor:
              over ? const Color(0xFFD9534F) : const Color(0xFF2E7D32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          content: Row(
            children: [
              Icon(
                over ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  over
                      ? '+${snack.kcal} kcal · ${-remaining} over limit'
                      : '+${snack.kcal} kcal · $remaining left',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () => _undoLastSnack(),
          ),
        ),
      );
  }

  Future<void> _deleteHistoryAt(int index, String name, int kcal) async {
    HapticFeedback.mediumImpact();
    final removed = await UserStorage.removeConsumptionAt(index);
    if (removed == null) return;
    final today = DateTime.now();
    final newKcal = await UserStorage.getKcalConsumed(today);
    final history = await UserStorage.getHistory(today);
    if (!mounted) return;
    setState(() {
      _kcalConsumed = newKcal;
      _history = history;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: const Color(0xFF424242),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          content: Text(
            'Removed $name (-$kcal kcal)',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: Colors.white,
            onPressed: () => _restoreEntry(index, removed),
          ),
        ),
      );
  }

  Future<void> _restoreEntry(int index, Map<String, dynamic> entry) async {
    final name = entry['name'] as String;
    final kcal = (entry['kcal'] as num).toInt();
    await UserStorage.addConsumption(name: name, kcal: kcal);
    final today = DateTime.now();
    final newKcal = await UserStorage.getKcalConsumed(today);
    final history = await UserStorage.getHistory(today);
    if (!mounted) return;
    setState(() {
      _kcalConsumed = newKcal;
      _history = history;
    });
  }

  Future<void> _undoLastSnack() async {
    HapticFeedback.selectionClick();
    final removed = await UserStorage.removeConsumptionAt(0);
    if (removed == null) return;
    final today = DateTime.now();
    final kcal = await UserStorage.getKcalConsumed(today);
    final history = await UserStorage.getHistory(today);
    if (!mounted) return;
    setState(() {
      _kcalConsumed = kcal;
      _history = history;
    });
  }

  static const _categoryColors = {
    'Biscuits & Cookies': Color(0xFFFFE0B2),
    'Chips & Savory': Color(0xFFFFCDD2),
    'Chocolates & Sweets': Color(0xFFD7CCC8),
    'Noodle Snacks': Color(0xFFFFF59D),
    'Cakes & Bakery': Color(0xFFF8BBD0),
  };

  static const _categoryIcons = {
    'Biscuits & Cookies': Icons.cookie_outlined,
    'Chips & Savory': Icons.lunch_dining_outlined,
    'Chocolates & Sweets': Icons.icecream_outlined,
    'Noodle Snacks': Icons.ramen_dining_outlined,
    'Cakes & Bakery': Icons.cake_outlined,
  };

  Widget _buildFoodCard(Snack snack) {
    final bg = _categoryColors[snack.category] ?? const Color(0xFFF0EDE8);
    final icon = _categoryIcons[snack.category] ?? Icons.restaurant_rounded;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(icon, size: 40, color: Colors.black54),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${snack.kcal} kcal · ${snack.serving}',
                        style: GoogleFonts.inter(
                            fontSize: 11, color: Colors.black45),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        snack.name,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _logSnack(snack),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Week calendar (shared with HomeTab) ───────────────────────────────────

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

class _HistoryPill extends StatefulWidget {
  const _HistoryPill({
    required this.name,
    required this.kcal,
    required this.onDelete,
  });

  final String name;
  final int kcal;
  final VoidCallback onDelete;

  @override
  State<_HistoryPill> createState() => _HistoryPillState();
}

class _HistoryPillState extends State<_HistoryPill>
    with SingleTickerProviderStateMixin {
  static const _holdDuration = Duration(milliseconds: 500);

  late final AnimationController _ctrl;
  bool _pressed = false;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: _holdDuration);
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_fired) {
        _fired = true;
        HapticFeedback.mediumImpact();
        widget.onDelete();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _start() {
    _fired = false;
    setState(() => _pressed = true);
    _ctrl.forward(from: 0);
  }

  void _cancel() {
    setState(() => _pressed = false);
    _ctrl.stop();
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _start(),
      onTapUp: (_) => _cancel(),
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _pressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            final t = _ctrl.value;
            final bg = Color.lerp(
              Colors.white,
              const Color(0xFFFFCDD2),
              t,
            )!;
            return Container(
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: const Color(0xFFD9534F).withValues(alpha: t),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: child,
                  ),
                  if (t > 0)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: FractionallySizedBox(
                            widthFactor: t,
                            heightFactor: 1,
                            child: Container(
                              color: const Color(0xFFD9534F)
                                  .withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.name,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.kcal} kcal',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
