import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'products_screen.dart';
import 'promo_codes_screen.dart';
import 'returns_screen.dart';
import 'reviews_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tile(context, Icons.inventory_2_outlined, 'Catalogue', 'Créer et modifier vos articles', const ProductsScreen()),
        _tile(context, Icons.confirmation_number_outlined, 'Codes promo', 'Créer et gérer vos offres', const PromoCodesScreen()),
        _tile(context, Icons.assignment_return_outlined, 'Retours & remboursements', 'Traiter les demandes des clients', const ReturnsScreen()),
        _tile(context, Icons.reviews_outlined, 'Avis clients', 'Modérer les avis publiés', const ReviewsScreen()),
      ],
    );
  }

  Widget _tile(BuildContext context, IconData icon, String title, String subtitle, Widget screen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: AppColors.ink.withOpacity(.06), shape: BoxShape.circle),
          child: Icon(icon, color: AppColors.ink, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.muted),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }
}
