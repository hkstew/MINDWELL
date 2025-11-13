import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ✅ import Reason Pages
import 'good_reason_page2.dart';
import 'neutral_reason_page2.dart';
import 'bad_reason_page2.dart';

// ✅ import Select Pages
import 'emoji_select_good_page2.dart';
import 'emoji_select_neutral_page2.dart';
import 'emoji_select_bad_page2.dart';

// ✅ import Data Store + Analyst Page
import 'emotion_data_store.dart';
import 'analyst_page.dart';

import 'bottom_nav_bar.dart';

enum EmotionType { good, neutral, bad }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.background = const Color(0xFF212121),
    this.greenSize = 170,
    this.smallSize = 160,
    this.spacing = 12,
    this.plusFontSize = 28,
    this.plusYOffset = 0,
    this.greenOffset = 0,
    this.yellowOffset = 0,
    this.redOffset = 0,
  });

  final Color background;
  final double greenSize;
  final double smallSize;
  final double spacing;
  final double plusFontSize;
  final double plusYOffset;
  final double greenOffset;
  final double yellowOffset;
  final double redOffset;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _gSecond = false;
  bool _ySecond = false;
  bool _rSecond = false;
  Timer? _timer;

  static const _togglePeriod = Duration(milliseconds: 1900);
  static const _switchDuration = Duration(milliseconds: 1200);

  int _currentIndex = 0;

  /// ✅ เก็บบันทึกอารมณ์ทั้งหมด (สำหรับแสดงใน Home)
  final List<Map<String, dynamic>> _reasonEntries = [];

  @override
  void initState() {
    super.initState();

    // ✅ โหลดข้อมูลจาก EmotionDataStore
    final store = EmotionDataStore();
    final allEntries = store.getAllEntries();
    _reasonEntries.addAll(allEntries);

    // ✅ ตั้ง Timer สำหรับสลับหน้าอีโมจิ
    _timer = Timer.periodic(_togglePeriod, (_) {
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
    _timer?.cancel();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      // ✅ เมื่อกดเมนู “วิเคราะห์”
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AnalystPage()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  /// ✅ Flow: Home → SelectPage2 → ReasonPage2 → กลับมาบันทึก
  Future<void> _openReasonPage(EmotionType type) async {
    Widget selectPage;
    switch (type) {
      case EmotionType.good:
        selectPage = const EmojiSelectGoodPage2();
        break;
      case EmotionType.neutral:
        selectPage = const EmojiSelectNeutralPage2();
        break;
      case EmotionType.bad:
        selectPage = const EmojiSelectBadPage2();
        break;
    }

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => selectPage,
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
              child: SlideTransition(position: slide, child: child));
        },
      ),
    );

    if (result != null && (result['text']?.trim().isNotEmpty ?? false)) {
      final entry = {
        'text': result['text'].trim(),
        'emotion': type,
        'subEmotion': result['subEmotion'] ?? '',
        'time': TimeOfDay.now(),
      };

      setState(() {
        _reasonEntries.insert(0, entry);
      });

      // ✅ บันทึกเข้า EmotionDataStore
      EmotionDataStore().addEntry(
        text: entry['text'],
        emotion: entry['emotion'],
        subEmotion: entry['subEmotion'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const plusWidth = 24.0;

    return Scaffold(
      backgroundColor: widget.background,
      appBar: AppBar(
        backgroundColor: widget.background,
        elevation: 0,
        title: Text(
          'บันทึกอารมณ์ของคุณ',
          style: GoogleFonts.poppins(
            color: const Color(0xFF90DAF4),
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            color: const Color(0xFF2C2C2C),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onSelected: (value) async {
              if (value == 'logout') {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              } else if (value == 'clear') {
                EmotionDataStore().clearAll();
                setState(() => _reasonEntries.clear());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("ล้างข้อมูลอารมณ์ทั้งหมดแล้ว"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text(
                      "ล้างข้อมูลทั้งหมด",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white),
                    SizedBox(width: 10),
                    Text("ออกจากระบบ",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // ✅ เขียวด้านบน
              GestureDetector(
                onTap: () => _openReasonPage(EmotionType.good),
                child: Transform.translate(
                  offset: Offset(0, widget.greenOffset),
                  child: _EmojiAutoToggle(
                    isSecond: _gSecond,
                    firstAsset: 'assets/icons/First_Green.png',
                    secondAsset: 'assets/icons/First_Green2.png',
                    size: widget.greenSize,
                    duration: _switchDuration,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ เหลือง + แดง
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final centerX = w / 2;
                  final yellowTop = widget.yellowOffset;
                  final redTop = widget.redOffset;
                  final yellowLeft = centerX -
                      widget.smallSize -
                      widget.spacing -
                      (plusWidth / 2);
                  final redLeft =
                      centerX + widget.spacing + (plusWidth / 2);
                  final plusTop = ((yellowTop + redTop) / 2.65) +
                      (widget.smallSize / 2) -
                      12 +
                      widget.plusYOffset;
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
                        Positioned(
                          top: yellowTop,
                          left: yellowLeft,
                          child: GestureDetector(
                            onTap: () =>
                                _openReasonPage(EmotionType.neutral),
                            child: _EmojiAutoToggle(
                              isSecond: _ySecond,
                              firstAsset: 'assets/icons/First_Yellow.png',
                              secondAsset: 'assets/icons/First_Yellow2.png',
                              size: widget.smallSize,
                              duration: _switchDuration,
                            ),
                          ),
                        ),
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
                        Positioned(
                          top: redTop,
                          left: redLeft,
                          child: GestureDetector(
                            onTap: () => _openReasonPage(EmotionType.bad),
                            child: _EmojiAutoToggle(
                              isSecond: _rSecond,
                              firstAsset: 'assets/icons/First_Red.png',
                              secondAsset: 'assets/icons/First_Red2.png',
                              size: widget.smallSize,
                              duration: _switchDuration,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 18),

              // ✅ Color Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AspectRatio(
                  aspectRatio: 6.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset('assets/icons/Color_Bar.png',
                        fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ✅ แสดงรายการอารมณ์ทั้งหมด
              if (_reasonEntries.isNotEmpty)
                Column(
                  children: _reasonEntries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: _ReasonCard(
                        text: e['text'],
                        emotion: e['emotion'],
                        subEmotion: e['subEmotion'] ?? '',
                        time: e['time'],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 0),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  const _ReasonCard({
    required this.text,
    required this.emotion,
    required this.subEmotion,
    required this.time,
  });

  final String text;
  final EmotionType emotion;
  final String subEmotion;
  final TimeOfDay time;

  @override
  Widget build(BuildContext context) {
    String icon = 'assets/icons/First_Green2.png';
    Color tint = const Color(0xFFA8F4B6);

    switch (emotion) {
      case EmotionType.good:
        icon = 'assets/icons/First_Green2.png';
        tint = const Color(0xFFA8F4B6);
        break;
      case EmotionType.neutral:
        icon = 'assets/icons/First_Yellow2.png';
        tint = const Color(0xFFF6E889);
        break;
      case EmotionType.bad:
        icon = 'assets/icons/First_Red2.png';
        tint = const Color(0xFFFF9A9A);
        break;
    }

    final timeText =
        '${time.hour}:${time.minute.toString().padLeft(2, "0")} น.';

    return Container(
      decoration: BoxDecoration(
        color: tint.withOpacity(0.35),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(icon, width: 56, height: 56),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'คุณรู้สึก $subEmotion',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      timeText,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
  });

  final bool isSecond;
  final String firstAsset;
  final String secondAsset;
  final double size;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final img = AnimatedSwitcher(
      duration: duration,
      switchInCurve: Curves.easeOutQuad,
      switchOutCurve: Curves.easeInQuad,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        );
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

    return SizedBox(width: size, height: size, child: img);
  }
}
