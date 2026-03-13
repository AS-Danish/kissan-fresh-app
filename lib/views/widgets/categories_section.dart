import 'package:flutter/material.dart';
import 'package:kissanfresh/views/widgets/selectable_category_card.dart';
import '../../model/category_item_model.dart';

class CategoriesSection extends StatelessWidget {
  final List<CategoryItemModel> categories;
  final int selectedIndex;
  final Function(int) onCategorySelected;

  const CategoriesSection({
    super.key,
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 85,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = categories[index];
          final bool isSelected = selectedIndex == index;

          return SelectableCategoryCard(
            icon: item.icon,
            label: item.label,
            isSelected: isSelected,
            onTap: () => onCategorySelected(index),
          );
        },
      ),
    );
  }
}
