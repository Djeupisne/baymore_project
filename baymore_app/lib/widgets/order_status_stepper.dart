import 'package:flutter/material.dart';
import '../models/order_status.dart';
import '../theme/app_colors.dart';

/// Représente visuellement les 4 étapes de la commande, avec l'étape
/// active mise en évidence — alimenté en temps réel par un StreamBuilder
/// sur le document Firestore de la commande.
class OrderStatusStepper extends StatelessWidget {
  final OrderStatus status;
  const OrderStatusStepper({super.key, required this.status});

  static const _steps = [
    OrderStatus.enAttente,
    OrderStatus.priseEnCharge,
    OrderStatus.enRoute,
    OrderStatus.livree,
  ];

  static const _icons = [
    Icons.receipt_long_outlined,
    Icons.storefront_outlined,
    Icons.local_shipping_outlined,
    Icons.home_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = status.stepIndex;
    return Column(
      children: List.generate(_steps.length, (i) {
        final done = i <= currentIndex;
        final isLast = i == _steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: done ? AppColors.ink : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: done ? AppColors.ink : AppColors.line, width: 1.4),
                    ),
                    child: Icon(_icons[i], size: 16, color: done ? AppColors.gold : AppColors.muted),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: i < currentIndex ? AppColors.ink : AppColors.line,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 26, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_steps[i].label,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: done ? AppColors.ink : AppColors.muted)),
                      const SizedBox(height: 3),
                      if (i == currentIndex)
                        Text(_steps[i].description,
                            style: const TextStyle(fontSize: 11.5, color: AppColors.muted, height: 1.4)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
