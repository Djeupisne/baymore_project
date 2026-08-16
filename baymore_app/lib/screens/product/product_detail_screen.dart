import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../l10n/app_strings.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../services/stock_alert_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/star_rating.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _service = ProductService();
  String? _selectedSize;
  String? _selectedColor;
  int _quantity = 1;
  int _pageIndex = 0;
  final PageController _pageController = PageController();

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: FutureBuilder<Product?>(
        future: _service.getById(widget.productId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final product = snap.data;
          if (product == null) return Center(child: Text(strings.t('productNotFound')));
          final fav = context.watch<FavoritesProvider>();

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: product.images.isEmpty
                                ? Container(color: AppColors.line)
                                : PageView.builder(
                                    controller: _pageController,
                                    itemCount: product.images.length,
                                    onPageChanged: (i) => setState(() => _pageIndex = i),
                                    itemBuilder: (context, i) => CachedNetworkImage(imageUrl: product.images[i], fit: BoxFit.cover),
                                  ),
                          ),
                          if (product.images.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0, right: 0,
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _pageController,
                                  count: product.images.length,
                                  effect: const WormEffect(dotHeight: 6, dotWidth: 6, activeDotColor: AppColors.gold, dotColor: Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 10, left: 10,
                            child: CircleAvatar(backgroundColor: Colors.white.withOpacity(.92),
                                child: IconButton(icon: const Icon(Icons.arrow_back, size: 18), onPressed: () => Navigator.pop(context))),
                          ),
                          Positioned(
                            top: 10, right: 10,
                            child: CircleAvatar(backgroundColor: Colors.white.withOpacity(.92),
                                child: IconButton(
                                  icon: Icon(fav.isFavorite(product.id) ? Icons.favorite : Icons.favorite_border, size: 18, color: AppColors.rose),
                                  onPressed: () => fav.toggle(product.id),
                                )),
                          ),
                        ]),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.subCategory.toUpperCase(),
                                  style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w700, letterSpacing: .06)),
                              const SizedBox(height: 4),
                              Text(product.name, style: Theme.of(context).textTheme.displayMedium),
                              const SizedBox(height: 8),
                              Row(children: [
                                Text(Formatters.cfa(product.price), style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 19, color: AppColors.ink)),
                                if (product.oldPrice != null) ...[
                                  const SizedBox(width: 10),
                                  Text(Formatters.cfa(product.oldPrice!), style: const TextStyle(decoration: TextDecoration.lineThrough, color: AppColors.muted, fontSize: 13)),
                                ],
                                const Spacer(),
                                const Icon(Icons.star, size: 15, color: AppColors.gold),
                                const SizedBox(width: 3),
                                Text('${product.rating.toStringAsFixed(1)} (${product.ratingCount})', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                              ]),
                              const SizedBox(height: 18),
                              if (product.sizes.isNotEmpty) ...[
                                Text(strings.size, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, children: product.sizes.map((s) {
                                  final selected = _selectedSize == s;
                                  return ChoiceChip(
                                    label: Text(s),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _selectedSize = s),
                                    selectedColor: AppColors.ink,
                                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.line),
                                  );
                                }).toList()),
                                const SizedBox(height: 18),
                              ],
                              if (product.colors.isNotEmpty) ...[
                                Text(strings.color, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, children: product.colors.map((c) {
                                  final selected = _selectedColor == c;
                                  return ChoiceChip(
                                    label: Text(c),
                                    selected: selected,
                                    onSelected: (_) => setState(() => _selectedColor = c),
                                    selectedColor: AppColors.ink,
                                    labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
                                    backgroundColor: Colors.white,
                                    side: const BorderSide(color: AppColors.line),
                                  );
                                }).toList()),
                                const SizedBox(height: 18),
                              ],
                              Text(strings.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                              const SizedBox(height: 6),
                              Text(product.description.isEmpty ? strings.t('noDescription') : product.description,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.5)),
                              const SizedBox(height: 10),
                              Text(product.inStock ? strings.tf('inStock', ['${product.stock}']) : strings.outOfStock,
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: product.inStock ? AppColors.success : AppColors.danger)),
                              const SizedBox(height: 24),
                              _ReviewsSection(product: product),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
                  child: product.inStock
                      ? Row(children: [
                          Container(
                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Row(children: [
                              IconButton(icon: const Icon(Icons.remove, size: 16), onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1)),
                              Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
                              IconButton(icon: const Icon(Icons.add, size: 16), onPressed: () => setState(() => _quantity++)),
                            ]),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                context.read<CartProvider>().addItem(product, size: _selectedSize, color: _selectedColor, quantity: _quantity);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(strings.tf('addedToCart', [product.name])),
                                  action: SnackBarAction(label: strings.t('viewCart'), textColor: AppColors.gold, onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()))),
                                ));
                              },
                              child: Text(strings.tf('addToCartWithPrice', [Formatters.cfa(product.price * _quantity)])),
                            ),
                          ),
                        ])
                      : _StockAlertButton(product: product),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Avis clients : lecture publique, dépôt réservé aux clients connectés.
