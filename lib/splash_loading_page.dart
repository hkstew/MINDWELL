import 'dart:async';
import 'package:flutter/material.dart';

// ✅ ใช้หน้าโฮมจริง และส่งค่าข้อความ/อารมณ์ไปแสดงใต้ Color Bar
import 'home_page.dart'; // มี EmotionType และ HomePage

class SplashLoadingPage extends StatefulWidget {
  const SplashLoadingPage({
    super.key,
    this.background = const Color(0xFF212121),
    this.accent = const Color(0xFF90DAF4),
    this.logoAsset = 'assets/logos/mindwell_logo.png',
    this.logoSize = 360,
    this.totalWait = const Duration(milliseconds: 2200),
  });

  final Color background;
  final Color accent;
  final String logoAsset;
  final double logoSize;
  final Duration totalWait;

  @override
  State<SplashLoadingPage> createState() => _SplashLoadingPageState();
}

class _SplashLoadingPageState extends State<SplashLoadingPage>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final AnimationController _decorCtrl;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;

  late final Animation<Offset> _topRightSlide;
  late final Animation<Offset> _midLeftSlide;
  late final Animation<Offset> _bottomRightSlide;
  late final Animation<double> _decorFade;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _decorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack),
    );

    _decorFade = CurvedAnimation(
      parent: _decorCtrl,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    );

    _topRightSlide = Tween<Offset>(
      begin: const Offset(0.3, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _decorCtrl,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
    ));

    _midLeftSlide = Tween<Offset>(
      begin: const Offset(-0.4, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _decorCtrl,
      curve: const Interval(0.15, 0.95, curve: Curves.easeOut),
    ));

    _bottomRightSlide = Tween<Offset>(
      begin: const Offset(0.4, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _decorCtrl,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    ));

    // ✅ ตั้งเวลาไปหน้า Home
    _timer = Timer(widget.totalWait, _goHome);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoCtrl.dispose();
    _decorCtrl.dispose();
    super.dispose();
  }

  // ✅ ไปหน้า HomePage (ไม่ต้องส่งพารามิเตอร์แล้ว)
  void _goHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomePage(),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final slide = Tween<Offset>(
            begin: const Offset(0.02, 0.05),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;

    return Scaffold(
      backgroundColor: widget.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ======= Decorations =======
            // Top-right bars
            Positioned(
              right: 12,
              top: 10,
              child: FadeTransition(
                opacity: _decorFade,
                child: SlideTransition(
                  position: _topRightSlide,
                  child: _BarsCluster(
                    mainColor: accent,
                    smallGap: 8,
                    bars: const [
                      _Bar(w: 130, h: 22, radius: 11),
                      _Bar(w: 90, h: 14, radius: 7),
                    ],
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),

            // Mid-left bar + dot
            Positioned(
              left: 0,
              top: 240,
              child: FadeTransition(
                opacity: _decorFade,
                child: SlideTransition(
                  position: _midLeftSlide,
                  child: _BarsCluster(
                    mainColor: accent,
                    smallGap: 8,
                    bars: const [
                      _Bar(w: 110, h: 18, radius: 9),
                      _Dot(size: 12),
                    ],
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
            ),

            // Bottom-right bars + dots
            Positioned(
              right: 8,
              bottom: 10,
              child: FadeTransition(
                opacity: _decorFade,
                child: SlideTransition(
                  position: _bottomRightSlide,
                  child: _BarsCluster(
                    mainColor: accent,
                    smallGap: 8,
                    bars: const [
                      _Dot(size: 14),
                      _Dot(size: 8),
                      _Bar(w: 140, h: 22, radius: 11),
                      _Bar(w: 100, h: 18, radius: 9),
                    ],
                    alignment: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // ======= Center Logo =======
            Center(
              child: FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset(
                    widget.logoAsset,
                    width: widget.logoSize,
                    height: widget.logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// กลุ่มแท่ง/จุดตามมุม
class _BarsCluster extends StatelessWidget {
  const _BarsCluster({
    required this.mainColor,
    required this.smallGap,
    required this.bars,
    required this.alignment,
  });

  final Color mainColor;
  final double smallGap;
  final List<Widget> bars;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final children = bars.map((w) {
      if (w is _Bar) {
        return Container(
          width: w.w,
          height: w.h,
          margin: EdgeInsets.only(bottom: smallGap),
          decoration: BoxDecoration(
            color: mainColor,
            borderRadius: BorderRadius.circular(w.radius),
          ),
        );
      } else if (w is _Dot) {
        return Container(
          width: w.size,
          height: w.size,
          margin: EdgeInsets.only(bottom: smallGap),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
        );
      }
      return const SizedBox.shrink();
    }).toList();

    return Align(
      alignment: alignment,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.w, required this.h, required this.radius});
  final double w, h, radius;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _Dot extends StatelessWidget {
  const _Dot({required this.size});
  final double size;
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
