import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:video_player/video_player.dart';

class NeutralReasonPage2 extends StatefulWidget {
  const NeutralReasonPage2({
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
  State<NeutralReasonPage2> createState() => _NeutralReasonPage2State();
}

class _NeutralReasonPage2State extends State<NeutralReasonPage2> {
  bool _second = false;
  Timer? _timer;

  final _controller = TextEditingController();
  final _focus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  VideoPlayerController? _video;

  /// ------------------------------
  /// แผนที่อารมณ์ → ไฟล์วิดีโอ
  /// ------------------------------
  final Map<String, String> emotionVideoMap = {
    "เบื่อ": "neutral1.mp4",
    "สับสน": "neutral2.mp4",
    "เหนื่อย": "neutral3.mp4",
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH');

    _timer = Timer.periodic(widget.togglePeriod, (_) {
      if (!mounted) return;
      setState(() => _second = !_second);
    });

    _initVideo();
  }

  void _initVideo() async {
    final fileName = emotionVideoMap[widget.highlightWord];

    if (fileName == null) {
      debugPrint("⚠️ วิดีโอของอารมณ์ '${widget.highlightWord}' ยังไม่ได้กำหนดใน emotionVideoMap");
      return;
    }

    final path = "assets/videos/$fileName";

    _video = VideoPlayerController.asset(path);

    try {
      await _video!.initialize();
      _video!.setLooping(true);
      _video!.play();
      setState(() {});
    } catch (e) {
      debugPrint("⚠️ โหลดวิดีโอไม่ได้: $path");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    _video?.dispose();
    super.dispose();
  }

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

  void _submit() {
    final text = _controller.text.trim();
    _focus.unfocus();

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
    const yellowHi = Color(0xFFFFE17A);
    const arrowFill = Color(0xFFF6D25C);

    final arrowStroke = Colors.black.withOpacity(0.7);

    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
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
                  mainAxisSize: MainAxisSize.min,
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
                              color: yellowHi,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ---------------------------
                    // TEXT INPUT
                    // ---------------------------
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDADADA),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: TextField(
                            controller: _controller,
                            maxLines: 6,
                            minLines: 5,
                            focusNode: _focus,
                            decoration:
                                const InputDecoration(border: InputBorder.none),
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
                                color: arrowFill,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: arrowStroke,
                                  width: 4,
                                ),
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: Colors.brown[900],
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // ---------------------------
                    // DATE + TIME PICKER
                    // ---------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _pickDate,
                          child: _DateTimeChip(
                            label: _formatDate(_selectedDate),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _pickTime,
                          child: _DateTimeChip(
                            label: "${_formatTime(_selectedTime)} น.",
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            await _pickDate();
                            await _pickTime();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFDADADA),
                            ),
                            child: const Icon(Icons.calendar_month,
                                color: Colors.grey),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    // ---------------------------
                    // 🎥 VIDEO PLAYER
                    // ---------------------------
                    if (_video != null && _video!.value.isInitialized)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          height: 150,
                          width: 150,
                          child: AspectRatio(
                            aspectRatio: _video!.value.aspectRatio,
                            child: VideoPlayer(_video!),
                          ),
                        ),
                      )
                    else
                      const SizedBox(
                        height: 300,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
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
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
