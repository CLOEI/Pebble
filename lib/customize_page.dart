import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:google_fonts/google_fonts.dart';
import 'services/user_storage.dart';

class CustomizePage extends StatefulWidget {
  const CustomizePage({
    super.key,
    required this.initialPebble,
    required this.initialExpression,
    required this.name,
  });

  final int initialPebble;
  final int initialExpression;
  final String name;

  @override
  State<CustomizePage> createState() => _CustomizePageState();
}

class _CustomizePageState extends State<CustomizePage>
    with SingleTickerProviderStateMixin {
  static const int _pebbleTotal = 12;
  static const int _expressionTotal = 12;

  late int _pebble;
  late int _expression;
  Set<int> _unlocked = {};
  int _tab = 0; // 0 = Pebble, 1 = Expression

  static const _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  void initState() {
    super.initState();
    _pebble = widget.initialPebble;
    _expression = widget.initialExpression;
    _loadUnlocked();
  }

  Future<void> _loadUnlocked() async {
    final unlocked = await UserStorage.getUnlockedPebbles();
    if (!mounted) return;
    setState(() => _unlocked = unlocked);
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    await UserStorage.saveCharacter(
      name: widget.name,
      pebbleIndex: _pebble,
      expressionIndex: _expression,
    );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _onLockedTap() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1600),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: const Color(0xFF424242),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          content: Row(
            children: [
              const Icon(Icons.lock_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                'Locked — earn as reward',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Solid sky base — prevents blur bleed at corners
          const ColoredBox(color: Color(0xFF5BA3D9)),
          // Blurred backdrop
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 160,
              sigmaY: 160,
              tileMode: TileMode.clamp,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset('assets/Sky.png',
                      fit: BoxFit.fitWidth, width: double.infinity),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset('assets/Hill.png',
                      fit: BoxFit.fitWidth, width: double.infinity),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildPreview(),
                const SizedBox(height: 12),
                _buildTabs(),
                const SizedBox(height: 12),
                Expanded(child: _buildGrid()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            'Customize',
            style: GoogleFonts.jersey20(
              fontSize: 24,
              color: Colors.white,
            ),
          ),
          GestureDetector(
            onTap: _save,
            child: Text(
              'Save',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF5A623),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset(
            'assets/Pebbles with Leg/${_pebble + 1}.png',
            fit: BoxFit.contain,
          ),
          FractionallySizedBox(
            widthFactor: 0.55,
            heightFactor: 0.55,
            child: Image.asset(
              'assets/Expression/${_expression + 1}.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Image.asset(
                  'assets/shadow.png',
                  fit: BoxFit.fitWidth,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton(0, 'Pebble'),
          const SizedBox(width: 8),
          _buildTabButton(1, 'Expression'),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label) {
    final selected = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(50),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _tab == 0 ? _pebbleTotal : _expressionTotal,
        itemBuilder: (context, i) =>
            _tab == 0 ? _buildPebbleCell(i) : _buildExpressionCell(i),
      ),
    );
  }

  Widget _buildPebbleCell(int i) {
    final selected = i == _pebble;
    final locked = !_unlocked.contains(i);

    Widget image = Image.asset(
      'assets/Pebbles with Leg/${i + 1}.png',
      fit: BoxFit.contain,
    );
    if (locked) {
      image = ColorFiltered(colorFilter: _greyscale, child: image);
    }

    return GestureDetector(
      onTap: () {
        if (locked) {
          _onLockedTap();
          return;
        }
        HapticFeedback.selectionClick();
        setState(() => _pebble = i);
      },
      child: Container(
        decoration: BoxDecoration(
          color: locked
              ? Colors.grey.shade100
              : (selected ? const Color(0xFFFFF1D6) : Colors.grey.shade50),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                selected ? const Color(0xFFF5A623) : Colors.transparent,
            width: 2.5,
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Stack(
          alignment: Alignment.center,
          children: [
            image,
            if (locked)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.lock_rounded,
                    color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpressionCell(int i) {
    final selected = i == _expression;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _expression = i);
      },
      child: Container(
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF5A623) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          'assets/Expression/${i + 1}.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
