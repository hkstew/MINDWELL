import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_page.dart';
import 'emotion_data_store.dart'; // ✅ เพิ่มเพื่อใช้ switchUserBox()

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? loginError;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<void> _login() async {
    setState(() => loginError = null);

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null && mounted) {
        // ✅ โหลดกล่องข้อมูลอารมณ์ของผู้ใช้ก่อนเข้า Splash
        await EmotionDataStore.switchUserBox();

        // ✅ ไปหน้า Splash ต่อเลย
        Navigator.pushReplacementNamed(context, '/splash');
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          loginError = "อีเมลหรือรหัสผ่านไม่ถูกต้อง";
        } else if (e.code == 'invalid-email') {
          loginError = "รูปแบบอีเมลไม่ถูกต้อง";
        } else {
          loginError = "เกิดข้อผิดพลาด: ${e.message}";
        }
      });
    } catch (e) {
      setState(() => loginError = "เกิดข้อผิดพลาดที่ไม่ทราบสาเหตุ");
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      // เลือกบัญชี Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // ผู้ใช้กดยกเลิก

      // ดึง token
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // ส่ง token ให้ Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null && mounted) {
        // ✅ โหลดกล่องข้อมูลอารมณ์ของผู้ใช้ Google ก่อนเข้า Splash
        await EmotionDataStore.switchUserBox();

        // ✅ ไปหน้า Splash ต่อเลย
        Navigator.pushReplacementNamed(context, '/splash');
      }
    } catch (e) {
      setState(() => loginError = "Google Sign-In ล้มเหลว: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 โลโก้ + LOGIN
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
                            text: "LOG",
                            style: GoogleFonts.poppins(
                              fontSize: 90,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF72A6B5),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 5),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          TextSpan(
                            text: "IN",
                            style: GoogleFonts.poppins(
                              fontSize: 90,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.2),
                                  offset: const Offset(0, 5),
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

            // ช่องกรอกอีเมล
            _buildInputField(emailController, "กรอกอีเมล"),
            const SizedBox(height: 20),

            // ช่องกรอกรหัสผ่าน + toggle 👁️
            _buildInputField(
              passwordController,
              "กรอกรหัส",
              obscure: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            // ✅ ข้อความ error
            if (loginError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    loginError!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // ลืมรหัสผ่าน
            Padding(
              padding: const EdgeInsets.only(right: 50),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "ลืมรหัสรึป่าว?",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ปุ่มเข้าสู่ระบบ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
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
                    "เข้าสู่ระบบ",
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

            // Divider
            Text(
              "หรือเข้าสู่ระบบด้วย",
              style: GoogleFonts.poppins(fontSize: 15),
            ),
            const SizedBox(height: 6),

            // Google Sign-In
            GestureDetector(
              onTap: _signInWithGoogle,
              child: Image.asset(
                "assets/icons/google_logo.png",
                height: 45,
              ),
            ),

            const SizedBox(height: 170),

            // ลิงก์สมัครสมาชิก
            Padding(
              padding: const EdgeInsets.only(bottom: 25),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: Text(
                  "คุณยังไม่มีบัญชีใช่ไหม?",
                  style: GoogleFonts.poppins(
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(255, 97, 205, 255),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText,
      {bool obscure = false, Widget? suffixIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withOpacity(1),
        borderRadius: BorderRadius.circular(50),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hintText,
            filled: true,
            fillColor: Colors.white,
            suffixIcon: suffixIcon,
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
