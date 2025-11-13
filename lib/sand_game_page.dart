import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SandGamePage extends StatefulWidget {
  const SandGamePage({super.key});

  @override
  State<SandGamePage> createState() => _SandGamePageState();
}

class _SandGamePageState extends State<SandGamePage> {
  int _score = 0;
  final List<bool> _isCrushed = List.generate(6, (_) => false);

  void _onTapSand(int index) {
    if (_isCrushed[index]) return; // ป้องกันกดซ้ำก่อนรีเซ็ต

    setState(() {
      _isCrushed[index] = true;
      _score++;
    });

    // ✅ ดีเลย์ 1 วิ แล้วกลับมาเป็นทรายปกติ
    Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isCrushed[index] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sandPiles = [
      const Offset(0.15, 0.6),
      const Offset(0.45, 0.55),
      const Offset(0.75, 0.6),
      const Offset(0.25, 0.75),
      const Offset(0.55, 0.78),
      const Offset(0.35, 0.9),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFADD8E6), // เผื่อโหลดพื้นหลังไม่ทัน
      body: Stack(
        children: [
          // 🌊 พื้นหลังทะเล
          Positioned.fill(
            child: Image.asset(
              'assets/images/sand_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // 🔙 ปุ่มย้อนกลับ
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),

          // 🏖️ วางกองทรายแต่ละกอง
          ...List.generate(sandPiles.length, (i) {
            return Positioned(
              left: MediaQuery.of(context).size.width * sandPiles[i].dx - 60,
              top: MediaQuery.of(context).size.height * sandPiles[i].dy - 60,
              child: GestureDetector(
                onTap: () => _onTapSand(i),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: _isCrushed[i]
                      ? Image.asset(
                          'assets/images/hand_smash.png',
                          key: ValueKey('crushed_$i'),
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        )
                      : Image.asset(
                          'assets/images/sand_pile.png',
                          key: ValueKey('pile_$i'),
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
