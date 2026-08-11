import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../services/order_service.dart';
import '../theme/app_colors.dart';
import 'orders_screen.dart';
import 'returns_screen.dart';

/// Tableau de bord : vue d'ensemble pour l'administrateur — chiffre
/// d'affaires, tendance des 7 derniers jours, top produits et commandes
/// qui attendent une action, pour piloter la boutique en un coup d'œil.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppOrder>>(
      future: OrderService().fetchAll(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final orders = snap.data!.where((o) => o.status != OrderStatus.annulee).toList();
        final today = DateTime.now();
        final todayOrders = orders.where((o) =>
            o.createdAt.year == today.year && o.createdAt.month == today.month && o.createdAt.day == today.day).toList();
        final revenueToday = todayOrders.fold<double>(0, (sum, o) => sum + o.total);

        final allOrders = snap.data!;
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

        // Top 3 articles les plus vendus (toutes commandes non annulées).
        final Map<String, int> soldQuantities = {};
        for (final o in orders) {
          for (final item in o.items) {
            final name = item['name'] ?? 'Article';
            soldQuantities[name] = (soldQuantities[name] ?? 0) + ((item['quantity'] ?? 1) as num).toInt();
          }
        }
        final topProducts = soldQuantities.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(children: [
              Expanded(child: _statCard('Commandes du jour', '${todayOrders.length}', Icons.today_outlined, AppColors.ink)),
              const SizedBox(width: 12),
              Expanded(child: _statCard('Chiffre d\'affaires du jour', '${revenueToday.toStringAsFixed(0)} F', Icons.payments_outlined, AppColors.success)),
            ]),
            const SizedBox(height: 20),
            const Text('Tendance des ventes (7 derniers jours)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 12),
            Container(
              height: 160,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
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
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(DateFormat('E', 'fr_FR').format(last7[i]), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(dailyRevenue.length, (i) {
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(toY: dailyRevenue[i], color: AppColors.ink, width: 18, borderRadius: BorderRadius.circular(4)),
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
                child: Column(children: topProducts.take(3).map((e) {
                  return ListTile(
                    dense: true,
                    leading: const Icon(Icons.local_fire_department_outlined, color: AppColors.sand, size: 20),
                    title: Text(e.key, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    trailing: Text('${e.value} vendus', style: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w700)),
                  );
                }).toList()),
              ),
              const SizedBox(height: 24),
            ],
            const Text('À traiter', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
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
        );
      },
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
