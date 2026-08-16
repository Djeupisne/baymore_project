import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/order_status.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/socket_service.dart';
import '../theme/app_colors.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _service = OrderService();
  OrderStatus? _filter;
  List<AppOrder> _orders = [];
  bool _loading = true;
  String? _error;

  StreamSubscription? _newOrderSub;
  StreamSubscription? _updateOrderSub;

  @override
  void initState() {
    super.initState();
    _load();
    // Diffusion en direct : dès qu'une commande est créée ou change de
    // statut ailleurs (par un collègue, un paiement confirmé...), la
    // liste se met à jour sans que le staff ait besoin de rafraîchir.
    final socket = SocketService().socket;
    _newOrderSub = _listen(socket, 'order:new', (data) {
      final order = AppOrder.fromJson(Map<String, dynamic>.from(data));
      if (!mounted) return;
      setState(() => _orders = [order, ..._orders.where((o) => o.id != order.id)]);
    });
    _updateOrderSub = _listen(socket, 'order:update', (data) {
      final updated = AppOrder.fromJson(Map<String, dynamic>.from(data));
      if (!mounted) return;
      setState(() => _orders = _orders.map((o) => o.id == updated.id ? updated : o).toList());
    });
  }

  StreamSubscription _listen(dynamic socket, String event, void Function(dynamic) handler) {
    socket.on(event, handler);
    return _SocketOffSubscription(socket, event, handler);
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final orders = await _service.fetchAll();
      if (!mounted) return;
      setState(() { _orders = orders; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = e is ApiException ? e.message : 'Impossible de charger les commandes.'; });
    }
  }

  /// Applique localement le nouveau statut sans attendre l'écho du socket,
  /// pour que l'écran réagisse instantanément même si la diffusion en
  /// direct est en retard ou indisponible.
  void _applyLocalUpdate(String orderId, AppOrder Function(AppOrder) update) {
    if (!mounted) return;
    setState(() => _orders = _orders.map((o) => o.id == orderId ? update(o) : o).toList());
  }

  @override
  void dispose() {
    _newOrderSub?.cancel();
    _updateOrderSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var orders = _orders;
    if (_filter != null) orders = orders.where((o) => o.status == _filter).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(spacing: 8, children: [
            _chip(null, 'Toutes'),
            _chip(OrderStatus.enAttente, 'Reçues'),
            _chip(OrderStatus.priseEnCharge, 'Prises en charge'),
            _chip(OrderStatus.enRoute, 'En route'),
            _chip(OrderStatus.livree, 'Livrées'),
          ]),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorState(message: _error!, onRetry: _load)
                  : orders.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(children: const [
                            SizedBox(height: 120),
                            Center(child: Text('Aucune commande', style: TextStyle(color: AppColors.muted))),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: orders.length,
                            itemBuilder: (context, i) => _OrderCard(
                              order: orders[i],
                              service: _service,
                              onLocalUpdate: _applyLocalUpdate,
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _chip(OrderStatus? status, String label) {
    final count = status == null ? _orders.length : _orders.where((o) => o.status == status).length;
    final selected = _filter == status;
    return ChoiceChip(
      label: Text(count > 0 ? '$label ($count)' : label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = status),
      selectedColor: AppColors.ink,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.ink, fontWeight: FontWeight.w700, fontSize: 12),
      backgroundColor: Colors.white,
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: AppColors.muted, size: 36),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onRetry, child: const Text('Réessayer')),
        ]),
      ),
    );
  }
}

/// Petit adaptateur pour pouvoir "annuler" un `socket.on(...)` avec la même
/// API qu'un StreamSubscription classique (utilisé uniquement pour le
/// nettoyage dans dispose()).
class _SocketOffSubscription implements StreamSubscription<dynamic> {
  final dynamic socket;
  final String event;
  final void Function(dynamic) handler;
  _SocketOffSubscription(this.socket, this.event, this.handler);

  @override
  Future<void> cancel() async => socket.off(event, handler);

  @override
  void onData(void Function(dynamic)? handleData) {}
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) {}
  @override
  void resume() {}
  @override
  bool get isPaused => false;
  @override
  Future<E> asFuture<E>([E? futureValue]) async => futureValue as E;
}

