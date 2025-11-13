import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'neutral_reason_page.dart';

/// หน้า: เลือกอารมณ์ของคุณ (เวอร์ชันอารมณ์กลาง ๆ / สีเหลือง)
/// - อิโมจิ 3 ตัว (บน, ซ้ายล่าง, ขวาล่าง)
/// - แต่ละตัวสลับรูป First_* <-> Sec_* อัตโนมัติแบบวน พร้อมทรานซิชัน
class EmojiSelectNeutralPage extends StatefulWidget {
  const EmojiSelectNeutralPage({super.key});

  @override
  State<EmojiSelectNeutralPage> createState() => _EmojiSelectNeutralPageState();
}

class _EmojiSelectNeutralPageState extends State<EmojiSelectNeutralPage> {
  bool _topSecond = false;
  bool _leftSecond = false;
  bool _rightSecond = false;

  Timer? _timer;

  static const _togglePeriod = Duration(milliseconds: 1900);
  static const _switchDuration = Duration(milliseconds: 1200);

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
                children: [
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
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // เนื้อหา
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 64),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_neutralRoute(
                          const NeutralReasonPage(
                            firstAsset: 'assets/icons/First_Yellow.png',
                            secondAsset: 'assets/icons/Sec_Yellow.png',
                            highlightWord: 'เหนื่อย',
                          ),
                        ));
                      },
                      child: _EmojiAutoToggle(
                        isSecond: _topSecond,
                        firstAsset: 'assets/icons/First_Yellow.png',
                        secondAsset: 'assets/icons/Sec_Yellow.png',
                        size: 170,
                        duration: _switchDuration,
                        glow: true,
                        glowColor: Colors.amberAccent.withOpacity(0.14),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // แถวล่าง
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_neutralRoute(
                          const NeutralReasonPage(
                            firstAsset: 'assets/icons/First_Yellow2.png',
                            secondAsset: 'assets/icons/Sec_Yellow2.png',
                            highlightWord: 'เบื่อ',
                          ),
                        ));
                      },
                      child: _EmojiAutoToggle(
                        isSecond: _leftSecond,
                        firstAsset: 'assets/icons/First_Yellow2.png',
                        secondAsset: 'assets/icons/Sec_Yellow2.png',
                        size: 150,
                        duration: _switchDuration,
                        glow: true,
                        glowColor: Colors.amberAccent.withOpacity(0.14),
                      ),
                    ),
                          ],
                        ),
                        const SizedBox(width: 22),
                        Column(
                          children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(_neutralRoute(
                          const NeutralReasonPage(
                            firstAsset: 'assets/icons/First_Yellow3.png',
                            secondAsset: 'assets/icons/Sec_Yellow3.png',
                            highlightWord: 'สับสน',
                          ),
                        ));
                      },
                      child: _EmojiAutoToggle(
                        isSecond: _rightSecond,
                        firstAsset: 'assets/icons/First_Yellow3.png',
                        secondAsset: 'assets/icons/Sec_Yellow3.png',
                        size: 150,
                        duration: _switchDuration,
                        glow: true,
                        glowColor: Colors.amberAccent.withOpacity(0.14),
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

class _EmojiAutoToggle extends StatelessWidget {
  const _EmojiAutoToggle({
    required this.isSecond,
    required this.firstAsset,
    required this.secondAsset,
    this.size = 160,
    this.duration = const Duration(milliseconds: 280),
    this.glow = false,
    this.glowColor,
  });

  final bool isSecond;
  final String firstAsset;
  final String secondAsset;
  final double size;
  final Duration duration;
  final bool glow;
  final Color? glowColor;

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
                  color: glowColor ?? Colors.white.withOpacity(0.12),
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

Route _neutralRoute(Widget page) {
  return PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
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