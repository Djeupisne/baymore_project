import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final void Function(int)? onRate;
  const StarRating({super.key, required this.rating, this.size = 16, this.onRate});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) {
      final filled = i < rating.round();
      final star = Icon(filled ? Icons.star : Icons.star_border, size: size, color: AppColors.gold);
      if (onRate == null) return star;
      return GestureDetector(onTap: () => onRate!(i + 1), child: Padding(padding: const EdgeInsets.only(right: 2), child: star));
    }));
  }
}
