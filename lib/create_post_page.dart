import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreatePostPage extends StatefulWidget {
  final String anonymousTag;
  final Function(String, int) onPostCreated;
  const CreatePostPage({
    super.key,
    required this.anonymousTag,
    required this.onPostCreated,
  });

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final TextEditingController _controller = TextEditingController();
  int _selectedCategory = 0;
  bool _isLoading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _submitPost() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    // ✅ ตรวจคำไม่เหมาะสม
    if (WordFilter.hasProfanity(content)) {
      _showWarningDialog();
      return;
    }

    setState(() => _isLoading = true);

    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('posts').add({
      'authorId': user.uid,
      'authorTag': widget.anonymousTag,
      'category': _selectedCategory,
      'content': content,
      'createdAt': FieldValue.serverTimestamp(),
    });

    widget.onPostCreated(content, _selectedCategory);
    if (context.mounted) Navigator.pop(context);
  }

  void _showWarningDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        title: Text(
          "ตรวจพบคำไม่เหมาะสม",
          style: GoogleFonts.poppins(
            color: Colors.redAccent,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
        ),
        content: Text(
          "ระบบตรวจพบว่ามีคำไม่เหมาะสมในโพสต์ของคุณ\nกรุณาแก้ไขก่อนโพสต์อีกครั้ง",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ตกลง", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['ทุกด้าน', 'ครอบครัว', 'การเรียน', 'ความรัก'];

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      // ----------------------------------------------------------
      // [แก้ไข] : ตั้งค่าเป็น false เพื่อไม่ให้ปุ่มดันขึ้นมาตามคีย์บอร์ด
      // ปุ่มกลับจะอยู่ที่เดิม (โดยจะถูกคีย์บอร์ดบังเมื่อพิมพ์)
      // ----------------------------------------------------------
      resizeToAvoidBottomInset: false,

      body: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'เพิ่มโพสต์',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔹 กล่องโพสต์
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2C),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.grey,
                              child: Icon(Icons.person, color: Colors.black),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              widget.anonymousTag,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A3A3A),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 6,
                            style: GoogleFonts.poppins(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'ระบายความรู้สึกของคุณ.....',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.white54,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 🔹 ปุ่มเลือกหมวดหมู่
                        Row(
                          children: [
                            Text(
                              "หมวดหมู่: ",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            DropdownButton<int>(
                              value: _selectedCategory,
                              dropdownColor: const Color(0xFF2C2C2C),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              underline: Container(),
                              items: List.generate(
                                categories.length,
                                (i) => DropdownMenuItem<int>(
                                  value: i,
                                  child: Text(categories[i]),
                                ),
                              ),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCategory = val);
                                }
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "*คุณสามารถโพสต์ได้ในด้าน ${categories[_selectedCategory]}",
                            style: GoogleFonts.poppins(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 🔹 ปุ่มโพสต์
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'โพสต์',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            // 🔹 ปุ่มกลับ (จะอยู่ที่เดิม ไม่เด้งตามคีย์บอร์ด)
            Positioned(
              bottom: 25,
              right: 25,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    'กลับ',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
//  UTILITY CLASS: สำหรับกรองคำหยาบ
// ======================================================
class WordFilter {
  static final List<String> _badWords = [
    // --- ภาษาไทย (คำสรรพนาม/คำด่า/คำหยาบคาย) ---
    'กู', 'มึง', 'ไอ้', 'อี',
    'เหี้ย', 'เชี่ย', 'เห้', 'เฮี่ย',
    'สัส', 'สัตว์', 'สัด', 'ไอ้สัส',
    'ควย', 'กวย', 'จัญไร', 'บรรลัย',
    'เย็ด', 'แม่เย็ด', 'เย้ด',
    'หี', 'แตด', 'จิ๋ม', 'โคม',
    'ห่า', 'ร่าน', 'แรด', 'ดอกทอง', 'ตอแหล',
    'กะหรี่', 'กระหรี่', 'โสเภณี', 'แมงดา',
    'หน้าตัวเมีย', 'ชาติชั่ว', 'สารเลว', 'ระยำ',
    'สวะ', 'ขยะ', 'สถุน', 'ไพร่', 'ขี้ข้า',
    'พ่อมึง', 'แม่มึง', 'โคตรพ่อ', 'โคตรแม่',
    'ชั่ว', 'เลว', 'นรก', 'เวร',
    'โง่', 'ควาย', 'ปัญญาอ่อน', 'สมองหมา', 'ปัญญาควาย',
    'ลูกกะหรี่', 'ลูกเมียน้อย',
    'เสือก', 'สะเออะ',

    // --- ภาษาอังกฤษ (Profanity & Insults) ---
    'fuck', 'fucker', 'fucking', 'motherfucker',
    'shit', 'bullshit',
    'bitch', 'son of a bitch',
    'asshole', 'ass', 'dumbass', 'jackass',
    'bastard',
    'cunt', 'pussy', 'twat',
    'dick', 'cock', 'penis', 'vagina',
    'slut', 'whore', 'skank',
    'fag', 'faggot', 'dyke', // (คำเหยียดเพศ)
    'nigger', 'nigga', 'chink', 'kike', // (คำเหยียดเชื้อชาติ - ควรแบนอย่างยิ่ง)
    'retard', 'idiot', 'stupid', 'moron', 'imbecile',
    'damn', 'dammit',
    'suck', 'sucks',
    'piss', 'pissed',
    'crap',
    'wanker', 'bollocks', 'bugger', 'prick',
  ];

  static bool hasProfanity(String text) {
    if (text.isEmpty) return false;
    final cleanText = text.toLowerCase();
    for (var word in _badWords) {
      if (cleanText.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
