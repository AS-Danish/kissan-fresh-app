import 'dart:ui';

class PromotionalCardModel {
  final String titleText;
  final String btnText;
  final VoidCallback onTap;

  PromotionalCardModel({
    required this.titleText,
    required this.btnText,
    required this.onTap,
  });
}
