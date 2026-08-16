import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
    NotificationService.addListener(_onNotificationUpdate);
  }

  @override
  void dispose() {
    NotificationService.removeListener(_onNotificationUpdate);
    super.dispose();
  }

  void _onNotificationUpdate() {
    if (mounted) setState(() => _future = _load());
  }

  Future<List<AppNotification>> _load() async {
    final list = await _service.fetchAll();
    return list;
  }

  Future<void> _refresh() async {
    setState(() => _future = _load());
    await _future;
  }

  Future<void> _markAsRead(String id, String title) async {
    await _service.markAsRead(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context, listen: false).t('notificationMarkedRead')}: $title')),
      );
    }
    await _refresh();
  }

  void _openNotificationDetails(AppNotification n) async {
    // Marquer comme lu d'abord
    await _service.markAsRead(n.id);
    
    // Afficher un message de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ouverture des détails de : ${n.title}')),
      );
    }
    
    // Navigation selon le type de notification
    switch (n.type) {
      case NotificationType.message:
        // Navigation vers la conversation - à implémenter selon votre structure
        if (mounted) {
          // TODO: Remplacer par la navigation réelle vers l'écran de conversation
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigation vers la conversation...')),
          );
        }
        break;
      case NotificationType.orderStatus:
      case NotificationType.newOrder:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigation vers le détail de la commande...')),
          );
        }
        break;
      case NotificationType.promotion:
      case NotificationType.newProduct:
      case NotificationType.restock:
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Navigation vers le produit...')),
          );
        }
        break;
      default:
        // Afficher les détails dans un dialog
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(n.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.body, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(
                    'Reçu le : ${Formatters.shortDate(n.receivedAt)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppStrings.of(context).close),
                ),
              ],
            ),
          );
        }
    }
    
    // Rafraîchir la liste après traitement
    await _refresh();
  }

  String _getNotificationTitle(AppNotification n, AppStrings strings) {
    switch (n.type) {
      case NotificationType.orderStatus:
        return strings.t('orderStatusNotification');
      case NotificationType.promotion:
        return strings.t('promotionNotification');
      case NotificationType.newProduct:
        return strings.t('newProductNotification');
      case NotificationType.restock:
        return strings.t('restockNotification');
      case NotificationType.newOrder:
        return strings.t('newOrderNotification');
      case NotificationType.message:
        return strings.t('messageNotification');
      case NotificationType.unknown:
        return n.title;
    }
  }

  IconData _getNotificationIcon(AppNotification n) {
    switch (n.type) {
      case NotificationType.orderStatus:
        return Icons.local_shipping_outlined;
      case NotificationType.promotion:
        return Icons.local_offer_outlined;
      case NotificationType.newProduct:
        return Icons.new_releases_outlined;
      case NotificationType.restock:
        return Icons.inventory_2_outlined;
      case NotificationType.newOrder:
        return Icons.shopping_bag_outlined;
      case NotificationType.message:
        return Icons.chat_bubble_outline;
      case NotificationType.unknown:
        return Icons.notifications_none_rounded;
    }
  }

  Color _getNotificationColor(AppNotification n) {
    switch (n.type) {
      case NotificationType.orderStatus:
        return AppColors.ink;
      case NotificationType.promotion:
        return AppColors.goldDeep;
      case NotificationType.newProduct:
        return AppColors.rose;
      case NotificationType.restock:
        return AppColors.sage;
      case NotificationType.newOrder:
        return AppColors.plum;
      case NotificationType.message:
        return AppColors.muted;
      case NotificationType.unknown:
        return AppColors.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.t('notificationsTitle')),
        actions: [
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: strings.t('markAllRead'),
            onPressed: () async {
              await _service.markAllRead();
              await _refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: strings.t('clearAll'),
            onPressed: () async {
              await _service.clear();
              await _refresh();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            if (items.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: strings.t('noNotifications'),
                    message: strings.t('noNotificationsMsg'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final n = items[i];
                final iconColor = _getNotificationColor(n);
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: n.read ? Colors.white : AppColors.ivory,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: n.read ? AppColors.line : AppColors.gold.withOpacity(0.3)),
                  ),
                  child: InkWell(
                    onTap: () => _openNotificationDetails(n),
                    borderRadius: BorderRadius.circular(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(.1),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(_getNotificationIcon(n), color: iconColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _getNotificationTitle(n, strings),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: n.read ? AppColors.ink : AppColors.ink,
                                      ),
                                    ),
                                  ),
                                  if (!n.read)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(n.body, style: TextStyle(fontSize: 12, color: n.read ? AppColors.muted : AppColors.inkSoft, height: 1.4)),
                              const SizedBox(height: 6),
                              Text(Formatters.shortDate(n.receivedAt), style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
