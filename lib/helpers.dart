import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

Color interpolateColour(int percentage) {
  int r1 = 255, g1 = 0, b1 = 0;
  int r2 = 255, g2 = 255, b2 = 0;
  int r3 = 0, g3 = 255, b3 = 0;
  int r, g, b;
  int n = max(100 - percentage, 0);

  if (n <= 30) {
    r = (r1 + ((r2 - r1) * n / 30)).round();
    g = (g1 + ((g2 - g1) * n / 30)).round();
    b = (b1 + ((b2 - b1) * n / 30)).round();
  } else {
    r = (r2 + ((r3 - r2) * (n - 30) / 70)).round();
    g = (g2 + ((g3 - g2) * (n - 30) / 70)).round();
    b = (b2 + ((b3 - b2) * (n - 30) / 70)).round();
  }
  return Color.fromRGBO(r, g, b, 1.0);
}
