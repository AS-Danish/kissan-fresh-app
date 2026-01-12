import 'package:flutter/cupertino.dart';

class DealsCardModel {
  final IconData icon;
  final String label;
  final String title;
  final String size;
  final String description;
  final String price;

  DealsCardModel({
    required this.icon,
    required this.title,
    required this.label,
    required this.size,
    required this.description,
    required this.price,
  });
}
