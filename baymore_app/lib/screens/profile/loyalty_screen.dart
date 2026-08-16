import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_strings.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

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
