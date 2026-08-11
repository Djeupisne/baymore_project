import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/favorites_provider.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const ProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fav = context.watch<FavoritesProvider>();
    final isFav = fav.isFavorite(product.id);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.15,
                  child: product.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.line),
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.line, child: const Icon(Icons.image_outlined)),
                        )
                      : Container(color: AppColors.line),
                ),
                if (product.isNew || product.isPromo)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        product.isPromo ? 'PROMO' : 'NOUVEAU',
                        style: const TextStyle(
                            color: AppColors.ivory, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => fav.toggle(product.id),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: Colors.white.withOpacity(.92),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        size: 14,
                        color: AppColors.rose,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.subCategory.toUpperCase(),
                      style: const TextStyle(fontSize: 9, letterSpacing: .06, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(Formatters.cfa(product.price),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.ink)),
                      if (product.ratingCount > 0)
                        Row(children: [
                          const Icon(Icons.star, size: 12, color: AppColors.gold),
                          const SizedBox(width: 2),
                          Text(product.rating.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                        ]),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
