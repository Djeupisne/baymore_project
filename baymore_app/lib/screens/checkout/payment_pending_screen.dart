import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_colors.dart';
import '../orders/order_tracking_screen.dart';

/// Écran affiché après ouverture du guichet CinetPay (Flooz / T-Money).
/// Il écoute en temps réel le champ `paymentStatus` de la commande — mis à
/// jour par le webhook `cinetpayNotify` côté serveur dès que le paiement est
/// confirmé — et redirige automatiquement vers le suivi de commande.
class PaymentPendingScreen extends StatefulWidget {
  final String orderId;
  const PaymentPendingScreen({super.key, required this.orderId});
  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen> {
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    try {
      final url = await PaymentService().initiatePayment(widget.orderId);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paiement en cours'), automaticallyImplyLeading: false),
      body: StreamBuilder<AppOrder?>(
        stream: OrderService().watchOrder(widget.orderId),
        builder: (context, snap) {
          final order = snap.data;
          final status = order?.paymentStatus ?? 'en_attente';

          if (status == 'paye') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: widget.orderId)),
                (route) => route.isFirst,
              );
            });
          }

          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (status == 'echoue') ...[
                    const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
                    const SizedBox(height: 16),
                    const Text('Le paiement a échoué', style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Vérifiez votre solde Mobile Money et réessayez, ou choisissez le paiement à la livraison.',
                        textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 12.5)),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _retrying ? null : _retry,
                        child: _retrying
                            ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Réessayer le paiement'),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 46, height: 46,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.gold),
                    ),
                    const SizedBox(height: 20),
                    const Text('En attente de confirmation', style: TextStyle(fontFamily: 'Fraunces', fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text(
                      "Validez le paiement dans la fenêtre Flooz / T-Money qui vient de s'ouvrir. Cette page se met à jour automatiquement dès confirmation.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.muted, fontSize: 12.5, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
