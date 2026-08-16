import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import 'order_tracking_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _showActive = true;
  final _service = OrderService();
  bool _reordering = false;
  Future<List<AppOrder>>? _future;
  String? _lastUid;

  Future<List<AppOrder>> _load() => _service.fetchMine(active: _showActive);

  void _setTab(bool active) {
    setState(() {
      _showActive = active;
      _future = _load();
    });
  }

  /// Ajoute au panier tous les articles d'une commande passée, en
  /// vérifiant leur disponibilité actuelle — le client n'a plus besoin de
  /// tout ressaisir pour racheter les mêmes articles.
  Future<void> _reorder(BuildContext context, AppOrder order) async {
    if (_reordering) return;
    setState(() => _reordering = true);
    final cart = context.read<CartProvider>();
    final productService = ProductService();
    int added = 0;
    int unavailable = 0;
    for (final item in order.items) {
      final product = await productService.getById(item['productId'] as String);
      if (product == null || !product.inStock) {
        unavailable++;
        continue;
      }
      cart.addItem(product, size: item['size'], color: item['color'], quantity: (item['quantity'] ?? 1) as int);
      added++;
    }
    setState(() => _reordering = false);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(unavailable == 0
          ? '$added article(s) ajouté(s) au panier'
          : '$added article(s) ajouté(s) · $unavailable indisponible(s)'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().uid;
    // Le widget reste vivant en permanence dans l'IndexedStack de la
    // navigation : sans ce suivi du uid, un changement de compte dans la
    // même session laisserait affichée la liste de commandes du compte
    // précédent (didChangeDependencies ne recharge qu'une seule fois).
    if (uid != _lastUid || _future == null) {
      _lastUid = uid;
      _future = _load();
    }
    final strings = AppStrings.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(strings.myOrders, style: Theme.of(context).textTheme.displayMedium),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setTab(true),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showActive ? AppColors.ink : Colors.transparent,
                        border: Border.all(color: AppColors.line),
                        borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                      ),
                      child: Text(strings.tabActive, style: TextStyle(color: _showActive ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setTab(false),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showActive ? AppColors.ink : Colors.transparent,
                        border: Border.all(color: AppColors.line),
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(22)),
                      ),
                      child: Text(strings.tabHistory, style: TextStyle(color: !_showActive ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: uid == null
                  ? EmptyState(icon: Icons.receipt_long_outlined, title: strings.loginToTrack, message: strings.loginToTrackMsg)
                  : RefreshIndicator(
                      onRefresh: () async { setState(() => _future = _load()); await _future; },
                      child: FutureBuilder<List<AppOrder>>(
                      future: _future,
                      builder: (context, snap) {
                        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                        final orders = snap.data!;
                        if (orders.isEmpty) {
                          return EmptyState(
                            icon: Icons.receipt_long_outlined,
                            title: _showActive ? strings.noActiveOrders : strings.noHistory,
                            message: _showActive ? strings.noActiveOrdersMsg : strings.noHistoryMsg,
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          itemCount: orders.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final o = orders[i];
                            return GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: o.id))),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                                    Text(strings.tf('orderNumber', [o.id.substring(0, 6).toUpperCase()]), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(20)),
                                      child: Text(o.status.labelFor(context), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
                                    ),
                                  ]),
                                  const SizedBox(height: 6),
                                  Text(Formatters.shortDate(o.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                                  const SizedBox(height: 10),
                                  Text('${o.items.length} article(s) · ${o.deliveryMode.labelFor(context)}', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(height: 6),
                                  Text(Formatters.cfa(o.total), style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 14)),
                                  if (o.status == OrderStatus.livree) ...[
                                    const SizedBox(height: 10),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _reorder(context, o),
                                        icon: const Icon(Icons.replay, size: 16),
                                        label: Text(strings.t('reorder')),
                                      ),
                                    ),
                                  ],
                                ]),
                              ),
                            );
                          },
                        );
                      },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
