import 'package:flutter/material.dart';

import 'home_page.dart';
import 'analyst_page.dart';
import 'community_page.dart';
import 'game_page.dart';
import 'travel_page.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const BottomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget nextPage;
    switch (index) {
      case 0:
        nextPage = const HomePage();
        break;
      case 1:
        nextPage = const AnalystPage();
        break;
      case 2:
        nextPage = const CommunityPage();
        break;
      case 3:
        nextPage = const GamePage();
        break;
      case 4:
        nextPage = const TravelPage();
        break;
      default:
        nextPage = const HomePage();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => nextPage,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          final fade =
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final slide = Tween<Offset>(
            begin: const Offset(0.03, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const icons = ['Home', 'Analyst', 'Commu', 'Game', 'Travel'];

    // ⭐ เพิ่มส่วนนี้: ป้องกัน NavBar ถูกบังด้วยปุ่มระบบมือถือ
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final safeBottom = bottomInset == 0 ? 12.0 : bottomInset;

    return Container(
      padding: EdgeInsets.only(bottom: safeBottom, top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false, // เราคุมเองผ่าน padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(icons.length, (i) {
            final name = icons[i];
            final isSelected = currentIndex == i;

            final asset = isSelected
                ? 'assets/icons/Sec_$name.png'
                : 'assets/icons/First_$name.png';

            return GestureDetector(
              onTap: () => _navigate(context, i),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(asset, width: 42, height: 42),
                  const SizedBox(height: 4),
                  if (isSelected)
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF90DAF4),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