/// La note moyenne affichée en haut de la fiche (product.rating) est
/// recalculée côté serveur à chaque nouvel avis.
class _ReviewsSection extends StatefulWidget {
  final Product product;
  const _ReviewsSection({required this.product});
  @override
  State<_ReviewsSection> createState() => _ReviewsSectionState();
}

class _ReviewsSectionState extends State<_ReviewsSection> {
  final _reviewService = ReviewService();
  late Future<List<Review>> _future;

  @override
  void initState() {
    super.initState();
    _future = _reviewService.fetchForProduct(widget.product.id);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(strings.t('customerReviews'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
          TextButton(
            onPressed: () => _openReviewDialog(context, strings),
            child: Text(strings.t('leaveReview'), style: const TextStyle(color: AppColors.goldDeep, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 8),
        FutureBuilder<List<Review>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
            final reviews = snap.data!;
            if (reviews.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(strings.t('noReviewsYet'),
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              );
            }
            return Column(
              children: reviews.map((r) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      StarRating(rating: r.rating, size: 13),
                    ]),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4)),
                    ],
                  ]),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  void _openReviewDialog(BuildContext context, AppStrings strings) {
    final auth = context.read<AuthProvider>();
    if (auth.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.t('loginToReview'))));
      return;
    }
    double rating = 5;
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(strings.t('yourReview')),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            StarRating(rating: rating, size: 26, onRate: (v) => setState(() => rating = v.toDouble())),
            const SizedBox(height: 12),
            TextField(controller: commentCtrl, maxLines: 3, decoration: InputDecoration(hintText: strings.t('yourCommentOptional'))),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.actionCancel)),
            ElevatedButton(
              onPressed: () async {
                await _reviewService.add(widget.product.id, rating: rating, comment: commentCtrl.text.trim());
                if (context.mounted) Navigator.pop(context);
                this.setState(() => _future = _reviewService.fetchForProduct(widget.product.id));
              },
              child: Text(strings.actionPublish),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton "Me prévenir" affiché à la place du bouton d'achat quand
/// l'article est en rupture de stock.
class _StockAlertButton extends StatefulWidget {
  final Product product;
  const _StockAlertButton({required this.product});
  @override
  State<_StockAlertButton> createState() => _StockAlertButtonState();
}

class _StockAlertButtonState extends State<_StockAlertButton> {
  final _service = StockAlertService();
  bool? _subscribed;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    if (auth.uid != null) {
      _service.isSubscribed(widget.product.id).then((v) {
        if (mounted) setState(() => _subscribed = v);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final strings = AppStrings.of(context);
    if (auth.uid == null) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(strings.t('loginToBeNotified')))),
          icon: const Icon(Icons.notifications_none, size: 18),
          label: Text(strings.t('notifyMeRestock')),
        ),
      );
    }

    final subscribed = _subscribed ?? false;
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _subscribed == null
            ? null
            : () async {
                if (subscribed) {
                  await _service.unsubscribe(widget.product.id);
                  setState(() => _subscribed = false);
                } else {
                  await _service.subscribe(widget.product.id);
                  setState(() => _subscribed = true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.t('notifiedWhenBack'))));
                  }
                }
              },
        icon: Icon(subscribed ? Icons.notifications_active : Icons.notifications_none, size: 18, color: subscribed ? AppColors.gold : AppColors.ink),
        label: Text(subscribed ? strings.t('youWillBeNotified') : strings.t('notifyMeRestock')),
      ),
    );
  }
}
