import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/catalog.dart';
import '../models/product.dart';
import '../services/catalog_service.dart';
import '../services/product_service.dart';
import '../services/image_upload_service.dart';
import '../theme/app_colors.dart';

class CatalogFormScreen extends StatefulWidget {
  final Catalog? existing;
  const CatalogFormScreen({super.key, this.existing});

  @override
  State<CatalogFormScreen> createState() => _CatalogFormScreenState();
}

class _CatalogFormScreenState extends State<CatalogFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _description;
  bool _isActive = true;
  DateTime? _startsAt;
  DateTime? _endsAt;
  bool _saving = false;
  String? _image;
  bool _uploading = false;
  List<String> _selectedProductIds = [];
  List<Product> _allProducts = [];
  bool _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _name = TextEditingController(text: c?.name ?? '');
    _description = TextEditingController(text: c?.description ?? '');
    _isActive = c?.isActive ?? true;
    _startsAt = c?.startsAt;
    _endsAt = c?.endsAt;
    _image = c?.image;
    _selectedProductIds = List<String>.from(c?.productIds ?? []);
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loadingProducts = true);
    try {
      final products = await ProductService().fetchAll();
      setState(() => _allProducts = products);
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _addImage() async {
    setState(() => _uploading = true);
    try {
      final url = await ImageUploadService().pickAndUpload(source: ImageSource.gallery);
      if (url != null) setState(() => _image = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de l'envoi de l'image. Réessayez.")));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startsAt : _endsAt) ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startsAt = picked;
        } else {
          _endsAt = picked;
        }
      });
    }
  }

  void _showProductSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sélectionner les articles'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: _loadingProducts
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _allProducts.length,
                  itemBuilder: (context, i) {
                    final p = _allProducts[i];
                    final selected = _selectedProductIds.contains(p.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (v) {
                        setState(() {
                          if (v == true) {
                            _selectedProductIds.add(p.id);
                          } else {
                            _selectedProductIds.remove(p.id);
                          }
                        });
                      },
                      title: Text(p.name, style: const TextStyle(fontSize: 12)),
                      subtitle: Text('${p.category} · ${p.price.toStringAsFixed(0)} F', style: const TextStyle(fontSize: 10)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final catalog = Catalog(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      description: _description.text.trim(),
      image: _image,
      productIds: _selectedProductIds,
      isActive: _isActive,
      startsAt: _startsAt,
      endsAt: _endsAt,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    try {
      if (widget.existing == null) {
        await CatalogService().create(catalog);
      } else {
        await CatalogService().update(widget.existing!.id, catalog);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Nouveau catalogue' : 'Modifier le catalogue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Image de couverture', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _uploading ? null : _addImage,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.ivory,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: _uploading
                    ? const Center(child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                    : _image != null
                        ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(_image!, fit: BoxFit.cover))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppColors.muted), SizedBox(height: 8), Text('Ajouter une image', style: TextStyle(color: AppColors.muted, fontSize: 12))],
                          ),
              ),
            ),
            if (_image != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                  label: const Text('Supprimer', style: TextStyle(color: AppColors.danger, fontSize: 11)),
                  onPressed: () => setState(() => _image = null),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom du catalogue'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            const SizedBox(height: 14),
            SwitchListTile(
              title: const Text('Actif'),
              subtitle: const Text('Les catalogues actifs sont visibles par les clients'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de début', style: TextStyle(fontSize: 12)),
              subtitle: Text(_startsAt != null ? '${_startsAt!.day}/${_startsAt!.month}/${_startsAt!.year}' : 'Non définie', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              trailing: const Icon(Icons.calendar_today, size: 16, color: AppColors.muted),
              onTap: () => _selectDate(true),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date de fin', style: TextStyle(fontSize: 12)),
              subtitle: Text(_endsAt != null ? '${_endsAt!.day}/${_endsAt!.month}/${_endsAt!.year}' : 'Non définie', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              trailing: const Icon(Icons.calendar_today, size: 16, color: AppColors.muted),
              onTap: () => _selectDate(false),
            ),
            const SizedBox(height: 10),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Articles', style: TextStyle(fontSize: 12)),
              subtitle: Text('${_selectedProductIds.length} article(s) sélectionné(s)', style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              trailing: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.muted),
              onTap: _showProductSelector,
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
