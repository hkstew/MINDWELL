import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'emoji_select_good_page.dart';
import 'emoji_select_bad_page.dart';
import 'emoji_select_neutral_page.dart';

/// หน้าเลือกอารมณ์ (ใช้สูตรวาง "+" แบบเดียวกับ emoji_intro_page และมี offset ปรับเองได้)
class EmojiSelectPage extends StatefulWidget {
  const EmojiSelectPage({
    super.key,
    this.backgroundColor = const Color(0xFF212121),

    // การ์ตูนมุมซ้ายล่าง
    this.cartoonAsset = 'assets/icons/Cartoon.png',
    this.cartoonSize = 380,
    this.cartoonLeft = -95,
    this.cartoonBottom = -80,

    // ขนาด/ระยะห่าง
    this.greenSize = 170,
    this.smallSize = 160,
    this.spacing = 12,

    // ปรับตำแหน่งได้เอง
    this.plusFontSize = 36,
    this.plusYOffset = -70,   // 👈 ปรับตำแหน่ง "+" (+ ลง / - ขึ้น)
    this.yellowOffset = 0,  // 👈 ปรับตำแหน่งอิโมจิเหลือง (+ ลง / - ขึ้น)
    this.redOffset = 0,     // 👈 ปรับตำแหน่งอิโมจิแดง (+ ลง / - ขึ้น)
  });

  final Color backgroundColor;

  // การ์ตูน
  final String cartoonAsset;
  final double cartoonSize;
  final double cartoonLeft;
  final double cartoonBottom;

  // ขนาด/ระยะห่าง
  final double greenSize;
  final double smallSize;
  final double spacing;

  // ปรับตำแหน่ง
  final double plusFontSize;
  final double plusYOffset;
  final double yellowOffset;
  final double redOffset;

  @override
  State<EmojiSelectPage> createState() => _EmojiSelectPageState();
}

class _EmojiSelectPageState extends State<EmojiSelectPage> {
  bool _gSecond = false; // green
  bool _ySecond = false; // yellow
  bool _rSecond = false; // red
  Timer? _timer;

  static const _togglePeriod = Duration(milliseconds: 1900);
  static const _switchDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_togglePeriod, (_) {
      setState(() {
        _gSecond = !_gSecond;
        _ySecond = !_ySecond;
        _rSecond = !_rSecond;
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
    const plusWidth = 24.0; // กว้างคร่าว ๆ ของ "+"
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    'เลือกอารมณ์ของคุณ',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF90DAF4),
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // เขียวด้านบน
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EmojiSelectGoodPage()),
                      );
                    },
                    child: _EmojiAutoToggle(
                      isSecond: _gSecond,
                      firstAsset: 'assets/icons/First_Green.png',
                      secondAsset: 'assets/icons/Sec_Green.png',
                      size: widget.greenSize,
                      duration: _switchDuration,
                      glow: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // แถวล่าง: เหลือง + "+" + แดง
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth;
                      final centerX = w / 2;

                      // ตำแหน่งบนของเหลือง/แดง (ใส่ offset ที่ปรับเองได้)
                      final yellowTop = widget.yellowOffset;
                      final redTop = widget.redOffset;

                      final yellowLeft =
                          centerX - widget.smallSize - widget.spacing - (plusWidth / 2);
                      final redLeft = centerX + widget.spacing + (plusWidth / 2);

                      // สูตรตามที่คุณต้องการ + เพิ่ม plusYOffset เพื่อปรับเอง
                      final plusTop = ((yellowTop + redTop) / 2.65) +
                          (widget.smallSize / 2) - 12 +
                          widget.plusYOffset;

                      // คำนวณความสูงกล่องให้เผื่อ offset
                      final rowHeight = widget.smallSize +
                          (widget.yellowOffset.abs() > widget.redOffset.abs()
                              ? widget.yellowOffset.abs()
                              : widget.redOffset.abs()) +
                          24;

                      return SizedBox(
                        width: double.infinity,
                        height: rowHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // เหลือง
                            Positioned(
                              top: yellowTop,
                              left: yellowLeft,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EmojiSelectNeutralPage(),
                                    ),
                                  );
                                },
                                child: _EmojiAutoToggle(
                                  isSecond: _ySecond,
                                  firstAsset: 'assets/icons/First_Yellow.png',
                                  secondAsset: 'assets/icons/Sec_Yellow.png',
                                  size: widget.smallSize,
                                  duration: _switchDuration,
                                  glow: true,
                                ),
                              ),
                            ),

                            // "+"
                            Positioned(
                              top: plusTop,
                              left: centerX - (plusWidth / 2),
                              child: Text(
                                '+',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: widget.plusFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            // แดง
                            Positioned(
                              top: redTop,
                              left: redLeft,
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const EmojiSelectBadPage(),
                                    ),
                                  );
                                },
                                child: _EmojiAutoToggle(
                                  isSecond: _rSecond,
                                  firstAsset: 'assets/icons/First_Red.png',
                                  secondAsset: 'assets/icons/Sec_Red.png',
                                  size: widget.smallSize,
                                  duration: _switchDuration,
                                  glow: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // การ์ตูนมุมซ้ายล่าง
            Positioned(
              left: widget.cartoonLeft,
              bottom: widget.cartoonBottom,
              child: IgnorePointer(
                ignoring: true,
                child: SizedBox(
                  width: widget.cartoonSize,
                  height: widget.cartoonSize,
                  child: Image.asset(widget.cartoonAsset, fit: BoxFit.contain),
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
        return FadeTransition(opacity: animation, child: ScaleTransition(scale: scale, child: child));
      },
      child: Image.asset(
        isSecond ? secondAsset : firstAsset,
        key: ValueKey(isSecond),
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );

    return glow
        ? Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
              borderRadius: BorderRadius.circular(size / 2),
            ),
            child: img,
          )
        : SizedBox(width: size, height: size, child: img);
  }
}
