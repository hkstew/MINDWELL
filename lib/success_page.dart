import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'emoji_intro_page.dart';

class SuccessPage extends StatefulWidget {
  const SuccessPage({super.key});

  @override
  State<SuccessPage> createState() => _SuccessPageState();
}

class _SuccessPageState extends State<SuccessPage> {
  @override
  void initState() {
    super.initState();

    // รอ 1.5 วิ แล้วเปลี่ยนหน้าแบบเฟด
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(_fadeRoute(const EmojiIntroPageFullCartoonWithBubble()));
    });
  }

  // สร้าง Route แบบเฟด ใช้ซ้ำได้
  PageRouteBuilder _fadeRoute(Widget page, {Duration duration = const Duration(milliseconds: 350)}) {
    return PageRouteBuilder(
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 โลโก้
            SizedBox(
              height: 305,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 0,
                    child: Image.asset(
                      "assets/logos/mindwell_logo.png",
                      height: 260,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 0),

            // 🔹 ไอคอนเช็กสีเขียว
            Icon(
              Icons.check_circle,
              size: 240,
              color: Colors.green[600],
            ),

            const SizedBox(height: 10),

            // 🔹 ข้อความแสดงผล
            Text(
              "สร้างบัญชีเรียบร้อยแล้ว!",
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Colors.green[700],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
