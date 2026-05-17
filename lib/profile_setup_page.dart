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
  int _gender = 1; // 0 = female, 1 = male
  int _selectedAge = 24;

  static const int _minAge = 10;
  static const int _maxAge = 80;
  static const double _itemWidth = 72.0;

  late final ScrollController _ageController;
  Timer? _snapTimer;

  @override
  void initState() {
    super.initState();
    _ageController = ScrollController();
    _ageController.addListener(_scheduleSnap);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ageController.jumpTo((_selectedAge - _minAge) * _itemWidth);
    });
  }

  @override
  void dispose() {
    _snapTimer?.cancel();
    _ageController.dispose();
    super.dispose();
  }

  void _scheduleSnap() {
    _snapTimer?.cancel();
    _snapTimer = Timer(const Duration(milliseconds: 80), _snap);
  }

  void _snap() {
    if (!_ageController.hasClients) return;
    final nearestIndex = (_ageController.offset / _itemWidth)
        .round()
        .clamp(0, _maxAge - _minAge);
    _ageController.animateTo(
      nearestIndex * _itemWidth,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
    setState(() => _selectedAge = _minAge + nearestIndex);
  }

  @override
  Widget build(BuildContext context) {
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
                  // Progress pills
                  Row(
                    children: List.generate(5, (i) {
                      final isActive = i <= 2;
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
                                // Gender selection
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _GenderButton(
                                      icon: Icons.female,
                                      isSelected: _gender == 0,
                                      onTap: () => setState(() => _gender = 0),
                                    ),
                                    const SizedBox(width: 16),
                                    _GenderButton(
                                      icon: Icons.male,
                                      isSelected: _gender == 1,
                                      onTap: () => setState(() => _gender = 1),
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
                  // Age picker + Next button
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
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
                                  'Age',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 56,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final sidePadding =
                                          (constraints.maxWidth - _itemWidth) /
                                          2;
                                      return AnimatedBuilder(
                                          animation: _ageController,
                                          builder: (context, _) {
                                            final scrollOffset =
                                                _ageController.hasClients
                                                    ? _ageController.offset
                                                    : (_selectedAge - _minAge) *
                                                        _itemWidth;
                                            return ListView.builder(
                                              controller: _ageController,
                                              scrollDirection: Axis.horizontal,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: sidePadding,
                                              ),
                                              physics:
                                                  const BouncingScrollPhysics(),
                                              itemCount:
                                                  _maxAge - _minAge + 1,
                                              itemBuilder: (context, i) {
                                                final distance =
                                                    (i * _itemWidth -
                                                            scrollOffset)
                                                        .abs();
                                                final scale = (1.0 -
                                                        distance /
                                                            (_itemWidth * 2.5))
                                                    .clamp(0.45, 1.0);
                                                final opacity = (1.0 -
                                                        distance /
                                                            (_itemWidth * 1.8))
                                                    .clamp(0.25, 1.0);
                                                return SizedBox(
                                                  width: _itemWidth,
                                                  child: Center(
                                                    child: Transform.scale(
                                                      scale: scale,
                                                      child: Opacity(
                                                        opacity: opacity,
                                                        child: Text(
                                                          '${_minAge + i}',
                                                          style:
                                                              GoogleFonts.inter(
                                                                fontSize: 34,
                                                                fontWeight:
                                                                    scale > 0.85
                                                                        ? FontWeight
                                                                            .bold
                                                                        : FontWeight
                                                                            .w400,
                                                                color:
                                                                    Colors
                                                                        .black,
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
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'year old',
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
                      Positioned(
                        bottom: -20,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                'Next',
                                style: GoogleFonts.jersey20(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
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
