import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/image_upload_service.dart';
import '../services/product_service.dart';
import '../theme/app_colors.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? existing;
  const ProductFormScreen({super.key, this.existing});
  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _price, _description, _stock;
  String _category = 'femme';
  String _subCategory = '';
  bool _isNew = false;
  bool _isPromo = false;
  bool _saving = false;
  List<String> _images = [];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(0) ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _stock = TextEditingController(text: p?.stock.toString() ?? '0');
    _category = p?.category ?? 'femme';
    _subCategory = p?.subCategory ?? '';
    _isNew = p?.isNew ?? false;
    _isPromo = p?.isPromo ?? false;
    _images = List<String>.from(p?.images ?? []);
  }

  Future<void> _addImage(ImageSource source) async {
    setState(() => _uploading = true);
    try {
      final url = await ImageUploadService().pickAndUpload(source: source);
      if (url != null) setState(() => _images.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Échec de l'envoi de l'image. Réessayez.")));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choisir depuis la galerie'),
            onTap: () { Navigator.pop(context); _addImage(ImageSource.gallery); },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Prendre une photo'),
            onTap: () { Navigator.pop(context); _addImage(ImageSource.camera); },
          ),
        ]),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins une photo.')));
      return;
    }
    setState(() => _saving = true);
    final product = Product(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      category: _category,
      subCategory: _subCategory.trim(),
      price: double.tryParse(_price.text) ?? 0,
      images: _images,
      description: _description.text.trim(),
      stock: int.tryParse(_stock.text) ?? 0,
      isNew: _isNew,
      isPromo: _isPromo,
    );
    try {
      if (widget.existing == null) {
        await ProductService().create(product);
      } else {
        await ProductService().update(widget.existing!.id, product);
      }
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing == null ? 'Nouvel article' : 'Modifier l\'article')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 10),
            SizedBox(
              height: 90,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ..._images.asMap().entries.map((entry) {
                    final i = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Stack(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(imageUrl: entry.value, width: 90, height: 90, fit: BoxFit.cover),
                        ),
                        Positioned(
                          top: 4, right: 4,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.removeAt(i)),
                            child: const CircleAvatar(radius: 11, backgroundColor: AppColors.danger, child: Icon(Icons.close, size: 13, color: Colors.white)),
                          ),
                        ),
                      ]),
                    );
                  }),
                  GestureDetector(
                    onTap: _uploading ? null : _showImageSourceSheet,
                    child: Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                      child: _uploading
                          ? const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                          : const Icon(Icons.add_a_photo_outlined, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Nom de l\'article'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Catégorie'),
              items: const [
                DropdownMenuItem(value: 'femme', child: Text('Femme')),
                DropdownMenuItem(value: 'homme', child: Text('Homme')),
                DropdownMenuItem(value: 'enfant', child: Text('Enfant')),
                DropdownMenuItem(value: 'beaute', child: Text('Beauté')),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'femme'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: _subCategory,
              decoration: const InputDecoration(labelText: 'Sous-catégorie (ex. sacs, chaussures, habits...)'),
              onChanged: (v) => _subCategory = v,
            ),
            const SizedBox(height: 14),
            TextFormField(controller: _price, decoration: const InputDecoration(labelText: 'Prix (F CFA)'), keyboardType: TextInputType.number,
                validator: (v) => (double.tryParse(v ?? '') == null) ? 'Prix invalide' : null),
            const SizedBox(height: 14),
            TextFormField(controller: _stock, decoration: const InputDecoration(labelText: 'Stock disponible'), keyboardType: TextInputType.number),
            const SizedBox(height: 14),
            TextFormField(controller: _description, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            const SizedBox(height: 10),
            SwitchListTile(title: const Text('Nouveauté'), value: _isNew, onChanged: (v) => setState(() => _isNew = v)),
            SwitchListTile(title: const Text('En promotion'), value: _isPromo, onChanged: (v) => setState(() => _isPromo = v)),
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
