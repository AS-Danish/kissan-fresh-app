import 'package:flutter/material.dart';

class BestsellerCardModel {
  final String image1;
  final String image2;
  final String image3;
  final String image4;
  final String moreCount;
  final String title;
  final VoidCallback onTap;

  BestsellerCardModel({
    required this.image1,
    required this.image2,
    required this.image3,
    required this.image4,
    required this.moreCount,
    required this.title,
    required this.onTap,
  });
}
