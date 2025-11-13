import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

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

  // ✅ ใส่ API key ของ Perspective API ที่นี่
  static const String PERSPECTIVE_API_KEY = "AIzaSyDKplKpQJ3yrwJMTsyjDqksaD1WiXxdYpk";

  Future<bool> _checkProfanity(String text) async {
    try {
      final url = Uri.parse(
          'https://commentanalyzer.googleapis.com/v1alpha1/comments:analyze?key=$PERSPECTIVE_API_KEY');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "comment": {"text": text},
          "languages": ["th", "en"],
          "requestedAttributes": {
            "TOXICITY": {},
            "INSULT": {},
            "PROFANITY": {},
            "THREAT": {},
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double toxicity =
            (data['attributeScores']?['TOXICITY']?['summaryScore']?['value'] ??
                0.0);
        final double insult =
            (data['attributeScores']?['INSULT']?['summaryScore']?['value'] ??
                0.0);
        final double profanity =
            (data['attributeScores']?['PROFANITY']?['summaryScore']?['value'] ??
                0.0);
        final double threat =
            (data['attributeScores']?['THREAT']?['summaryScore']?['value'] ??
                0.0);

        // ถ้ามีอย่างใดอย่างหนึ่งสูงเกิน 0.7 ถือว่าไม่เหมาะสม
        if (toxicity > 0.7 || insult > 0.7 || profanity > 0.7 || threat > 0.7) {
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Perspective API Error: $e");
      return false;
    }
  }

  Future<void> _submitPost() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _isLoading = true);

    // ✅ ตรวจคำไม่เหมาะสม
    final hasBadWord = await _checkProfanity(content);
    if (hasBadWord) {
      setState(() => _isLoading = false);
      _showWarningDialog();
      return;
    }

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
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
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

            // 🔹 ปุ่มกลับ
            Positioned(
              bottom: 25,
              right: 25,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
