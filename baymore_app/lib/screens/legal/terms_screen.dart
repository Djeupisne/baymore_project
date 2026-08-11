import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Conditions générales de vente — modèle de départ à faire relire par
/// un professionnel du droit avant publication (obligations spécifiques
/// au e-commerce et à la vente à distance au Togo/UEMOA).
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conditions générales')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _LegalNotice(),
          SizedBox(height: 20),
          _Section(title: '1. Objet', body:
              "Les présentes conditions régissent la vente d'accessoires (habits, sacs, chaussures, produits cosmétiques) proposés par Baymore via son application mobile, à destination de particuliers résidant principalement à Lomé et ses environs."),
          _Section(title: '2. Commandes', body:
              "Toute commande passée sur l'application vaut acceptation des présentes conditions. La commande est confirmée après validation du panier et choix du mode de livraison ou de retrait."),
          _Section(title: '3. Prix et paiement', body:
              "Les prix sont indiqués en Francs CFA (F CFA), toutes taxes comprises. Le paiement s'effectue à la livraison (espèces) ou en ligne via Flooz ou T-Money au moment de la commande."),
          _Section(title: '4. Livraison', body:
              "Baymore propose la livraison à domicile (frais indiqués au moment de la commande) ou le retrait en boutique. Les délais communiqués sont indicatifs."),
          _Section(title: '5. Retours et remboursements', body:
              "Le client peut demander un retour ou un remboursement depuis l'application dans un délai raisonnable après réception, pour tout article non conforme ou endommagé. Chaque demande est examinée individuellement par la boutique."),
          _Section(title: '6. Annulation', body:
              "Le client peut annuler sa commande sans frais tant qu'elle n'a pas encore été prise en charge par la boutique."),
          _Section(title: '7. Programme de fidélité', body:
              "Les points fidélité et le programme de parrainage sont proposés à titre commercial et peuvent être modifiés ou suspendus par Baymore à tout moment, sans effet rétroactif sur les avantages déjà acquis."),
          _Section(title: '8. Contact', body:
              "Pour toute question, le client peut contacter la boutique directement depuis l'application (section Aide et assistance)."),
        ],
      ),
    );
  }
}

class _LegalNotice extends StatelessWidget {
  const _LegalNotice();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
      child: const Text(
        "Modèle de conditions générales fourni à titre de point de départ — à faire valider par un professionnel du droit avant publication, notamment pour la conformité avec la réglementation togolaise et UEMOA sur la vente à distance.",
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
