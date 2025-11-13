import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ เพิ่มสำหรับเปิดลิงก์

import 'emotion_data_store.dart';
import 'home_page.dart'; // เพื่อใช้ EmotionType
import 'bottom_nav_bar.dart';

class AnalystPage extends StatefulWidget {
  const AnalystPage({super.key});

  @override
  State<AnalystPage> createState() => _AnalystPageState();
}

class _AnalystPageState extends State<AnalystPage> {
  late Timer _timer;
  bool _greenSecond = false;
  bool _yellowSecond = false;
  bool _redSecond = false;
  PeriodType _selectedPeriod = PeriodType.today;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      setState(() {
        _greenSecond = !_greenSecond;
        _yellowSecond = !_yellowSecond;
        _redSecond = !_redSecond;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // ✅ ฟังก์ชันเปิดเว็บไซต์
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'ไม่สามารถเปิดลิงก์: $url';
    }
  }

  String _getEmotionText(EmotionType type) {
    switch (type) {
      case EmotionType.good:
        return "ดี";
      case EmotionType.neutral:
        return "เบื่อ";
      case EmotionType.bad:
        return "โกรธ";
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

  @override
  Widget build(BuildContext context) {
    final store = EmotionDataStore();
    final counts = store.getEmotionCountsForPeriod(_selectedPeriod);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final dominant = store.getDominantEmotionForPeriod(_selectedPeriod);

    EmotionType? most;
    EmotionType? least;
    if (total > 0) {
      most = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
      least = counts.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
    }

    double _emojiSize(EmotionType type) {
      if (total == 0) return 80;
      final ratio = (counts[type] ?? 1) / total;
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

                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white70),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<PeriodType>(
                        value: _selectedPeriod,
                        dropdownColor: const Color(0xFF212121),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white),
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
                        onChanged: (val) =>
                            setState(() => _selectedPeriod = val!),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 🏺 ถ้วย + อิโมจิ
                SizedBox(
                  height: 230,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CustomPaint(
                        size: const Size(double.infinity, 220),
                        painter: _CupBackgroundPainter(),
                      ),
                      if (counts.isNotEmpty) ...[
                        Positioned(
                          bottom: 35,
                          left: 60,
                          child: _AnimatedEmoji(
                            asset: _getEmojiAsset(EmotionType.bad, _redSecond),
                            size: _emojiSize(EmotionType.bad),
                          ),
                        ),
                        Positioned(
                          bottom: 35,
                          right: 60,
                          child: _AnimatedEmoji(
                            asset:
                                _getEmojiAsset(EmotionType.good, _greenSecond),
                            size: _emojiSize(EmotionType.good),
                          ),
                        ),
                        Positioned(
                          bottom: 25,
                          child: _AnimatedEmoji(
                            asset: _getEmojiAsset(
                                EmotionType.neutral, _yellowSecond),
                            size: _emojiSize(EmotionType.neutral),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ✅ ข้อความซ้ายขวา
                if (most != null || least != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (most != null)
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: "คุณ\n"),
                                TextSpan(
                                  text: _getEmotionText(most),
                                  style: TextStyle(
                                    color: _getEmotionColor(most),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(text: "\nมากที่สุด"),
                              ],
                            ),
                          ),
                        if (least != null)
                          RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                              children: [
                                const TextSpan(text: "คุณ\n"),
                                TextSpan(
                                  text: _getEmotionText(least),
                                  style: TextStyle(
                                    color: _getEmotionColor(least),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(text: "\nน้อยที่สุด"),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // ✅ ข้อความสรุป + เงื่อนไขลิงก์
                if (dominant != null)
                  Column(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
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
                                      "${_getPeriodLabel(_selectedPeriod)}อารมณ์ของคุณอยู่ในเกณฑ์ "),
                              TextSpan(
                                text: _getEmotionText(dominant),
                                style: TextStyle(
                                  color: _getEmotionColor(dominant),
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🟠 แสดงลิงก์เฉพาะ "เดือนนี้" + "อารมณ์แย่"
                      if (_selectedPeriod == PeriodType.month &&
                          dominant == EmotionType.bad)
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
                                      horizontal: 18, vertical: 8),
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

                const SizedBox(height: 10),

                // ✅ แถบ Bar Chart
                if (total > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: counts.entries.map((e) {
                      final ratio =
                          total == 0 ? 0.0 : (e.value / total).clamp(0.0, 1.0);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Image.asset(
                              _getEmojiAsset(e.key, true),
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 70,
                              child: Text(
                                _getEmotionText(e.key),
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
                                        color: _getBarColor(e.key),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              e.value.toString(),
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

class _CupBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final path = Path();
    path.moveTo(20, 20);
    path.lineTo(20, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 30,
      size.width - 20,
      size.height - 40,
    );
    path.lineTo(size.width - 20, 20);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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
