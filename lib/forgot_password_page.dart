import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _sendResetLink() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showPopup(
        title: "ผิดพลาด",
        message: "กรุณากรอกอีเมลก่อน",
      );
      return;
    }

    try {
      // ส่งลิงก์รีเซ็ตรหัสผ่าน
      await _auth.sendPasswordResetEmail(email: email);

      // ถ้าสำเร็จ
      _showPopup(
        title: "ส่งสำเร็จ!",
        message: "เราได้ส่งลิงก์สำหรับเปลี่ยนรหัสผ่านไปที่อีเมลของคุณแล้ว",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        _showPopup(
          title: "ไม่พบอีเมลนี้",
          message: "ไม่มีบัญชีที่ใช้อีเมลนี้อยู่ในระบบของเรา",
        );
      } else {
        _showPopup(
          title: "เกิดข้อผิดพลาด",
          message: e.message ?? "ไม่สามารถส่งลิงก์ได้",
        );
      }
    }
  }

  void _showPopup({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 22,
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "ตกลง",
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF72A6B5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 ปุ่มกลับ
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back_ios, size: 28),
                ),
              ),

              const SizedBox(height: 0),

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

                    // const SizedBox(height: 10),

                    Positioned(
                      top: 220,
                      child: Text.rich(
                        textAlign: TextAlign.center,
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "เราจะส่งลิงค์เปลี่ยนรหัสผ่าน\nไปที่", 
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF72A6B5),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0, 3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                            TextSpan(
                              text: "อีเมลของคุณ",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[600],
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.2),
                                    offset: const Offset(0,3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 กล่องใส่อีเมล
              Material(
                elevation: 5,
                shadowColor: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(40),
                child: TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "กรอกอีเมล",
                    filled: true,
                    fillColor: const Color(0xFFECECEC),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(40),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 🔹 ปุ่มยืนยัน
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _sendResetLink,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90DAF4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    elevation: 5,
                  ),
                  child: Text(
                    "ยืนยัน",
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
