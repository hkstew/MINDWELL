import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'final_intro_page.dart';
import 'home_page.dart'; // ✅ ใช้ EmotionType

class GoodReasonPage extends StatefulWidget {
  const GoodReasonPage({
    super.key,
    required this.firstAsset,
    required this.secondAsset,
    required this.highlightWord, // คำไฮไลต์ เช่น "อารมณ์ดี" / "ดีใจ" / "ผ่อนคลาย"
    this.backgroundColor = const Color(0xFF212121),
    this.emojiSize = 190,
    this.togglePeriod = const Duration(milliseconds: 1900),
    this.switchDuration = const Duration(milliseconds: 1200),
    this.onSubmit, // ส่งข้อความกลับหรือจะนำทางต่อก็ได้
  });

  final String firstAsset;
  final String secondAsset;
  final String highlightWord;
  final Color backgroundColor;
  final double emojiSize;
  final Duration togglePeriod;
  final Duration switchDuration;
  final void Function(String text)? onSubmit;

  @override
  State<GoodReasonPage> createState() => _GoodReasonPageState();
}

class _GoodReasonPageState extends State<GoodReasonPage> {
  bool _second = false;
  Timer? _timer;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.togglePeriod, (_) {
      if (!mounted) return;
      setState(() => _second = !_second);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    widget.onSubmit?.call(text);

    // เก็บคีย์บอร์ดก่อนเปลี่ยนหน้า
    _focusNode.unfocus();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => FinalIntroPage(
          // ✅ ส่งข้อความ + ชนิดอารมณ์ (ดี)
          reasonText: text,
          emotion: EmotionType.good,
        ),
        transitionDuration: const Duration(milliseconds: 600),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          final fade = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          final slide = Tween<Offset>(
            begin: const Offset(0.06, 0.02),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
          return FadeTransition(opacity: fade, child: SlideTransition(position: slide, child: child));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // ปุ่ม Back
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/icons/back_arrow.png',
                    width: 22,
                    height: 22,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // เนื้อหา
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 28, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // อิโมจิใหญ่ (สลับอัตโนมัติ)
                    AnimatedSwitcher(
                      duration: widget.switchDuration,
                      switchInCurve: Curves.easeOutQuad,
                      switchOutCurve: Curves.easeInQuad,
                      transitionBuilder: (child, animation) {
                        final scale = Tween<double>(begin: 0.92, end: 1.0)
                            .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutBack));
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(scale: scale, child: child),
                        );
                      },
                      child: Image.asset(
                        _second ? widget.secondAsset : widget.firstAsset,
                        key: ValueKey(_second),
                        width: widget.emojiSize,
                        height: widget.emojiSize,
                        fit: BoxFit.contain,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ข้อความหัวเรื่อง
                    _PromptLine(highlight: widget.highlightWord),

                    const SizedBox(height: 14),

                    // กล่องพิมพ์ + ปุ่มลูกศรลอย
                    Stack(
                      children: [
                        // กล่องพิมพ์
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDADADA),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: 6,
                            minLines: 5,
                            style: GoogleFonts.poppins(
                              color: Colors.black87,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'พิมพ์ความคิดเห็นของคุณที่นี่...',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.black.withOpacity(0.45),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        // ปุ่มลูกศร
                        Positioned(
                          right: -4,
                          bottom: -6,
                          child: GestureDetector(
                            onTap: _submit,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7BFF85), // เขียวอ่อน
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.7),
                                  width: 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.teal[900],
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptLine extends StatelessWidget {
  const _PromptLine({required this.highlight});
  final String highlight;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.poppins(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    final hi = GoogleFonts.poppins(
      color: const Color(0xFF7BFF85),
      fontSize: 18,
      fontWeight: FontWeight.w900,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(text: 'บอกเราได้มั้ยทำไมคุณถึงรู้สึก', style: base),
          const TextSpan(text: ' '),
          TextSpan(text: highlight, style: hi),
        ],
      ),
    );
  }
}
