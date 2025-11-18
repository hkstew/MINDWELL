import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_page.dart';
import 'analyst_page.dart';
import 'package:home_widget/home_widget.dart';

enum PeriodType { today, week, month }

class EmotionEntry {
  final String text;
  final EmotionType emotion;
  final String subEmotion;
  final DateTime dateTime;

  EmotionEntry({
    required this.text,
    required this.emotion,
    required this.subEmotion,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() => {
    'text': text,
    'emotion': emotion.index,
    'subEmotion': subEmotion,
    'dateTime': dateTime.toIso8601String(),
  };

  factory EmotionEntry.fromMap(Map<String, dynamic> map) {
    return EmotionEntry(
      text: map['text'] ?? "",
      emotion: EmotionType.values[map['emotion']],
      subEmotion: map['subEmotion'] ?? "",
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}

class EmotionDataStore {
  static final EmotionDataStore _instance = EmotionDataStore._internal();
  factory EmotionDataStore() => _instance;
  EmotionDataStore._internal();

  static late Box _box;
  static String? _userId;

  static Future<void> init() async {
    await Hive.initFlutter();
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'guest';
    _box = await Hive.openBox('emotionBox_$_userId');
  }

  final Map<String, List<EmotionEntry>> _dailyEntries = {};

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> updateEmotionWidget(
    String emotionText,
    String emotionKey,
  ) async {
    await HomeWidget.saveWidgetData(
      'today_emotion',
      emotionText,
    ); // เช่น "วันนี้คุณรู้สึก เหนื่อย"
    await HomeWidget.saveWidgetData(
      'today_emotion_key',
      emotionKey,
    ); // เช่น "yellow3"
    await HomeWidget.updateWidget(
      name: 'EmotionWidgetProvider',
      iOSName: 'EmotionWidget', // ไม่ใช้ก็ได้บน Android แต่ใส่ได้
    );
  }

  Future<void> addEntry({
    required String text,
    required EmotionType emotion,
    required String subEmotion,
    required DateTime dateTime,
  }) async {
    final key = _dateKey(dateTime);

    final entry = EmotionEntry(
      text: text,
      emotion: emotion,
      subEmotion: subEmotion,
      dateTime: dateTime,
    );

    _dailyEntries.putIfAbsent(key, () => []);
    _dailyEntries[key]!.insert(0, entry);

    await _box.put(key, _dailyEntries[key]!.map((e) => e.toMap()).toList());
  }

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

  EmotionType? getDominantEmotionForPeriod(PeriodType type) {
    final counts = getEmotionCountsForPeriod(type);
    if (counts.values.every((v) => v == 0)) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  Future<void> clearAll() async {
    _dailyEntries.clear();
    await _box.clear();
  }

  /// ✔️ ดึงรายการทั้งหมด (ใช้หน้า Home)
  List<EmotionEntry> getAllEntries() {
    loadAllData();
    return _dailyEntries.values.expand((list) => list).toList();
  }

  /// ⭐⭐⭐ ฟังก์ชันอัปเดตรายการ (แก้ไขข้อความ + เวลา) ⭐⭐⭐
  Future<void> updateEntry({
    required EmotionEntry oldEntry,
    required EmotionEntry newEntry,
  }) async {
    final oldKey = _dateKey(oldEntry.dateTime);
    final newKey = _dateKey(newEntry.dateTime);

    // โหลดรายการในวันเก่า
    final oldStored = _box.get(oldKey);

    if (oldStored == null || oldStored is! List) return;

    List<EmotionEntry> oldList = oldStored
        .map((m) => EmotionEntry.fromMap(Map<String, dynamic>.from(m)))
        .toList();

    // ลบรายการเดิม
    oldList.removeWhere((e) => e.dateTime == oldEntry.dateTime);

    // ถ้าวันเก่าไม่มีรายการแล้ว → ลบทั้ง key
    if (oldList.isEmpty) {
      await _box.delete(oldKey);
      _dailyEntries.remove(oldKey);
    } else {
      await _box.put(oldKey, oldList.map((e) => e.toMap()).toList());
      _dailyEntries[oldKey] = oldList;
    }

    // เพิ่มรายการใหม่ในวันใหม่
    final newStored = _box.get(newKey);
    List<EmotionEntry> newList = [];

    if (newStored != null && newStored is List) {
      newList = newStored
          .map((m) => EmotionEntry.fromMap(Map<String, dynamic>.from(m)))
          .toList();
    }

    newList.insert(0, newEntry);

    await _box.put(newKey, newList.map((e) => e.toMap()).toList());
    _dailyEntries[newKey] = newList;
  }

  static Future<void> switchUserBox() async {
    final user = FirebaseAuth.instance.currentUser;
    _userId = user?.uid ?? 'guest';
    _box = await Hive.openBox('emotionBox_$_userId');
  }

  /// ⭐⭐⭐ ฟังก์ชันลบรายการ ⭐⭐⭐
  Future<void> deleteEntry(EmotionEntry entry) async {
    final key = _dateKey(entry.dateTime);

    final stored = _box.get(key);
    if (stored == null || stored is! List) return;

    // แปลงข้อมูลกลับเป็น EmotionEntry
    List<EmotionEntry> items = stored
        .map<EmotionEntry>(
          (m) => EmotionEntry.fromMap(Map<String, dynamic>.from(m)),
        )
        .toList();

    // ลบรายการที่ dateTime ตรงกัน
    items.removeWhere((e) => e.dateTime == entry.dateTime);

    // ถ้าวันนั้นไม่มีข้อมูล → ลบทั้ง key
    if (items.isEmpty) {
      await _box.delete(key);
      _dailyEntries.remove(key);
    } else {
      await _box.put(key, items.map((e) => e.toMap()).toList());
      _dailyEntries[key] = items;
    }
  }

  List<EmotionEntry> getEntriesForPeriod(PeriodType type) {
    switch (type) {
      case PeriodType.today:
        return getEntriesForToday();

      case PeriodType.week:
        return getEntriesForWeek();

      case PeriodType.month:
        return getEntriesForMonth();
    }
  }
}
