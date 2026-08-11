import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_address.dart';
import '../../providers/auth_provider.dart';
import '../../services/address_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state.dart';

/// Carnet d'adresses : le client les enregistre une fois et les
/// réutilise en un clic à chaque commande (voir CheckoutScreen).
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});
  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final _service = AddressService();
  late Future<List<AppAddress>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  void _reload() => setState(() => _future = _service.fetchAll());

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthProvider>().uid;
    if (uid == null) return const Scaffold(body: Center(child: Text('Connectez-vous')));

    return Scaffold(
      appBar: AppBar(title: const Text('Mes adresses')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        onPressed: () => _openForm(context),
      ),
      body: FutureBuilder<List<AppAddress>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final addresses = snap.data!;
          if (addresses.isEmpty) {
            return const EmptyState(
              icon: Icons.location_on_outlined,
              title: 'Aucune adresse enregistrée',
              message: 'Ajoutez votre adresse pour commander plus rapidement la prochaine fois.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
            itemCount: addresses.length,
            itemBuilder: (context, i) {
              final a = addresses[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                child: Row(children: [
                  Icon(a.isDefault ? Icons.push_pin : Icons.location_on_outlined, color: a.isDefault ? AppColors.gold : AppColors.muted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        if (a.isDefault) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(20)),
                            child: const Text('Par défaut', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 3),
                      Text(a.fullAddress, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
                    ]),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18, color: AppColors.muted),
                    onSelected: (v) async {
                      if (v == 'edit') _openForm(context, existing: a);
                      if (v == 'delete') { await _service.delete(a.id); _reload(); }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, {AppAddress? existing}) {
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    final addressCtrl = TextEditingController(text: existing?.fullAddress ?? '');
    bool isDefault = existing?.isDefault ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(existing == null ? 'Nouvelle adresse' : 'Modifier l\'adresse',
                  style: const TextStyle(fontFamily: 'Fraunces', fontSize: 17, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Nom (ex. Maison, Bureau)')),
              const SizedBox(height: 12),
              TextField(controller: addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Adresse complète, quartier, repère')),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Adresse par défaut', style: TextStyle(fontSize: 13)),
                value: isDefault,
                onChanged: (v) => setModalState(() => isDefault = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (labelCtrl.text.trim().isEmpty || addressCtrl.text.trim().isEmpty) return;
                    final address = AppAddress(
                      id: existing?.id ?? '',
                      label: labelCtrl.text.trim(),
                      fullAddress: addressCtrl.text.trim(),
                      isDefault: isDefault,
                    );
                    if (existing == null) {
                      await _service.add(address);
                    } else {
                      await _service.update(address);
                    }
                    if (context.mounted) Navigator.pop(context);
                    _reload();
                  },
                  child: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
