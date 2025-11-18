import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ เพิ่ม
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ใช้เช็กสถานะผู้ใช้
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_new_app/analyst_page.dart';
import 'login_page.dart';
import 'register_page.dart';
import 'success_page.dart';
import 'splash_loading_page.dart';
import 'home_page.dart';
import 'emotion_data_store.dart';
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HomeWidget.setAppGroupId("group.emotion.widget");
  HomeWidget.registerBackgroundCallback((data) async {
    // สามารถสั่ง update widget เบื้องหลังได้
  });
  await Firebase.initializeApp();
  await Hive.initFlutter();
  await EmotionDataStore.init();

  final currentUser = FirebaseAuth.instance.currentUser;

  if (currentUser != null) {
    await EmotionDataStore.switchUserBox();
  }

  runApp(MyApp(initialRoute: currentUser != null ? '/splash' : '/'));
}

class MyApp extends StatelessWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MindWell',

      // ✅ เพิ่ม Localizations ให้ DatePicker ใช้งานได้ (สำคัญ!)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('th'), Locale('en')],

      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      initialRoute: initialRoute,
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/success': (context) => const SuccessPage(),
        '/splash': (context) => const SplashLoadingPage(),
        '/home': (context) => const HomePage(),
      },
    );
  }
}
