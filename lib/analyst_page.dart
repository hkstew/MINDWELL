import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:math' as Math;

import 'emotion_data_store.dart';
import 'home_page.dart'; // ใช้ EmotionType
import 'bottom_nav_bar.dart';

class AnalystPage extends StatefulWidget {
  const AnalystPage({super.key});

  @override
  State<AnalystPage> createState() => _AnalystPageState();
}

// ---------------------------------------------------------------------------
// BUBBLE MODEL
// ---------------------------------------------------------------------------
class _Bubble {
  Offset pos;
  double size;
  final String subEmotion;

  _Bubble(this.pos, this.size, this.subEmotion);
}

// ---------------------------------------------------------------------------
// BUBBLE PHYSICS LAYOUT (แบบเกมผลไม้)
// ---------------------------------------------------------------------------
List<_Bubble> layoutBubblesInCup(List<_Bubble> bubbles, Size cupSize) {
  const double padding = 12;

  // 1) วางแบบสุ่มในก้นถ้วยก่อน
  for (var b in bubbles) {
    b.pos = Offset(
      cupSize.width * (0.3 + (0.4 * (b.size % 100) / 100)),
      cupSize.height - (b.size * 0.6),
    );
  }

  // 2) ดันไม่ให้ทับกัน
  for (int iter = 0; iter < 40; iter++) {
    for (int i = 0; i < bubbles.length; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        final a = bubbles[i];
        final b = bubbles[j];

        final dx = b.pos.dx - a.pos.dx;
        final dy = b.pos.dy - a.pos.dy;

        final dist = (dx * dx + dy * dy).sqrt();
        final minDist = (a.size / 2) + (b.size / 2) - 4;

        if (dist < minDist) {
          final d = dist == 0 ? 1 : dist;
          final overlap = (minDist - d) / 2;

          final nx = dx / d;
          final ny = dy / d;

          a.pos = Offset(a.pos.dx - nx * overlap, a.pos.dy - ny * overlap);
          b.pos = Offset(b.pos.dx + nx * overlap, b.pos.dy + ny * overlap);
        }
      }
    }
  }

  // 3) ดันไม่ให้ทะลุผนังถ้วย
  for (var b in bubbles) {
    final left = b.size / 2 + padding;
    final right = cupSize.width - b.size / 2 - padding;

    if (b.pos.dx < left) b.pos = Offset(left, b.pos.dy);
    if (b.pos.dx > right) b.pos = Offset(right, b.pos.dy);

    if (b.pos.dy > cupSize.height - b.size / 2 - padding) {
      b.pos = Offset(b.pos.dx, cupSize.height - b.size / 2 - padding);
    }
  }

  return bubbles;
}

// ให้ Dart ใช้ sqrt() ได้
extension _DoubleSqrt on double {
  double sqrt() => Math.sqrt(this);
}

class BubbleItem {
  final _SubEmotionCount item;
  Offset pos;
  double size;

  BubbleItem({required this.item, required this.pos, required this.size});
}

class _SubEmotionCount {
  final String name;
  final int count;
  int get originalCount => count;
  _SubEmotionCount(this.name, this.count);
}

class _AnalystPageState extends State<AnalystPage> {
  late Timer _timer;
  bool _greenSecond = false;
  bool _yellowSecond = false;
  bool _redSecond = false;

  PeriodType _selectedPeriod = PeriodType.today;

  /// แปลง EmotionEntry ทั้งหมดเป็นกลุ่มอิโมจิตาม subEmotion
  Map<String, int> _countSubEmotions(List<EmotionEntry> entries) {
    final map = <String, int>{};

    for (var e in entries) {
      final key = e.subEmotion.trim();
      if (key.isEmpty) continue;

      map[key] = (map[key] ?? 0) + 1;
    }

    return map;
  }

