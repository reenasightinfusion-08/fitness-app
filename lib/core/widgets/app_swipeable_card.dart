import 'package:flutter/material.dart';

import 'package:fitness_app/core/theme/theme.dart';
import 'package:fitness_app/core/widgets/app_bottom_sheet.dart';

/// A card wrapper that allows horizontal swipe to reveal a right-aligned
/// action button capped at 20% of the container width.
class AppSwipeableCard extends StatefulWidget {
  const AppSwipeableCard({
    super.key,
    required this.child,
    required this.onDelete,
    required this.confirmTitle,
    required this.confirmMessage,
  });

  final Widget child;
  final VoidCallback onDelete;
  final String confirmTitle;
  final String confirmMessage;

  @override
  State<AppSwipeableCard> createState() => _AppSwipeableCardState();
}

class _AppSwipeableCardState extends State<AppSwipeableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double actionWidth) {
    setState(() {
      _dragExtent = (_dragExtent + details.primaryDelta!).clamp(-actionWidth, 0.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details, double actionWidth) {
    if (_dragExtent.abs() > actionWidth / 2) {
      _animateTo(-actionWidth);
    } else {
      _animateTo(0.0);
    }
  }

  void _animateTo(double target) {
    _animation = Tween<double>(
      begin: _dragExtent,
      end: target,
    ).animate(_controller)..addListener(() => setState(() {
        _dragExtent = _animation.value;
      }));
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionWidth = constraints.maxWidth * 0.20;

        return Stack(
          children: [
            // Red Delete button background on the right 20%
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: actionWidth,
                  child: Material(
                    color: context.colors.danger,
                    borderRadius: AppBorderRadius.xxl,
                    child: InkWell(
                      borderRadius: AppBorderRadius.xxl,
                      onTap: () async {
                        final confirmed = await AppBottomSheet.confirm(
                          context,
                          title: widget.confirmTitle,
                          message: widget.confirmMessage,
                          confirmLabel: 'Delete routine',
                          isDestructive: true,
                        );
                        if (confirmed == true) {
                          widget.onDelete();
                        } else {
                          _animateTo(0.0);
                        }
                      },
                      child: Center(
                        child: Icon(Icons.delete_outline_rounded, color: AppColors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main child card capped to slide at most 20% left
            GestureDetector(
              onHorizontalDragUpdate: (details) =>
                  _onHorizontalDragUpdate(details, actionWidth),
              onHorizontalDragEnd: (details) =>
                  _onHorizontalDragEnd(details, actionWidth),
              child: Transform.translate(
                offset: Offset(_dragExtent, 0),
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}
