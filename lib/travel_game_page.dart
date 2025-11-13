import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TravelGamePage extends StatefulWidget {
  const TravelGamePage({super.key});

  @override
  State<TravelGamePage> createState() => _TravelGamePageState();
}

class _TravelGamePageState extends State<TravelGamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _loop;
  final Random _rand = Random();

  // world position ของผู้เล่น (ไม่ใช่พิกัดบนจอ)
  Offset _playerWorld = Offset.zero;
  Offset _moveDir = Offset.zero;

  // HUD
  int _hp = 15;
  int _maxHp = 15;
  int _coin = 0;

  // entity ต่าง ๆ
  final List<_Heart> _hearts = [];
  final List<_Npc> _npcs = [];
  final List<_Monster> _monsters = [];

  // player sprite (⭐ เพิ่มใหม่)
  String _playerSprite = 'assets/icons/Cartoon.png';

  // เสียง
  final AudioPlayer _sfxCollect = AudioPlayer();
  final AudioPlayer _sfxHit = AudioPlayer();
  final AudioPlayer _sfxNpc = AudioPlayer();
  final AudioPlayer _bgm = AudioPlayer();

  @override
  void initState() {
    super.initState();

    _loadSelectedCharacter();  // ⭐ โหลดตัวละครจาก Firestore

    _spawnInitial();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateWorld);

    _loop.repeat();
    _playBgm();
  }

  // ⭐ โหลดตัวละครที่ผู้ใช้เลือกจากหน้าแต่งตัว
  Future<void> _loadSelectedCharacter() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (doc.exists && doc.data()!.containsKey('selectedCharacter')) {
      final int index = doc['selectedCharacter']; // 1–8

      setState(() {
        _playerSprite = 'assets/char/char$index.png';  
        // ถ้าไฟล์เป็น PNG ให้เปลี่ยนเป็น:
        // _playerSprite = 'assets/char/char$index.png';
      });
    }
  }

  Future<void> _playBgm() async {
    try {
      await _bgm.setReleaseMode(ReleaseMode.loop);
      await _bgm.play(AssetSource('sounds/travel_bgm.mp3'));
    } catch (_) {}
  }

  void _spawnInitial() {
    const double mapRange = 800;

    for (int i = 0; i < 15; i++) {
      _hearts.add(_Heart(worldPos: _randomPoint(mapRange)));
    }
    for (int i = 0; i < 6; i++) {
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
    _loop.dispose();
    _bgm.dispose();
    _sfxCollect.dispose();
    _sfxHit.dispose();
    _sfxNpc.dispose();
    super.dispose();
  }

  void _updateWorld() {
    const double speed = 170;
    const double dt = 0.016;

    if (_moveDir != Offset.zero && _hp > 0) {
      final dir = _moveDir / _moveDir.distance;
      _playerWorld += dir * speed * dt;
    }

    // monster ไล่ตามผู้เล่น
    for (final m in _monsters) {
      final toPlayer = _playerWorld - m.worldPos;
      if (toPlayer.distance > 5) {
        final v = toPlayer / toPlayer.distance;
        m.worldPos += v * 90 * dt;
      }
    }

    _checkCollisions();
    setState(() {});
  }

  Future<void> _playSfx(AudioPlayer player, String asset) async {
    try {
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (_) {}
  }

  void _checkCollisions() {
    if (_hp <= 0) return;

    // เก็บหัวใจ
    for (final h in _hearts) {
      if (!h.collected && (h.worldPos - _playerWorld).distance < 40) {
        h.collected = true;
        _coin += 1;
        _hp = (_hp + 1).clamp(0, _maxHp);
        _playSfx(_sfxCollect, 'sounds/collect.mp3');
      }
    }

    // ช่วย NPC
    for (final n in _npcs) {
      if (!n.helped && (n.worldPos - _playerWorld).distance < 50) {
        n.helped = true;
        _coin += 5;
        _playSfx(_sfxNpc, 'sounds/npc.mp3');
      }
    }

    // ชนมอนสเตอร์
    for (final m in _monsters) {
      if ((m.worldPos - _playerWorld).distance < 45) {
        _hp -= 1;
        _playSfx(_sfxHit, 'sounds/hit.mp3');
        if (_hp <= 0) {
          _showGameOver();
        }
      }
    }
  }

  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'เกมจบ',
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
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
                    width: 48,
                    height: 72,
                  ),
                );
              }),

              // ⭐ ผู้เล่น (สกินตามที่เลือก)
              Align(
                alignment: Alignment.center,
                child: Image.asset(
                  _playerSprite,
                  height: 80,
                ),
              ),

              // HUD
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C3B1E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Text('$_hp',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 4),
                      const Icon(Icons.favorite, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 10),
                      // Text('$_coin',
                      //     style: GoogleFonts.poppins(
                      //         color: Colors.white, fontWeight: FontWeight.w700)),
                      // const SizedBox(width: 4),
                      // Image.asset('assets/images/coin.png', width: 18, height: 18),
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
                            borderRadius: BorderRadius.circular(18)),
                        title: Text(
                          'หยุดเกม',
                          style: GoogleFonts.poppins(
                              color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('เล่นต่อ',
                                style: TextStyle(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child:
                                const Text('ออก', style: TextStyle(color: Colors.white)),
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
                    child:
                        const Icon(Icons.pause, color: Colors.white, size: 24),
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
    });
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
