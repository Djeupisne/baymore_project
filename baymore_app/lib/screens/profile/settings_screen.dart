import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = '';
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _group([
            _row(Icons.language_outlined, 'Langue', trailing: 'Français'),
            _row(Icons.notifications_outlined, 'Notifications', trailing: 'Activées'),
            _row(Icons.info_outline, 'Version de l\'application', trailing: _version.isEmpty ? '...' : _version),
          ]),
          const SizedBox(height: 24),
          const Text('Zone de danger', style: TextStyle(fontSize: 10.5, letterSpacing: .08, color: AppColors.danger, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: InkWell(
              onTap: _deleting ? null : () => _confirmDelete(context),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  const Icon(Icons.delete_forever_outlined, size: 18, color: AppColors.danger),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Supprimer mon compte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger))),
                  if (_deleting) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer votre compte ?'),
        content: const Text(
            'Cette action est définitive : votre profil, vos adresses et vos favoris seront supprimés. Vos commandes passées restent conservées pour la comptabilité de la boutique.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context);
            },
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    setState(() => _deleting = true);
    try {
      await AuthService().deleteAccount();
      if (context.mounted) {
        await context.read<AuthProvider>().logout();
        if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de supprimer le compte pour le moment. Réessayez plus tard.')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(children: rows),
      );

  Widget _row(IconData icon, String title, {String? trailing}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.inkSoft),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ]),
    );
  }
}
