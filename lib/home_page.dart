import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_links/app_links.dart';

import 'emoji_select_good_page2.dart';
import 'emoji_select_neutral_page2.dart';
import 'emoji_select_bad_page2.dart';

import 'emotion_data_store.dart';
import 'analyst_page.dart';
import 'bottom_nav_bar.dart';
import 'emotion_detail_page.dart';

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

  @override
  State<HomePage> createState() => _HomePageState();

  final Color background;
  final double greenSize;
  final double smallSize;
  final double spacing;
  final double plusFontSize;
  final double plusYOffset;
  final double greenOffset;
  final double yellowOffset;
  final double redOffset;
}

class _HomePageState extends State<HomePage> {
  bool _gSecond = false;
  bool _ySecond = false;
  bool _rSecond = false;
  Timer? _timer;

  static const _togglePeriod = Duration(milliseconds: 1900);
  static const _switchDuration = Duration(milliseconds: 1200);

  final List<EmotionEntry> _reasonEntries = [];

  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _reloadEntries();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      handleWidgetLaunch(context);
    });

    _timer = Timer.periodic(_togglePeriod, (_) {
      if (!mounted) return;
      setState(() {
        _gSecond = !_gSecond;
        _ySecond = !_ySecond;
        _rSecond = !_rSecond;
      });
    });
  }

  void handleWidgetLaunch(BuildContext ctx) async {
    try {
      _appLinks = AppLinks();

      // 👉 ดึง initial link (เปิดแอปครั้งแรก)
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(ctx, initial);
      }

      // 👉 ดักเมื่อเปิดแอปจาก widget ตอนที่แอปกำลังรันอยู่
      _appLinks.uriLinkStream.listen((uri) {
        _handleUri(ctx, uri);
      });
    } catch (e) {
      debugPrint("AppLinks error: $e");
    }
  }

  void _handleUri(BuildContext ctx, Uri uri) {
    debugPrint("URI => $uri");

    if (uri.queryParameters['openPage'] == 'analyst') {
      Navigator.push(
        ctx,
        MaterialPageRoute(builder: (_) => const AnalystPage()),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// โหลดข้อมูลจาก Hive
  void _reloadEntries() {
    final store = EmotionDataStore();
    final list = store.getAllEntries();

    setState(() {
      _reasonEntries
        ..clear()
        ..addAll(list);
    });
  }

  // เปิดหน้าเลือกอีโมจิ → reason → save
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
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      ),
    );

    if (result != null) {
      final rawDt = result['dateTime'] ?? result['datetime'] ?? DateTime.now();
      final DateTime dateTime = rawDt is DateTime ? rawDt : DateTime.now();

      await EmotionDataStore().addEntry(
        text: (result['text'] ?? '').trim(),
        emotion: type,
        subEmotion: (result['subEmotion'] ?? '').toString(),
        dateTime: dateTime,
      );

      _reloadEntries();
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
                await EmotionDataStore().clearAll();
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
                    Text("ออกจากระบบ", style: TextStyle(color: Colors.white)),
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

              GestureDetector(
                onTap: () => _openReasonPage(EmotionType.good),
                child: _EmojiAutoToggle(
                  isSecond: _gSecond,
                  firstAsset: 'assets/icons/First_Green.png',
                  secondAsset: 'assets/icons/Sec_Green.png',
                  size: 150,
                  duration: _switchDuration,
                ),
              ),

              const SizedBox(height: 12),

              /// Yellow + Red
              LayoutBuilder(
                builder: (_, constraints) {
                  final w = constraints.maxWidth;
                  final centerX = w / 1.9;

                  final yellowLeft =
                      centerX -
                      widget.smallSize -
                      widget.spacing -
                      (plusWidth / 2);
                  final redLeft = centerX + widget.spacing + (plusWidth / 9);

                  return SizedBox(
                    height: widget.smallSize + 40,
                    child: Stack(
                      children: [
                        Positioned(
                          left: yellowLeft,
                          child: GestureDetector(
                            onTap: () => _openReasonPage(EmotionType.neutral),
                            child: _EmojiAutoToggle(
                              isSecond: _ySecond,
                              firstAsset: 'assets/icons/First_Yellow.png',
                              secondAsset: 'assets/icons/First_Yellow2.png',
                              size: 150,
                              duration: _switchDuration,
                            ),
                          ),
                        ),
                        Positioned(
                          top: widget.smallSize / 2 - 60,
                          left: centerX - plusWidth / 1.5,
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
                          left: redLeft,
                          child: GestureDetector(
                            onTap: () => _openReasonPage(EmotionType.bad),
                            child: _EmojiAutoToggle(
                              isSecond: _rSecond,
                              firstAsset: 'assets/icons/First_Red.png',
                              secondAsset: 'assets/icons/First_Red2.png',
                              size: 150,
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

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: AspectRatio(
                  aspectRatio: 6.5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/icons/Color_Bar.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              /// ⭐ รายการทั้งหมด
              if (_reasonEntries.isNotEmpty)
                Column(
                  children: _reasonEntries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _ReasonCard(
                        entry: entry,
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: const Color(0xFF2C2C2C),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: Text(
                                'ลบรายการนี้?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              content: Text(
                                'คุณต้องการลบข้อความนี้หรือไม่?',
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text(
                                    'ยกเลิก',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text(
                                    'ลบ',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await EmotionDataStore().deleteEntry(entry);
                            _reloadEntries();
                          }
                        },
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

/// ------------------------------------------------------------
///                   REASON CARD
/// ------------------------------------------------------------
class _ReasonCard extends StatelessWidget {
  const _ReasonCard({required this.entry, required this.onDelete});

  final EmotionEntry entry;
  final VoidCallback onDelete;

  /// MAP อารมณ์ย่อย → รูปอิโมจิจริง
  String _emojiForSubEmotion(String sub) {
    final map = {
      // GOOD
      "ดีใจ": "assets/icons/First_Green2.png",
      "ผ่อนคลาย": "assets/icons/First_Green3.png",
      "อารมณ์ดี": "assets/icons/First_Green.png",

      // NEUTRAL
      "เบื่อ": "assets/icons/First_Yellow.png",
      "เหนื่อย": "assets/icons/First_Yellow3.png",
      "สับสน": "assets/icons/First_Yellow2.png",

      // BAD
      "โกรธ / เครียด": "assets/icons/First_Red.png",
      "กังวล": "assets/icons/First_Red3.png",
      "เศร้า": "assets/icons/First_Red2.png",
    };

    return map[sub] ?? "assets/icons/default.png";
  }

  @override
  Widget build(BuildContext context) {
    final emojiAsset = _emojiForSubEmotion(entry.subEmotion);

    // สีพื้นตาม emotion หลัก
    Color tint;
    switch (entry.emotion) {
      case EmotionType.good:
        tint = const Color(0xFFA8F4B6);
        break;
      case EmotionType.neutral:
        tint = const Color(0xFFF6E889);
        break;
      case EmotionType.bad:
        tint = const Color(0xFFFF9A9A);
        break;
    }

    final timeText =
        '${entry.dateTime.hour.toString().padLeft(2, "0")}:${entry.dateTime.minute.toString().padLeft(2, "0")} น.';

    return GestureDetector(
      onTap: () async {
        final updated = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => EmotionDetailPage(
              text: entry.text,
              emotion: entry.emotion,
              subEmotion: entry.subEmotion,
              dateTime: entry.dateTime,
            ),
          ),
        );

        if (updated == true) {
          (context as Element).markNeedsBuild();
        }
      },
      child: Container(
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
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    emojiAsset,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 10),

                /// TEXT BUBBLE
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 22,
                        ),
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          entry.text,
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
                            'คุณรู้สึก ${entry.subEmotion}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            timeText,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
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

            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 20,
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

/// ------------------------------------------------------------
///                  Emoji Auto Toggle
/// ------------------------------------------------------------
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
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: Curves.easeOutQuad,
        switchOutCurve: Curves.easeInQuad,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
              child: child,
            ),
          );
        },
        child: Image.asset(
          isSecond ? secondAsset : firstAsset,
          key: ValueKey(isSecond),
          width: size,
          height: size,
        ),
      ),
    );
  }
}
