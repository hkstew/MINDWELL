import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'home_page.dart';
import 'emotion_data_store.dart';

class EmotionDetailPage extends StatefulWidget {
  const EmotionDetailPage({
    super.key,
    required this.text,
    required this.emotion,
    required this.subEmotion,
    required this.dateTime,
  });

  final String text;
  final EmotionType emotion;
  final String subEmotion;
  final DateTime dateTime;

  @override
  State<EmotionDetailPage> createState() => _EmotionDetailPageState();
}

class _EmotionDetailPageState extends State<EmotionDetailPage> {
  late DateTime _currentDateTime;
  late String _currentText;

  @override
  void initState() {
    super.initState();
    _currentDateTime = widget.dateTime;
    _currentText = widget.text;

    initializeDateFormatting("th_TH", null);
  }

  // -----------------------------
  // บันทึกการแก้ไขกลับเข้า Hive
  // -----------------------------
  Future<void> _saveEditedEntry() async {
    final store = EmotionDataStore();

    // ลบอันเก่าออกก่อน
    await store.deleteEntry(
      EmotionEntry(
        text: widget.text,
        emotion: widget.emotion,
        subEmotion: widget.subEmotion,
        dateTime: widget.dateTime,
      ),
    );

    // เพิ่มอันใหม่ที่แก้ไขแล้ว
    await store.addEntry(
      text: _currentText,
      emotion: widget.emotion,
      subEmotion: widget.subEmotion,
      dateTime: _currentDateTime,
    );
  }

  // -----------------------------
  // สีพื้นหลังตามอารมณ์
  // -----------------------------
  Color _getBackgroundColor() {
    switch (widget.emotion) {
      case EmotionType.good:
        return const Color(0xFF4F8350);
      case EmotionType.neutral:
        return const Color(0xFF8A7A3F);
      case EmotionType.bad:
        return const Color(0xFF7A2E2E);
    }
  }

  // -----------------------------
  // แก้ไขข้อความ
  // -----------------------------
  Future<void> _editText() async {
    final controller = TextEditingController(text: _currentText);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("แก้ไขข้อความ"),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text("บันทึก"),
            ),
          ],
        );
      },
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _currentText = result);
    }
  }

  // -----------------------------
  // แก้ไขวันที่ / เวลา
  // -----------------------------
  Future<void> _editDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _currentDateTime,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      locale: const Locale("th", "TH"),
    );

    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_currentDateTime),
    );

    if (time == null) return;

    setState(() {
      _currentDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  // -----------------------------
  // Format Thai
  // -----------------------------
  String _formatDateTime(DateTime dt) {
    final d = DateFormat("d MMM yy", "th_TH").format(dt);
    final t = DateFormat("HH:mm", "th_TH").format(dt);
    return "$d   $t น.";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: SafeArea(
        child: Stack(
          children: [
            // ------------------------------------
            // ปุ่ม Back (บันทึกก่อน pop)
            // ------------------------------------
            Positioned(
              top: 14,
              left: 14,
              child: GestureDetector(
                onTap: () async {
                  await _saveEditedEntry();
                  if (!mounted) return;
                  Navigator.pop(context, true);
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.arrow_back, size: 24),
                ),
              ),
            ),

            // ------------------------------------
            // ปุ่มแก้ไขข้อความ & วันที่
            // ------------------------------------
            Positioned(
              top: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _editText,
                    child: Text(
                      "แก้ไขข้อความ",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _editDateTime,
                    child: Text(
                      "เปลี่ยนวันที่",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ------------------------------------
            // ข้อความตรงกลางจอ
            // ------------------------------------
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _currentText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),

            // ------------------------------------
            // วันที่/เวลา
            // ------------------------------------
            Positioned(
              bottom: 20,
              right: 20,
              child: Text(
                _formatDateTime(_currentDateTime),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
