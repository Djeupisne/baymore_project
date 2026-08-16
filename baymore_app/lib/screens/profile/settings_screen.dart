import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
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
    final strings = AppStrings.of(context);
    final locale = context.watch<LocaleProvider>().locale;
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _group([
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  _openLanguagePicker(context, strings);
                },
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(children: [
                    const Icon(Icons.language_outlined, size: 18, color: AppColors.inkSoft),
                    const SizedBox(width: 12),
                    Expanded(child: Text(strings.language, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(locale.languageCode == 'en' ? strings.english : strings.french,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldDeep)),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.goldDeep),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
            _row(Icons.notifications_outlined, strings.notifications, trailing: strings.enabled),
            _row(Icons.info_outline, strings.appVersion, trailing: _version.isEmpty ? '...' : _version),
          ]),
          const SizedBox(height: 24),
          Text(strings.dangerZone, style: const TextStyle(fontSize: 10.5, letterSpacing: .08, color: AppColors.danger, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: InkWell(
              onTap: _deleting ? null : () => _confirmDelete(context, strings),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                child: Row(children: [
                  const Icon(Icons.delete_forever_outlined, size: 18, color: AppColors.danger),
                  const SizedBox(width: 12),
                  Expanded(child: Text(strings.deleteAccount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.danger))),
                  if (_deleting) const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openLanguagePicker(BuildContext context, AppStrings strings) {
    final localeProvider = context.read<LocaleProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.language),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(strings.french),
              trailing: localeProvider.locale.languageCode == 'fr' ? const Icon(Icons.check, color: AppColors.gold) : null,
              onTap: () {
                localeProvider.setLocale(const Locale('fr'));
                Navigator.pop(dialogContext);
              },
            ),
            ListTile(
              title: Text(strings.english),
              trailing: localeProvider.locale.languageCode == 'en' ? const Icon(Icons.check, color: AppColors.gold) : null,
              onTap: () {
                localeProvider.setLocale(const Locale('en'));
                Navigator.pop(dialogContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppStrings strings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(strings.t('deleteAccountTitle')),
        content: Text(strings.t('deleteAccountBody')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(strings.actionCancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(context, strings);
            },
            child: Text(strings.t('deleteAccountPermanently')),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, AppStrings strings) async {
    setState(() => _deleting = true);
    try {
      await AuthService().deleteAccount();
      if (context.mounted) {
        await context.read<AuthProvider>().logout();
        if (context.mounted) Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.t('deleteAccountError'))));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(children: rows),
      );

  Widget _row(IconData icon, String title, {String? trailing, bool showChevron = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 18, color: AppColors.inkSoft),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        if (showChevron) ...[
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ],
      ]),
    );
  }
}
