import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/customer.dart';
import '../models/order.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(customer.name.isEmpty ? 'Client' : customer.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.line)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow(Icons.email_outlined, customer.email),
              const SizedBox(height: 8),
              _infoRow(Icons.phone_outlined, customer.phone.isEmpty ? 'Non renseigné' : customer.phone),
              const SizedBox(height: 8),
              _infoRow(Icons.star_border, '${customer.loyaltyPoints} points fidélité'),
              const SizedBox(height: 8),
              _infoRow(Icons.today_outlined, 'Client depuis le ${DateFormat('dd MMM yyyy', 'fr_FR').format(customer.createdAt)}'),
              if (customer.phone.isNotEmpty) ...[
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('tel:${customer.phone}')),
                      icon: const Icon(Icons.call_outlined, size: 16),
                      label: const Text('Appeler'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => launchUrl(Uri.parse('https://wa.me/' + customer.phone.replaceAll(' ', '')), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('WhatsApp'),
                    ),
                  ),
                ]),
              ],
            ]),
          ),
          const SizedBox(height: 20),
          const Text('Historique de commandes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 10),
          FutureBuilder<List<AppOrder>>(
            future: CustomerService().fetchOrdersFor(customer.uid),
            builder: (context, snap) {
              if (!snap.hasData) return const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()));
              final orders = snap.data!;
              if (orders.isEmpty) return const Text('Aucune commande pour ce client.', style: TextStyle(color: AppColors.muted, fontSize: 12.5));
              return Column(children: orders.map((o) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.line)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('#${o.id.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        Text(DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(o.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ]),
                    ),
                    Text('${o.total.toStringAsFixed(0)} F', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                );
              }).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.muted),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 12.5))),
    ]);
  }
}
