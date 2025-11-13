import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'after_bubble_summary_page.dart';

class BubbleGamePage extends StatefulWidget {
  const BubbleGamePage({super.key});

  @override
  State<BubbleGamePage> createState() => _BubbleGamePageState();
}

class _BubbleGamePageState extends State<BubbleGamePage> {
  final Random _random = Random();
  int _score = 0;
  List<_Bubble> bubbles = [];

  @override
  void initState() {
    super.initState();
    _generateBubbles();
  }

  void _generateBubbles() {
    bubbles = List.generate(5, (_) {
      final size = 70 + _random.nextDouble() * 80;
      final left = _random.nextDouble() * 250;
      final top = _random.nextDouble() * 500;
      return _Bubble(left: left, top: top, size: size);
    });
  }

  void _popBubble(int index) {
    setState(() {
      bubbles[index] = bubbles[index].copyWith(isPopped: true);
      _score++;
    });

    // ลบฟองที่แตกออกหลัง 700ms แล้วเพิ่มฟองใหม่
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        bubbles.removeAt(index);
        bubbles.add(_Bubble(
          left: _random.nextDouble() * 250,
          top: _random.nextDouble() * 500,
          size: 70 + _random.nextDouble() * 80,
        ));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6784A5),
      body: SafeArea(
        child: Stack(
          children: [
            // 🔹 ฟองสบู่ทั้งหมด
            ...bubbles.asMap().entries.map((entry) {
              final i = entry.key;
              final b = entry.value;
              return AnimatedPositioned(
                key: ValueKey(b.hashCode),
                duration: const Duration(milliseconds: 500),
                left: b.left,
                top: b.top,
                child: GestureDetector(
                  onTap: () => _popBubble(i),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: b.isPopped
                        ? Image.asset(
                            'assets/images/bubble_Burst.png', // รูปฟองแตก
                            key: ValueKey('burst_$i'),
                            width: b.size,
                            height: b.size,
                          )
                        : Image.asset(
                            'assets/images/bubble.png', // รูปฟองปกติ
                            key: ValueKey('bubble_$i'),
                            width: b.size,
                            height: b.size,
                          ),
                  ),
                ),
              );
            }),

            // 🔹 ปุ่มย้อนกลับ
            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                backgroundColor: Colors.white.withOpacity(0.4),
                radius: 20,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () {
                    // ไปหน้าแสดงคะแนนหลังเล่น
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AfterBubbleSummaryPage(score: _score),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 🔹 ตัวนับคะแนน
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.4),
                    radius: 20,
                    child: Text(
                      '$_score',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ต่อเนื่อง',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ✅ คลาสเก็บข้อมูลฟองแต่ละอัน
class _Bubble {
  final double left;
  final double top;
  final double size;
  final bool isPopped;

  _Bubble({
    required this.left,
    required this.top,
    required this.size,
    this.isPopped = false,
  });

  _Bubble copyWith({bool? isPopped}) {
    return _Bubble(
      left: left,
      top: top,
      size: size,
      isPopped: isPopped ?? this.isPopped,
    );
  }
}
