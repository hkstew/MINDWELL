import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';

/// ✅ ระยะเวลาที่ใช้ดูข้อมูล
enum PeriodType { today, week, month }

/// ✅ โครงสร้างข้อมูล 1 รายการอารมณ์
class EmotionEntry {
  final String text;
  final EmotionType emotion;
  final String subEmotion;
  final TimeOfDay time;
  final DateTime date;

  EmotionEntry({
    required this.text,
    required this.emotion,
    required this.subEmotion,
    required this.time,
    required this.date,
  });

  /// 🔹 แปลงเป็น Map สำหรับเก็บใน Hive
  Map<String, dynamic> toMap() => {
        'text': text,
        'emotion': emotion.index,
        'subEmotion': subEmotion,
        'hour': time.hour,
        'minute': time.minute,
        'date': date.toIso8601String(),
      };

  /// 🔹 แปลงกลับจาก Map เป็น EmotionEntry
  factory EmotionEntry.fromMap(Map<String, dynamic> map) {
    return EmotionEntry(
      text: map['text'],
      emotion: EmotionType.values[map['emotion']],
      subEmotion: map['subEmotion'],
      time: TimeOfDay(hour: map['hour'], minute: map['minute']),
      date: DateTime.parse(map['date']),
    );
  }
}

/// ✅ ตัวจัดการข้อมูลอารมณ์ส่วนกลาง (Global Shared Store)
class EmotionDataStore {
  static final EmotionDataStore _instance = EmotionDataStore._internal();
  factory EmotionDataStore() => _instance;
  EmotionDataStore._internal();

  static late Box _box; // กล่อง Hive สำหรับเก็บข้อมูล
  static String? _userId; // 🧩 แยกตาม uid ของผู้ใช้

  /// ✅ เรียกตอนเริ่มแอป (ใน main.dart)
  static Future<void> init() async {
    await Hive.initFlutter();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'guest';
    _box = await Hive.openBox('emotionBox_$_userId'); // 👈 แยกกล่องตาม uid
  }

  /// ✅ เก็บข้อมูลในหน่วยความจำ (ใช้คู่กับ Hive)
  final Map<String, List<EmotionEntry>> _dailyEntries = {};

  /// ✅ แปลงวันที่ให้เป็น key string เช่น "2025-11-09"
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// ✅ เพิ่มข้อมูลใหม่
  Future<void> addEntry({
    required String text,
    required EmotionType emotion,
    required String subEmotion,
  }) async {
    final now = DateTime.now();
    final key = _dateKey(now);
    final entry = EmotionEntry(
      text: text,
      emotion: emotion,
      subEmotion: subEmotion,
      time: TimeOfDay.now(),
      date: now,
    );

    _dailyEntries.putIfAbsent(key, () => []);
    _dailyEntries[key]!.insert(0, entry);

    final storedList = _dailyEntries[key]!.map((e) => e.toMap()).toList();
    await _box.put(key, storedList);
  }

  /// ✅ โหลดข้อมูลจาก Hive (ทุกครั้งที่เปิดแอป)
  void loadAllData() {
    _dailyEntries.clear();
    for (var key in _box.keys) {
      final stored = _box.get(key);
      if (stored != null && stored is List) {
        _dailyEntries[key] = stored
            .map((m) => EmotionEntry.fromMap(Map<String, dynamic>.from(m)))
            .toList();
      }
    }
  }

  /// ✅ ดึงข้อมูลของ “วันนี้”
  List<EmotionEntry> getEntriesForToday() {
    final key = _dateKey(DateTime.now());
    final stored = _box.get(key);
    if (stored != null && stored is List) {
      _dailyEntries[key] = stored
          .map((m) => EmotionEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }
    return _dailyEntries[key] ?? [];
  }

  /// ✅ ดึงข้อมูลของ “สัปดาห์นี้”
  List<EmotionEntry> getEntriesForWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    loadAllData();
    return _dailyEntries.entries
        .where((e) {
          final date = DateTime.parse(e.key);
          return date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              date.isBefore(weekEnd);
        })
        .expand((e) => e.value)
        .toList();
  }

  /// ✅ ดึงข้อมูลของ “เดือนนี้”
  List<EmotionEntry> getEntriesForMonth() {
    final now = DateTime.now();
    loadAllData();
    return _dailyEntries.entries
        .where((e) {
          final date = DateTime.parse(e.key);
          return date.year == now.year && date.month == now.month;
        })
        .expand((e) => e.value)
        .toList();
  }

  /// ✅ คืนค่าสถิติรวมแต่ละอารมณ์ตามช่วงเวลา
  Map<EmotionType, int> getEmotionCountsForPeriod(PeriodType type) {
    List<EmotionEntry> entries = [];
    switch (type) {
      case PeriodType.today:
        entries = getEntriesForToday();
        break;
      case PeriodType.week:
        entries = getEntriesForWeek();
        break;
      case PeriodType.month:
        entries = getEntriesForMonth();
        break;
    }

    final counts = {
      EmotionType.good: 0,
      EmotionType.neutral: 0,
      EmotionType.bad: 0,
    };
    for (final e in entries) {
      counts[e.emotion] = (counts[e.emotion] ?? 0) + 1;
    }
    return counts;
  }

  /// ✅ คืนค่าอารมณ์หลัก (dominant) ของช่วงเวลา
  EmotionType? getDominantEmotionForPeriod(PeriodType type) {
    final counts = getEmotionCountsForPeriod(type);
    if (counts.values.every((v) => v == 0)) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  /// ✅ เคลียร์ข้อมูลของผู้ใช้คนปัจจุบันเท่านั้น
  Future<void> clearAll() async {
    _dailyEntries.clear();
    await _box.clear();
  }

  /// ✅ ดึงข้อมูลทั้งหมด (ทุกวัน)
  List<Map<String, dynamic>> getAllEntries() {
    loadAllData();
    final allEntries = _dailyEntries.values.expand((list) => list).toList();

    return allEntries.map((e) {
      return {
        'text': e.text,
        'emotion': e.emotion,
        'subEmotion': e.subEmotion,
        'time': e.time,
        'date': e.date,
      };
    }).toList();
  }

  /// ✅ เมื่อผู้ใช้ใหม่ล็อกอิน → เปลี่ยนกล่อง Hive เป็นของ user นั้น
  static Future<void> switchUserBox() async {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'guest';
    _box = await Hive.openBox('emotionBox_$_userId');
  }
}
