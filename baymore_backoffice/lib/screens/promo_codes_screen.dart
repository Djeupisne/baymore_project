import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promo_code.dart';
import '../services/promo_service.dart';
import '../theme/app_colors.dart';
import 'promo_code_form_screen.dart';

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});
  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  final _service = PromoCodeService();
  late Future<List<PromoCode>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchAll());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau code'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoCodeFormScreen()));
          _reload();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<PromoCode>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final codes = snap.data!;
            if (codes.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Aucun code promo. Créez-en un pour lancer une offre.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: codes.length,
              itemBuilder: (context, i) {
                final p = codes[i];
                final expired = p.expiresAt != null && p.expiresAt!.isBefore(DateTime.now());
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Text(p.code, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: .5)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (p.active && !expired) ? AppColors.success.withOpacity(.12) : AppColors.danger.withOpacity(.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            expired ? 'Expiré' : (p.active ? 'Actif' : 'Inactif'),
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: (p.active && !expired) ? AppColors.success : AppColors.danger),
                          ),
                        ),
                      ]),
                      Switch(
                        value: p.active,
                        activeColor: AppColors.ink,
                        onChanged: (v) async { await _service.toggleActive(p.code, v); _reload(); },
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Text(
                      p.type == 'PERCENT'
                          ? '-${p.value.toStringAsFixed(0)}%' + (p.maxDiscount != null ? ' (max ${p.maxDiscount!.toStringAsFixed(0)} F)' : '')
                          : '-${p.value.toStringAsFixed(0)} F CFA',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                    if (p.minOrder != null) Text('Dès ${p.minOrder!.toStringAsFixed(0)} F d\'achat', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    if (p.expiresAt != null) Text('Expire le ${DateFormat('dd MMM yyyy', 'fr_FR').format(p.expiresAt!)}', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    if (p.description.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: Text(p.description, style: const TextStyle(fontSize: 11, color: AppColors.muted))),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => PromoCodeFormScreen(existing: p)));
                            _reload();
                          },
                          child: const Text('Modifier'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _confirmDelete(context, p.code),
                      ),
                    ]),
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce code ?'),
        content: Text('Le code $code ne sera plus utilisable par les clients.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async { await _service.delete(code); if (context.mounted) Navigator.pop(context); _reload(); },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
