import 'package:flutter/material.dart';
import '../models/catalog.dart';
import '../services/catalog_service.dart';
import '../theme/app_colors.dart';
import 'catalog_form_screen.dart';

class CatalogsScreen extends StatefulWidget {
  const CatalogsScreen({super.key});

  @override
  State<CatalogsScreen> createState() => _CatalogsScreenState();
}

class _CatalogsScreenState extends State<CatalogsScreen> {
  final _service = CatalogService();
  late Future<List<Catalog>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchAll());
    await _future;
  }

  void _confirmDelete(BuildContext context, Catalog catalog) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 48),
        title: const Text('Supprimer le catalogue'),
        content: Text('Êtes-vous sûr de vouloir supprimer "${catalog.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.delete, size: 18),
            label: const Text('Supprimer'),
            onPressed: () async {
              Navigator.pop(context);
              await _service.delete(catalog.id);
              _reload();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.ink,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau catalogue'),
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogFormScreen()));
          _reload();
        },
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Catalog>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final catalogs = snap.data!;
            if (catalogs.isEmpty) {
              return const Center(child: Text('Aucun catalogue. Créez le premier avec le bouton ci-dessous.', style: TextStyle(color: AppColors.muted)));
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: catalogs.length,
              itemBuilder: (context, i) {
                final c = catalogs[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: c.image != null
                            ? Image.network(c.image!, fit: BoxFit.cover)
                            : Container(color: AppColors.ivory, child: const Icon(Icons.collections_outlined, color: AppColors.muted)),
                      ),
                    ),
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${c.productIds.length} articles · ${c.isActive ? "Actif" : "Inactif"}', style: const TextStyle(fontSize: 11)),
                        if (c.description.isNotEmpty)
                          Text(c.description, style: const TextStyle(fontSize: 10, color: AppColors.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogFormScreen(existing: c))).then((_) => _reload());
                        } else if (value == 'delete') {
                          _confirmDelete(context, c);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Modifier')])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: AppColors.danger), SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: AppColors.danger))])),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => CatalogFormScreen(existing: c)));
                      _reload();
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
