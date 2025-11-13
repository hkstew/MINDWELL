import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    final uid = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'แจ้งเตือน',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ถ้ายังไม่มีผู้ใช้
            if (uid == null)
              Expanded(
                child: Center(
                  child: Text(
                    'กรุณาเข้าสู่ระบบเพื่อดูการแจ้งเตือน',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              // รายการแจ้งเตือน
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  // เอา orderBy ออกเพื่อเลี่ยง composite index
                  stream: firestore
                      .collection('notifications')
                      .where('ownerId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      // แสดง error แทนการค้าง
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'เกิดข้อผิดพลาดในการโหลดแจ้งเตือน\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // ดึงและ sort ในฝั่ง client ตาม createdAt (ล่าสุดอยู่บน)
                    final docs = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final ta = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                        final tb = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                        return tb.compareTo(ta);
                      });

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          'ยังไม่มีการแจ้งเตือน',
                          style: GoogleFonts.poppins(
                            color: Colors.white60,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    // อัปเดต read=true สำหรับที่ยังไม่อ่าน
                    final batch = firestore.batch();
                    for (var d in docs) {
                      final isRead = (d.data() as Map<String, dynamic>)['read'] ?? false;
                      if (!isRead) batch.update(d.reference, {'read': true});
                    }
                    // ไม่ต้อง await ใน build – fire and forget
                    batch.commit();

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final n = docs[i].data() as Map<String, dynamic>;
                        final actor = n['actorTag'] ?? 'anonymous';
                        final content = n['postContent'] ?? '';
                        final type = n['type'] ?? 'like';
                        final time = (n['createdAt'] as Timestamp?)?.toDate();
                        final mins = time == null
                            ? '-'
                            : '${DateTime.now().difference(time).inMinutes} นาทีที่แล้ว';

                        String message;
                        IconData icon;
                        Color color;
                        switch (type) {
                          case 'like':
                            message = 'กดโอบใจให้โพสต์ของคุณ';
                            icon = Icons.favorite;
                            color = Colors.pinkAccent;
                            break;
                          case 'love':
                            message = 'กดเยี่ยมให้โพสต์ของคุณ';
                            icon = Icons.favorite_rounded;
                            color = Colors.redAccent;
                            break;
                          case 'comment':
                            message = 'ได้แสดงความคิดเห็นในโพสต์ของคุณ';
                            icon = Icons.chat_bubble_outline;
                            color = Colors.lightBlueAccent;
                            break;
                          default:
                            message = 'มีการตอบสนองในโพสต์ของคุณ';
                            icon = Icons.notifications_active;
                            color = Colors.amber;
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                    backgroundColor: Colors.grey,
                                    child: Icon(Icons.person, color: Colors.black),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$actor $message',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                content,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(icon, color: color, size: 20),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.favorite, color: Colors.red, size: 18),
                                    ],
                                  ),
                                  Text(
                                    mins,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
