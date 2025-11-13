import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AfterBubbleSummaryPage extends StatelessWidget {
  final int score;
  const AfterBubbleSummaryPage({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6784A5),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'คุณกดต่อเนื่องได้ทั้งหมด',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: GoogleFonts.poppins(
                      fontSize: 46,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4E6A86),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'แต้ม!',
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'กลับไปหน้าเกม',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF49647F),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
