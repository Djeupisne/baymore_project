import 'package:flutter/material.dart';
import '../../services/promo_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class PromoListScreen extends StatefulWidget {
  const PromoListScreen({super.key});
  @override
  State<PromoListScreen> createState() => _PromoListScreenState();
}

class _PromoListScreenState extends State<PromoListScreen> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = PromoService().fetchActive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bons de réduction')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final codes = snap.data!;
          if (codes.isEmpty) {
            return const EmptyState(
              icon: Icons.confirmation_number_outlined,
              title: 'Aucun code actif pour le moment',
              message: 'Revenez bientôt — de nouvelles offres arrivent régulièrement.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: codes.length,
            itemBuilder: (context, i) {
              final c = codes[i];
              final isPercent = c['type'] == 'PERCENT';
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.rose, AppColors.sand]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c['code'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: .5)),
                      const SizedBox(height: 4),
                      Text(
                        isPercent ? '-${(c['value'] as num).toStringAsFixed(0)}%' : '-${Formatters.cfa(c['value'])}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      if (c['minOrder'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Dès ${Formatters.cfa(c['minOrder'])} d\'achat', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                      if ((c['description'] as String?)?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(c['description'], style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ]),
                  ),
                  const Icon(Icons.local_offer_outlined, color: Colors.white, size: 28),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
