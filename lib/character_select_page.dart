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

  final List<String> thumbnails =
      List.generate(8, (i) => 'assets/char/char${i + 1}.png');
  final List<String> videos =
      List.generate(8, (i) => 'assets/char/Char${i + 1}.mp4');

  // ⭐ แก้ error ตรงนี้
  Future<void> _playPreview(int index) async {
    setState(() {
      _isVideoReady = false;
      _selectedIndex = index;
    });

    try {
      // ปิดตัวเก่า
      final old = _controller;
      _controller = VideoPlayerController.asset(videos[index]);

      await _controller!.initialize();
      await _controller!.setLooping(true);
      await _controller!.play();

      setState(() {
        _isVideoReady = true;
      });

      old?.dispose();
    } catch (e) {
      print("❌ Video Preview Error: $e");
      setState(() {
        _isVideoReady = false;
      });
    }
  }

  Future<void> _saveSelectedCharacter() async {
    final user = _auth.currentUser;
    if (user == null || _selectedIndex == null) return;

    await _firestore.collection("users").doc(user.uid).set({
      "selectedCharacter": _selectedIndex! + 1,
    }, SetOptions(merge: true));

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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ⭐ PREVIEW VIDEO SAFE MODE
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: _selectedIndex == null
                  ? Center(
                      child: Text(
                        "แตะเพื่อดูตัวอย่างชุด",
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

            // GRID ตัวละคร
            Expanded(
              child: GridView.builder(
                itemCount: thumbnails.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => _playPreview(index),
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          thumbnails[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ปุ่มเลือก
            if (_selectedIndex != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSelectedCharacter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    "เลือกตัวนี้",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
