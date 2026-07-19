import 'package:flutter/material.dart';

class BlinkingMic extends StatefulWidget {
  final Widget child;
  const BlinkingMic({super.key, required this.child});
  @override
  State<BlinkingMic> createState() => _BlinkingMicState();
}

class _BlinkingMicState extends State<BlinkingMic>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: widget.child);
  }
}
