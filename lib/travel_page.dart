import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_new_app/travel_game_page.dart';
import 'bottom_nav_bar.dart';
import 'how_to_play_page.dart';
import 'character_select_page.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String characterImage = 'assets/icons/Cartoon.png';

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
    final uid = _auth.currentUser?.uid;

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

            // ❤️ แสดงจำนวนหัวใจที่เก็บได้ทั้งหมด (มุมขวาบน)
            if (uid != null)
              Positioned(
                top: 16,
                right: 16,
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection("users").doc(uid).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }

                    final data = snapshot.data!.data() as Map<String, dynamic>?;

                    // ⭐ ใช้ totalHearts เป็นค่าของสะสมทั้งหมด
                    final hearts = data?["totalHearts"] ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.redAccent,
                            size: 26,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            hearts.toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // 🧒 ตัวละคร
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 180),
                child: Image.asset(
                  characterImage,
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
                      horizontal: 60,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TravelGamePage()),
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
                      horizontal: 50,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CharacterSelectPage(),
                      ),
                    );

                    // โหลดใหม่หลังจากเปลี่ยนตัวละคร
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
