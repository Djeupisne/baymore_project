import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

/// Portefeuille cashback : 2% du montant de chaque commande livrée est
/// crédité automatiquement (voir la route PATCH /orders/:id/status côté
/// backend). Affichage seul pour l'instant — l'utilisation au paiement
/// pourra être ajoutée plus tard au checkout.
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiClient().get('/wallet');
  }

  @override
  Widget build(BuildContext context) {
    context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Mon portefeuille')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final balance = (snap.data!['balance'] ?? 0) as num;
          final transactions = List<Map<String, dynamic>>.from(snap.data!['transactions'] ?? []);

          return Column(children: [
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppColors.ink, Color(0xFF302B22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Solde disponible', style: TextStyle(color: Color(0xFFC9BFA8), fontSize: 11)),
                const SizedBox(height: 6),
                Text(Formatters.cfa(balance), style: const TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('2% de cashback crédité automatiquement à chaque commande livrée',
                    style: TextStyle(color: Color(0xFFC9BFA8), fontSize: 11, height: 1.4)),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [Text('Historique', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14))]),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: transactions.isEmpty
                  ? const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Aucune transaction pour le moment',
                      message: 'Votre cashback apparaîtra ici après votre première commande livrée.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: transactions.length,
                      itemBuilder: (context, i) {
                        final t = transactions[i];
                        final createdAt = DateTime.tryParse(t['createdAt'] ?? '') ?? DateTime.now();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                          child: Row(children: [
                            const Icon(Icons.add_circle_outline, color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(t['reason'] ?? 'Cashback', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                                Text(DateFormat('dd MMM yyyy', 'fr_FR').format(createdAt), style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                              ]),
                            ),
                            Text('+${Formatters.cfa(t['amount'] ?? 0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                          ]),
                        );
                      },
                    ),
            ),
          ]);
        },
      ),
    );
  }
}