  /// คืนค่า emoji icon ตาม subEmotion
  String _subEmojiAsset(String subEmotion) {
    switch (subEmotion.trim()) {
      // 🌿 เขียว
      case 'ดีใจ':
        return 'assets/icons/First_Green2.png';
      case 'ผ่อนคลาย':
        return 'assets/icons/First_Green3.png';
      case 'อารมณ์ดี':
        return 'assets/icons/First_Green.png';

      // 🌼 เหลือง
      case 'เบื่อ':
        return 'assets/icons/First_Yellow.png';
      case 'สับสน':
        return 'assets/icons/First_Yellow3.png';
      case 'เหนื่อย':
        return 'assets/icons/First_Yellow2.png';

      // 🔥 แดง
      case 'เศร้า':
        return 'assets/icons/First_Red2.png';
      case 'กังวล':
        return 'assets/icons/First_Red3.png';

      // รูปแบบชื่อโกรธ/เครียด ที่ผู้ใช้กรอกอาจไม่เหมือนกัน
      case 'โกรธ / เครียด':
      case 'โกรธ/เครียด':
      case 'โกรธ_เครียด':
        return 'assets/icons/First_Red.png';
    }

    // DEFAULT ถ้าไม่ตรงอะไรเลย
    return 'assets/icons/First_Green.png';
  }

  /// ขนาดอิโมจิ (large = max count, small = min count)
  double _scaleSize(int count, int maxCount, int minCount) {
    if (maxCount == minCount) return 56; // ถ้าจำนวนเท่ากันหมด ให้ขนาดเท่ากัน

    final minSize = 44.0;
    final maxSize = 66.0;

    return minSize +
        ((count - minCount) / (maxCount - minCount)) * (maxSize - minSize);
  }

