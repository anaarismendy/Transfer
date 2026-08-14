import 'package:flutter/material.dart';

import 'package:prueba_tecnica/presentation/widgets/soft.dart';

class Wordmark extends StatelessWidget {
  final double size;

  const Wordmark({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: brandRaised(radius: size * 0.325),
      child: Icon(
        Icons.arrow_forward_rounded,
        color: Colors.white,
        size: size * 0.45,
      ),
    );
  }
}
