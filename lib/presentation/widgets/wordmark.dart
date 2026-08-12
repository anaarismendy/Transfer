import 'package:flutter/material.dart';

import '../../core/theme.dart';

class Wordmark extends StatelessWidget {
  final bool showTagline;
  final double fontSize;
  final Color color;
  final Color ruleColor;

  const Wordmark({
    super.key,
    this.showTagline = true,
    this.fontSize = 30,
    this.color = mist,
    this.ruleColor = aqua,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'TRANSFER',
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            height: 1,
            fontWeight: FontWeight.w300,
            letterSpacing: fontSize * 0.3,
          ),
        ),
        SizedBox(height: fontSize * 0.3),
        Container(width: fontSize * 3, height: 1.5, color: ruleColor),
        if (showTagline) ...[
          const SizedBox(height: 10),
          Text(
            'CONSOLA DE TRANSFERENCIAS',
            style: eyebrow.copyWith(color: color.withValues(alpha: 0.7)),
          ),
        ],
      ],
    );
  }
}
