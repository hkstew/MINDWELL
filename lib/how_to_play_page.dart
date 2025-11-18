import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HowToPlayPage extends StatefulWidget {
  const HowToPlayPage({super.key});

  @override
  State<HowToPlayPage> createState() => _HowToPlayPageState();
}

class _HowToPlayPageState extends State<HowToPlayPage> {
  int _pageIndex = 0;

  final List<_HowToItem> _items = const [
    _HowToItem(
      title: 'กำลังใจ',
      image: 'assets/images/heart.png',
      description:
          'เดินเก็บกำลังใจที่สุ่มเกิดอยู่ทั่วแผนที่และนำมันไปให้กับคนที่ต้องการกำลังใจ',
    ),
    _HowToItem(
      title: 'NPC ที่ต้องการกำลังใจ',
      image: 'assets/images/npc.png',
      description:
          'NPC จะสุ่มเกิดตามทางต่างๆ หากคุณนำกำลังใจที่เก็บได้เป็นจำนวน 100 หัวใจมามอบให้เขา คุณจะได้รับการปลดล็อคสกินชุดเสื้อผ้าแบบสุ่ม',
    ),
    _HowToItem(
      title: 'ปีศาจ',
      image: 'assets/images/mon1.png',
      description:
          'ปีศาจความโกรธและปีศาจความเศร้าจะคอยไล่ล่าคุณ ระวังอย่าให้ความเครียดและความเศร้าพรากกำลังใจไปจากคุณ',
    ),
  ];

  void _next() {
    if (_pageIndex < _items.length - 1) {
      setState(() => _pageIndex++);
    } else {
      // ⭐ สำคัญ: ปิดหน้าสอนกลับไป TravelGamePage
      Navigator.pop(context, true);
    }
  }

  void _back() {
    if (_pageIndex > 0) {
      setState(() => _pageIndex--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _items[_pageIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/travelin.jpg',
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),

            Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  'วิธีการเล่น',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5C3B1E),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              item.image,
                              width: 110,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item.description,
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_items.length, (i) {
                    final isActive = i == _pageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isActive ? Colors.yellow : Colors.white54,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),

                const Spacer(),

                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_pageIndex > 0)
                        _brownButton(text: 'ย้อนกลับ', onTap: _back)
                      else
                        const SizedBox(width: 120),

                      _brownButton(
                        text: _pageIndex == _items.length - 1
                            ? 'เข้าใจแล้ว'
                            : 'ถัดไป',
                        onTap: _next,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _brownButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5C3B1E),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HowToItem {
  final String title;
  final String image;
  final String description;

  const _HowToItem({
    required this.title,
    required this.image,
    required this.description,
  });
}
