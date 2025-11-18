import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CommentPage extends StatefulWidget {
  final String postId;
  final String postAuthorId;
  final String postContent;
  final String currentUserTag;

  const CommentPage({
    super.key,
    required this.postId,
    required this.postAuthorId,
    required this.postContent,
    required this.currentUserTag,
  });

  @override
  State<CommentPage> createState() => _CommentPageState();
}

class _CommentPageState extends State<CommentPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _controller = TextEditingController();
  bool _isSending = false;

  /// ส่งคอมเมนต์
  Future<void> _sendComment() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (_controller.text.trim().isEmpty) return;

    final text = _controller.text.trim();

    // -----------------------------------------------------
    // [ส่วนที่เพิ่ม] : ตรวจสอบคำหยาบก่อนส่ง
    // -----------------------------------------------------
    if (WordFilter.hasProfanity(text)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เนื้อหาของคุณมีคำไม่สุภาพ กรุณาแก้ไข',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 2),
        ),
      );
      // หยุดการทำงาน ไม่ส่งข้อมูลไป Firebase
      return;
    }
    // -----------------------------------------------------

    _controller.clear();
    setState(() => _isSending = true);

    try {
      final commentRef = _firestore
          .collection("posts")
          .doc(widget.postId)
          .collection("comments")
          .doc();

      await commentRef.set({
        "userId": uid,
        "tag": widget.currentUserTag,
        "content": text,
        "createdAt": FieldValue.serverTimestamp(),
      });

      // นับจำนวนคอมเมนต์ใหม่
      final commentCountSnap = await _firestore
          .collection("posts")
          .doc(widget.postId)
          .collection("comments")
          .get();

      await _firestore.collection("posts").doc(widget.postId).update({
        "commentCount": commentCountSnap.docs.length,
      });

      // แจ้งเตือนเจ้าของโพสต์ (ถ้าไม่ใช่คนเดิม)
      if (widget.postAuthorId != uid) {
        await _firestore.collection("notifications").add({
          "ownerId": widget.postAuthorId,
          "actorTag": widget.currentUserTag,
          "postContent": widget.postContent,
          "type": "comment",
          "icon": "comment",
          "createdAt": FieldValue.serverTimestamp(),
          "read": false,
        });
      }
    } catch (e) {
      // จัดการ Error เล็กน้อยเผื่อเน็ตหลุด
      debugPrint("Error sending comment: $e");
    }

    setState(() => _isSending = false);
  }

  /// ลบคอมเมนต์ของตัวเอง
  Future<void> _deleteComment(String commentId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _firestore
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .doc(commentId)
        .delete();

    // อัปเดตจำนวนคอมเมนต์ใหม่
    final snap = await _firestore
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .get();

    await _firestore.collection("posts").doc(widget.postId).update({
      "commentCount": snap.docs.length,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFF212121),

      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          "ความคิดเห็น",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Column(
        children: [
          // ---------------- COMMENT LIST ----------------
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("posts")
                  .doc(widget.postId)
                  .collection("comments")
                  .orderBy("createdAt", descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final comments = snapshot.data!.docs;

                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      "ยังไม่มีความคิดเห็น",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    bottom: 100,
                  ), // กันบังด้วย input
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final doc = comments[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final tag = data["tag"] ?? "anonymous";
                    final text = data["content"] ?? "";
                    final userId = data["userId"];

                    final timestamp = (data["createdAt"] as Timestamp?)
                        ?.toDate();
                    final minutesAgo = timestamp == null
                        ? "-"
                        : "${DateTime.now().difference(timestamp).inMinutes} นาทีที่แล้ว";

                    final isOwner = userId == _auth.currentUser?.uid;

                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.black),
                      ),
                      title: Text(
                        tag,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "$text\n$minutesAgo",
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isOwner
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteComment(doc.id),
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),

          // ---------------- INPUT SAFE AREA ----------------
          SafeArea(
            minimum: const EdgeInsets.only(bottom: 10), // ดันขึ้นจากขอบ
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(color: Color(0xFF2C2C2C)),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "เขียนความคิดเห็น...",
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF3A3A3A),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  GestureDetector(
                    onTap: _isSending ? null : _sendComment,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.greenAccent,
                      child: _isSending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
//  UTILITY CLASS: สำหรับกรองคำหยาบ
// ======================================================
class WordFilter {
  // รายการคำหยาบ
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

  /// ตรวจสอบว่ามีคำหยาบหรือไม่ (return true ถ้าเจอคำหยาบ)
  static bool hasProfanity(String text) {
    if (text.isEmpty) return false;

    // แปลงเป็นตัวพิมพ์เล็กเพื่อตรวจสอบง่ายขึ้น
    final cleanText = text.toLowerCase();

    for (var word in _badWords) {
      // ตรวจสอบว่ามีคำหยาบอยู่ในข้อความหรือไม่
      if (cleanText.contains(word.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
