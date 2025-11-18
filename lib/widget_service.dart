import 'package:home_widget/home_widget.dart';
import 'emotion_data_store.dart';
import 'home_page.dart';

class WidgetService {
  static const String widgetName = 'EmotionWidgetProvider';
  static const String emotionKey = 'today_emotion_text';
  static const String emotionColor = 'today_emotion_color';
  static const String emotionImage = 'today_emotion_image';

  /// อัปเดตข้อมูลสำหรับวิดเจ็ต
  static Future<void> updateWidget() async {
    final store = EmotionDataStore();
    final entries = store.getEntriesForToday();

    if (entries.isEmpty) {
      await HomeWidget.saveWidgetData(emotionKey, 'ยังไม่มีข้อมูล');
      await HomeWidget.updateWidget(name: widgetName);
      return;
    }

    // หาจำนวนมากที่สุด
    final counts = store.getEmotionCountsForPeriod(PeriodType.today);
    final dominant = store.getDominantEmotionForPeriod(PeriodType.today);

    // หาซับอารมณ์ที่ใช้ล่าสุดของกลุ่มนั้น
    final latest = entries.firstWhere(
      (e) => e.emotion == dominant,
      orElse: () => entries.first,
    );

    await HomeWidget.saveWidgetData(emotionKey, latest.subEmotion);

    // สี
    String color = "white";
    switch (dominant) {
      case EmotionType.good:
        color = "#7BFF85";
        break;
      case EmotionType.neutral:
        color = "#F6E889";
        break;
      case EmotionType.bad:
        color = "#FF7B7B";
        break;
      
      case null:
        color = "FFFFFF";
        break;
    }
    await HomeWidget.saveWidgetData(emotionColor, color);

    // รูป
    await HomeWidget.saveWidgetData(emotionImage, latest.subEmotion);

    await HomeWidget.updateWidget(name: widgetName);
  }
}