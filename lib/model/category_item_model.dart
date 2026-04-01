import 'package:flutter/material.dart';

class CategoryItemModel {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  CategoryItemModel({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
