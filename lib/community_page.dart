import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'bottom_nav_bar.dart';
import 'create_post_page.dart';
import 'notification_page.dart';
import 'comment_page.dart';

/// ------------------------------------------------------------
///  ฟังก์ชันแปลงเวลาให้อ่านง่าย: นาที / ชั่วโมง / วัน
/// ------------------------------------------------------------
String timeAgo(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inMinutes < 1) return "เมื่อสักครู่";
  if (diff.inMinutes < 60) return "${diff.inMinutes} นาทีที่แล้ว";
  if (diff.inHours < 24) return "${diff.inHours} ชั่วโมงที่แล้ว";
  if (diff.inDays < 7) return "${diff.inDays} วันที่แล้ว";

  return "${time.day.toString().padLeft(2, '0')}/"
      "${time.month.toString().padLeft(2, '0')}/"
      "${time.year}";
}

/// ============================================================
///                       COMMUNITY PAGE
/// ============================================================
class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  int _selectedTab = 0;
  String? _anonymousTag;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initUserTag();
  }

  /// สุ่ม anonymousTag ถ้ายังไม่มีใน Firestore
  Future<void> _initUserTag() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists && userDoc.data()?['anonymousTag'] != null) {
      setState(() => _anonymousTag = userDoc['anonymousTag']);
    } else {
      final rand = Random().nextInt(900) + 100;
      final tag = 'anonymous#${rand.toString().padLeft(3, '0')}';
      await userRef.set({'anonymousTag': tag}, SetOptions(merge: true));
      setState(() => _anonymousTag = tag);
    }
  }

  Future<void> _deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final post = await _firestore.collection('posts').doc(postId).get();
    if (post.exists && post['authorId'] == user.uid) {
      await post.reference.delete();
    }
  }

  Future<void> _reportPost(String postId, String authorTag) async {
    await _firestore.collection('reports').add({
      'postId': postId,
      'authorTag': authorTag,
      'reportedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['ทุกด้าน', 'ครอบครัว', 'การเรียน', 'ความรัก'];

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
          children: [
            // --------------------------------------------------
            // Header
            // --------------------------------------------------
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2C2C2C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white70),
                    ),
                  ),

                  Text(
                    'ฟีดระบาย',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  // Notification icon
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('notifications')
                        .where('ownerId', isEqualTo: _auth.currentUser?.uid)
                        .where('read', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationPage(),
                                ),
                              );
                            },
                            child: const Icon(Icons.mail_outline,
                                color: Colors.white70),
                          ),
                          if (count > 0)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$count',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 10),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // --------------------------------------------------
            // Tabs
            // --------------------------------------------------
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(categories.length, (i) {
                  final selected = _selectedTab == i;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = i),
                    child: Column(
                      children: [
                        Text(
                          categories[i],
                          style: GoogleFonts.poppins(
                            color: selected ? Colors.white : Colors.white60,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (selected)
                          Container(
                            margin: const EdgeInsets.only(top: 3),
                            height: 2,
                            width: 30,
                            color: Colors.amberAccent,
                          ),
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // --------------------------------------------------
            // Posts
            // --------------------------------------------------
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('posts')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final posts = snapshot.data!.docs;

                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 100),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      final doc = posts[index];
                      final data = doc.data() as Map<String, dynamic>;

                      if (_selectedTab != 0 &&
                          data['category'] != _selectedTab) {
                        return const SizedBox();
                      }

                      final ts = (data['createdAt'] as Timestamp?)?.toDate();
                      final ago = ts == null ? "เมื่อสักครู่" : timeAgo(ts);

                      // -----------------------------------------------------
                      // [ส่วนที่เพิ่ม] : เซ็นเซอร์ข้อความก่อนนำไปแสดงผล
                      // -----------------------------------------------------
                      final rawContent = data['content'] ?? '';
                      final cleanContent = WordFilter.censor(rawContent);
                      // -----------------------------------------------------

                      return _PostCard(
                        postId: doc.id,
                        authorId: data['authorId'],
                        name: data['authorTag'] ?? 'anonymous',
                        timeAgoText: ago,
                        content: cleanContent, // ส่งข้อความที่กรองแล้วไปแสดง
                        currentUserTag: _anonymousTag ?? '',
                        commentCount: data['commentCount'] ?? 0,
                        onDelete: data['authorId'] == _auth.currentUser?.uid
                            ? () => _deletePost(doc.id)
                            : null,
                        onReport: () =>
                            _reportPost(doc.id, data['authorTag'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          if (_anonymousTag != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreatePostPage(
                  anonymousTag: _anonymousTag!,
                  onPostCreated: (text, cat) =>
                      setState(() => _selectedTab = cat),
                ),
              ),
            );
          }
        },
      ),

      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }
}

/// ============================================================
///                         POST CARD
/// ============================================================
class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.postId,
    required this.authorId,
    required this.name,
    required this.timeAgoText,
    required this.content,
    required this.currentUserTag,
    required this.commentCount,
    this.onReport,
    this.onDelete,
  });

  final String postId;
  final String authorId;
  final String name;
  final String timeAgoText;
  final String content;
  final String currentUserTag;
  final int commentCount;

  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool isLiked = false;
  String? selectedHeartIcon;

  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _commentCount = widget.commentCount;
    _loadLikeStatus();
    _listenCommentCount();
  }

  void _listenCommentCount() {
    _firestore
        .collection("posts")
        .doc(widget.postId)
        .collection("comments")
        .snapshots()
        .listen((snap) {
      setState(() => _commentCount = snap.docs.length);
    });
  }

  Future<void> _loadLikeStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore
        .collection("posts")
        .doc(widget.postId)
        .collection("likes")
        .doc(uid)
        .get();

    if (doc.exists) {
      setState(() {
        isLiked = true;
        selectedHeartIcon = doc['icon'];
      });
    }
  }

  Future<void> _toggleHeart() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final likeRef =
        _firestore.collection("posts").doc(widget.postId).collection("likes").doc(uid);

    String newIcon;
    if (isLiked) {
      newIcon = (selectedHeartIcon == "Sec_Heart") ? "First_Heart" : "Sec_Heart";
    } else {
      newIcon = "Sec_Heart";
    }

    await likeRef.set({
      "icon": newIcon,
      "likedAt": FieldValue.serverTimestamp(),
    });

    if (widget.authorId != uid) {
      await _firestore.collection("notifications").add({
        "ownerId": widget.authorId,
        "actorTag": widget.currentUserTag,
        "postContent": widget.content,
        "type": "like",
        "icon": newIcon,
        "createdAt": FieldValue.serverTimestamp(),
        "read": false,
      });
    }

    setState(() {
      isLiked = true;
      selectedHeartIcon = newIcon;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.black),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Text(
                      widget.name,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  PopupMenuButton<int>(
                    color: const Color(0xFF2A2A2A),
                    icon: const Icon(Icons.more_horiz, color: Colors.white70),
                    onSelected: (v) {
                      if (v == 0) widget.onReport?.call();
                      if (v == 1) widget.onDelete?.call();
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 0,
                        child: Text('รายงานโพสต์',
                            style: GoogleFonts.poppins(color: Colors.white)),
                      ),
                      if (widget.onDelete != null)
                        PopupMenuItem(
                          value: 1,
                          child: Text('ลบโพสต์',
                              style: GoogleFonts.poppins(color: Colors.white)),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 6),

              Text(
                widget.timeAgoText,
                style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
              ),

              const SizedBox(height: 10),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.content,
                  style: GoogleFonts.poppins(
                      color: Colors.white, fontSize: 13),
                ),
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CommentPage(
                        postId: widget.postId,
                        postAuthorId: widget.authorId,
                        postContent: widget.content,
                        currentUserTag: widget.currentUserTag,
                      ),
                    ),
                  );
                },
                child: Text(
                  "ดูความคิดเห็นทั้งหมด ($_commentCount)",
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),

        // หัวใจโชว์ใหญ่ (ไม่รับคลิก)
        Positioned(
          bottom: -160,
          left: -150,
          child: IgnorePointer(
            child: Image.asset(
              isLiked
                  ? "assets/icons/${selectedHeartIcon ?? 'Sec_Heart'}.png"
                  : "assets/icons/First_Heart.png",
              width: 400,
              height: 400,
            ),
          ),
        ),

        // ปุ่มหัวใจที่คลิกได้จริง
        Positioned(
          bottom: 15,
          left: 29,
          child: GestureDetector(
            onTap: _toggleHeart,
            child: Image.asset(
              isLiked
                  ? "assets/icons/${selectedHeartIcon ?? 'Sec_Heart'}.png"
                  : "assets/icons/First_Heart.png",
              width: 40,
              height: 40,
            ),
          ),
        ),
      ],
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
    
    final cleanText = text.toLowerCase();

    for (var word in _badWords) {
      if (cleanText.contains(word.toLowerCase())) {
        return true; 
      }
    }
    return false;
  }

  /// เปลี่ยนคำหยาบเป็นเครื่องหมายดอกจัน (*)
  static String censor(String text) {
    if (text.isEmpty) return text;
    String processedText = text;
    String lowerText = text.toLowerCase();

    for (var word in _badWords) {
      if (lowerText.contains(word.toLowerCase())) {
        final replacement = '*' * word.length;
        processedText = processedText.replaceAll(
          RegExp(word, caseSensitive: false), 
          replacement
        );
      }
    }
    return processedText;
  }
}