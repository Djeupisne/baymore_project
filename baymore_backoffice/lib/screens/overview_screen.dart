import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';
import 'orders_screen.dart';
import 'returns_screen.dart';

/// Tableau de bord : vue d'ensemble pour l'administrateur — chiffre
/// d'affaires, tendance des 7 derniers jours, top produits et commandes
/// qui attendent une action, pour piloter la boutique en un coup d'œil.
/// Se met à jour en temps réel dès qu'une commande est créée ou change
/// de statut, sans avoir à changer d'onglet ni tirer pour rafraîchir.
class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});
  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  List<AppOrder>? _orders;
  String? _error;
  int? _touchedBarIndex;

  StreamSubscription? _newOrderSub;
  StreamSubscription? _updateOrderSub;

  @override
  void initState() {
    super.initState();
    _load();
    final socket = SocketService().socket;
    _newOrderSub = _listen(socket, 'order:new', (data) {
      if (_orders == null) return;
      final order = AppOrder.fromJson(Map<String, dynamic>.from(data));
      if (!mounted) return;
      setState(() => _orders = [order, ..._orders!.where((o) => o.id != order.id)]);
    });
    _updateOrderSub = _listen(socket, 'order:update', (data) {
      if (_orders == null) return;
      final updated = AppOrder.fromJson(Map<String, dynamic>.from(data));
      if (!mounted) return;
      setState(() => _orders = _orders!.map((o) => o.id == updated.id ? updated : o).toList());
    });
  }

  StreamSubscription _listen(dynamic socket, String event, void Function(dynamic) handler) {
    socket.on(event, handler);
    return _SocketOffSub(socket, event, handler);
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final orders = await OrderService().fetchAll();
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e is ApiException ? e.message : 'Impossible de charger le tableau de bord.');
    }
  }

  @override
  void dispose() {
    _newOrderSub?.cancel();
    _updateOrderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_orders == null && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _orders == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 36),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 14),
            OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
          ]),
        ),
      );
    }

    final orders = _orders!.where((o) => o.status != OrderStatus.annulee).toList();
    final today = DateTime.now();
    final todayOrders = orders.where((o) =>
        o.createdAt.year == today.year && o.createdAt.month == today.month && o.createdAt.day == today.day).toList();
    final revenueToday = todayOrders.fold<double>(0, (sum, o) => sum + o.total);

    final allOrders = _orders!;
    final enAttente = allOrders.where((o) => o.status == OrderStatus.enAttente).toList();
    final priseEnCharge = allOrders.where((o) => o.status == OrderStatus.priseEnCharge).toList();
    final enRoute = allOrders.where((o) => o.status == OrderStatus.enRoute).toList();
    final paiementEnAttente = allOrders.where((o) => o.paymentStatus == 'EN_ATTENTE').toList();

    // Chiffre d'affaires des 7 derniers jours, jour par jour.
    final last7 = List.generate(7, (i) => DateTime(today.year, today.month, today.day).subtract(Duration(days: 6 - i)));
    final dailyRevenue = last7.map((day) {
      return orders.where((o) =>
          o.createdAt.year == day.year && o.createdAt.month == day.month && o.createdAt.day == day.day)
          .fold<double>(0, (sum, o) => sum + o.total);
    }).toList();
    final dailyCount = last7.map((day) {
      return orders.where((o) =>
          o.createdAt.year == day.year && o.createdAt.month == day.month && o.createdAt.day == day.day).length;
    }).toList();

    final weekTotal = dailyRevenue.fold<double>(0, (a, b) => a + b);
    final maxRevenue = dailyRevenue.fold<double>(0, (a, b) => b > a ? b : a);

    // Comparaison avec les 7 jours précédents pour afficher une tendance.
    final prev7Start = last7.first.subtract(const Duration(days: 7));
    final prevWeekTotal = orders.where((o) =>
        !o.createdAt.isBefore(prev7Start) && o.createdAt.isBefore(last7.first))
        .fold<double>(0, (sum, o) => sum + o.total);
    final trendPct = prevWeekTotal > 0 ? ((weekTotal - prevWeekTotal) / prevWeekTotal * 100) : (weekTotal > 0 ? 100.0 : 0.0);

    // Top 3 articles les plus vendus (toutes commandes non annulées).
    final Map<String, int> soldQuantities = {};
    for (final o in orders) {
      for (final item in o.items) {
        final name = item['name'] ?? 'Article';
        soldQuantities[name] = (soldQuantities[name] ?? 0) + ((item['quantity'] ?? 1) as num).toInt();
      }
    }
    final topProducts = soldQuantities.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(children: [
            Expanded(child: _statCard('Commandes du jour', '${todayOrders.length}', Icons.today_outlined, AppColors.ink)),
            const SizedBox(width: 12),
            Expanded(child: _statCard('Chiffre d\'affaires du jour', '${revenueToday.toStringAsFixed(0)} F', Icons.payments_outlined, AppColors.success)),
          ]),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tendance des ventes (7 derniers jours)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (trendPct >= 0 ? AppColors.success : AppColors.danger).withOpacity(.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(trendPct >= 0 ? Icons.trending_up : Icons.trending_down,
                    size: 13, color: trendPct >= 0 ? AppColors.success : AppColors.danger),
                const SizedBox(width: 3),
                Text('${trendPct >= 0 ? '+' : ''}${trendPct.toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: trendPct >= 0 ? AppColors.success : AppColors.danger)),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Text('${weekTotal.toStringAsFixed(0)} F CFA cette semaine · vs semaine précédente',
              style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 12),
          Container(
            height: 200,
            padding: const EdgeInsets.fromLTRB(4, 20, 12, 8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: dailyRevenue.every((v) => v == 0)
                ? const Center(child: Text('Aucune vente cette semaine', style: TextStyle(color: AppColors.muted, fontSize: 12)))
                : BarChart(
                    BarChartData(
                      maxY: maxRevenue == 0 ? 10 : maxRevenue * 1.25,
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.ink,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final day = DateFormat('EEEE d MMM', 'fr_FR').format(last7[groupIndex]);
                            final count = dailyCount[groupIndex];
                            return BarTooltipItem(
                              '${rod.toY.toStringAsFixed(0)} F CFA\n',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12),
                              children: [
                                TextSpan(
                                  text: '$day · $count commande${count > 1 ? 's' : ''}',
                                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500, fontSize: 10.5),
                                ),
                              ],
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          setState(() {
                            if (!event.isInterestedForInteractions || response == null || response.spot == null) {
                              _touchedBarIndex = null;
                              return;
                            }
                            _touchedBarIndex = response.spot!.touchedBarGroupIndex;
                          });
                        },
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= last7.length) return const SizedBox();
                              final isToday = i == last7.length - 1;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  isToday ? "Auj." : DateFormat('E', 'fr_FR').format(last7[i]),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isToday ? AppColors.ink : AppColors.muted,
                                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(dailyRevenue.length, (i) {
                        final isTouched = i == _touchedBarIndex;
                        final isToday = i == last7.length - 1;
                        return BarChartGroupData(x: i, barRods: [
                          BarChartRodData(
                            toY: dailyRevenue[i] == 0 ? 0.6 : dailyRevenue[i],
                            width: isTouched ? 22 : 18,
                            borderRadius: BorderRadius.circular(5),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                  ? [AppColors.gold, AppColors.sand]
                                  : [AppColors.ink, AppColors.ink.withOpacity(.75)],
                            ),
                          ),
                        ]);
                      }),
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          if (topProducts.isNotEmpty) ...[
            const Text('Meilleures ventes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
              child: Column(children: topProducts.take(3).toList().asMap().entries.map((entry) {
                final rank = entry.key;
                final e = entry.value;
                final medalColor = [AppColors.gold, AppColors.muted, AppColors.sand][rank];
                return ListTile(
                  dense: true,
                  leading: Container(
                    width: 28, height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: medalColor.withOpacity(.15), shape: BoxShape.circle),
                    child: Text('${rank + 1}', style: TextStyle(color: medalColor, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  title: Text(e.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                  trailing: Text('${e.value} vendus', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                );
              }).toList()),
            ),
            const SizedBox(height: 24),
          ],
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('À traiter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('En direct', style: TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
            ]),
          ]),
          const SizedBox(height: 12),
          _actionRow(context, 'Commandes reçues, en attente de prise en charge', enAttente.length, AppColors.danger, Icons.new_releases_outlined, const OrdersScreen()),
          const SizedBox(height: 10),
          _actionRow(context, 'Commandes prises en charge, à faire partir', priseEnCharge.length, AppColors.sand, Icons.storefront_outlined, const OrdersScreen()),
          const SizedBox(height: 10),
          _actionRow(context, 'Livraisons en cours', enRoute.length, AppColors.gold, Icons.local_shipping_outlined, const OrdersScreen()),
          if (paiementEnAttente.isNotEmpty) ...[
            const SizedBox(height: 10),
            _actionRow(context, 'Paiements Mobile Money en attente de confirmation', paiementEnAttente.length, AppColors.danger, Icons.hourglass_empty, const OrdersScreen()),
          ],
          const SizedBox(height: 10),
          _actionRow(context, 'Demandes de retour à examiner', 0, AppColors.plum, Icons.assignment_return_outlined, const ReturnsScreen(), alwaysShow: true),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 10),
        Text(value, style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ]),
    );
  }

  Widget _actionRow(BuildContext context, String label, int count, Color color, IconData icon, Widget destination, {bool alwaysShow = false}) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
          if (!alwaysShow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: count > 0 ? color : AppColors.ivory, borderRadius: BorderRadius.circular(20)),
              child: Text('$count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: count > 0 ? Colors.white : AppColors.muted)),
            )
          else
            const Icon(Icons.chevron_right, color: AppColors.muted),
        ]),
      ),
    );
  }
}

class _SocketOffSub implements StreamSubscription<dynamic> {
  final dynamic socket;
  final String event;
  final void Function(dynamic) handler;
  _SocketOffSub(this.socket, this.event, this.handler);

  @override
  Future<void> cancel() async => socket.off(event, handler);
  @override
  void onData(void Function(dynamic)? handleData) {}
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) {}
  @override
  void resume() {}
  @override
  bool get isPaused => false;
  @override
  Future<E> asFuture<E>([E? futureValue]) async => futureValue as E;
}
