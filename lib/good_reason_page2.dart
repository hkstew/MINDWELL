import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:video_player/video_player.dart';

class GoodReasonPage2 extends StatefulWidget {
  const GoodReasonPage2({
    super.key,
    required this.firstAsset,
    required this.secondAsset,
    required this.highlightWord,
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
  State<GoodReasonPage2> createState() => _GoodReasonPage2State();
}

class _GoodReasonPage2State extends State<GoodReasonPage2> {
  bool _second = false;
  Timer? _timer;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH');

    // toggle emoji
    _timer = Timer.periodic(widget.togglePeriod, (_) {
      if (!mounted) return;
      setState(() => _second = !_second);
    });

    _initVideo();
  }

  // -----------------------------
  //  LOAD VIDEO BY EMOTION KEYWORD
  // -----------------------------
  void _initVideo() {
    String file = "assets/videos/good3.mp4"; // default

    switch (widget.highlightWord) {
      case "ดีใจ":
        file = "assets/videos/good1.mp4";
        break;
      case "ผ่อนคลาย":
        file = "assets/videos/good2.mp4";
        break;
      case "อารมณ์ดี":
        file = "assets/videos/good3.mp4";
        break;
    }

    _videoController = VideoPlayerController.asset(file)
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.play();
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    _videoController.dispose();
    super.dispose();
  }

  // ---------------------------
  // PICK DATE
  // ---------------------------
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      locale: const Locale('th', 'TH'),
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ---------------------------
  // PICK TIME
  // ---------------------------
  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  String _formatDate(DateTime d) =>
      DateFormat("d MMM yy", "th_TH").format(d);

  String _formatTime(TimeOfDay t) {
    final dt = DateTime(2024, 1, 1, t.hour, t.minute);
    return DateFormat("HH:mm", "th_TH").format(dt);
  }

  // ---------------------------
  // SUBMIT
  // ---------------------------
  Future<void> _submit() async {
    final text = _controller.text.trim();
    _focusNode.unfocus();

    final finalDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    Navigator.pop(context, {
      'text': text,
      'subEmotion': widget.highlightWord,
      'dateTime': finalDateTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    final arrowStroke = Colors.black.withOpacity(0.7);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // -------------------------
            // ปุ่ม BACK
            // -------------------------
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
                  child: Image.asset('assets/icons/back_arrow.png', width: 22),
                ),
              ),
            ),

            // -------------------------
            // CONTENT
            // -------------------------
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 28, left: 20, right: 20),
                child: Column(
                  children: [
                    // EMOJI
                    AnimatedSwitcher(
                      duration: widget.switchDuration,
                      transitionBuilder: (child, anim) {
                        final scale = Tween(begin: 0.92, end: 1.0).animate(
                          CurvedAnimation(
                            parent: anim,
                            curve: Curves.easeOutBack,
                          ),
                        );
                        return FadeTransition(
                          opacity: anim,
                          child: ScaleTransition(scale: scale, child: child),
                        );
                      },
                      child: Image.asset(
                        _second ? widget.secondAsset : widget.firstAsset,
                        key: ValueKey(_second),
                        width: widget.emojiSize,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _PromptLine(highlight: widget.highlightWord),

                    const SizedBox(height: 14),

                    // INPUT + ARROW
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
                            focusNode: _focusNode,
                            maxLines: 6,
                            minLines: 5,
                            style: GoogleFonts.poppins(
                                fontSize: 16, color: Colors.black87),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'พิมพ์ความคิดเห็นของคุณที่นี่...',
                            ),
                          ),
                        ),

                        Positioned(
                          right: -4,
                          bottom: -6,
                          child: GestureDetector(
                            onTap: _submit,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7BFF85),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: arrowStroke,
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

                    const SizedBox(height: 26),

                    // DATE + TIME
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickDate,
                          child: _DateTimeChip(label: _formatDate(_selectedDate)),
                        ),
                        const SizedBox(width: 12),

                        GestureDetector(
                          onTap: _pickTime,
                          child: _DateTimeChip(
                              label: "${_formatTime(_selectedTime)} น."),
                        ),

                        const SizedBox(width: 12),

                        GestureDetector(
                          onTap: () async {
                            await _pickDate();
                            await _pickTime();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDADADA),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              size: 28,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // -------------------------
                    // VIDEO SECTION
                    // -------------------------
                    if (_videoController.value.isInitialized)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 150,
                          width: 150,
                          child: VideoPlayer(_videoController),
                        ),
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

// ---------------------------
// DATE/TIME CHIP UI
// ---------------------------
class _DateTimeChip extends StatelessWidget {
  final String label;
  const _DateTimeChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ---------------------------
// PROMPT TEXT
// ---------------------------
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
          TextSpan(text: 'บอกเราได้มั้ยทำไมคุณถึงรู้สึก ', style: base),
          TextSpan(text: highlight, style: hi),
        ],
      ),
    );
  }
}
