import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_address.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../services/promo_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../orders/order_tracking_screen.dart';
import 'payment_pending_screen.dart';

/// Frais de livraison fixe pour la livraison à domicile (à adapter selon zone).
const double kDeliveryFeeDomicile = 1500;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryMode _mode = DeliveryMode.domicile;
  String _payment = 'especes'; // especes, flooz, tmoney
  final _addressController = TextEditingController();
  final _promoController = TextEditingController();
  bool _placing = false;
  bool _checkingPromo = false;

  AppAddress? _selectedAddress;
  bool _useNewAddress = false;

  double _discount = 0;
  String? _appliedPromo;
  String? _promoMessage;

  static const _pickupAddress = 'Boutique Baymore — Adidogomé, Lomé';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final auth = context.watch<AuthProvider>();
    final strings = AppStrings.of(context);
    final deliveryFee = _mode == DeliveryMode.domicile ? kDeliveryFeeDomicile : 0.0;
    final total = (cart.subtotal + deliveryFee - _discount).clamp(0, double.infinity);

    return Scaffold(
      appBar: AppBar(title: Text(strings.t('checkoutTitle'))),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(strings.t('deliveryModeTitle'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  _deliveryOption(
                    mode: DeliveryMode.domicile,
                    title: strings.t('deliveryHome'),
                    subtitle: strings.tf('deliveryHomeSubtitle', [Formatters.cfa(kDeliveryFeeDomicile)]),
                    icon: Icons.local_shipping_outlined,
                  ),
                  const SizedBox(height: 10),
                  _deliveryOption(
                    mode: DeliveryMode.retrait,
                    title: strings.t('deliveryPickup'),
                    subtitle: strings.t('deliveryPickupSubtitle'),
                    icon: Icons.storefront_outlined,
                  ),
                  const SizedBox(height: 20),
                  if (_mode == DeliveryMode.domicile) ...[
                    Text(strings.t('deliveryAddressTitle'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 10),
                    if (auth.uid != null) _AddressPicker(
                      uid: auth.uid!,
                      selected: _selectedAddress,
                      useNew: _useNewAddress,
                      onSelect: (a) => setState(() { _selectedAddress = a; _useNewAddress = false; }),
                      onUseNew: () => setState(() { _useNewAddress = true; _selectedAddress = null; }),
                    ),
                    if (_useNewAddress || auth.uid == null) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(hintText: strings.t('addressHint')),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                      child: Row(children: [
                        const Icon(Icons.storefront_outlined, color: AppColors.gold),
                        const SizedBox(width: 10),
                        const Expanded(child: Text(_pickupAddress, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                      ]),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Text(strings.t('paymentModeTitle'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  _paymentOption('especes', strings.t('paymentCash'), strings.t('paymentCashSubtitle'), Icons.payments_outlined),
                  const SizedBox(height: 8),
                  _paymentOption('flooz', strings.t('paymentFlooz'), strings.t('paymentFloozSubtitle'), Icons.smartphone_outlined),
                  const SizedBox(height: 8),
                  _paymentOption('tmoney', strings.t('paymentTmoney'), strings.t('paymentTmoneySubtitle'), Icons.smartphone_outlined),
                  const SizedBox(height: 20),
                  Text(strings.t('promoCode'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _promoController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(hintText: strings.t('promoHint')),
                        enabled: _appliedPromo == null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    if (_appliedPromo == null)
                      ElevatedButton(
                        onPressed: _checkingPromo ? null : () => _applyPromo(cart.subtotal, strings),
                        child: _checkingPromo
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(strings.actionApply),
                      )
                    else
                      OutlinedButton(
                        onPressed: () => setState(() { _appliedPromo = null; _discount = 0; _promoMessage = null; _promoController.clear(); }),
                        child: Text(strings.actionRemove),
                      ),
                  ]),
                  if (_promoMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(_promoMessage!, style: TextStyle(fontSize: 11.5, color: _appliedPromo != null ? AppColors.success : AppColors.danger)),
                  ],
                  const SizedBox(height: 24),
                  Text(strings.t('summaryTitle'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  const SizedBox(height: 10),
                  _summaryRow(strings.subtotal, Formatters.cfa(cart.subtotal)),
                  _summaryRow(strings.delivery, deliveryFee == 0 ? strings.free : Formatters.cfa(deliveryFee)),
                  if (_discount > 0) _summaryRow(strings.tf('discountWithCode', ['$_appliedPromo']), '- ${Formatters.cfa(_discount)}'),
                  const Divider(height: 24, color: AppColors.line),
                  _summaryRow(strings.total, Formatters.cfa(total), bold: true),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              decoration: const BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.line))),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _placing ? null : () => _placeOrder(cart, auth, deliveryFee, total.toDouble(), strings),
                  child: _placing
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(strings.tf('confirmWithTotal', [Formatters.cfa(total)])),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyPromo(double subtotal, AppStrings strings) async {
    if (_promoController.text.trim().isEmpty) return;
    setState(() => _checkingPromo = true);
    final result = await PromoService().validate(_promoController.text, subtotal);
    setState(() {
      _checkingPromo = false;
      if (result.valid) {
        _discount = result.discount;
        _appliedPromo = _promoController.text.trim().toUpperCase();
        _promoMessage = result.message.isNotEmpty ? result.message : strings.t('promoApplied');
      } else {
        _discount = 0;
        _appliedPromo = null;
        _promoMessage = result.message.isNotEmpty ? result.message : strings.t('promoInvalid');
      }
    });
  }

  Widget _deliveryOption({required DeliveryMode mode, required String title, required String subtitle, required IconData icon}) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppColors.ink : AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ]),
          ),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.ink : AppColors.line, size: 20),
        ]),
      ),
    );
  }

  Widget _paymentOption(String value, String title, String subtitle, IconData icon) {
    final selected = _payment == value;
    return GestureDetector(
      onTap: () => setState(() => _payment = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line, width: selected ? 1.6 : 1),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppColors.ink : AppColors.muted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
            ]),
          ),
          Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? AppColors.ink : AppColors.line, size: 18),
        ]),
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: bold ? 14 : 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: bold ? 15 : 12.5, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
      ]),
    );
  }

  Future<void> _placeOrder(CartProvider cart, AuthProvider auth, double deliveryFee, double total, AppStrings strings) async {
    final address = _mode == DeliveryMode.domicile
        ? (_useNewAddress || _selectedAddress == null ? _addressController.text.trim() : _selectedAddress!.fullAddress)
        : _pickupAddress;

    if (_mode == DeliveryMode.domicile && address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.t('addressMissing'))));
      return;
    }
    if (auth.uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.t('loginToOrder'))));
      return;
    }
    setState(() => _placing = true);
    try {
      final orderId = await OrderService().createOrder({
        'items': cart.toOrderItems(),
        'subtotal': cart.subtotal,
        'deliveryFee': deliveryFee,
        'discount': _discount,
        'promoCode': _appliedPromo,
        'total': total,
        'deliveryMode': _mode.asString,
        'deliveryAddress': address,
        'paymentMethod': _payment,
      });
      cart.clear();

      if (_payment == 'especes') {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => OrderTrackingScreen(orderId: orderId)),
            (route) => route.isFirst,
          );
        }
        return;
      }

      // Mobile Money (Flooz / T-Money) : on ouvre le guichet CinetPay puis
      // on bascule sur un écran qui attend la confirmation en temps réel.
      final paymentUrl = await PaymentService().initiatePayment(orderId);
      await launchUrl(Uri.parse(paymentUrl), mode: LaunchMode.externalApplication);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => PaymentPendingScreen(orderId: orderId)),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.t('orderError'))));
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}

