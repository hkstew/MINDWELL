package io.flutter.plugins;

import android.app.PendingIntent;
import android.appwidget.AppWidgetManager;
import android.appwidget.AppWidgetProvider;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.widget.RemoteViews;

import com.example.my_new_app.R;   // <-- ถ้า package app คุณไม่ใช่ com.example.my_new_app ให้เปลี่ยนให้ตรง

public class EmotionWidgetProvider extends AppWidgetProvider {

    @Override
    public void onUpdate(Context context, AppWidgetManager manager, int[] appWidgetIds) {

        for (int appWidgetId : appWidgetIds) {

            // 1) อ่านค่าจาก SharedPreferences ของ home_widget
            SharedPreferences prefs = context.getSharedPreferences(
                    "HomeWidgetPreferences",
                    Context.MODE_PRIVATE
            );

            // ข้อความอารมณ์ และ key สี/ตัวละคร
            String emotion = prefs.getString("today_emotion", "อารมณ์");
            String key = prefs.getString("today_emotion_key", "neutral");

            // 2) ผูกกับ layout emotion_widget.xml
            RemoteViews views = new RemoteViews(context.getPackageName(), R.layout.emotion_widget);

            // ข้อความ
            views.setTextViewText(R.id.txtEmotion, emotion);
            views.setTextColor(R.id.txtEmotion, resolveColor(key));

            // รูป highlight glow + ตัวการ์ตูน
            views.setImageViewResource(R.id.imgGlow, getGlowRes(key));
            views.setImageViewResource(R.id.imgCharacter, getCharacterRes(key));

            // 3) กดแล้วเปิดหน้า Analyst ผ่าน deep link mindwell://open/analyst
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse("mindwell://open/analyst"));
            PendingIntent pendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
            );
            views.setOnClickPendingIntent(R.id.rootWidget, pendingIntent);

            // 4) อัปเดต widget
            manager.updateAppWidget(appWidgetId, views);
        }
    }

    // ---------- เลือก glow ตามสีอารมณ์ ----------
    private int getGlowRes(String key) {
        if (key.startsWith("red")) {
            return R.drawable.glow_red;
        }
        if (key.startsWith("green")) {
            return R.drawable.glow_green;
        }
        if (key.startsWith("yellow")) {
            return R.drawable.glow_yellow;
        }
        return R.drawable.glow_green;
    }

    // ---------- เลือกรูปตัวละครตามอารมณ์ย่อย ----------
    private int getCharacterRes(String key) {
        switch (key) {
            // แดง
            case "red":
                return R.drawable.red;     // โกรธ / เครียด
            case "red2":
                return R.drawable.red2;    // เศร้า
            case "red3":
                return R.drawable.red3;    // กังวล

            // เขียว
            case "green":
                return R.drawable.green;   // อารมณ์ดี
            case "green2":
                return R.drawable.green2;  // ดีใจ
            case "green3":
                return R.drawable.green3;  // ผ่อนคลาย

            // เหลือง
            case "yellow":
                return R.drawable.yellow;  // เบื่อ
            case "yellow2":
                return R.drawable.yellow2; // สับสน
            case "yellow3":
                return R.drawable.yellow3; // เหนื่อย

            default:
                return R.drawable.green;
        }
    }

    // ---------- สีข้อความตามกลุ่มอารมณ์ ----------
    private int resolveColor(String key) {
        if (key.startsWith("red")) {
            return 0xFFFF6B6B;     // แดง
        }
        if (key.startsWith("green")) {
            return 0xFF7BFF85;     // เขียว
        }
        if (key.startsWith("yellow")) {
            return 0xFFF6E889;     // เหลือง
        }
        return 0xFFFFFFFF;
    }
}
