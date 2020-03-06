import 'package:flutter/widgets.dart';

const NOT_FOUND = -1;

class SlidingBehaviour extends StatefulWidget {
  final Widget child;

  final double minHeight;
  final double maxHeight;
  final List<double> anchors;
  final Function(double value) onSlide;
  final Function(int anchorIndex) onSnap;
  SlidingBehaviour({
    @required this.child,
    @required this.minHeight,
    @required this.maxHeight,
    @required this.onSlide,
    @required this.onSnap,
    this.anchors = const [0.0, 1.0],
    Key key,
  }) : super(key: key);

  @override
  _SlidingBehaviourState createState() => _SlidingBehaviourState();
}

class _SlidingBehaviourState extends State<SlidingBehaviour> with SingleTickerProviderStateMixin {
  AnimationController slidingAnimation;

  double get minHeight => widget.minHeight;
  double get maxHeight => widget.maxHeight;

  @override
  void initState() {
    slidingAnimation = AnimationController(vsync: this);
    slidingAnimation.addListener(_onSlide);
    slidingAnimation.addStatusListener(_onSlideAnimationStatusChanged);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: slidingAnimation,
        builder: (BuildContext context, Widget child) {
          return SizedBox(
            height: _calculateSheetHeight(),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }

  @override
  void dispose() {
    slidingAnimation.dispose();
    super.dispose();
  }

  void _onSlide() {
    if (widget.onSlide != null) {
      widget.onSlide(slidingAnimation.value);
    }
  }

  void _onSlideAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      final anchorIndex = widget.anchors.indexWhere((anchor) => anchor == slidingAnimation.value);
      if (anchorIndex != -1 && widget.onSnap != null) {
        widget.onSnap(anchorIndex);
      }
    }
  }

  void _onDragStart(DragStartDetails event) {
    // 1. Check if scroll available. If so, return
    // 2. Dismiss all running animations
  }

  void _onDragUpdate(DragUpdateDetails event) {
    slidingAnimation.value -= event.delta.dy / (maxHeight - minHeight);
  }

  void _onDragEnd(DragEndDetails event) {
    final y = slidingAnimation.value;
    final velocity = event.velocity.pixelsPerSecond.dy;

    final snapPointIndex = _findPointToSnapIndex(y, velocity);
    snapTo(snapPointIndex);
  }

  int _findPointToSnapIndex(double currentValue, double velocity) {
    final upperAnchorIndex = widget.anchors.indexWhere((anchor) => anchor >= currentValue);
    final bottomAnchorIndex = widget.anchors.lastIndexWhere((anchor) => anchor < currentValue);

    if (velocity < 0 && upperAnchorIndex != NOT_FOUND) {
      return upperAnchorIndex;
    } else {
      return bottomAnchorIndex == NOT_FOUND ? 0 : bottomAnchorIndex;
    }
  }

  double _calculateSheetHeight() {
    return slidingAnimation.value * (maxHeight - minHeight) + minHeight;
  }

  Future<void> snapTo(int anchorIndex) {
    final positionToAnimate = widget.anchors[anchorIndex];

    return slidingAnimation.animateTo(
      positionToAnimate,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }
}