/// Sélecteur d'adresse enregistrée, avec option "Nouvelle adresse".
class _AddressPicker extends StatefulWidget {
  final String uid;
  final AppAddress? selected;
  final bool useNew;
  final void Function(AppAddress) onSelect;
  final VoidCallback onUseNew;

  const _AddressPicker({
    required this.uid,
    required this.selected,
    required this.useNew,
    required this.onSelect,
    required this.onUseNew,
  });

  @override
  State<_AddressPicker> createState() => _AddressPickerState();
}

class _AddressPickerState extends State<_AddressPicker> {
  late Future<List<AppAddress>> _future;

  @override
  void initState() {
    super.initState();
    _future = AddressService().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return FutureBuilder<List<AppAddress>>(
      future: _future,
      builder: (context, snap) {
        final addresses = snap.data ?? [];
        if (addresses.isNotEmpty && widget.selected == null && !widget.useNew) {
          final def = addresses.firstWhere((a) => a.isDefault, orElse: () => addresses.first);
          WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSelect(def));
        }
        return Column(children: [
          ...addresses.map((a) {
            final isSelected = widget.selected?.id == a.id;
            return GestureDetector(
              onTap: () => widget.onSelect(a),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isSelected ? AppColors.ink : AppColors.line, width: isSelected ? 1.6 : 1),
                ),
                child: Row(children: [
                  Icon(Icons.location_on_outlined, size: 18, color: isSelected ? AppColors.ink : AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(a.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                      Text(a.fullAddress, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                    ]),
                  ),
                  Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: isSelected ? AppColors.ink : AppColors.line),
                ]),
              ),
            );
          }),
          GestureDetector(
            onTap: widget.onUseNew,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: widget.useNew ? AppColors.ink : AppColors.line, width: widget.useNew ? 1.6 : 1),
              ),
              child: Row(children: [
                Icon(Icons.add_location_alt_outlined, size: 18, color: widget.useNew ? AppColors.ink : AppColors.muted),
                const SizedBox(width: 10),
                Expanded(child: Text(strings.t('useNewAddress'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
                Icon(widget.useNew ? Icons.radio_button_checked : Icons.radio_button_off, size: 18, color: widget.useNew ? AppColors.ink : AppColors.line),
              ]),
            ),
          ),
        ]);
      },
    );
  }
}
