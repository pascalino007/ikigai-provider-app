import 'package:flutter/material.dart';

/// Curved bottom edge for the green hero header (wallet-style transition to white body).
class DashboardHeaderClipper extends CustomClipper<Path> {
  DashboardHeaderClipper({this.curveHeight = 28});

  final double curveHeight;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - curveHeight)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height + curveHeight * 0.35,
        size.width,
        size.height - curveHeight,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant DashboardHeaderClipper oldClipper) =>
      oldClipper.curveHeight != curveHeight;
}
