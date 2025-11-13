import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ไม่ต้อง import select page / home_page ที่นี่ เพื่อเลี่ยงวงจรอ้างอิง

class BadReasonPage2 extends StatefulWidget {
  const BadReasonPage2({
    super.key,
    required this.firstAsset,
    required this.secondAsset,
    required this.highlightWord, // เช่น "เศร้า" / "กังวล" / "โกรธ \\ เครียด"
    this.backgroundColor = const Color(0xFF212121),
    this.emojiSize = 190,
    this.togglePeriod = const Duration(milliseconds: 1900),
    this.switchDuration = const Duration(milliseconds: 1200),
    this.onSubmit,
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
  State<BadReasonPage2> createState() => _BadReasonPage2State();
}

class _BadReasonPage2State extends State<BadReasonPage2> {
  bool _second = false;
  bool _submitting = false;

  Timer? _timer;
  final _controller = TextEditingController();
  final _focus = FocusNode();

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
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitting) return; // กันกดรัว
    final text = _controller.text.trim();

    _focus.unfocus();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อความก่อนส่ง')),
      );
      return;
    }

    setState(() => _submitting = true);
    widget.onSubmit?.call(text);

    // ✅ ใช้ post-frame เพื่อเลี่ยง !_debugLocked เวลา pop ระหว่าง frame เดียวกับ gesture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(<String, dynamic>{
        'text': text,
        'subEmotion': widget.highlightWord, // ส่งชื่ออารมณ์ย่อยกลับไปโฮม
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    const redHi = Color(0xFFFF7B7B); // สีไฮไลต์ข้อความ
    const arrowFill = Color(0xFFFF6B6B); // สีปุ่มลูกศร
    final arrowStroke = Colors.black.withOpacity(0.7);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Back
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: _submitting ? null : () => Navigator.of(context).pop(),
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

            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 28, left: 20, right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Emoji auto toggle
                    AnimatedSwitcher(
                      duration: widget.switchDuration,
                      switchInCurve: Curves.easeOutQuad,
                      switchOutCurve: Curves.easeInQuad,
                      transitionBuilder: (child, animation) {
                        final scale = Tween<double>(begin: 0.92, end: 1.0)
                            .animate(CurvedAnimation(
                                parent: animation, curve: Curves.easeOutBack));
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

                    // Prompt
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'บอกเราได้มั้ยทำไมคุณถึงรู้สึก ',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextSpan(
                            text: widget.highlightWord,
                            style: GoogleFonts.poppins(
                              color: redHi,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Text box + arrow button
                    Stack(
                      children: [
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
                            focusNode: _focus,
                            maxLines: 6,
                            minLines: 5,
                            enabled: !_submitting,
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
                        Positioned(
                          right: -4,
                          bottom: -6,
                          child: GestureDetector(
                            onTap: _submitting ? null : _submit,
                            child: Opacity(
                              opacity: _submitting ? 0.6 : 1,
                              child: Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: arrowFill,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: arrowStroke, width: 4),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.35),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  size: 28,
                                ),
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