class _OrderCard extends StatefulWidget {
  final AppOrder order;
  final OrderService service;
  final void Function(String orderId, AppOrder Function(AppOrder) update) onLocalUpdate;
  const _OrderCard({required this.order, required this.service, required this.onLocalUpdate});
  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _busy = false;
  bool _cancelling = false;
  bool _sharingLocation = false;
  StreamSubscription<Position>? _positionSub;

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _showAssignDriverDialog() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assigner un livreur'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nom du livreur')),
          const SizedBox(height: 10),
          TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Valider')),
        ],
      ),
    );
    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await widget.service.assignDriver(widget.order.id, nameCtrl.text.trim(), phoneCtrl.text.trim());
      widget.onLocalUpdate(widget.order.id, (o) => AppOrder(
            id: o.id, userId: o.userId, items: o.items, total: o.total, deliveryMode: o.deliveryMode,
            deliveryAddress: o.deliveryAddress, paymentMethod: o.paymentMethod, paymentStatus: o.paymentStatus,
            status: o.status, driverName: nameCtrl.text.trim(), driverPhone: phoneCtrl.text.trim(), createdAt: o.createdAt,
          ));
    } else {
      throw _CancelledException();
    }
  }

  Future<void> _advance() async {
    final next = widget.order.status.next;
    if (next == null) return;
    setState(() => _busy = true);
    try {
      if (next == OrderStatus.enRoute && widget.order.driverName == null) {
        await _showAssignDriverDialog();
      }
      await widget.service.advanceStatus(widget.order.id, next);
      widget.onLocalUpdate(widget.order.id, (o) => AppOrder(
            id: o.id, userId: o.userId, items: o.items, total: o.total, deliveryMode: o.deliveryMode,
            deliveryAddress: o.deliveryAddress, paymentMethod: o.paymentMethod, paymentStatus: o.paymentStatus,
            status: next, driverName: o.driverName, driverPhone: o.driverPhone, createdAt: o.createdAt,
          ));
    } on _CancelledException {
      // L'utilisateur a fermé la boîte de dialogue "Assigner un livreur" sans valider.
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la commande'),
        content: const Text('Confirmer l\'annulation de cette commande ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Non')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _cancelling = true);
    try {
      await widget.service.cancel(widget.order.id);
      widget.onLocalUpdate(widget.order.id, (o) => AppOrder(
            id: o.id, userId: o.userId, items: o.items, total: o.total, deliveryMode: o.deliveryMode,
            deliveryAddress: o.deliveryAddress, paymentMethod: o.paymentMethod, paymentStatus: o.paymentStatus,
            status: OrderStatus.annulee, driverName: o.driverName, driverPhone: o.driverPhone, createdAt: o.createdAt,
          ));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _cancelling = false);
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    final message = e is ApiException ? e.message : 'Une erreur est survenue. Réessayez.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.danger));
  }

  /// Active/désactive le partage de position en direct — à utiliser par le
  /// livreur lui-même depuis son téléphone pendant qu'il est "En route".
  /// La position est envoyée à chaque déplacement de 30 mètres ou plus.
  Future<void> _toggleLocationSharing() async {
    if (_sharingLocation) {
      await _positionSub?.cancel();
      setState(() => _sharingLocation = false);
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Autorisation de localisation refusée. Activez-la dans les réglages du téléphone.")));
      }
      return;
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activez la localisation (GPS) de votre téléphone.')));
      }
      return;
    }

    setState(() => _sharingLocation = true);
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 30),
    ).listen((position) {
      widget.service.updateDriverPosition(widget.order.id, position.latitude, position.longitude);
    });

    try {
      final current = await Geolocator.getCurrentPosition();
      await widget.service.updateDriverPosition(widget.order.id, current.latitude, current.longitude);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final next = o.status.next;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('#${(o.id.length >= 6 ? o.id.substring(0, 6) : o.id).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(20)),
            child: Text(o.status.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
        const SizedBox(height: 6),
        Text(DateFormat('dd MMM, HH:mm', 'fr_FR').format(o.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 8),
        Text('${o.items.length} article(s) · ${o.deliveryMode == 'RETRAIT' ? 'Retrait boutique' : 'Livraison domicile'}', style: const TextStyle(fontSize: 12)),
        if (o.deliveryMode != 'RETRAIT') Text(o.deliveryAddress, style: const TextStyle(fontSize: 11.5, color: AppColors.muted)),
        const SizedBox(height: 6),
        Text('${o.total.toStringAsFixed(0)} F CFA · ${_paymentLabel(o)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
        if (o.driverName != null) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Livreur : ${o.driverName} · ${o.driverPhone ?? ''}', style: const TextStyle(fontSize: 11.5, color: AppColors.sand, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Row(children: [
          if (next != null)
            Expanded(
              child: ElevatedButton(
                onPressed: _busy ? null : _advance,
                child: _busy
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Marquer : ${next.label}'),
              ),
            ),
          if (o.status != OrderStatus.livree && o.status != OrderStatus.annulee) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _cancelling ? null : _cancel,
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              child: _cancelling
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.danger))
                  : const Text('Annuler'),
            ),
          ],
        ]),
        if (o.status == OrderStatus.enRoute) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _toggleLocationSharing,
              icon: Icon(_sharingLocation ? Icons.location_on : Icons.location_off_outlined,
                  size: 18, color: _sharingLocation ? AppColors.success : AppColors.ink),
              label: Text(
                _sharingLocation ? 'Position partagée en direct — arrêter' : 'Je livre : partager ma position en direct',
                style: TextStyle(color: _sharingLocation ? AppColors.success : AppColors.ink, fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(side: BorderSide(color: _sharingLocation ? AppColors.success : AppColors.line)),
            ),
          ),
        ],
      ]),
    );
  }

  String _paymentLabel(AppOrder o) {
    if (o.paymentMethod == 'especes') return 'Espèces à la livraison';
    final status = o.paymentStatus == 'PAYE' ? 'payé' : o.paymentStatus == 'ECHOUE' ? 'échoué' : 'en attente';
    return '${o.paymentMethod == 'flooz' ? 'Flooz' : 'T-Money'} ($status)';
  }
}

class _CancelledException implements Exception {}
