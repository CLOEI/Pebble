import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
            alignment: const Alignment(1, 0.4),
            child: Image.asset(
              'assets/mascot.png',
              width: MediaQuery.of(context).size.width * 0.80,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 56),
                Row(
                  children: List.generate(5, (i) {
                    final isActive = i == 0;
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
                const SizedBox(height: 48),
                Text(
                  'Welcome to',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Pebbles',
                  style: GoogleFonts.jersey20(
                    color: Colors.white,
                    fontSize: 88,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A solid space to track your journey and grow stronger alongside the Rockies.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 40),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        'Lets roll !',
                        style: GoogleFonts.jersey20(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
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
}
