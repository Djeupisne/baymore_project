import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/api_client.dart';

class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});
  
  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  bool _converting = false;

  Future<void> _convertPoints() async {
    final auth = context.read<AuthProvider>();
    final profile = auth.profile;
    if (profile == null || profile.loyaltyPoints <= 0) return;

    setState(() => _converting = true);
    try {
      final client = ApiClient();
      await client.post('/loyalty/convert', data: {'points': profile.loyaltyPoints});
      await auth.refreshProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${profile.loyaltyPoints} points convertis en ${profile.loyaltyPoints} FCFA')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la conversion'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _converting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.loyaltyPoints)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.gold, AppColors.sand], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(strings.t('yourBalance'), style: const TextStyle(color: Colors.white, fontSize: 11)),
              const SizedBox(height: 6),
              Text(strings.tf('pointsSuffix', ['${profile?.loyaltyPoints ?? 0}']),
                  style: const TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 24),
          Text(strings.t('howToEarnPoints'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          _infoRow(Icons.shopping_bag_outlined, strings.t('earnPointsSpend'), strings.t('earnPointsSpendMsg')),
          const SizedBox(height: 10),
          _infoRow(Icons.people_alt_outlined, strings.t('earnPointsReferral'), strings.t('earnPointsReferralMsg')),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
            child: Text(
              strings.t('loyaltyWalletNote'),
              style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.ink, AppColors.ink.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.swap_horiz, color: AppColors.gold, size: 22),
                const SizedBox(width: 10),
                Text(strings.t('convertPointsTitle'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ]),
              const SizedBox(height: 8),
              Text(strings.t('convertPointsSubtitle'), style: const TextStyle(color: Color(0xFFC9BFA8), fontSize: 11)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: profile != null && profile.loyaltyPoints > 0 && !_converting ? _convertPoints : null,
                  icon: _converting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.account_balance_wallet, size: 18),
                  label: Text(_converting
                      ? strings.t('converting')
                      : strings.tf('convertPointsBtn', ['${profile?.loyaltyPoints ?? 0}'])),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(strings.t('conversionRate'), textAlign: TextAlign.center, style: const TextStyle(color: AppColors.gold, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Row(children: [
        Icon(icon, color: AppColors.gold, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted, height: 1.3)),
          ]),
        ),
      ]),
    );
  }
}
