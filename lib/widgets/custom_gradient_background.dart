
import 'package:flutter/material.dart';

class CustomGradientBackground extends StatelessWidget {
  final Widget child;

  const CustomGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFFFFCF5),
        gradient: RadialGradient(
          center: Alignment(-0.95, -0.85),
          radius: 1.6,
          colors: [
            Color(0xFFBDE9B9),
            Color(0xFFE4F5DF),
            Color(0xFFFFFCF5),
            Color(0xFFFFE6A3),
          ],
          stops: [0.0, 0.27, 0.62, 1.0],
        ),
      ),
      child: child,
    );
  }
}
