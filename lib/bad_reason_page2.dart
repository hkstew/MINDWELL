import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:video_player/video_player.dart';

class BadReasonPage2 extends StatefulWidget {
  const BadReasonPage2({
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
  State<BadReasonPage2> createState() => _BadReasonPage2State();
}

class _BadReasonPage2State extends State<BadReasonPage2> {
  bool _second = false;
  bool _submitting = false;

  Timer? _timer;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay.now();

  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();

    initializeDateFormatting('th_TH');

    _timer = Timer.periodic(widget.togglePeriod, (_) {
      if (!mounted) return;
      setState(() => _second = !_second);
    });

    _loadVideo();
  }

  // ---------------------------------------------------
  // โหลดวิดีโอตามอารมณ์
  // ---------------------------------------------------
  void _loadVideo() {
    String file = "assets/videos/bad1.mp4"; // default

    switch (widget.highlightWord) {
      case "เศร้า":
        file = "assets/videos/bad1.mp4";
        break;
      case "กังวล":
        file = "assets/videos/bad2.mp4";
        break;
      case "โกรธ / เครียด":
        file = "assets/videos/bad3.mp4";
        break;
    }

    _videoController = VideoPlayerController.asset(file)
      ..initialize().then((_) {
        _videoController!.setLooping(true);
        _videoController!.play();
        setState(() {});
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // ----------------------------
  // PICK DATE
  // ----------------------------
  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2035),
      locale: const Locale("th", "TH"),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  // ----------------------------
  // PICK TIME
  // ----------------------------
  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  String _formatDate(DateTime d) =>
      DateFormat("d MMM yy", "th_TH").format(d);

  String _formatTime(TimeOfDay t) {
    final dt = DateTime(2024, 1, 1, t.hour, t.minute);
    return DateFormat("HH:mm", "th_TH").format(dt);
  }

  void _submit() {
    final text = _controller.text.trim();

    final combinedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    Navigator.of(context).pop({
      'text': text,
      'subEmotion': widget.highlightWord,
      'dateTime': combinedDateTime,
    });
  }

  @override
  Widget build(BuildContext context) {
    const redHi = Color(0xFFFF7B7B);
    const arrowFill = Color(0xFFFF6B6B);
    final arrowStroke = Colors.black.withOpacity(0.7);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // BACK BUTTON
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
                  child: Image.asset('assets/icons/back_arrow.png', width: 22),
                ),
              ),
            ),

            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 28, left: 20, right: 20),
                child: Column(
                  children: [
                    AnimatedSwitcher(
                      duration: widget.switchDuration,
                      child: Image.asset(
                        _second ? widget.secondAsset : widget.firstAsset,
                        key: ValueKey(_second),
                        width: widget.emojiSize,
                      ),
                    ),

                    const SizedBox(height: 16),

                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "บอกเราได้มั้ยทำไมคุณถึงรู้สึก ",
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

                    // TEXT FIELD
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDADADA),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TextField(
                            controller: _controller,
                            focusNode: _focus,
                            maxLines: 6,
                            minLines: 5,
                            style: GoogleFonts.poppins(fontSize: 16),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "พิมพ์ความคิดเห็นของคุณที่นี่...",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.black54,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        Positioned(
                          right: -4,
                          bottom: -6,
                          child: GestureDetector(
                            onTap: _submitting ? null : _submit,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: arrowFill,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: arrowStroke,
                                  width: 4,
                                ),
                              ),
                              child: const Icon(Icons.arrow_forward,
                                  size: 28, color: Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // DATE + TIME PICKER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickDate,
                          child: _box(_formatDate(selectedDate)),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _pickTime,
                          child: _box("${_formatTime(selectedTime)} น."),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await _pickDate();
                            await _pickTime();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: _circle(),
                            child: const Icon(
                              Icons.calendar_month,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // -------------------------------------------------
                    // วิดีโอแสดงอารมณ์ด้านล่าง
                    // -------------------------------------------------
                    if (_videoController?.value.isInitialized ?? false)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SizedBox(
                          height: 150,
                          width: 150,
                          child: VideoPlayer(_videoController!),
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

  // UI HELPERS
  Widget _box(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFDADADA),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  BoxDecoration _circle() => BoxDecoration(
        color: const Color(0xFFDADADA),
        shape: BoxShape.circle,
      );
}
