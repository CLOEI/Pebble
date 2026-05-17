import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'profile_setup_page.dart';

class CharacterCreationPage extends StatefulWidget {
  const CharacterCreationPage({super.key});

  @override
  State<CharacterCreationPage> createState() => _CharacterCreationPageState();
}

class _CharacterCreationPageState extends State<CharacterCreationPage> {
  int _selectedPebble = 0;
  int _selectedExpression = 0;
  final _nameController = TextEditingController();

  static const int _total = 12;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
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
                      final isActive = i <= 1;
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
                  // Main card with paper texture
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset('assets/paper.png', fit: BoxFit.cover),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                            child: Column(
                              children: [
                                Text(
                                  'Pick your first',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Pebbles',
                                  style: GoogleFonts.jersey20(
                                    fontSize: 48,
                                    color: Colors.black,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Pebble display with arrows
                                Expanded(
                                  child: Row(
                                    children: [
                                      _ArrowButton(
                                        icon: Icons.chevron_left,
                                        onTap: () => setState(() {
                                          _selectedPebble =
                                              (_selectedPebble - 1 + _total) %
                                              _total;
                                        }),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/Pebbles with Leg/${_selectedPebble + 1}.png',
                                                  fit: BoxFit.contain,
                                                ),
                                                FractionallySizedBox(
                                                  widthFactor: 0.55,
                                                  heightFactor: 0.55,
                                                  child: Image.asset(
                                                    'assets/Expression/${_selectedExpression + 1}.png',
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
                                          ],
                                        ),
                                      ),
                                      _ArrowButton(
                                        icon: Icons.chevron_right,
                                        onTap: () => setState(() {
                                          _selectedPebble =
                                              (_selectedPebble + 1) % _total;
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Expression scroll row
                                SizedBox(
                                  height: 76,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _total,
                                    itemBuilder: (context, i) {
                                      final isSelected =
                                          i == _selectedExpression;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedExpression = i,
                                        ),
                                        child: Container(
                                          width: 68,
                                          height: 68,
                                          margin: EdgeInsets.only(
                                            right: i < _total - 1 ? 10 : 0,
                                          ),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color:
                                                isSelected
                                                    ? const Color(0xFFF5A623)
                                                    : Colors.grey.shade200,
                                          ),
                                          padding: const EdgeInsets.all(10),
                                          child: Image.asset(
                                            'assets/Expression/${i + 1}.png',
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Name input card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'What should we call you ?',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                                TextField(
                                  controller: _nameController,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.jersey20(
                                    fontSize: 32,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Rocky',
                                    hintStyle: GoogleFonts.jersey20(
                                      fontSize: 32,
                                      color: Colors.grey.shade300,
                                    ),
                                    border: const UnderlineInputBorder(),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: const UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.black26),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Join button overlapping card bottom
                      Positioned(
                        bottom: -20,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProfileSetupPage(
                                name: _nameController.text,
                                pebbleIndex: _selectedPebble,
                                expressionIndex: _selectedExpression,
                              ),
                            ),
                          ),
                          child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                              child: Text(
                                'Join the Rockies',
                                style: GoogleFonts.jersey20(
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
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

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
