import 'package:flutter/material.dart';

class SweetCake {
  SweetCake({required this.center, required this.size});

  Offset center;
  double size;

  Offset get topLeft => center - Offset(size / 2, size / 2);
}
