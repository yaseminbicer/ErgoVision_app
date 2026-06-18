import 'dart:ui';
import 'package:flutter/material.dart';
import 'sidebar_widget.dart';

class AppLayout extends StatefulWidget {
  final Widget? child;
  final Widget Function(VoidCallback toggleMenu)? builder;
  final String currentPage;

  const AppLayout({
    super.key,
    this.child,
    this.builder,
    required this.currentPage,
  }) : assert(child != null || builder != null);

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final double menuWidth = 280;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  void toggleMenu() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// MAIN CONTENT (with slide + scale animation)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              double slide = menuWidth * _animation.value;
              double scale = 1 - (_animation.value * 0.05);

              return Transform(
                transform: Matrix4.identity()
                  ..translate(slide)
                  ..scale(scale),
                alignment: Alignment.centerLeft,
                child: child,
              );
            },
            child: widget.builder?.call(toggleMenu) ?? widget.child!,
          ),

          /// OVERLAY (tap outside to close)
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return _animation.value > 0
                  ? GestureDetector(
                      onTap: toggleMenu,
                      child: Container(
                        color: Colors.black.withOpacity(0.2 * _animation.value),
                      ),
                    )
                  : const SizedBox();
            },
          ),

          /// SIDEBAR
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-menuWidth + (menuWidth * _animation.value), 0),
                child: SizedBox(
                  width: menuWidth,
                  child: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                      child: SidebarWidget(
                        currentPage: widget.currentPage,
                        onClose: toggleMenu,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
