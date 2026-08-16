import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../legal/privacy_screen.dart';
import '../legal/terms_screen.dart';
import 'addresses_screen.dart';
import 'edit_profile_screen.dart';
import 'loyalty_screen.dart';
import 'promo_list_screen.dart';
import 'settings_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _orderService = OrderService();
  int? _orderCount;
  String? _lastLoadedUid;

  Future<void> _loadOrderCount() async {
    try {
      final results = await Future.wait([
        _orderService.fetchMine(active: true),
        _orderService.fetchMine(active: false),
      ]);
      if (mounted) setState(() => _orderCount = results[0].length + results[1].length);
    } catch (_) {
      if (mounted) setState(() => _orderCount = null);
    }
  }

  /// Recharge le profil et le nombre de commandes dès que le compte
  /// connecté change (ou à la première ouverture de l'onglet) — le widget
  /// reste vivant en permanence dans l'IndexedStack de la navigation, donc
  /// initState() seul ne suffit pas : sans ce suivi du uid, un changement de
  /// compte dans la même session laisserait affichées les données du
  /// compte précédent.
  void _syncForCurrentAccount(AuthProvider auth) {
    if (auth.uid == _lastLoadedUid) return;
    _lastLoadedUid = auth.uid;
    _orderCount = null; // mutation directe (pas de setState pendant build)
    if (auth.uid == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      auth.refreshProfile();
      _loadOrderCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final strings = AppStrings.of(context);
    _syncForCurrentAccount(auth);

    if (!auth.isLoggedIn) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(strings.t('loginPrompt'), style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(strings.t('loginPromptMsg'),
                    textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
                    child: Text(strings.login),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text(strings.t('authCreateAccount')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final profile = auth.profile;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.ink, Color(0xFF302B22)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(0)),
              ),
              child: Row(children: [
                CircleAvatar(radius: 26, backgroundColor: const Color(0xFF3B362B),
                    child: Text(profile?.name.isNotEmpty == true ? profile!.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontFamily: 'Fraunces', color: AppColors.gold, fontSize: 20))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(profile?.name ?? '', style: const TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(profile?.email ?? '', style: const TextStyle(color: Color(0xFFC9BFA8), fontSize: 11)),
                  ]),
                ),
              ]),
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  _stat('${profile?.loyaltyPoints ?? 0}', strings.loyaltyPoints),
                  const SizedBox(width: 10),
                  _stat(_orderCount != null ? '$_orderCount' : '—', strings.orders),
                  const SizedBox(width: 10),
                  _stat(Formatters.cfa(profile?.walletBalance ?? 0), strings.accountBalance),
                ]),
              ),
            ),
            _sectionTitle('Général'),
            _group([
              _row(context, Icons.person_outline, 'Modifier le profil', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()))),
              _row(context, Icons.location_on_outlined, strings.myAddresses, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressesScreen()))),
              _row(context, Icons.settings_outlined, strings.settings, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
            ]),
            _sectionTitle('Activité promotionnelle'),
            _group([
              _row(context, Icons.confirmation_number_outlined, 'Bons de réduction', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoListScreen()))),
              _row(context, Icons.star_border, 'Points fidélité (${profile?.loyaltyPoints ?? 0})', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen()))),
              _row(context, Icons.account_balance_wallet_outlined, strings.myWallet, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
            ]),
            _sectionTitle('Gagnez avec Baymore'),
            _group([
              _row(context, Icons.people_alt_outlined, 'Parrainez et gagnez', onTap: () => _shareReferral(context, profile?.referralCode)),
            ]),
            _sectionTitle('Aide et assistance'),
            _group([
              _row(context, Icons.support_agent_outlined, strings.t('contactSupport'), onTap: () => _showContactSupport(context)),
              _row(context, Icons.chat_bubble_outline, strings.contactShop, onTap: () => _openWhatsApp()),
              _row(context, Icons.description_outlined, 'Conditions générales', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsScreen()))),
              _row(context, Icons.privacy_tip_outlined, 'Politique de confidentialité', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyScreen()))),
            ]),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton.icon(
                onPressed: () => context.read<AuthProvider>().logout(),
                icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
                label: Text(strings.logout, style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // Remplacez ce numéro par celui de votre boutique (indicatif inclus, sans le +).
  static const String _whatsappNumber = '22890000000';

  Future<void> _shareReferral(BuildContext context, String? code) async {
    if (code == null) return;
    await Share.share(
      "Découvre Baymore, la boutique en ligne d'accessoires femme, homme et enfant à Lomé 🛍️\n"
      "Utilise mon code $code à l'inscription et gagnons tous les deux des points fidélité !",
    );
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent("Bonjour Baymore, j'ai une question sur ma commande.")}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _showContactSupport(BuildContext context) async {
    final strings = AppStrings.of(context, listen: false);
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.t('contactSupport'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 16),
            _contactTile(Icons.phone_outlined, strings.t('phone'), '+228 90 00 00 00', () => launchUrl(Uri.parse('tel:+22890000000'))),
            _contactTile(Icons.email_outlined, strings.t('email'), 'support@baymore.com', () => launchUrl(Uri.parse('mailto:support@baymore.com'))),
            _contactTile(Icons.chat_bubble_outlined, 'WhatsApp', strings.t('chatOnWhatsApp'), () => _openWhatsApp()),
            _contactTile(Icons.location_on_outlined, strings.t('address'), 'Lomé, Togo', null),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12)),
              child: Text(strings.t('supportHours'), style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactTile(IconData icon, String label, String value, VoidCallback? onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.ink, size: 22),
      title: Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
      subtitle: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted) : null,
      onTap: onTap,
    );
  }

  Widget _stat(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
        child: Column(children: [
          Text(value, style: const TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9.5, color: AppColors.muted), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
        child: Text(title, style: const TextStyle(fontSize: 10.5, letterSpacing: .08, color: AppColors.muted, fontWeight: FontWeight.w700)),
      );

  Widget _group(List<Widget> rows) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
        child: Column(children: rows),
      );

  Widget _row(BuildContext context, IconData icon, String title, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Icon(icon, size: 18, color: AppColors.inkSoft),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
          const Icon(Icons.chevron_right, size: 18, color: AppColors.muted),
        ]),
      ),
    );
  }
}
