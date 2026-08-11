import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../models/order_status.dart';
import '../../models/return_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/return_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/order_status_stepper.dart';

/// Écran de suivi en temps réel : chaque mise à jour du statut faite côté
/// boutique/livreur (Firestore) apparaît instantanément ici via StreamBuilder,
/// sans action de l'utilisateur — c'est le cœur du "suivi en temps réel" demandé.
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});
  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _service = OrderService();
  bool _cancelling = false;

  static const String _whatsappNumber = '22890000000';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Suivi de la commande')),
      body: StreamBuilder<AppOrder?>(
        stream: _service.watchOrder(widget.orderId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final order = snap.data;
          if (order == null) return const Center(child: Text('Commande introuvable'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: order.status == OrderStatus.livree ? AppColors.success.withOpacity(.1) : AppColors.ink,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(children: [
                    Icon(
                      order.status == OrderStatus.livree ? Icons.check_circle : Icons.local_shipping_outlined,
                      color: order.status == OrderStatus.livree ? AppColors.success : AppColors.gold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(order.status.label,
                            style: TextStyle(
                                fontFamily: 'Fraunces', fontWeight: FontWeight.w600, fontSize: 15,
                                color: order.status == OrderStatus.livree ? AppColors.success : AppColors.ivory)),
                        const SizedBox(height: 2),
                        Text(order.status.description,
                            style: TextStyle(
                                fontSize: 11.5,
                                color: order.status == OrderStatus.livree ? AppColors.inkSoft : const Color(0xFFC9BFA8))),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),

                // Carte en temps réel du livreur pendant l'étape "en route"
                if (order.status == OrderStatus.enRoute && order.driverLat != null && order.driverLng != null) ...[
                  const Text('Position du livreur', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(order.driverLat!, order.driverLng!),
                          zoom: 14,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('driver'),
                            position: LatLng(order.driverLat!, order.driverLng!),
                            infoWindow: InfoWindow(title: order.driverName ?? 'Livreur'),
                          ),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (order.driverName != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                      child: Row(children: [
                        const CircleAvatar(radius: 18, backgroundColor: AppColors.ink, child: Icon(Icons.person, color: AppColors.gold, size: 18)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(order.driverName!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                            const Text('Votre livreur', style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
                          ]),
                        ),
                        if (order.driverPhone != null)
                          IconButton(icon: const Icon(Icons.call_outlined, color: AppColors.ink), onPressed: () {}),
                      ]),
                    ),
                  const SizedBox(height: 24),
                ],

                const Text('Étapes de la commande', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 14),
                OrderStatusStepper(status: order.status),

                const SizedBox(height: 8),
                const Text('Détails de la commande', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                  child: Column(children: [
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(children: [
                          Expanded(child: Text('${item['quantity']}× ${item['name']}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                          Text(Formatters.cfa((item['price'] as num) * (item['quantity'] as num)), style: const TextStyle(fontSize: 12.5)),
                        ]),
                      ),
                    const Divider(height: 1, color: AppColors.line),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(children: [
                        _row('Mode de livraison', order.deliveryMode.label),
                        _row('Adresse', order.deliveryAddress),
                        _row('Paiement', _paymentLabel(order.paymentMethod)),
                        if (order.discount > 0) _row('Remise${order.promoCode != null ? ' (${order.promoCode})' : ''}', '- ${Formatters.cfa(order.discount)}'),
                        const SizedBox(height: 6),
                        _row('Total', Formatters.cfa(order.total), bold: true),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 20),

                if (order.status == OrderStatus.enAttente) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancelling ? null : () => _confirmCancel(context, order.id),
                      icon: _cancelling
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.close, size: 18, color: AppColors.danger),
                      label: Text(_cancelling ? 'Annulation...' : 'Annuler la commande',
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.danger)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],

                if (order.status == OrderStatus.livree) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _shareReceipt(order),
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Partager le reçu'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ReturnRequestSection(order: order),
                  const SizedBox(height: 10),
                ],

                OutlinedButton.icon(
                  onPressed: () => _contactSupport(order.id),
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text('Une question sur cette commande ? Contactez-nous'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, String orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande ?'),
        content: const Text('Cette action est définitive. Vous pourrez toujours recommander ces articles plus tard.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retour')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    try {
      await _service.cancelOrder(orderId);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  Future<void> _shareReceipt(AppOrder order) async {
    final buffer = StringBuffer();
    buffer.writeln('Reçu Baymore — Commande #${order.id.substring(0, 6).toUpperCase()}');
    buffer.writeln(Formatters.date(order.createdAt));
    buffer.writeln('');
    for (final item in order.items) {
      buffer.writeln('${item['quantity']}× ${item['name']} — ${Formatters.cfa((item['price'] as num) * (item['quantity'] as num))}');
    }
    buffer.writeln('');
    if (order.discount > 0) buffer.writeln('Remise : -${Formatters.cfa(order.discount)}');
    buffer.writeln('Total : ${Formatters.cfa(order.total)}');
    buffer.writeln('Livraison : ${order.deliveryMode.label}');
    buffer.writeln('Merci pour votre confiance — Baymore');
    await Share.share(buffer.toString());
  }

  Future<void> _contactSupport(String orderId) async {
    final text = "Bonjour Baymore, j'ai une question sur ma commande #${orderId.substring(0, 6).toUpperCase()}.";
    final uri = Uri.parse('https://wa.me/$_whatsappNumber?text=${Uri.encodeComponent(text)}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _paymentLabel(String v) {
    switch (v) {
      case 'flooz': return 'Flooz (Mobile Money)';
      case 'tmoney': return 'T-Money (Mobile Money)';
      default: return 'Paiement à la livraison';
    }
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        Flexible(
          child: Text(value, textAlign: TextAlign.right,
              style: TextStyle(fontSize: bold ? 13.5 : 12, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ),
      ]),
    );
  }
}

/// Demande de retour / remboursement — visible uniquement sur une commande
/// livrée. Affiche le statut de la demande si elle existe déjà.
class _ReturnRequestSection extends StatefulWidget {
  final AppOrder order;
  const _ReturnRequestSection({required this.order});
  @override
  State<_ReturnRequestSection> createState() => _ReturnRequestSectionState();
}

class _ReturnRequestSectionState extends State<_ReturnRequestSection> {
  final _returnService = ReturnService();
  late Future<ReturnRequest?> _future;

  @override
  void initState() {
    super.initState();
    _future = _returnService.fetchForOrder(widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ReturnRequest?>(
      future: _future,
      builder: (context, snap) {
        final existing = snap.data;
        if (existing != null) {
          final color = existing.status == ReturnStatus.refuse
              ? AppColors.danger
              : existing.status == ReturnStatus.rembourse
                  ? AppColors.success
                  : AppColors.gold;
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(.3))),
            child: Row(children: [
              Icon(Icons.assignment_return_outlined, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Demande de retour : ${existing.status.label}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: color)),
                  if (existing.staffNote != null && existing.staffNote!.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(top: 4), child: Text(existing.staffNote!, style: const TextStyle(fontSize: 11.5, color: AppColors.muted))),
                ]),
              ),
            ]),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openReturnDialog(context),
            icon: const Icon(Icons.assignment_return_outlined, size: 18),
            label: const Text('Demander un retour ou remboursement'),
          ),
        );
      },
    );
  }

  void _openReturnDialog(BuildContext context) {
    final auth = context.read<AuthProvider>();
    if (auth.uid == null) return;
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Retour ou remboursement'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Expliquez brièvement la raison de votre demande.', style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 10),
          TextField(controller: reasonCtrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Ex. article endommagé, mauvaise taille...')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (reasonCtrl.text.trim().isEmpty) return;
              await _returnService.create(orderId: widget.order.id, reason: reasonCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
              setState(() => _future = _returnService.fetchForOrder(widget.order.id));
            },
            child: const Text('Envoyer la demande'),
          ),
        ],
      ),
    );
  }
}
