import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Section Informations de contact
          _buildSectionTitle('Informations de contact'),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email',
            value: 'support@baymore.com',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            value: '+225 07 07 07 07 07',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.location_on_outlined,
            title: 'Adresse',
            value: 'Abidjan, Côte d\'Ivoire',
            onTap: () {},
          ),
          
          const SizedBox(height: 32),
          
          // Section Envoyer un message
          _buildSectionTitle('Envoyer un message au support'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Sujet',
                    hintText: 'Ex: Problème de commande',
                    prefixIcon: Icon(Icons.subject_outlined, color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    hintText: 'Décrivez votre demande...',
                    prefixIcon: Icon(Icons.message_outlined, color: AppColors.muted),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer le message'),
                  onPressed: () {
                    // TODO: Implémenter l'envoi du message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Message envoyé avec succès !'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Section FAQ
          _buildSectionTitle('Questions fréquentes'),
          const SizedBox(height: 12),
          _buildFAQItem(
            question: 'Comment modifier une commande ?',
            answer: 'Accédez à la section Commandes, sélectionnez la commande et cliquez sur Modifier.',
          ),
          const SizedBox(height: 8),
          _buildFAQItem(
            question: 'Comment créer un code promo ?',
            answer: 'Allez dans Plus > Codes promo, puis cliquez sur Nouveau code.',
          ),
          const SizedBox(height: 8),
          _buildFAQItem(
            question: 'Comment gérer les retours ?',
            answer: 'Consultez la section Retours & remboursements pour traiter les demandes.',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.ink.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.ink, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
        ],
      ),
    );
  }

  Widget _buildFAQItem({required String question, required String answer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
