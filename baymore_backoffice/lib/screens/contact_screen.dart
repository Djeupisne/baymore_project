import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isSubmitting = false;

  // FAQ dynamique avec plus de questions
  final List<Map<String, String>> _faqItems = [
    {
      'question': 'Comment modifier une commande ?',
      'answer': 'Accédez à la section Commandes, sélectionnez la commande concernée et cliquez sur Modifier. Notez que seules les commandes en statut "En attente" peuvent être modifiées.',
    },
    {
      'question': 'Comment créer un code promo ?',
      'answer': 'Allez dans Plus > Codes promo, puis cliquez sur Nouveau code. Remplissez le formulaire avec le code, le type de remise, la valeur et les conditions optionnelles.',
    },
    {
      'question': 'Comment gérer les retours clients ?',
      'answer': 'Consultez la section Retours & remboursements. Vous pouvez accepter ou refuser les demandes de retour, et suivre l\'état de chaque demande.',
    },
    {
      'question': 'Comment ajouter un nouveau produit ?',
      'answer': 'Dans la section Produits, cliquez sur le bouton "+" puis remplissez le formulaire avec les détails du produit, les images, les variantes et les stocks.',
    },
    {
      'question': 'Comment contacter un client ?',
      'answer': 'Depuis la fiche client ou la détail d\'une commande, vous trouverez les coordonnées du client (email, téléphone). Vous pouvez également envoyer des notifications push via le système.',
    },
    {
      'question': 'Comment suivre les livraisons en temps réel ?',
      'answer': 'La section Commandes affiche le statut de chaque livraison. Les livreurs partagent leur position en temps réel via l\'application mobile.',
    },
    {
      'question': 'Que faire en cas de problème technique ?',
      'answer': 'Contactez notre support technique via ce formulaire ou par email. Décrivez précisément le problème rencontré et incluez des captures d\'écran si possible.',
    },
    {
      'question': 'Comment consulter les statistiques de ventes ?',
      'answer': 'Le tableau de bord affiche les statistiques en temps réel : ventes du jour, revenus, meilleures ventes, et l\'évolution sur les 30 derniers jours.',
    },
  ];

  final List<bool> _expandedFaq = List.filled(8, false);

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // TODO: Implémenter l'API d'envoi de message au backend
      await Future.delayed(const Duration(seconds: 1)); // Simulation
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Message envoyé avec succès ! Notre équipe vous répondra sous 24h.'),
            backgroundColor: Color(0xFF27AE60),
          ),
        );
        _subjectController.clear();
        _messageController.clear();
        _formKey.currentState!.reset();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'oualoumidjeupisne@gmail.com',
      query: 'subject=Demande de support Baymore',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+22893360150');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
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
            value: 'oualoumidjeupisne@gmail.com',
            onTap: _launchEmail,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.phone_outlined,
            title: 'Téléphone',
            value: '+228 93 36 01 50',
            onTap: _launchPhone,
          ),
          const SizedBox(height: 12),
          _buildContactCard(
            icon: Icons.location_on_outlined,
            title: 'Adresse',
            value: 'Lomé, Togo',
            onTap: null,
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _subjectController,
                    decoration: const InputDecoration(
                      labelText: 'Sujet',
                      hintText: 'Ex: Problème de commande, Question technique...',
                      prefixIcon: Icon(Icons.subject_outlined, color: AppColors.muted),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez entrer un sujet' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      hintText: 'Décrivez votre demande en détail...',
                      prefixIcon: Icon(Icons.message_outlined, color: AppColors.muted),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez entrer votre message' : null,
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
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Envoi en cours...' : 'Envoyer le message'),
                    onPressed: _isSubmitting ? null : _submitMessage,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Section FAQ
          _buildSectionTitle('Questions fréquentes'),
          const SizedBox(height: 12),
          ...List.generate(_faqItems.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildExpandableFAQItem(
                question: _faqItems[index]['question']!,
                answer: _faqItems[index]['answer']!,
                isExpanded: _expandedFaq[index],
                onToggle: () {
                  setState(() {
                    _expandedFaq[index] = !_expandedFaq[index];
                  });
                },
              ),
            );
          }),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.line),
          boxShadow: onTap != null
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
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
      ),
    );
  }

  Widget _buildExpandableFAQItem({
    required String question,
    required String answer,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.gold,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gold.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
