import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'how_to_play_page.dart';

class TravelGamePage extends StatefulWidget {
  const TravelGamePage({super.key});

  @override
  State<TravelGamePage> createState() => _TravelGamePageState();
}

class _TravelGamePageState extends State<TravelGamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _loop;
  final Random _rand = Random();

  int _totalHearts = 0; // หัวใจสะสมทั้งหมดจากฐานข้อมูล

  // world position ของผู้เล่น (ไม่ใช่พิกัดบนจอ)
  Offset _playerWorld = Offset.zero;
  Offset _moveDir = Offset.zero;

  // HUD
  int _hp = 1;
  int _maxHp = 1;
  int _coin = 0; // หัวใจที่เก็บในเกม

  // entity ต่าง ๆ
  final List<_Heart> _hearts = [];
  final List<_Npc> _npcs = [];
  final List<_Monster> _monsters = [];

  // player sprite
  String _playerSprite = 'assets/icons/Cartoon.png';

  // ⭐ ชุดที่ปลดล็อกแล้ว
  Set<int> _unlockedSkins = {1};

  // เสียง
  final AudioPlayer _sfxCollect = AudioPlayer();
  final AudioPlayer _sfxHit = AudioPlayer();
  final AudioPlayer _sfxNpc = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();

  @override
  void initState() {
    ImageCache imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSize = 1000;
    imageCache.maximumSizeBytes = 1024 * 1024 * 256;

    super.initState();
    _checkTutorialStatus();
    _loadSelectedCharacter();
    _loadTotalHearts();
    _spawnInitial();

    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateWorld);

    _loop.stop();
    _playBgm();
  }

  Future<void> _checkTutorialStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final hasSeen = userDoc.data()?['seenTravelTutorial'] ?? false;

    if (!hasSeen) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HowToPlayPage()),
      );

      if (result == true) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'seenTravelTutorial': true,
        }, SetOptions(merge: true));

        _loop.repeat();
      }
    } else {
      _loop.repeat();
    }
  }

  // ⭐ โหลดข้อมูลตัวละคร + ชุดที่ปลดล็อกแล้ว
  Future<void> _loadSelectedCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final data = doc.data() ?? {};

    // โหลดชุดที่เลือก
    if (data.containsKey("selectedCharacter")) {
      final index = data["selectedCharacter"];
      _playerSprite = "assets/char/char$index.png";
    }

    // โหลดชุดที่ปลดล็อก
    if (data.containsKey("unlockedSkins")) {
      _unlockedSkins = (data["unlockedSkins"] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toSet();
    } else {
      _unlockedSkins = {1};
    }

    setState(() {});
  }

  Future<void> _loadTotalHearts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    _totalHearts = doc.data()?['totalHearts'] ?? 0;

    setState(() {});
  }

  Future<void> _playBgm() async {
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.play(AssetSource('sounds/travel_bgm.mp3'));
    } catch (_) {}
  }

  void _spawnInitial() {
    const double mapRange = 800;

    for (int i = 0; i < 50; i++) {
      _hearts.add(_Heart(worldPos: _randomPoint(mapRange)));
    }
    for (int i = 0; i < 10; i++) {
      _npcs.add(_Npc(worldPos: _randomPoint(mapRange)));
    }
    for (int i = 0; i < 5; i++) {
      _monsters.add(_Monster(worldPos: _randomPoint(mapRange)));
    }
  }

  Offset _randomPoint(double r) {
    return Offset(
      _rand.nextDouble() * 2 * r - r,
      _rand.nextDouble() * 2 * r - r,
    );
  }

  @override
  void dispose() {
    if (_loop.isAnimating) {
      _loop.stop();
    }
    _loop.dispose();

    _bgm.dispose();
    _sfxCollect.dispose();
    _sfxHit.dispose();
    _sfxNpc.dispose();

    super.dispose();
  }

  void _updateWorld() {
    if (!mounted) return;
    const double speed = 170;
    const double dt = 0.016;

    bool needUpdate = false;

    if (_moveDir != Offset.zero && _hp > 0) {
      final dir = _moveDir / _moveDir.distance;
      _playerWorld += dir * speed * dt;
      needUpdate = true;
    }

    // monster ไล่ผู้เล่น
    for (final m in _monsters) {
      final toPlayer = _playerWorld - m.worldPos;
      if (toPlayer.distance > 5) {
        final v = toPlayer / toPlayer.distance;
        m.worldPos += v * 30 * dt; // ช้าลง
        needUpdate = true;
      }
    }

    _checkCollisions();

    if (needUpdate) setState(() {});
  }

  Future<void> _playSfx(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.setSource(AssetSource(asset));
      await player.resume();
    } catch (_) {}
  }

  Future<void> _playHitSound() async {
    try {
      final p = AudioPlayer();
      await p.play(AssetSource('sounds/hit.mp3'));
      p.onPlayerComplete.listen((_) => p.dispose());
    } catch (_) {}
  }

  // ---------------------------------------
  // 🚀 เช็คการชนต่าง ๆ
  // ---------------------------------------

  void _checkCollisions() {
    if (_hp <= 0) return;

    // เก็บหัวใจ
    for (final h in _hearts) {
      if (!h.collected && (h.worldPos - _playerWorld).distance < 40) {
        h.collected = true;
        _coin += 1;
        _totalHearts += 1;
        _playSfx(_sfxCollect, 'sounds/collect.mp3');
      }
    }

    // ชน NPC = เปิดร้านแลกชุด
    for (final n in _npcs) {
      if (!n.helped && (n.worldPos - _playerWorld).distance < 50) {
        n.helped = true;
        _showNpcShop();
      }
    }

    // ชนมอนสเตอร์
    for (final m in _monsters) {
      if ((m.worldPos - _playerWorld).distance < 25) {
        _hp -= 1;
        _playHitSound();

        if (_hp <= 0) {
          _showGameOver();
        }
      }
    }
  }

  // ---------------------------------------
  // 🏪 ร้าน NPC แลกชุด
  // ---------------------------------------

  void _showNpcShop() async {
    _loop.stop();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final int totalHearts = _totalHearts; // ใช้ค่าปัจจุบันในเกม

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          "ร้าน NPC",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "คุณมี $totalHearts หัวใจ\nต้องใช้ 100 หัวใจเพื่อสุ่มปลดล็อกชุดใหม่",
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loop.repeat();
            },
            child: const Text("ปิด", style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              if (totalHearts < 100) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("หัวใจไม่พอ ต้องมี 100 ❤️ เพื่อแลกชุด"),
                  ),
                );
                return;
              }
              Navigator.pop(context);
              await _unlockRandomSkin();
            },
            child: const Text(
              "แลกชุด (100)",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // 🎁 สุ่มปลดล็อกชุด
  // ---------------------------------------

  Future<void> _unlockRandomSkin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // โหลดข้อมูลปัจจุบัน
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .get();
    final data = doc.data() ?? {};

    final Set<int> unlocked = (data["unlockedSkins"] ?? [1])
        .map<int>((e) => (e as num).toInt())
        .toSet();

    const allSkins = {1, 2, 3, 4}; // ✔ มีแค่ 4 ชุดตามที่คุณกำหนด
    final remaining = allSkins.difference(unlocked);

    if (remaining.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("คุณปลดล็อกครบทุกชุดแล้ว!")));
      _loop.repeat();
      return;
    }

    final int currentHearts = _totalHearts;

    if (currentHearts < 100) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("หัวใจไม่พอ ต้องมี 100 ❤️")));
      _loop.repeat();
      return;
    }

    // สุ่มชุดใหม่
    final newSkin = remaining.elementAt(Random().nextInt(remaining.length));

    _totalHearts -= 100;
    setState(() {}); // อัปเดต HUD

    // หักหัวใจ + เซฟชุดใหม่
    await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
      "totalHearts": _totalHearts,
      "unlockedSkins": [...unlocked, newSkin],
    }, SetOptions(merge: true));

    // popup
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "ปลดล็อกชุดใหม่!",
          style: GoogleFonts.poppins(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Image.asset("assets/char/char$newSkin.png", height: 140),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loop.repeat();
            },
            child: const Text("เยี่ยม!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------
  // ☠️ จบเกม
  // ---------------------------------------

  void _showGameOver() async {
    if (_isGameOverShown) return;
    _isGameOverShown = true;

    _loop.stop();

    // เซฟหัวใจทั้งหมดลง Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
        "totalHearts": FieldValue.increment(_coin),
      }, SetOptions(merge: true));
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'เกมจบ',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'คุณเก็บกำลังใจได้ทั้งหมด $_coin ชิ้น',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('กลับ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  bool _isGameOverShown = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);

        Offset worldToScreen(Offset w) =>
            w - _playerWorld + Offset(size.width / 2, size.height / 2);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                // พื้นหลัง tile
                _InfiniteBackground(
                  worldOffset: _playerWorld,
                  screenSize: size,
                  asset: 'assets/images/travelin.jpg',
                ),

                // Hearts
                ..._hearts.where((h) => !h.collected).map((h) {
                  return Positioned(
                    left: worldToScreen(h.worldPos).dx - 16,
                    top: worldToScreen(h.worldPos).dy - 16,
                    child: Image.asset(
                      'assets/images/heart.png',
                      width: 32,
                      height: 32,
                    ),
                  );
                }),

                // NPC
                ..._npcs.map((n) {
                  return Positioned(
                    left: worldToScreen(n.worldPos).dx - 24,
                    top: worldToScreen(n.worldPos).dy - 36,
                    child: Image.asset(
                      'assets/images/npc.png',
                      width: 48,
                      height: 72,
                    ),
                  );
                }),

                // Monsters
                ..._monsters.map((m) {
                  return Positioned(
                    left: worldToScreen(m.worldPos).dx - 24,
                    top: worldToScreen(m.worldPos).dy - 36,
                    child: Image.asset(
                      m.type == 0
                          ? 'assets/images/mon1.png'
                          : 'assets/images/mon2.png',
                      width: 100,
                      height: 100,
                    ),
                  );
                }),

                // ⭐ ผู้เล่น (สกินตามที่เลือก)
                Align(
                  alignment: Alignment.center,
                  child: Image.asset(_playerSprite, height: 80),
                ),

                // HUD
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C3B1E),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '$_totalHearts',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Image.asset(
                          'assets/images/heart.png',
                          width: 18,
                          height: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                // Pause
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          backgroundColor: const Color(0xFF2C2C2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          title: Text(
                            'หยุดเกม',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'เล่นต่อ',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'ออก',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.pause,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Joystick
                Positioned(
                  left: 20,
                  bottom: 30,
                  child: _Joystick(
                    size: 110,
                    onChanged: (dir) => _moveDir = dir,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// -------------------------------------------------------------

class _Heart {
  Offset worldPos;
  bool collected;
  _Heart({required this.worldPos, this.collected = false});
}

class _Npc {
  Offset worldPos;
  bool helped;
  _Npc({required this.worldPos, this.helped = false});
}

class _Monster {
  Offset worldPos;
  int type;
  _Monster({required this.worldPos, int? type})
    : type = type ?? Random().nextInt(2);
}

// -------------------------------------------------------------

class _InfiniteBackground extends StatelessWidget {
  final Offset worldOffset;
  final Size screenSize;
  final String asset;

  const _InfiniteBackground({
    required this.worldOffset,
    required this.screenSize,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final double w = screenSize.width;
    final double h = screenSize.height;

    final dx = -worldOffset.dx % w;
    final dy = -worldOffset.dy % h;

    return Stack(
      children: [
        for (int ix = -1; ix <= 1; ix++)
          for (int iy = -1; iy <= 1; iy++)
            Positioned(
              left: dx + ix * w,
              top: dy + iy * h,
              width: w,
              height: h,
              child: Image.asset(asset, fit: BoxFit.cover),
            ),
      ],
    );
  }
}

// -------------------------------------------------------------

class _Joystick extends StatefulWidget {
  final double size;
  final ValueChanged<Offset> onChanged;

  const _Joystick({required this.size, required this.onChanged});

  @override
  State<_Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<_Joystick> {
  Offset _knobPos = Offset.zero;

  void _update(Offset localPos) {
    final r = widget.size / 2;
    final center = Offset(r, r);
    Offset delta = localPos - center;

    if (delta.distance > r - 20) {
      delta = Offset.fromDirection(delta.direction, r - 20);
    }

    setState(() => _knobPos = delta);
    widget.onChanged(delta == Offset.zero ? Offset.zero : delta);
  }

  void _reset() {
    setState(() => _knobPos = Offset.zero);
    widget.onChanged(Offset.zero);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.size / 2;

    return GestureDetector(
      onPanStart: (d) => _update(d.localPosition),
      onPanUpdate: (d) => _update(d.localPosition),
      onPanEnd: (_) => _reset(),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 3),
              ),
            ),
            Positioned(
              left: r + _knobPos.dx - 24,
              top: r + _knobPos.dy - 24,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD54F),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
