import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'splash_loading_page.dart';
import 'home_page.dart'; // สำหรับ EmotionType

class FinalIntroPage extends StatefulWidget {
  const FinalIntroPage({
    super.key,

    // ======= ปรับตำแหน่งเหมือน emoji_intro_page =======
    this.greenSize = 140,
    this.smallSize = 118,
    this.spacing = 16,        // ระยะห่างระหว่างอิโมจิกับ "+"
    this.plusFontSize = 36,   // ขนาด "+"
    this.plusYOffset = -60,   // ปรับขึ้น/ลงของ "+"
    this.yellowOffset = 0,    // ปรับตำแหน่งอิโมจิเหลือง (+ลง / -ขึ้น)
    this.redOffset = 0,       // ปรับตำแหน่งอิโมจิแดง (+ลง / -ขึ้น)

    // ======= ค่าที่ได้จาก ReasonPage =======
    this.reasonText,
    this.emotion,
  });

  // layout controls
  final double greenSize;
  final double smallSize;
  final double spacing;
  final double plusFontSize;
  final double plusYOffset;
  final double yellowOffset;
  final double redOffset;

  // data from ReasonPage
  final String? reasonText;
  final EmotionType? emotion;

  @override
  State<FinalIntroPage> createState() => _FinalIntroPageState();
}

class _FinalIntroPageState extends State<FinalIntroPage>
    with TickerProviderStateMixin {
  // ลอยอิโมจิ
  late final AnimationController _floatCtrl;
  // ลำดับเข้า
  late final AnimationController _enterCtrl;
  // pulse “กดเพื่อไปต่อ”
  late final AnimationController _pulseCtrl;
  late final Animation<Offset> _cartoonSlide;
  late final Animation<double> _cartoonFade;
  late final Animation<double> _bubbleFade;

  // toggle อิโมจิ
  bool _gSecond = false, _ySecond = false, _rSecond = false;
  Timer? _toggleTimer;
  static const _togglePeriod = Duration(milliseconds: 1800);
  static const _switchDuration = Duration(milliseconds: 900);

  // ค่าลอย (คงที่)
  static const double _greenAmplitude = 6;
  static const double _smallAmplitude = 7;
  static const double _phaseGreen = 0.0;
  static const double _phaseYellow = math.pi / 2;
  static const double _phaseRed = math.pi * 1.2;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();

    _cartoonSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOutBack),
    ));
    _cartoonFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.25, 0.85, curve: Curves.easeOut),
    );
    _bubbleFade = CurvedAnimation(
      parent: _enterCtrl,
      curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      lowerBound: 0.95,
      upperBound: 1.05,
    )..repeat(reverse: true);

    // toggle first/sec อัตโนมัติ
    _toggleTimer = Timer.periodic(_togglePeriod, (_) {
      if (!mounted) return;
      setState(() {
        _gSecond = !_gSecond;
        _ySecond = !_ySecond;
        _rSecond = !_rSecond;
      });
    });
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    _enterCtrl.dispose();
    _pulseCtrl.dispose();
    _toggleTimer?.cancel();
    super.dispose();
  }

  // ✅ ไป SplashLoadingPage (ไม่ต้องส่งพารามิเตอร์แล้ว)
  void _goToMain() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SplashLoadingPage(),
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, animation, __, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final slide = Tween<Offset>(
            begin: const Offset(0.0, 0.05),
            end: Offset.zero,
          ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  // emoji ลอย + สลับรูป
  Widget _floatingToggleEmoji({
    required String firstAsset,
    required String secondAsset,
    required bool isSecond,
    required double size,
    required double amplitude,
    required double phase,
  }) {
    final img = AnimatedSwitcher(
      duration: _switchDuration,
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (child, anim) {
        final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        );
        return FadeTransition(
          opacity: anim,
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

    return AnimatedBuilder(
      animation: _floatCtrl,
      builder: (_, child) {
        final t = _floatCtrl.value * 2 * math.pi;
        final dy = math.sin(t + phase) * amplitude;
        final scale = 1.0 + math.sin(t + phase) * 0.015;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: img,
    );
  }

  @override
  Widget build(BuildContext context) {
    const bg = Color(0xFF212121);
    final smallSize = widget.smallSize;
    final spacing = widget.spacing;
    const plusWidth = 24.0; // กว้างคร่าว ๆ ของ "+"
    final plusFontSize = widget.plusFontSize;

    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _goToMain,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ====== หัวเรื่อง + เขียวด้านบน ======
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'เลือกอารมณ์ของคุณ',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF90DAF4),
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _floatingToggleEmoji(
                      firstAsset: 'assets/icons/First_Green.png',
                      secondAsset: 'assets/icons/Sec_Green.png',
                      isSecond: _gSecond,
                      size: widget.greenSize,
                      amplitude: _greenAmplitude,
                      phase: _phaseGreen,
                    ),
                    const SizedBox(height: 8),

                    // ====== แถวล่าง: เหลือง + "+" + แดง ======
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final w = constraints.maxWidth;
                        final centerX = w / 2;
                        final containerHeight =
                            smallSize + _smallAmplitude * 2 + 12;

                        return SizedBox(
                          width: double.infinity,
                          height: containerHeight,
                          child: AnimatedBuilder(
                            animation: _floatCtrl,
                            builder: (context, child) {
                              final baseTopForEmoji =
                                  (containerHeight - smallSize) / 2;

                              final yellowLeft = centerX -
                                  smallSize -
                                  spacing -
                                  (plusWidth / 2);
                              final redLeft =
                                  centerX + spacing + (plusWidth / 2);

                              final yellowTop =
                                  baseTopForEmoji + widget.yellowOffset;
                              final redTop =
                                  baseTopForEmoji + widget.redOffset;

                              final plusTop = ((yellowTop + redTop) / 2.65) +
                                  (smallSize / 2) -
                                  12 +
                                  widget.plusYOffset;

                              return Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // เหลือง
                                  Positioned(
                                    top: yellowTop,
                                    left: yellowLeft,
                                    child: _floatingToggleEmoji(
                                      firstAsset:
                                          'assets/icons/First_Yellow.png',
                                      secondAsset:
                                          'assets/icons/Sec_Yellow.png',
                                      isSecond: _ySecond,
                                      size: smallSize,
                                      amplitude: _smallAmplitude,
                                      phase: _phaseYellow,
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
                                        fontSize: plusFontSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // แดง
                                  Positioned(
                                    top: redTop,
                                    left: redLeft,
                                    child: _floatingToggleEmoji(
                                      firstAsset:
                                          'assets/icons/First_Red.png',
                                      secondAsset:
                                          'assets/icons/Sec_Red.png',
                                      isSecond: _rSecond,
                                      size: smallSize,
                                      amplitude: _smallAmplitude,
                                      phase: _phaseRed,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ====== บับเบิล + การ์ตูน + ปุ่มไปต่อ ======
            Positioned(
              left: 20,
              right: 20,
              bottom: 28,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _bubbleFade,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          margin: const EdgeInsets.only(bottom: 58),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'น้องโอบใจเข้าใจอารมณ์ของพี่ๆแล้วครับ\nต่อจากนี้จะเข้าสู่ตัวแอปหลักแล้วนะ',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 60,
                          bottom: 42,
                          child: Transform.rotate(
                            angle: 0.78,
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FadeTransition(
                    opacity: _cartoonFade,
                    child: SlideTransition(
                      position: _cartoonSlide,
                      child: Image.asset(
                        'assets/icons/Cartoon.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _goToMain,
                    child: ScaleTransition(
                      scale: _pulseCtrl,
                      child: Text(
                        'กดเพื่อไปต่อ',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
