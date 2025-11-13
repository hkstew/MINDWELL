import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'good_reason_page.dart';

/// หน้า: เลือกอารมณ์ของคุณ (เวอร์ชันอารมณ์ดี)
/// - อิโมจิ 3 ตัว (บน, ซ้ายล่าง, ขวาล่าง)
/// - แต่ละตัวสลับรูป First_* <-> Sec_* อัตโนมัติแบบวน พร้อมทรานซิชัน
class EmojiSelectGoodPage extends StatefulWidget {
  const EmojiSelectGoodPage({super.key});

  @override
  State<EmojiSelectGoodPage> createState() => _EmojiSelectGoodPageState();
}

class _EmojiSelectGoodPageState extends State<EmojiSelectGoodPage> {
  // สถานะสลับภาพของแต่ละอิโมจิ
  bool _topSecond = false;
  bool _leftSecond = false;
  bool _rightSecond = false;

  Timer? _timer;

  // จังหวะสลับ (เหมือนหน้าก่อน)
  static const _togglePeriod = Duration(milliseconds: 1200);
  static const _switchDuration = Duration(milliseconds: 280);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_togglePeriod, (_) {
      setState(() {
        _topSecond = !_topSecond;
        _leftSecond = !_leftSecond;
        _rightSecond = !_rightSecond;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Stack(
          children: [
            // Header
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ปุ่มย้อนกลับ
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/icons/back_arrow.png',
                        width: 22,
                        height: 22,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'เลือกอารมณ์ของคุณ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF90DAF4),
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44), // balance space of back button
                ],
              ),
            ),

            // เนื้อหาหลัก
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // อิโมจิบนกลาง
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_goodRoute(
                          const GoodReasonPage(
                            firstAsset: 'assets/icons/First_Green.png',
                            secondAsset: 'assets/icons/Sec_Green.png',
                            highlightWord: 'อารมณ์ดี',
                          ),
                        ));
                      },
                      child: _EmojiAutoToggle(
                        isSecond: _topSecond,
                        firstAsset: 'assets/icons/First_Green.png',
                        secondAsset: 'assets/icons/Sec_Green.png',
                        size: 170,
                        duration: _switchDuration,
                        glow: true,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // แถวล่าง: ซ้าย & ขวา + ใส่ label ใต้แต่ละรูป
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                    // อิโมจิซ้ายล่าง (ดีใจ)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_goodRoute(
                          const GoodReasonPage(
                            firstAsset: 'assets/icons/First_Green2.png',
                            secondAsset: 'assets/icons/Sec_Green2.png',
                            highlightWord: 'ดีใจ',
                          ),
                        ));
                      },
                      child: _EmojiAutoToggle(
                        isSecond: _leftSecond,
                        firstAsset: 'assets/icons/First_Green2.png',
                        secondAsset: 'assets/icons/Sec_Green2.png',
                        size: 150,
                        duration: _switchDuration,
                        glow: true,
                      ),
                    ),
                  ],
                ),
                        const SizedBox(width: 22),
                        Column(
                          children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_goodRoute(
                          const GoodReasonPage(
                            firstAsset: 'assets/icons/First_Green3.png',
                            secondAsset: 'assets/icons/Sec_Green3.png',
                            highlightWord: 'ผ่อนคลาย',
                          ),
                        ));
                      },
                      child: _EmojiAutoToggle(
                        isSecond: _rightSecond,
                        firstAsset: 'assets/icons/First_Green3.png',
                        secondAsset: 'assets/icons/Sec_Green3.png',
                        size: 150,
                        duration: _switchDuration,
                        glow: true,
                      ),
                    ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// วิดเจ็ตอิโมจิแบบ “สลับตามสถานะ” พร้อม Transition (Fade + Scale) + Glow เบา ๆ
class _EmojiAutoToggle extends StatelessWidget {
  const _EmojiAutoToggle({
    required this.isSecond,
    required this.firstAsset,
    required this.secondAsset,
    this.size = 160,
    this.duration = const Duration(milliseconds: 280),
    this.glow = false,
  });

  final bool isSecond;
  final String firstAsset;
  final String secondAsset;
  final double size;
  final Duration duration;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final img = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.92, end: 1.0)
            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Image.asset(
        isSecond ? secondAsset : firstAsset,
        key: ValueKey(isSecond),
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );

    final body = glow
        ? Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.12),
                  blurRadius: 26,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: img,
          )
        : SizedBox(width: size, height: size, child: img);

    return body;
  }
}
Route _goodRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final slide = Tween<Offset>(begin: const Offset(0.06, 0.02), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
