import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ ใช้เช็กสถานะผู้ใช้
import 'package:hive_flutter/hive_flutter.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'success_page.dart';
import 'splash_loading_page.dart'; // ✅ หน้า Splash ก่อนเข้าโฮม
import 'home_page.dart';
import 'emotion_data_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await EmotionDataStore.init();

  // ✅ ตรวจสอบผู้ใช้ที่ล็อกอินอยู่ใน Firebase
  final currentUser = FirebaseAuth.instance.currentUser;

  // ✅ ถ้ามีผู้ใช้ที่ล็อกอินอยู่ → โหลดกล่อง Hive ของคนนั้นโดยตรง
  if (currentUser != null) {
    await EmotionDataStore.switchUserBox(); // 🔹 โหลดกล่องข้อมูลของ user นั้นก่อนเปิดแอป
  }

  runApp(MyApp(
    initialRoute: currentUser != null ? '/splash' : '/', // ถ้ามีผู้ใช้ → ไป splash ก่อนเข้าโฮม
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindWell',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/success': (context) => const SuccessPage(),
        '/splash': (context) => const SplashLoadingPage(), // ✅ หน้าโหลดก่อนเข้าโฮม
        '/home': (context) => const HomePage(),
      },
    );
  }
}
