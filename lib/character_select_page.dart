import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

class CharacterSelectPage extends StatefulWidget {
  const CharacterSelectPage({super.key});

  @override
  State<CharacterSelectPage> createState() => _CharacterSelectPageState();
}

class _CharacterSelectPageState extends State<CharacterSelectPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int? _selectedIndex;
  VideoPlayerController? _controller;
  bool _isVideoReady = false;
  bool _isLoadingUser = true;

  /// ชุดที่ปลดล็อกแล้ว (เก็บ id เป็น 1–8)
  Set<int> _unlockedSkins = {1};

  /// ตอนนี้เหลือแค่ 8 ชุด
  final List<String> thumbnails =
      List.generate(8, (i) => 'assets/char/char${i + 1}.png');
  final List<String> videos =
      List.generate(8, (i) => 'assets/char/Char${i + 1}.mp4');

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// โหลดข้อมูล user: ปลดล็อกชุดอะไรแล้ว + เลือกตัวไหนอยู่
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() => _isLoadingUser = false);
      return;
    }

    try {
      final doc = await _firestore.collection("users").doc(user.uid).get();
      final data = doc.data() ?? {};

      // โหลดชุดที่ปลดล็อกแล้ว: [1,2,3,4...]
      final dynamic unlockedRaw = data["unlockedSkins"];
      if (unlockedRaw is List && unlockedRaw.isNotEmpty) {
        _unlockedSkins = unlockedRaw.map((e) => (e as num).toInt()).toSet();
      } else {
        _unlockedSkins = {1}; // Default ปลดล็อกชุดแรกเสมอ
      }

      // โหลดชุดที่เลือกอยู่
      final int? selectedChar = (data["selectedCharacter"] as num?)?.toInt();

      if (selectedChar != null &&
          _unlockedSkins.contains(selectedChar) &&
          selectedChar >= 1 &&
          selectedChar <= thumbnails.length) {
        _selectedIndex = selectedChar - 1;
      } else {
        // เลือกชุดแรกที่ปลดล็อกจริง
        final firstUnlocked = _unlockedSkins.first;
        _selectedIndex = firstUnlocked - 1;
      }

      setState(() {
        _isLoadingUser = false;
      });

      // preview ชุดที่เลือกอยู่
      if (_selectedIndex != null) {
        _playPreview(_selectedIndex!);
      }
    } catch (e) {
      debugPrint("Load user skins error: $e");
      setState(() => _isLoadingUser = false);
    }
  }

  /// เล่นวิดีโอตัวอย่างของชุด (ถ้าปลดล็อกแล้ว)
  Future<void> _playPreview(int index) async {
    final skinId = index + 1;

    if (!_unlockedSkins.contains(skinId)) {
      setState(() {
        _selectedIndex = null; // reset preview
        _isVideoReady = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ชุดนี้ยังไม่ถูกปลดล็อก\nลองไปแลกกับ NPC ในเกมก่อนนะ',
            style: GoogleFonts.poppins(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isVideoReady = false;
      _selectedIndex = index;
    });

    try {
      final old = _controller;
      await old?.pause();
      old?.dispose();

      _controller = VideoPlayerController.asset(videos[index]);
      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      setState(() {
        _isVideoReady = true;
      });
    } catch (e) {
      debugPrint("❌ Video Preview Error: $e");
    }
  }

  Future<void> _saveSelectedCharacter() async {
    final user = _auth.currentUser;
    if (user == null || _selectedIndex == null) return;

    final skinId = _selectedIndex! + 1;
    if (!_unlockedSkins.contains(skinId)) return;

    await _firestore.collection("users").doc(user.uid).set(
      {"selectedCharacter": skinId},
      SetOptions(merge: true),
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      appBar: AppBar(
        backgroundColor: const Color(0xFF212121),
        elevation: 0,
        title: Text(
          "เลือกชุดตัวละคร",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoadingUser
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : SafeArea(
              // ใช้ SafeArea เฉพาะล่าง เพื่อกันปุ่มชนแถบระบบ
              top: false,
              left: false,
              right: false,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // ⭐ Preview Video
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _selectedIndex == null
                          ? Center(
                              child: Text(
                                "แตะชุดที่ปลดล็อกเพื่อดูตัวอย่าง",
                                style: GoogleFonts.poppins(
                                  color: Colors.white54,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : !_isVideoReady
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: AspectRatio(
                                    aspectRatio:
                                        _controller?.value.aspectRatio ?? 1.0,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                    ),

                    const SizedBox(height: 20),

                    // ⭐ Grid รายการชุด
                    Expanded(
                      child: GridView.builder(
                        itemCount: thumbnails.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 1,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final skinId = index + 1;
                          final isUnlocked = _unlockedSkins.contains(skinId);
                          final isSelected = _selectedIndex == index;

                          return GestureDetector(
                            onTap: () {
                              if (!isUnlocked) {
                                setState(() {
                                  _selectedIndex = null;
                                  _isVideoReady = false;
                                });

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'ชุดนี้ยังไม่ถูกปลดล็อก\nลองไปแลกกับ NPC ในเกมก่อนนะ',
                                      style: GoogleFonts.poppins(),
                                    ),
                                  ),
                                );
                                return;
                              }

                              _playPreview(index);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.greenAccent
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      thumbnails[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black54,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.lock,
                                          color: Colors.white70,
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ⭐ ปุ่มเลือกชุด + SafeArea ล่าง กันชนแถบระบบมือถือ
                    if (_selectedIndex != null &&
                        _unlockedSkins.contains(_selectedIndex! + 1))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _saveSelectedCharacter,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              "เลือกชุดนี้",
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
