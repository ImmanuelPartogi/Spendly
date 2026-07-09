import 'package:flutter/material.dart';
import '../../core/utils/category_utils.dart';

class CategoryBubble extends StatelessWidget {
  final String category;
  final double size;

  const CategoryBubble({
    super.key,
    required this.category,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final color = CategoryUtils.getColor(category);
    final icon = CategoryUtils.getIcon(category);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: color,
        size: size * 0.50,
      ),
    );
  }
}