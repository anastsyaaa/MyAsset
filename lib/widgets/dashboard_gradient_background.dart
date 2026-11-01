import 'package:flutter/material.dart';

class DashboardGradientBackground extends StatelessWidget {
  final Widget child;

  const DashboardGradientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Warna dasar putih krem
        const Positioned.fill(
          child: ColoredBox(
            color: Color(0xFFFFFDF8),
          ),
        ),

        // Gradasi hijau kiri atas
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1.15, -1.05),
                radius: 0.95,
                colors: [
                  Color(0xFFBCE9B8),
                  Color(0xFFE6F5E2),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),

        // Gradasi kuning kanan atas
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1.2, -1.1),
                radius: 0.9,
                colors: [
                  Color(0xFFFFD978),
                  Color(0xFFFFEAB5),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),

        // Gradasi hijau kiri bawah
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-1.15, 1.15),
                radius: 0.85,
                colors: [
                  Color(0xFFBCE9B8),
                  Color(0xFFE6F5E2),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),

        // Gradasi kuning kanan bawah
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(1.15, 1.15),
                radius: 0.85,
                colors: [
                  Color(0xFFFFD978),
                  Color(0xFFFFEAB5),
                  Color(0x00FFFFFF),
                ],
                stops: [0.0, 0.35, 1.0],
              ),
            ),
          ),
        ),

        // Konten Dashboard dan navigasi tetap di atas gradasi
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}