import 'package:flutter/material.dart';

import 'package:windmark/app/app_copy.dart';
import 'package:windmark/app/theme.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = AppColors.card,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class DisclaimerNote extends StatelessWidget {
  const DisclaimerNote({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppCopy.disclaimer,
      style: Theme.of(context).textTheme.bodySmall
          ?.copyWith(color: AppColors.inkSoft, height: 1.5),
    );
  }
}

class SealMark extends StatelessWidget {
  const SealMark({super.key, required this.text, this.size = 56});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.cinnabar,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.46,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// 按钮因未填所问而不可用时，仍接收点击。
class FillQuestionTap extends StatelessWidget {
  const FillQuestionTap({
    super.key,
    required this.blocked,
    required this.onBlocked,
    required this.child,
  });

  final bool blocked;
  final VoidCallback onBlocked;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!blocked) {
      return child;
    }
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBlocked,
          ),
        ),
      ],
    );
  }
}

class ToneBadge extends StatelessWidget {
  const ToneBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}
