import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  /// Si fourni (cas de l'onglet Panier dans la barre du bas), bascule vers
  /// l'onglet Boutique au lieu de tenter un Navigator.pop() qui n'a rien
  /// en dessous puisque cet écran n'est pas "poussé" mais affiché tel quel.
  final VoidCallback? onContinueShopping;
  const CartScreen({super.key, this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Mon panier')),
      body: cart.isEmpty
          ? EmptyState(
              icon: Icons.shopping_bag_outlined,
              title: 'Votre panier est vide',
              message: 'Parcourez la boutique et ajoutez vos articles préférés.',
              actionLabel: 'Continuer mes achats',
              onAction: onContinueShopping ?? () => Navigator.maybePop(context),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.line),
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: Row(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 58, height: 58,
                              child: item.product.images.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: item.product.images.first, fit: BoxFit.cover)
                                  : Container(color: AppColors.line),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              if (item.size != null || item.color != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                                  child: Text([if (item.size != null) item.size, if (item.color != null) item.color].join(' · '),
                                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                )
                              else
                                const SizedBox(height: 6),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                Text(Formatters.cfa(item.lineTotal), style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w600, fontSize: 13)),
                                Container(
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    IconButton(iconSize: 16, icon: const Icon(Icons.remove), onPressed: () => cart.decrement(item.lineKey)),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    IconButton(iconSize: 16, icon: const Icon(Icons.add), onPressed: () => cart.increment(item.lineKey)),
                                  ]),
                                ),
                              ]),
                            ]),
                          ),
                        ]),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
                  child: Column(children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      const Text('Sous-total', style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft)),
                      Text(Formatters.cfa(cart.subtotal), style: const TextStyle(fontSize: 12.5)),
                    ]),
                    const SizedBox(height: 6),
                    const Text('Frais de livraison calculés à l\'étape suivante', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                        child: const Text('Passer la commande'),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
    );
  }
}
