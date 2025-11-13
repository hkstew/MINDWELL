import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'success_page.dart';
import 'emotion_data_store.dart'; // ✅ เพิ่ม import เพื่อใช้ switchUserBox()

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String? passwordError; // ตรวจสอบ password ซ้ำ
  String? firebaseError; // error จาก Firebase

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _register() async {
    setState(() {
      firebaseError = null;
    });

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        firebaseError = "รหัสผ่านไม่ตรงกัน";
      });
      return;
    }

    try {
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ✅ หลังสมัครสมาชิกสำเร็จ โหลด Hive ของผู้ใช้ใหม่
      await EmotionDataStore.switchUserBox();

      // ✅ ไปหน้า SuccessPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          firebaseError = "อีเมลนี้ถูกใช้งานแล้ว";
        } else if (e.code == 'weak-password') {
          firebaseError = "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร";
        } else if (e.code == 'invalid-email') {
          firebaseError = "รูปแบบอีเมลไม่ถูกต้อง";
        } else {
          firebaseError = "เกิดข้อผิดพลาด: ${e.message}";
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 โลโก้ + "สร้างบัญชี"
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
                  Positioned(
                    top: 190,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: "สร้าง",
                            style: GoogleFonts.poppins(
                              fontSize: 70,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.15),
                                  offset: const Offset(0, 4),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: "บัญชี",
                            style: GoogleFonts.poppins(
                              fontSize: 70,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF72A6B5),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.15),
                                  offset: const Offset(0, 4),
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

            const SizedBox(height: 5),

            _buildInputField(emailController, "กรอกอีเมล"),
            const SizedBox(height: 20),

            _buildInputField(passwordController, "กรอกรหัส", obscure: true),
            const SizedBox(height: 20),

            _buildInputField(
              confirmPasswordController,
              "ยืนยันรหัสอีกครั้ง",
              obscure: true,
              onChanged: (value) {
                setState(() {
                  if (value == passwordController.text) {
                    passwordError = "*ยืนยันรหัสถูกต้อง";
                  } else {
                    passwordError = "*รหัสผ่านไม่ตรงกัน";
                  }
                });
              },
            ),

            if (passwordError != null)
              Padding(
                padding: const EdgeInsets.only(top: 14, left: 60),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    passwordError!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: passwordError == "*ยืนยันรหัสถูกต้อง"
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            if (firebaseError != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  firebaseError!,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),

            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF90DAF4),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black.withOpacity(1),
                  ),
                  child: Text(
                    "ยืนยัน",
                    style: GoogleFonts.poppins(
                      fontSize: 35,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText,
      {bool obscure = false, Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(1),
        borderRadius: BorderRadius.circular(50),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: const Color.fromARGB(255, 245, 245, 245),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 25, horizontal: 40),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(50),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}