  Widget bubbleCupWidget(List<_SubEmotionCount> items) {
    if (items.isEmpty) return const SizedBox(height: 260);

    // จำกัดสูงสุด 9 bubble
    final maxItems = items.length > 9 ? 9 : items.length;

    // แปลงเป็น bubble + คำนวณขนาด
    List<_Bubble> bubbles = items.take(maxItems).map((e) {
      final size = 28 + (e.count * 12).toDouble();
      return _Bubble(Offset.zero, size, e.name);
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cupWidth = constraints.maxWidth;
        const double cupHeight = 300;

        // รวมความกว้างทั้งหมด
        final totalWidth = bubbles.fold<double>(
          0,
          (sum, b) => sum + b.size + 10,
        );

        // ถ้ากว้างเกินแก้ว → scale ลงทั้งหมด
        final scale = totalWidth > cupWidth * 0.78
            ? (cupWidth * 1) / totalWidth
            : 1.0;

        // แยกเป็น 1 หรือ 2 แถว
        List<_Bubble> row1 = [];
        List<_Bubble> row2 = [];

        if (bubbles.length <= 4) {
          row1 = bubbles;
        } else {
          final mid = (bubbles.length / 2).ceil();
          row1 = bubbles.sublist(0, mid);
          row2 = bubbles.sublist(mid);
        }

        List<Widget> buildRow(List<_Bubble> row) {
          return row
              .map(
                (b) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 1,
                  ), //ความห่างอิโมจิ
                  child: Image.asset(
                    _subEmojiAsset(b.subEmotion),
                    width: b.size * scale,
                    height: b.size * scale,
                  ),
                ),
              )
              .toList();
        }

        return SizedBox(
          width: cupWidth,
          height: cupHeight,
          child: Stack(
            children: [
              // วาดถ้วย
              CustomPaint(
                size: Size(cupWidth, cupHeight),
                painter: _CupBackgroundPainter(),
              ),

              // วางเป็น 1–2 แถว
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const SizedBox(height: 60), // ← ยกอิโมจิขึ้นจากก้นแก้ว
                      if (row2.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: buildRow(row2),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: buildRow(row1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // --------------------------------------------------
  // เปิดลิงก์ (วัดใจ.com)
  // --------------------------------------------------
  Future<void> _launchURL(String url) async {
    try {
      final uri = Uri(
        scheme: "https",
        host: "xn--82cx0dxb9e.com", // วัดใจ.com -> punycode
        path: "",
      );

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw "cannot launch";
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("เปิดลิงก์ไม่สำเร็จ")));
    }
  }

  // --------------------------------------------------
  // แปลง EmotionType ⇒ ข้อความสรุป (ใช้สำหรับข้อความด้านบน)
  // --------------------------------------------------
  String _getEmotionText(EmotionType type) {
    // ใช้ชื่อแบบเดิมของคุณเป็น “ชื่อกลุ่มอารมณ์”
    switch (type) {
      case EmotionType.good:
        return "ดีใจ";
      case EmotionType.neutral:
        return "เบื่อ";
      case EmotionType.bad:
        return "โกรธ / เครียด";
    }
  }

  String _getPeriodLabel(PeriodType type) {
    switch (type) {
      case PeriodType.today:
        return "วันนี้";
      case PeriodType.week:
        return "สัปดาห์นี้";
      case PeriodType.month:
        return "เดือนนี้";
    }
  }

  Color _getBarColor(EmotionType type) {
    switch (type) {
      case EmotionType.good:
        return const Color(0xFF7BFF85);
      case EmotionType.neutral:
        return const Color(0xFFF6E889);
      case EmotionType.bad:
        return const Color(0xFFFF7B7B);
    }
  }

  Color _getEmotionColor(EmotionType type) {
    switch (type) {
      case EmotionType.good:
        return const Color(0xFF7BFF85);
      case EmotionType.neutral:
        return const Color(0xFFF6E889);
      case EmotionType.bad:
        return const Color(0xFFFF7B7B);
    }
  }

  /// อิโมจิแบบ “ไอคอนกลุ่มสี” สำหรับตรงถ้วย
  String _getEmojiAsset(EmotionType type, bool second) {
    switch (type) {
      case EmotionType.good:
        return second
            ? 'assets/icons/Sec_Green.png'
            : 'assets/icons/First_Green.png';
      case EmotionType.neutral:
        return second
            ? 'assets/icons/Sec_Yellow.png'
            : 'assets/icons/First_Yellow.png';
      case EmotionType.bad:
        return second
            ? 'assets/icons/Sec_Red.png'
            : 'assets/icons/First_Red.png';
    }
  }

  // --------------------------------------------------
  // ✅ อิโมจิของ “อารมณ์ย่อย” (ใช้กับ Bar chart)
  //   subEmotionName ต้องตรงกับที่บันทึกจากหน้า reason
  // --------------------------------------------------
  String _getSubEmotionEmojiAsset(String name, EmotionType type) {
    switch (name) {
      // เขียว
      case 'ดีใจ':
        return 'assets/icons/First_Green2.png';
      case 'ผ่อนคลาย':
        return 'assets/icons/First_Green3.png';
      case 'อารมณ์ดี':
        return 'assets/icons/First_Green.png';

      // เหลือง
      case 'เบื่อ':
        return 'assets/icons/First_Yellow.png';
      case 'สับสน':
        return 'assets/icons/First_Yellow3.png';
      case 'เหนื่อย':
        return 'assets/icons/First_Yellow2.png';

      // แดง
      case 'เศร้า':
        return 'assets/icons/First_Red2.png';
      case 'กังวล':
        return 'assets/icons/First_Red3.png';
      case 'โกรธ / เครียด':
      case 'โกรธ/เครียด':
      case 'โกรธ_เครียด':
        return 'assets/icons/First_Red.png';
    }

    // ถ้าหาไม่เจอ ให้ fallback เป็นไอคอนกลุ่มสีเดิม
    return _getEmojiAsset(type, true);
  }

  // --------------------------------------------------
  // กรองช่วงเวลา (วันนี้ / สัปดาห์ / เดือน)
  // --------------------------------------------------
  bool _isInSelectedPeriod(DateTime dt, PeriodType period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);

    switch (period) {
      case PeriodType.today:
        return target == today;

      case PeriodType.week:
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return target.isAtSameMomentAs(startOfWeek) ||
            target.isAtSameMomentAs(endOfWeek) ||
            (target.isAfter(startOfWeek) && target.isBefore(endOfWeek));

      case PeriodType.month:
        return dt.year == now.year && dt.month == now.month;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = EmotionDataStore();
    final allEntries = store.getAllEntries();

    // 1) กรองช่วงเวลาที่เลือก
    final periodEntries = allEntries
        .where((e) => _isInSelectedPeriod(e.dateTime, _selectedPeriod))
        .toList();

    // 2) นับอารมณ์ย่อยในช่วงเวลานั้น
    final subCounts = _countSubEmotions(periodEntries);

    // 3) แปลงเป็น list<_SubEmotionCount>
    final subItems = subCounts.entries
        .map((e) => _SubEmotionCount(e.key, e.value))
        .toList();

    // ---------------------------------------------------------
    // 2) รวมกลุ่มตาม "อารมณ์ย่อย" เพื่อใช้ใน Bar chart
    //    key = subEmotion (String)
    // ---------------------------------------------------------
    final Map<String, _SubEmotionStat> subStats = {};
    final Map<EmotionType, int> typeCounts = {
      EmotionType.good: 0,
      EmotionType.neutral: 0,
      EmotionType.bad: 0,
    };

    for (final entry in periodEntries) {
      final sub = (entry.subEmotion ?? '').toString().trim();
      if (sub.isEmpty) continue;

      // นับจำนวนตามกลุ่มสี เพื่อใช้สรุป + ถ้วย
      typeCounts[entry.emotion] = (typeCounts[entry.emotion] ?? 0) + 1;

      if (!subStats.containsKey(sub)) {
        subStats[sub] = _SubEmotionStat(
          name: sub,
          type: entry.emotion,
          count: 1,
        );
      } else {
        subStats[sub]!.count += 1;
      }
    }

    final List<_SubEmotionStat> subEmotionList = subStats.values.toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    final int totalSubCount = subEmotionList.fold<int>(
      0,
      (sum, s) => sum + s.count,
    );

    // ---------------------------------------------------------
    // 3) หาอารมณ์หลักระดับ "กลุ่มสี" เพื่อใช้ข้อความสรุป/ถ้วย
    // ---------------------------------------------------------
    final int totalTypeCount = typeCounts.values.fold<int>(0, (a, b) => a + b);

    EmotionType? dominantType;
    EmotionType? mostType;
    EmotionType? leastType;

    final List<_SubEmotionStat> sortedSubs = List.from(subEmotionList)
      ..sort((a, b) => b.count.compareTo(a.count));

    _SubEmotionStat? mostSub;
    _SubEmotionStat? leastSub;

    if (sortedSubs.isNotEmpty) {
      mostSub = sortedSubs.first;

      // หาอันที่น้อยที่สุด แต่ต้องเป็นอารมณ์ที่มี count > 0 จริง ๆ
      final nonZeroSubs = sortedSubs.where((s) => s.count > 0).toList();
      if (nonZeroSubs.isNotEmpty) {
        leastSub = nonZeroSubs.last;
      }
    }

    if (totalTypeCount > 0) {
      // Dominant = อารมณ์ที่มากที่สุด
      dominantType = typeCounts.entries
          .where((e) => e.value > 0)
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;

      mostType = dominantType;

      // น้อยที่สุด (ที่มีอย่างน้อย 1)
      final nonZero = typeCounts.entries.where((e) => e.value > 0).toList();
      if (nonZero.isNotEmpty) {
        leastType = nonZero.reduce((a, b) => a.value <= b.value ? a : b).key;
      }
    }

    double _emojiSize(EmotionType type) {
      if (totalTypeCount == 0) return 80;
      final ratio = (typeCounts[type] ?? 1) / totalTypeCount;
      return 70 + (ratio * 70);
    }

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            child: Column(
              children: [
                Text(
                  'วิเคราะห์อารมณ์ของคุณ',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),

                // ----------------- Dropdown ช่วงเวลา -----------------
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white70),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PeriodType>(
                        value: _selectedPeriod,
                        dropdownColor: const Color(0xFF212121),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          color: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PeriodType.today,
                            child: Text("วันนี้"),
                          ),
                          DropdownMenuItem(
                            value: PeriodType.week,
                            child: Text("สัปดาห์นี้"),
                          ),
                          DropdownMenuItem(
                            value: PeriodType.month,
                            child: Text("เดือนนี้"),
                          ),
                        ],
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() {
                            _selectedPeriod = val;
                          });
                        },
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ----------------- ถ้วย + อิโมจิ -----------------
                SizedBox(
                  height: 280,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 300),
                        painter: _CupBackgroundPainter(),
                      ),

                      // 👉 พีรามิดอารมณ์
                      bubbleCupWidget(subItems),
                    ],
                  ),
                ),

                // ----------------- ข้อความมากที่สุด / น้อยที่สุด -----------------
                if (mostSub != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // ⭐ มากที่สุด
                        Column(
                          children: [
                            Text(
                              "คุณ",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),

                            // subEmoji
                            Image.asset(
                              _getSubEmotionEmojiAsset(
                                mostSub!.name,
                                mostSub!.type,
                              ),
                              width: 40,
                              height: 40,
                            ),
                            const SizedBox(height: 2),

                            Text(
                              mostSub!.name,
                              style: GoogleFonts.poppins(
                                color: _getEmotionColor(mostSub!.type),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),

                            Text(
                              "มากที่สุด",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),

                        // ⭐ น้อยที่สุด (แสดงเฉพาะถ้ามีมากกว่า 1 อารมณ์)
                        if (leastSub != null && sortedSubs.length > 1)
                          Column(
                            children: [
                              Text(
                                "คุณ",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),

                              Image.asset(
                                _getSubEmotionEmojiAsset(
                                  leastSub!.name,
                                  leastSub!.type,
                                ),
                                width: 40,
                                height: 40,
                              ),
                              const SizedBox(height: 2),

                              Text(
                                leastSub!.name,
                                style: GoogleFonts.poppins(
                                  color: _getEmotionColor(leastSub!.type),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 2),

                              Text(
                                "น้อยที่สุด",
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // ----------------- ข้อความสรุป + ลิงก์ -----------------
                if (dominantType != null)
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF212121),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    "${_getPeriodLabel(_selectedPeriod)}อารมณ์ของคุณอยู่ในเกณฑ์ ",
                              ),
                              TextSpan(
                                text: _getEmotionText(dominantType),
                                style: TextStyle(
                                  color: _getEmotionColor(dominantType),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if ((_selectedPeriod == PeriodType.week ||
                              _selectedPeriod == PeriodType.month) &&
                          dominantType == EmotionType.bad)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            children: [
                              Text(
                                "เราแนะนำให้คุณทำ",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  _launchURL("https://วัดใจ.com");
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(
                                    "วัดใจ.com",
                                    style: GoogleFonts.poppins(
                                      color: Colors.greenAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                const SizedBox(height: 16),

                // ----------------- Bar Chart ตาม "อารมณ์ย่อย" -----------------
                if (totalSubCount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: subEmotionList.map((s) {
                      final ratio = totalSubCount == 0
                          ? 0.0
                          : (s.count / totalSubCount).clamp(0.0, 1.0);
                      final emojiAsset = _getSubEmotionEmojiAsset(
                        s.name,
                        s.type,
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Image.asset(emojiAsset, width: 26, height: 26),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 90,
                              child: Text(
                                s.name,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Stack(
                                children: [
                                  Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: ratio,
                                    child: Container(
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: _getBarColor(s.type),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              s.count.toString(),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 1),
    );
  }
}

// --------------------------------------------------
// Model เล็ก ๆ สำหรับเก็บสถิติอารมณ์ย่อย
// --------------------------------------------------
class _SubEmotionStat {
  final String name;
  final EmotionType type;
  int count;

  _SubEmotionStat({
    required this.name,
    required this.type,
    required this.count,
  });
}

// --------------------------------------------------
// วาดถ้วย
// --------------------------------------------------
class _CupBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();

    path.moveTo(40, 20);
    path.lineTo(40, size.height - 60);

    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width - 40,
      size.height - 60,
    );

    path.lineTo(size.width - 40, 20);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// --------------------------------------------------
// อนิเมตอิโมจิบนถ้วย
// --------------------------------------------------
class _AnimatedEmoji extends StatelessWidget {
  final String asset;
  final double size;
  const _AnimatedEmoji({required this.asset, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: Image.asset(
        asset,
        key: ValueKey(asset),
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
