import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/promo_code.dart';
import '../services/promo_service.dart';

class PromoCodeFormScreen extends StatefulWidget {
  final PromoCode? existing;
  const PromoCodeFormScreen({super.key, this.existing});
  @override
  State<PromoCodeFormScreen> createState() => _PromoCodeFormScreenState();
}

class _PromoCodeFormScreenState extends State<PromoCodeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _code, _value, _maxDiscount, _minOrder, _description;
  String _type = 'percent';
  bool _active = true;
  DateTime? _expiresAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _code = TextEditingController(text: p?.code ?? '');
    _value = TextEditingController(text: p?.value.toStringAsFixed(0) ?? '');
    _maxDiscount = TextEditingController(text: p?.maxDiscount?.toStringAsFixed(0) ?? '');
    _minOrder = TextEditingController(text: p?.minOrder?.toStringAsFixed(0) ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _type = p?.type ?? 'percent';
    _active = p?.active ?? true;
    _expiresAt = p?.expiresAt;
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _expiresAt = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final promo = PromoCode(
      code: _code.text.trim().toUpperCase(),
      type: _type,
      value: double.tryParse(_value.text) ?? 0,
      maxDiscount: _maxDiscount.text.trim().isEmpty ? null : double.tryParse(_maxDiscount.text),
      minOrder: _minOrder.text.trim().isEmpty ? null : double.tryParse(_minOrder.text),
      active: _active,
      expiresAt: _expiresAt,
      description: _description.text.trim(),
    );
    try {
      await PromoCodeService().save(promo);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifier le code' : 'Nouveau code promo')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _code,
              enabled: !isEditing, // le code est l'identifiant du document, non modifiable après création
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Code (ex. BIENVENUE10)'),
              validator: (v) => (v == null || v.trim().length < 3) ? 'Code trop court' : null,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Type de remise'),
              items: const [
                DropdownMenuItem(value: 'percent', child: Text('Pourcentage (%)')),
                DropdownMenuItem(value: 'fixed', child: Text('Montant fixe (F CFA)')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'percent'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: _type == 'percent' ? 'Valeur (%)' : 'Valeur (F CFA)'),
              validator: (v) => (double.tryParse(v ?? '') == null) ? 'Valeur invalide' : null,
            ),
            if (_type == 'percent') ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _maxDiscount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Remise maximum (F CFA, optionnel)'),
              ),
            ],
            const SizedBox(height: 14),
            TextFormField(
              controller: _minOrder,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Montant minimum de commande (optionnel)'),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_expiresAt == null ? 'Pas de date d\'expiration' : 'Expire le ${DateFormat('dd MMM yyyy', 'fr_FR').format(_expiresAt!)}'),
              trailing: TextButton(onPressed: _pickExpiry, child: const Text('Choisir')),
            ),
            const SizedBox(height: 8),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description interne (optionnel)'), maxLines: 2),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Actif'),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
