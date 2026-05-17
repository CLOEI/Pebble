import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileSetupPage extends StatefulWidget {
  final String name;
  final int pebbleIndex;
  final int expressionIndex;

  const ProfileSetupPage({
    super.key,
    this.name = 'Rocky',
    this.pebbleIndex = 0,
    this.expressionIndex = 0,
  });

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  int _gender = 1;
  int _step = 0; // 0 = age, 1 = weight, 2 = height

  static const double _itemWidth = 72.0;

  static const _configs = [
    (label: 'Age', unit: 'year old', min: 10, max: 80, initial: 24),
    (label: 'Weight', unit: 'kg', min: 30, max: 200, initial: 70),
    (label: 'Height', unit: 'cm', min: 100, max: 250, initial: 170),
  ];

  final List<int> _values = [24, 70, 170];
  late final List<ScrollController> _controllers;
  Timer? _snapTimer;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final c = ScrollController(
        initialScrollOffset: (_values[i] - _configs[i].min) * _itemWidth,
      );
      c.addListener(() => _scheduleSnap(i));
      return c;
    });
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _scheduleSnap(int index) {
    if (index != _step) return;
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 80), () => _snap(index));
  }

  void _snap(int index) {
    final c = _controllers[index];
    if (!c.hasClients) return;
    final config = _configs[index];
    final nearest = (c.offset / _itemWidth)
        .round()
        .clamp(0, config.max - config.min);
    final target = nearest * _itemWidth;
    if ((c.offset - target).abs() < 1.0) return; // already snapped
    c.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    setState(() => _values[index] = config.min + nearest);
  }

  @override
  Widget build(BuildContext context) {
    final config = _configs[_step];

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Image.asset(
                    'assets/Sky.png',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Image.asset(
                    'assets/Hill.png',
                    fit: BoxFit.fitWidth,
                    width: double.infinity,
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  // Progress pills — advances with each step
                  Row(
                    children: List.generate(5, (i) {
                      final isActive = i <= 2 + _step;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                          height: 6,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  // Main card
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/paper.png', fit: BoxFit.cover),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Welcome,',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  widget.name.isEmpty ? 'Rocky' : widget.name,
                                  style: GoogleFonts.jersey20(
                                    fontSize: 56,
                                    color: Colors.black,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/Pebbles with Leg/${widget.pebbleIndex + 1}.png',
                                        fit: BoxFit.contain,
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: 0.55,
                                        heightFactor: 0.55,
                                        child: Image.asset(
                                          'assets/Expression/${widget.expressionIndex + 1}.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _GenderButton(
                                      icon: Icons.female,
                                      isSelected: _gender == 0,
                                      onTap: () =>
                                          setState(() => _gender = 0),
                                    ),
                                    const SizedBox(width: 16),
                                    _GenderButton(
                                      icon: Icons.male,
                                      isSelected: _gender == 1,
                                      onTap: () =>
                                          setState(() => _gender = 1),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Let's set your starting point !",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Picker card + buttons
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(0, 16, 0, 36),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  config.label,
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _DrumPicker(
                                  key: ValueKey(_step),
                                  controller: _controllers[_step],
                                  minVal: config.min,
                                  maxVal: config.max,
                                  selectedVal: _values[_step],
                                  itemWidth: _itemWidth,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  config.unit,
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Buttons
                      Positioned(
                        bottom: -20,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: _step == 0
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.spaceBetween,
                          children: [
                            if (_step > 0)
                              _PillButton(
                                label: 'Back',
                                onTap: () => setState(() => _step--),
                              ),
                            _PillButton(
                              label: _step == 2 ? 'Done !' : 'Next',
                              onTap: () {
                                if (_step < 2) {
                                  setState(() => _step++);
                                } else {
                                  // TODO: finish onboarding
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrumPicker extends StatelessWidget {
  const _DrumPicker({
    super.key,
    required this.controller,
    required this.minVal,
    required this.maxVal,
    required this.selectedVal,
    required this.itemWidth,
  });

  final ScrollController controller;
  final int minVal;
  final int maxVal;
  final int selectedVal;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sidePadding = (constraints.maxWidth - itemWidth) / 2;
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final scrollOffset = controller.hasClients
                  ? controller.offset
                  : (selectedVal - minVal) * itemWidth;
              return ListView.builder(
                controller: controller,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: sidePadding),
                physics: const BouncingScrollPhysics(),
                itemCount: maxVal - minVal + 1,
                itemBuilder: (context, i) {
                  final distance = (i * itemWidth - scrollOffset).abs();
                  final scale =
                      (1.0 - distance / (itemWidth * 2.5)).clamp(0.45, 1.0);
                  final opacity =
                      (1.0 - distance / (itemWidth * 1.8)).clamp(0.25, 1.0);
                  return SizedBox(
                    width: itemWidth,
                    child: Center(
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            '${minVal + i}',
                            style: GoogleFonts.inter(
                              fontSize: 34,
                              fontWeight: scale > 0.85
                                  ? FontWeight.bold
                                  : FontWeight.w400,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              label,
              style: GoogleFonts.jersey20(fontSize: 20, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? const Color(0xFFF5A623) : Colors.grey.shade300,
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}
