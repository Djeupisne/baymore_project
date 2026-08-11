import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';

class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().profile;
    return Scaffold(
      appBar: AppBar(title: const Text('Points fidélité')),
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
              const Text('Votre solde', style: TextStyle(color: Colors.white, fontSize: 11)),
              const SizedBox(height: 6),
              Text('${profile?.loyaltyPoints ?? 0} points', style: const TextStyle(fontFamily: 'Fraunces', color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700)),
            ]),
          ),
          const SizedBox(height: 24),
          const Text('Comment gagner des points ?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 12),
          _infoRow(Icons.shopping_bag_outlined, '1 point tous les 1 000 F CFA dépensés',
              'Crédité automatiquement dès que votre commande est livrée.'),
          const SizedBox(height: 10),
          _infoRow(Icons.people_alt_outlined, '50 points par parrainage',
              'Vous et votre filleul recevez chacun 50 points quand il utilise votre code à l\'inscription.'),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
            child: const Text(
              "Vos points fidélité sont distincts de votre solde portefeuille (cashback) — retrouvez-le dans Profil > Mon portefeuille.",
              style: TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4),
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
