import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Politique de confidentialité — modèle de départ à personnaliser et
/// faire relire avant publication. Une politique de confidentialité
/// accessible est OBLIGATOIRE pour publier sur le Play Store dès lors que
/// l'app gère des comptes utilisateurs (ce qui est le cas ici).
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Politique de confidentialité')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _Notice(),
          SizedBox(height: 20),
          _Section(title: 'Données collectées', body:
              "Nom, e-mail, téléphone, adresses de livraison, historique de commandes et d'avis, points fidélité. Ces informations sont nécessaires au traitement de vos commandes et à l'amélioration de nos services."),
          _Section(title: 'Utilisation des données', body:
              "Vos données servent exclusivement à : traiter vos commandes et livraisons, vous contacter en cas de besoin, gérer votre programme de fidélité, et vous envoyer des notifications liées à vos commandes. Elles ne sont jamais vendues à des tiers."),
          _Section(title: 'Partage des données', body:
              "Vos données de paiement Mobile Money sont transmises à notre prestataire de paiement (CinetPay) uniquement pour traiter la transaction. Aucune autre donnée n'est partagée avec des tiers hors obligation légale."),
          _Section(title: 'Conservation', body:
              "Vos données sont conservées tant que votre compte est actif. Vous pouvez demander la suppression de votre compte et de vos données à tout moment depuis Profil > Paramètres."),
          _Section(title: 'Sécurité', body:
              "Vos données sont hébergées sur une infrastructure sécurisée (Firebase/Google Cloud) avec des règles d'accès strictes : seul vous-même et l'équipe autorisée de Baymore peuvent y accéder."),
          _Section(title: 'Vos droits', body:
              "Vous pouvez à tout moment consulter, corriger ou supprimer vos données personnelles depuis l'application, ou en contactant la boutique."),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: const Text(
        "Modèle de politique de confidentialité fourni à titre de point de départ — personnalisez-la avec vos informations réelles (raison sociale, contact) et faites-la valider avant publication sur le Play Store.",
        style: TextStyle(fontSize: 11, color: AppColors.muted, fontStyle: FontStyle.italic, height: 1.4),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.ink)),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, height: 1.5)),
      ]),
    );
  }
}
