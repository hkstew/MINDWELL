import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bottom_nav_bar.dart';
import 'bubble_game_page.dart';
import 'sand_game_page.dart';

class GamePage extends StatefulWidget {
  const GamePage({super.key});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  bool isLightMode = true; // true = Light, false = Deep
  int _currentIndex = 3;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // 🔹 หัวข้อ
              Text(
                'เกมผ่อนคลาย',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF90DAF4),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              // 🔹 สวิตช์โหมด (Light / Deep)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildModeButton('Light mode', isLightMode, true),
                    _buildModeButton('Deep mode', !isLightMode, false),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // 🔹 พื้นที่เกม (เปลี่ยนตามโหมด)
              Expanded(
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: isLightMode
                        ? _buildGameCard(
                            key: const ValueKey('light'),
                            image: 'assets/images/BubbleBG.png',
                            title: 'เกมกดฟองสบู่',
                            color: const Color(0xFFB4F1FF),
                          )
                        : _buildGameCard(
                            key: const ValueKey('deep'),
                            image: 'assets/images/SandBG.png',
                            title: 'เกมทุบทราย',
                            color: const Color(0xFFFFDE89),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 3),
    );
  }

  /// 🔸 ปุ่มสลับโหมด
  Widget _buildModeButton(String text, bool isActive, bool lightMode) {
    return GestureDetector(
      onTap: () => setState(() => isLightMode = lightMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.transparent,
        ),
        child: Column(
          children: [
            Text(
              text,
              style: GoogleFonts.poppins(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            if (isActive)
              Container(
                width: 60,
                height: 2,
                color: const Color(0xFFFFE072),
              ),
          ],
        ),
      ),
    );
  }

  /// 🔸 การ์ดเกมแต่ละโหมด
  Widget _buildGameCard({
    required Key key,
    required String image,
    required String title,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        // 🫧 หากอยู่ใน Light Mode → ไปหน้า BubbleGamePage
        if (title == 'เกมกดฟองสบู่') {
          Navigator.of(context).push(
            _createPageRoute(const BubbleGamePage()),
          );
        }
        // 🏖️ ถ้าเป็นเกม Deep Mode → ไปหน้า SandGamePage
        else if (title == 'เกมทุบทราย') {
          Navigator.of(context).push(
            _createPageRoute(const SandGamePage()),
          );
        }
      },
      child: Column(
        key: key,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔸 Transition สวย ๆ ตอนเข้าเกม
  PageRouteBuilder _createPageRoute(Widget page) {
    return PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 700),
      reverseTransitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
