import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SurveyPage extends StatefulWidget {
  const SurveyPage({super.key});

  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final Set<int> _selected = {};

  static const _options = [
    'For a healthy Lifestyle',
    'To remove bad habits',
    'To track calories',
    'Just exploring',
  ];

  // Staggered left offsets to match the design
  static const _offsets = [0.0, 60.0, 20.0, 80.0];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 160, sigmaY: 160, tileMode: TileMode.clamp),
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
          // group.png at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Image.asset(
              'assets/group.png',
              fit: BoxFit.fitWidth,
              width: double.infinity,
            ),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // Progress pills
                  Row(
                    children: List.generate(4, (i) {
                      final isActive = i <= 3;
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
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
                  const SizedBox(height: 48),
                  Text(
                    'The Rockies are curious\nas why you\'re joining them',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'you can select more than one !',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Staggered options
                  ...List.generate(_options.length, (i) {
                    final isSelected = _selected.contains(i);
                    return Padding(
                      padding: EdgeInsets.only(
                        left: _offsets[i],
                        bottom: 14,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isSelected
                              ? _selected.remove(i)
                              : _selected.add(i);
                        }),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(50),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                              ),
                              child: Text(
                                _options[i],
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.black87
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  // Done button
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            'Done !',
                            style: GoogleFonts.jersey20(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
