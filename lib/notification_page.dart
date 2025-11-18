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
            // ---------------- HEADER ----------------
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

            // ---------------- ไม่มีผู้ใช้ ----------------
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('notifications')
                      .where('ownerId', isEqualTo: uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
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

                    // ---------------- จัดเรียงล่าสุดบน ----------------
                    final docs = snapshot.data!.docs.toList()
                      ..sort((a, b) {
                        final ta =
                            (a['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0;
                        final tb =
                            (b['createdAt'] as Timestamp?)
                                ?.millisecondsSinceEpoch ??
                            0;
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

                    // ---------------- Mark as read ----------------
                    final batch = firestore.batch();
                    for (var d in docs) {
                      final isRead =
                          (d.data() as Map<String, dynamic>)['read'] ?? false;
                      if (!isRead) batch.update(d.reference, {'read': true});
                    }
                    batch.commit();

                    return ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final n = docs[i].data() as Map<String, dynamic>;
                        final actor = n['actorTag'] ?? 'anonymous';
                        final content = n['postContent'] ?? '';
                        final type = n['type'] ?? 'like';
                        final iconName = n['icon'];
                        final ts = n['createdAt'] as Timestamp?;
                        final time = ts?.toDate();

                        // ---------------- แก้ไขส่วนคำนวณเวลาตรงนี้ ----------------
                        String timeDisplay = '-';
                        if (time != null) {
                          final diff = DateTime.now().difference(time);
                          if (diff.inDays > 0) {
                            timeDisplay = '${diff.inDays} วันที่แล้ว';
                          } else if (diff.inHours > 0) {
                            timeDisplay = '${diff.inHours} ชั่วโมงที่แล้ว';
                          } else {
                            timeDisplay = '${diff.inMinutes} นาทีที่แล้ว';
                          }
                        }
                        // -----------------------------------------------------

                        // ---------------- ข้อความแจ้งเตือน ----------------
                        String message;

                        if (type == 'comment') {
                          message = 'แสดงความคิดเห็นในโพสต์ของคุณ';
                        } else if (type == 'like') {
                          if (iconName == 'Sec_Heart') {
                            message = 'กดโอบใจให้โพสต์ของคุณ';
                          } else if (iconName == 'good') {
                            message = 'กดเยี่ยมให้โพสต์ของคุณ';
                          } else {
                            message = 'ส่งหัวใจให้โพสต์ของคุณ';
                          }
                        } else {
                          message = 'มีปฏิกิริยากับโพสต์ของคุณ';
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
                              // ---------------- Avatar + Text + Reaction Icon ----------------
                              Row(
                                children: [
                                  const CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // ข้อความแจ้งเตือน
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

                                  // ไอคอน reaction/comment
                                  if (iconName != null)
                                    Image.asset(
                                      "assets/icons/$iconName.png",
                                      width: 0,
                                      height: 0,
                                    ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // ---------------- เนื้อหาโพสต์ ----------------
                              Text(
                                content,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ---------------- เวลา (เรียกใช้ timeDisplay) ----------------
                              Text(
                                timeDisplay, // ใช้ตัวแปรที่คำนวณใหม่
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
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
