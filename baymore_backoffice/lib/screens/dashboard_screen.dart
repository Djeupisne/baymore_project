import 'package:flutter/material.dart';
import '../services/staff_auth_service.dart';
import '../theme/app_colors.dart';
import '../components/ui_components.dart';
import 'customers_screen.dart';
import 'more_screen.dart';
import 'orders_screen.dart';
import 'overview_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;
  final _screens = const [OverviewScreen(), OrdersScreen(), CustomersScreen(), MoreScreen()];
  final _titles = const ['Tableau de bord', 'Commandes', 'Clients', 'Plus'];

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 48),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Se déconnecter'),
            onPressed: () async {
              Navigator.pop(context);
              await StaffAuthService().logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_titles[_index], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text('Baymore Backoffice', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500)),
          ],
        ),
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.ivory,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.logout, size: 20),
              onPressed: _confirmLogout,
              tooltip: 'Déconnexion',
            ),
          ),
        ],
      ),
      body: _screens[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        height: 72,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Aperçu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Clients',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Plus',
          ),
        ],
      ),
    );
  }
}
