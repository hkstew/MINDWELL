import 'package:flutter/material.dart';
import 'emoji_select_page.dart';


/// หน้าอิโมจิ + การ์ตูน 2 จังหวะ + กล่องข้อความ 2 ข้อความ (ฉากที่ 1)
/// จากนั้นสไลด์ซ้ายไปฉากที่ 2 (การ์ตูนซ้าย + กล่องขวา) บนหน้าจอเดียวด้วย PageView
class EmojiIntroPageFullCartoonWithBubble extends StatefulWidget {
  const EmojiIntroPageFullCartoonWithBubble({
    super.key,

    // ===== Scene 1: การ์ตูนขวา + กล่องซ้าย (พารามิเตอร์เดิมของคุณ) =====
    this.greenOffset = 0,
    this.yellowOffset = 0,
    this.redOffset = 0,
    this.backgroundColor = const Color(0xFF212121),
    this.greenSize = 170,
    this.smallSize = 160,
    this.spacing = 12,

    this.showCartoon = true,
    this.cartoonAsset = 'assets/icons/Cartoon.png',
    this.cartoonSize = 380,
    this.cartoonVisibleHeight = 143,
    this.cartoonRight,
    this.cartoonLeft,
    this.cartoonBottomOffset = 0,
    this.cartoonDelay = const Duration(milliseconds: 1200),
    this.cartoonDuration = const Duration(milliseconds: 650),
    this.cartoonCurve = Curves.easeOutBack,

    this.fullRevealDelayAfterHead = const Duration(milliseconds: 300),
    this.fullRevealDuration = const Duration(milliseconds: 600),
    this.fullRevealCurve = Curves.easeInOutCubic,
    this.fullRevealExtraOffset = -80,

    this.firstMessage = 'สวัสดีครับพี่ๆ นี่น้องโอบใจเอง',
    this.secondMessage = 'คนที่จะมารับฟังสิ่งที่พี่ๆระบายและคอยโอบกอดพี่ๆครับ',
    this.bubbleDelayAfterFullReveal = const Duration(milliseconds: 600),
    this.bubbleTransitionDuration = const Duration(milliseconds: 1600),
    this.firstMessageVisibleDuration = const Duration(milliseconds: 3500),
    this.bubbleMaxWidth = 240,
    this.bubblePadding = const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    this.bubbleBorderRadius = const BorderRadius.all(Radius.circular(16)),
    this.bubbleBackground = const Color(0xFFFFFFFF),
    this.bubbleTextStyle = const TextStyle(
      color: Colors.black,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
    this.bubbleRight = 140, // ใช้ฝั่งซ้าย/ขวาอย่างใดอย่างหนึ่ง
    this.bubbleLeft,
    this.bubbleBottom = 250,

    this.bubbleTailOnRight = false,
    this.bubbleTailOffset = 24,
    this.bubbleTailBottom = -10,
    this.autoTailToCartoon = true,

    // ===== รอหลังข้อความสองก่อนเลื่อนไปซีน 2 =====
    this.nextSceneDelayAfterSecondMessage = const Duration(milliseconds: 900),

    // ===== Scene transition (ซีน1 -> ซีน2 ด้วย PageView) =====
    this.sceneTransitionDuration = const Duration(milliseconds: 1000),
    this.sceneTransitionCurve = Curves.easeInOutCubic,

    // ===== Scene 2: การ์ตูนซ้าย + กล่องขวา (ใหม่) =====
    this.leftCartoonRight,
    this.leftCartoonLeft = -95,
    this.leftCartoonBottomOffset = 0,
    this.leftCartoonDelayAfterSceneSwitch = const Duration(milliseconds: 150),
    this.leftCartoonSize,
    this.leftCartoonVisibleHeight,
    this.leftFullRevealExtraOffset,

    this.leftBubbleLeft,
    this.leftBubbleRight = 40,
    this.leftBubbleBottom = 250,
    this.leftFirstMessage = 'และนี่คือฟีเจอร์สำหรับบันทึกอารมณ์ของพี่ๆ',
    this.leftSecondMessage = 'น้องโอบใจอยากรู้ว่าอารมณ์ของพี่ๆ ตอนนี้คืออารมณ์ไหน',
    this.leftBubbleDelayAfterFullReveal,
    this.leftBubbleTransitionDuration,
    this.leftFirstMessageVisibleDuration,
    this.leftAutoTailToCartoon,
  });

  // =========== Scene 1 (ของเดิม) ===========
  final double greenOffset;
  final double yellowOffset;
  final double redOffset;
  final Color backgroundColor;
  final double greenSize;
  final double smallSize;
  final double spacing;

  final bool showCartoon;
  final String cartoonAsset;
  final double cartoonSize;
  final double cartoonVisibleHeight;
  final double? cartoonRight;
  final double? cartoonLeft;
  final double cartoonBottomOffset;
  final Duration cartoonDelay;
  final Duration cartoonDuration;
  final Curve cartoonCurve;

  final Duration fullRevealDelayAfterHead;
  final Duration fullRevealDuration;
  final Curve fullRevealCurve;
  final double fullRevealExtraOffset;

  final String firstMessage;
  final String secondMessage;
  final Duration bubbleDelayAfterFullReveal;
  final Duration bubbleTransitionDuration;
  final Duration firstMessageVisibleDuration;
  final double bubbleMaxWidth;
  final EdgeInsets bubblePadding;
  final BorderRadius bubbleBorderRadius;
  final Color bubbleBackground;
  final TextStyle bubbleTextStyle;
  final double? bubbleRight;
  final double? bubbleLeft;
  final double bubbleBottom;

  final bool bubbleTailOnRight;
  final double bubbleTailOffset;
  final double bubbleTailBottom;
  final bool autoTailToCartoon;

  final Duration nextSceneDelayAfterSecondMessage;

  // Transition ระหว่างฉาก
  final Duration sceneTransitionDuration;
  final Curve sceneTransitionCurve;

  // =========== Scene 2 (ใหม่: การ์ตูนซ้าย + กล่องขวา) ===========
  final double? leftCartoonRight;
  final double? leftCartoonLeft;
  final double leftCartoonBottomOffset;
  final Duration leftCartoonDelayAfterSceneSwitch;
  final double? leftCartoonSize;
  final double? leftCartoonVisibleHeight;
  final double? leftFullRevealExtraOffset;

  final double? leftBubbleLeft;
  final double? leftBubbleRight;
  final double leftBubbleBottom;
  final String leftFirstMessage;
  final String leftSecondMessage;
  final Duration? leftBubbleDelayAfterFullReveal;
  final Duration? leftBubbleTransitionDuration;
  final Duration? leftFirstMessageVisibleDuration;
  final bool? leftAutoTailToCartoon;

  @override
  State<EmojiIntroPageFullCartoonWithBubble> createState() =>
      _EmojiIntroPageFullCartoonWithBubbleState();
}

class _EmojiIntroPageFullCartoonWithBubbleState
    extends State<EmojiIntroPageFullCartoonWithBubble> {
  final PageController _pageController = PageController();

  void _goNextScene() {
    if (!mounted) return;
    _pageController.animateToPage(
      1,
      duration: widget.sceneTransitionDuration,
      curve: widget.sceneTransitionCurve,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // ห้ามรูดเอง
          children: [
            // ===== Scene 1: การ์ตูนขวา + กล่องซ้าย =====
            _IntroScene(
              // Emoji layout
              backgroundColor: widget.backgroundColor,
              greenSize: widget.greenSize,
              smallSize: widget.smallSize,
              spacing: widget.spacing,
              greenOffset: widget.greenOffset,
              yellowOffset: widget.yellowOffset,
              redOffset: widget.redOffset,

              // Cartoon (right)
              showCartoon: widget.showCartoon,
              cartoonAsset: widget.cartoonAsset,
              cartoonSize: widget.cartoonSize,
              cartoonVisibleHeight: widget.cartoonVisibleHeight,
              cartoonLeft: widget.cartoonLeft,
              cartoonRight: widget.cartoonRight ?? -95,
              cartoonBottomOffset: widget.cartoonBottomOffset,
              cartoonDelay: widget.cartoonDelay,
              cartoonDuration: widget.cartoonDuration,
              cartoonCurve: widget.cartoonCurve,
              fullRevealDelayAfterHead: widget.fullRevealDelayAfterHead,
              fullRevealDuration: widget.fullRevealDuration,
              fullRevealCurve: widget.fullRevealCurve,
              fullRevealExtraOffset: widget.fullRevealExtraOffset,

              // Bubble (left)
              bubbleLeft: widget.bubbleLeft ?? 40,
              bubbleRight: widget.bubbleRight,
              bubbleBottom: widget.bubbleBottom,
              firstMessage: widget.firstMessage,
              secondMessage: widget.secondMessage,
              bubbleDelayAfterFullReveal: widget.bubbleDelayAfterFullReveal,
              bubbleTransitionDuration: widget.bubbleTransitionDuration,
              firstMessageVisibleDuration: widget.firstMessageVisibleDuration,
              bubbleMaxWidth: widget.bubbleMaxWidth,
              bubblePadding: widget.bubblePadding,
              bubbleBorderRadius: widget.bubbleBorderRadius,
              bubbleBackground: widget.bubbleBackground,
              bubbleTextStyle: widget.bubbleTextStyle,

              autoTailToCartoon: widget.autoTailToCartoon,
              bubbleTailOnRight: widget.bubbleTailOnRight,
              bubbleTailOffset: widget.bubbleTailOffset,
              bubbleTailBottom: widget.bubbleTailBottom,

              // เมื่อจบข้อความที่สอง -> รออีกนิด -> เลื่อนไปหน้า 2
              onFinishedSecondMessage: () async {
                await Future.delayed(widget.nextSceneDelayAfterSecondMessage);
                _goNextScene();
              },
            ),

            // ===== Scene 2: การ์ตูนซ้าย + กล่องขวา =====
            _IntroScene(
              backgroundColor: widget.backgroundColor,
              greenSize: widget.greenSize,
              smallSize: widget.smallSize,
              spacing: widget.spacing,
              greenOffset: widget.greenOffset,
              yellowOffset: widget.yellowOffset,
              redOffset: widget.redOffset,

              // Cartoon (left)
              showCartoon: widget.showCartoon,
              cartoonAsset: widget.cartoonAsset,
              cartoonSize: widget.leftCartoonSize ?? widget.cartoonSize,
              cartoonVisibleHeight:
                  widget.leftCartoonVisibleHeight ?? widget.cartoonVisibleHeight,
              cartoonLeft: widget.leftCartoonLeft ?? -95,
              cartoonRight: widget.leftCartoonRight,
              cartoonBottomOffset: widget.leftCartoonBottomOffset,
              cartoonDelay: widget.leftCartoonDelayAfterSceneSwitch,
              cartoonDuration: widget.cartoonDuration,
              cartoonCurve: widget.cartoonCurve,
              fullRevealDelayAfterHead: widget.fullRevealDelayAfterHead,
              fullRevealDuration: widget.fullRevealDuration,
              fullRevealCurve: widget.fullRevealCurve,
              fullRevealExtraOffset:
                  widget.leftFullRevealExtraOffset ?? widget.fullRevealExtraOffset,

              // Bubble (right)
              bubbleLeft: widget.leftBubbleLeft,
              bubbleRight: widget.leftBubbleRight ?? 40,
              bubbleBottom: widget.leftBubbleBottom,
              firstMessage: widget.leftFirstMessage,
              secondMessage: widget.leftSecondMessage,
              bubbleDelayAfterFullReveal:
                  widget.leftBubbleDelayAfterFullReveal ??
                      widget.bubbleDelayAfterFullReveal,
              bubbleTransitionDuration:
                  widget.leftBubbleTransitionDuration ??
                      widget.bubbleTransitionDuration,
              firstMessageVisibleDuration:
                  widget.leftFirstMessageVisibleDuration ??
                      widget.firstMessageVisibleDuration,
              bubbleMaxWidth: widget.bubbleMaxWidth,
              bubblePadding: widget.bubblePadding,
              bubbleBorderRadius: widget.bubbleBorderRadius,
              bubbleBackground: widget.bubbleBackground,
              bubbleTextStyle: widget.bubbleTextStyle,

              autoTailToCartoon:
                  widget.leftAutoTailToCartoon ?? widget.autoTailToCartoon,
              bubbleTailOnRight: true, // ซีนนี้ติ่งอยู่ขวา
              bubbleTailOffset: widget.bubbleTailOffset,
              bubbleTailBottom: widget.bubbleTailBottom,

              onFinishedSecondMessage: () {
                // เมื่อจบข้อความที่สอง → ไปหน้าเลือกอารมณ์
                Future.delayed(const Duration(milliseconds: 2500), () {
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmojiSelectPage()),
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// วิดเจ็ตฉากหนึ่ง (การ์ตูน 2 จังหวะ + bubble 2 ข้อความ)
class _IntroScene extends StatefulWidget {
  const _IntroScene({
    super.key,
    // Emoji
    required this.backgroundColor,
    required this.greenSize,
    required this.smallSize,
    required this.spacing,
    required this.greenOffset,
    required this.yellowOffset,
    required this.redOffset,
    // Cartoon
    required this.showCartoon,
    required this.cartoonAsset,
    required this.cartoonSize,
    required this.cartoonVisibleHeight,
    required this.cartoonLeft,
    required this.cartoonRight,
    required this.cartoonBottomOffset,
    required this.cartoonDelay,
    required this.cartoonDuration,
    required this.cartoonCurve,
    required this.fullRevealDelayAfterHead,
    required this.fullRevealDuration,
    required this.fullRevealCurve,
    required this.fullRevealExtraOffset,
    // Bubble
    required this.bubbleLeft,
    required this.bubbleRight,
    required this.bubbleBottom,
    required this.firstMessage,
    required this.secondMessage,
    required this.bubbleDelayAfterFullReveal,
    required this.bubbleTransitionDuration,
    required this.firstMessageVisibleDuration,
    required this.bubbleMaxWidth,
    required this.bubblePadding,
    required this.bubbleBorderRadius,
    required this.bubbleBackground,
    required this.bubbleTextStyle,
    required this.autoTailToCartoon,
    required this.bubbleTailOnRight,
    required this.bubbleTailOffset,
    required this.bubbleTailBottom,
    required this.onFinishedSecondMessage,
  });

  // Emoji
  final Color backgroundColor;
  final double greenSize;
  final double smallSize;
  final double spacing;
  final double greenOffset;
  final double yellowOffset;
  final double redOffset;

  // Cartoon
  final bool showCartoon;
  final String cartoonAsset;
  final double cartoonSize;
  final double cartoonVisibleHeight;
  final double? cartoonLeft;
  final double? cartoonRight;
  final double cartoonBottomOffset;
  final Duration cartoonDelay;
  final Duration cartoonDuration;
  final Curve cartoonCurve;
  final Duration fullRevealDelayAfterHead;
  final Duration fullRevealDuration;
  final Curve fullRevealCurve;
  final double fullRevealExtraOffset;

  // Bubble
  final double? bubbleLeft;
  final double? bubbleRight;
  final double bubbleBottom;
  final String firstMessage;
  final String secondMessage;
  final Duration bubbleDelayAfterFullReveal;
  final Duration bubbleTransitionDuration;
  final Duration firstMessageVisibleDuration;
  final double bubbleMaxWidth;
  final EdgeInsets bubblePadding;
  final BorderRadius bubbleBorderRadius;
  final Color bubbleBackground;
  final TextStyle bubbleTextStyle;

  final bool autoTailToCartoon;
  final bool bubbleTailOnRight;
  final double bubbleTailOffset;
  final double bubbleTailBottom;

  final VoidCallback onFinishedSecondMessage;

  @override
  State<_IntroScene> createState() => _IntroSceneState();
}

class _IntroSceneState extends State<_IntroScene> {
  // Cartoon bottom position
  late double _bottom;
  late Duration _curDur;
  late Curve _curCurve;

  bool _showBubble = false;
  int _bubbleIndex = 0; // 0 -> first, 1 -> second

  @override
  void initState() {
    super.initState();
    _bottom = -widget.cartoonSize + widget.cartoonBottomOffset;
    _curDur = widget.cartoonDuration;
    _curCurve = widget.cartoonCurve;

    // Step 1: delay -> head
    Future.delayed(widget.cartoonDelay, () {
      if (!mounted || !widget.showCartoon) return;
      setState(() {
        _curDur = widget.cartoonDuration;
        _curCurve = widget.cartoonCurve;
        _bottom = -(widget.cartoonSize - widget.cartoonVisibleHeight) +
            widget.cartoonBottomOffset;
      });

      // Step 2: to full
      final w2 = widget.cartoonDuration + widget.fullRevealDelayAfterHead;
      Future.delayed(w2, () {
        if (!mounted || !widget.showCartoon) return;
        setState(() {
          _curDur = widget.fullRevealDuration;
          _curCurve = widget.fullRevealCurve;
          _bottom = 0 + widget.cartoonBottomOffset + widget.fullRevealExtraOffset;
        });

        // Step 3: bubble
        final w3 = widget.fullRevealDuration + widget.bubbleDelayAfterFullReveal;
        Future.delayed(w3, () {
          if (!mounted) return;
          setState(() => _showBubble = true);

          // message 1 -> message 2
          Future.delayed(widget.firstMessageVisibleDuration, () {
            if (!mounted) return;
            setState(() => _bubbleIndex = 1);

            // แจ้งว่าจบข้อความที่สองแล้ว (ให้ parent เปลี่ยนฉาก/สไลด์)
            final totalTrans = widget.bubbleTransitionDuration;
            Future.delayed(totalTrans, () {
              if (!mounted) return;
              widget.onFinishedSecondMessage();
            });
          });
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      final h = c.maxHeight;

      // Emoji positions
      final greenBaseTop = h * 0.12;
      final smallBaseTop = h * 0.34;

      final greenTop = greenBaseTop + widget.greenOffset;
      final yellowTop = smallBaseTop + widget.yellowOffset;
      final redTop = smallBaseTop + widget.redOffset;

      final centerX = w / 2;
      const plusWidth = 24.0;
      final greenLeft = (w - widget.greenSize) / 2;
      final yellowLeft =
          centerX - widget.smallSize - widget.spacing - (plusWidth / 2);
      final redLeft = centerX + widget.spacing + (plusWidth / 2);

      // Cartoon center X (for auto-tail)
      final cartoonCenterX = widget.cartoonLeft != null
          ? (widget.cartoonLeft! + widget.cartoonSize / 2)
          : (w - ((widget.cartoonRight ?? 0) + widget.cartoonSize / 2));

      return Stack(
        children: [
          // Green
          Positioned(
            top: greenTop,
            left: greenLeft,
            child: Image.asset(
              'assets/icons/First_Green.png',
              width: widget.greenSize,
              height: widget.greenSize,
              fit: BoxFit.contain,
            ),
          ),

          // +
          Positioned(
            top: ((yellowTop + redTop) / 2.65) + (widget.smallSize / 2) - 12,
            left: centerX - (plusWidth / 2),
            child: const Text(
              '+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Yellow
          Positioned(
            top: yellowTop,
            left: yellowLeft,
            child: Image.asset(
              'assets/icons/First_Yellow.png',
              width: widget.smallSize,
              height: widget.smallSize,
              fit: BoxFit.contain,
            ),
          ),

          // Red
          Positioned(
            top: redTop,
            left: redLeft,
            child: Image.asset(
              'assets/icons/First_Red.png',
              width: widget.smallSize,
              height: widget.smallSize,
              fit: BoxFit.contain,
            ),
          ),

          // Cartoon
          if (widget.showCartoon)
            AnimatedPositioned(
              duration: _curDur,
              curve: _curCurve,
              bottom: _bottom,
              left: widget.cartoonLeft,
              right: widget.cartoonRight,
              child: IgnorePointer(
                ignoring: true,
                child: SizedBox(
                  width: widget.cartoonSize,
                  height: widget.cartoonSize,
                  child: Image.asset(widget.cartoonAsset, fit: BoxFit.contain),
                ),
              ),
            ),

          // Bubble
          if (_showBubble)
            Positioned(
              left: widget.bubbleLeft,
              right: widget.bubbleRight,
              bottom: widget.bubbleBottom,
              child: _AutoTailBubble(
                screenWidth: w,
                cartoonCenterX: cartoonCenterX,
                maxWidth: widget.bubbleMaxWidth,
                padding: widget.bubblePadding,
                borderRadius: widget.bubbleBorderRadius,
                background: widget.bubbleBackground,
                textStyle: widget.bubbleTextStyle,
                duration: widget.bubbleTransitionDuration,
                messages: [widget.firstMessage, widget.secondMessage],
                index: _bubbleIndex,
                bubbleLeft: widget.bubbleLeft,
                bubbleRight: widget.bubbleRight,
                tailBottom: widget.bubbleTailBottom,
                manualTailOnRight: widget.bubbleTailOnRight,
                manualTailOffset: widget.bubbleTailOffset,
                enableAutoTail: widget.autoTailToCartoon,
              ),
            ),
        ],
      );
    });
  }
}

/// ====== Auto-tail bubble ======
class _AutoTailBubble extends StatefulWidget {
  const _AutoTailBubble({
    super.key,
    required this.screenWidth,
    required this.cartoonCenterX,
    required this.maxWidth,
    required this.padding,
    required this.borderRadius,
    required this.background,
    required this.textStyle,
    required this.duration,
    required this.messages,
    required this.index,
    required this.bubbleLeft,
    required this.bubbleRight,
    required this.tailBottom,
    required this.manualTailOnRight,
    required this.manualTailOffset,
    required this.enableAutoTail,
  });

  final double screenWidth;
  final double cartoonCenterX;
  final double maxWidth;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color background;
  final TextStyle textStyle;
  final Duration duration;
  final List<String> messages;
  final int index;

  final double? bubbleLeft;
  final double? bubbleRight;
  final double tailBottom;

  final bool manualTailOnRight;
  final double manualTailOffset;
  final bool enableAutoTail;

  @override
  State<_AutoTailBubble> createState() => _AutoTailBubbleState();
}

class _AutoTailBubbleState extends State<_AutoTailBubble> {
  final _key = GlobalKey();
  double? _w;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rb = _key.currentContext?.findRenderObject() as RenderBox?;
      if (rb != null && rb.hasSize && _w != rb.size.width) {
        setState(() => _w = rb.size.width);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableAutoTail || _w == null) {
      return _BubbleSwitcher(
        key: _key,
        index: widget.index,
        duration: widget.duration,
        maxWidth: widget.maxWidth,
        padding: widget.padding,
        borderRadius: widget.borderRadius,
        background: widget.background,
        textStyle: widget.textStyle,
        messages: widget.messages,
        tailOnRight: widget.manualTailOnRight,
        tailOffset: widget.manualTailOffset,
        tailBottom: widget.tailBottom,
      );
    }

    final bw = _w!;
    final bubbleLeftX =
        widget.bubbleLeft ?? (widget.screenWidth - ((widget.bubbleRight ?? 0) + bw));
    final bubbleRightX = bubbleLeftX + bw;

    final distLeft = (widget.cartoonCenterX - bubbleLeftX).abs();
    final distRight = (bubbleRightX - widget.cartoonCenterX).abs();
    final tailOnRight = distRight < distLeft;

    double offsetFromEdge = tailOnRight
        ? (bubbleRightX - widget.cartoonCenterX)
        : (widget.cartoonCenterX - bubbleLeftX);
    offsetFromEdge = offsetFromEdge.clamp(12.0, bw - 12.0);

    return _BubbleSwitcher(
      key: _key,
      index: widget.index,
      duration: widget.duration,
      maxWidth: widget.maxWidth,
      padding: widget.padding,
      borderRadius: widget.borderRadius,
      background: widget.background,
      textStyle: widget.textStyle,
      messages: widget.messages,
      tailOnRight: tailOnRight,
      tailOffset: offsetFromEdge,
      tailBottom: widget.tailBottom,
    );
  }
}

class _BubbleSwitcher extends StatelessWidget {
  const _BubbleSwitcher({
    super.key,
    required this.index,
    required this.duration,
    required this.maxWidth,
    required this.padding,
    required this.borderRadius,
    required this.background,
    required this.textStyle,
    required this.messages,
    required this.tailOnRight,
    required this.tailOffset,
    required this.tailBottom,
  });

  final int index;
  final Duration duration;
  final double maxWidth;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color background;
  final TextStyle textStyle;
  final List<String> messages;

  final bool tailOnRight;
  final double tailOffset;
  final double tailBottom;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.05, 0.15),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: _SpeechBubble(
        key: ValueKey(index),
        text: messages[index],
        maxWidth: maxWidth,
        padding: padding,
        borderRadius: borderRadius,
        background: background,
        textStyle: textStyle,
        tailOnRight: tailOnRight,
        tailOffset: tailOffset,
        tailBottom: tailBottom,
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    super.key,
    required this.text,
    required this.maxWidth,
    required this.padding,
    required this.borderRadius,
    required this.background,
    required this.textStyle,
    this.tailOnRight = false,
    this.tailOffset = 24,
    this.tailBottom = -10,
  });

  final String text;
  final double maxWidth;
  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color background;
  final TextStyle textStyle;

  final bool tailOnRight;
  final double tailOffset;
  final double tailBottom;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: background,
              borderRadius: borderRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(text, style: textStyle),
          ),
        ),
        Positioned(
          left: tailOnRight ? null : tailOffset,
          right: tailOnRight ? tailOffset : null,
          bottom: tailBottom,
          child: Transform.rotate(
            angle: tailOnRight ? -0.785398 : 0.785398, // -45° / 45°
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
