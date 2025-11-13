import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'bottom_nav_bar.dart';
import 'create_post_page.dart';
import 'notification_page.dart';

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

  /// ✅ สุ่ม Anonymous tag ถ้ายังไม่มีใน Firestore
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

  /// ✅ ลบโพสต์ของตนเอง
  Future<void> _deletePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final post = await _firestore.collection('posts').doc(postId).get();
    if (post.exists && post['authorId'] == user.uid) {
      await post.reference.delete();
    }
  }

  /// ✅ รายงานโพสต์
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
            // 🔹 Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ปุ่มโปรไฟล์
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
                  // 🔔 ปุ่มแจ้งเตือน
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
                                    builder: (_) => const NotificationPage()),
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

            // 🔹 Tabs
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
                          )
                      ],
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 ฟีดโพสต์
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
                      final content = data['content'] ?? '';
                      final author = data['authorTag'] ?? 'anonymous';
                      final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
                      final minsAgo = timestamp == null
                          ? 0
                          : DateTime.now().difference(timestamp).inMinutes;
                      final isMine = data['authorId'] == _auth.currentUser?.uid;

                      if (_selectedTab != 0 && data['category'] != _selectedTab) {
                        return const SizedBox();
                      }

                      return _PostCard(
                        postId: doc.id,
                        authorId: data['authorId'],
                        name: author,
                        minutesAgo: minsAgo,
                        content: content,
                        onReport: () => _reportPost(doc.id, author),
                        onDelete: isMine ? () => _deletePost(doc.id) : null,
                        currentUserTag: _anonymousTag ?? '',
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🔹 Floating Add Button
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
                  onPostCreated: (text, cat) {
                    setState(() => _selectedTab = cat);
                  },
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

class _PostCard extends StatefulWidget {
  const _PostCard({
    required this.postId,
    required this.authorId,
    required this.name,
    required this.minutesAgo,
    required this.content,
    required this.currentUserTag,
    this.onReport,
    this.onDelete,
  });

  final String postId;
  final String authorId;
  final String name;
  final int minutesAgo;
  final String content;
  final String currentUserTag;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool isLiked = false;
  int likeCount = 0;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
    _countLikes();
  }

  Future<void> _checkLikeStatus() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final likeDoc = await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(uid)
        .get();
    setState(() => isLiked = likeDoc.exists);
  }

  Future<void> _countLikes() async {
    final snapshot = await _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .get();
    setState(() => likeCount = snapshot.size);
  }

  Future<void> _toggleLike() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final likeRef = _firestore
        .collection('posts')
        .doc(widget.postId)
        .collection('likes')
        .doc(uid);

    final postRef = _firestore.collection('posts').doc(widget.postId);
    final postDoc = await postRef.get();
    final postOwnerId = widget.authorId;

    if (isLiked) {
      await likeRef.delete();
      setState(() {
        isLiked = false;
        likeCount--;
      });
    } else {
      await likeRef.set({'likedAt': FieldValue.serverTimestamp()});
      setState(() {
        isLiked = true;
        likeCount++;
      });

      // ✅ แจ้งเตือนเจ้าของโพสต์ (ถ้าไม่ใช่ตัวเอง)
      if (postOwnerId != uid) {
        await _firestore.collection('notifications').add({
          'ownerId': postOwnerId,
          'actorTag': widget.currentUserTag,
          'postContent': widget.content,
          'type': 'like',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          const SizedBox(height: 4),
          Text(
            "${widget.minutesAgo} นาทีที่แล้ว",
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
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 10),

          // ❤️ ปุ่มไลค์
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.favorite,
                  color: isLiked ? Colors.pinkAccent : Colors.white38,
                ),
                onPressed: _toggleLike,
              ),
              Text(
                likeCount.toString(),
                style: GoogleFonts.poppins(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
