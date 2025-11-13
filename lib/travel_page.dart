import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottom_nav_bar.dart';

import 'how_to_play_page.dart';
import 'character_select_page.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  int coin = 130; // จำนวนเหรียญจำลอง

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String characterImage = 'assets/icons/Cartoon.png'; // ตัวละครเริ่มต้น

  @override
  void initState() {
    super.initState();
    _loadSelectedCharacter();
  }

  /// โหลดตัวละครที่ผู้ใช้เลือกจาก Firestore
  Future<void> _loadSelectedCharacter() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _firestore.collection("users").doc(user.uid).get();
    final selected = doc.data()?["selectedCharacter"];

    if (selected != null) {
      setState(() {
        characterImage = "assets/char/char$selected.png";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Stack(
          children: [
            // 🏞️ พื้นหลัง
            Positioned.fill(
              child: Image.asset(
                'assets/images/travelbg.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // 💰 เหรียญ
            // Positioned(
            //   top: 20,
            //   right: 20,
            //   child: Container(
            //     padding:
            //         const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFF5C3B1E),
            //       borderRadius: BorderRadius.circular(30),
            //     ),
            //     child: Row(
            //       children: [
            //         Text(
            //           '$coin',
            //           style: GoogleFonts.poppins(
            //             color: Colors.white,
            //             fontWeight: FontWeight.w700,
            //             fontSize: 18,
            //           ),
            //         ),
            //         const SizedBox(width: 4),
            //         Image.asset(
            //           'assets/images/coin.png',
            //           width: 30,
            //           height: 30,
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // 🧒 ตัวละคร
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: Image.asset(
                  characterImage, // ← โหลดตามที่เลือก
                  height: 300,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // 🟤 ปุ่ม “เริ่มผจญภัย”
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 110),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C3B1E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HowToPlayPage(),
                      ),
                    );
                  },
                  child: Text(
                    'เริ่มผจญภัย',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),

            // 🟤 ปุ่ม “แต่งตัว”
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C3B1E),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    // ไปหน้าเลือกตัวละคร
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CharacterSelectPage(),
                      ),
                    );

                    // โหลดใหม่หลังกลับมา
                    _loadSelectedCharacter();
                  },
                  child: Text(
                    'แต่งตัว',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }
}
