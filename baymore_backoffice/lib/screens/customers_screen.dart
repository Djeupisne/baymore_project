import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/customer_service.dart';
import '../theme/app_colors.dart';
import 'customer_detail_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _query = '';
  late Future<List<Customer>> _future;

  @override
  void initState() {
    super.initState();
    _future = CustomerService().fetchAll();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Rechercher un client (nom, e-mail, téléphone)',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.line)),
          ),
          onChanged: (v) => setState(() => _query = v.toLowerCase()),
        ),
      ),
      Expanded(
        child: FutureBuilder<List<Customer>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            var customers = snap.data!;
            if (_query.isNotEmpty) {
              customers = customers.where((c) =>
                  c.name.toLowerCase().contains(_query) ||
                  c.email.toLowerCase().contains(_query) ||
                  c.phone.contains(_query)).toList();
            }
            if (customers.isEmpty) return const Center(child: Text('Aucun client trouvé', style: TextStyle(color: AppColors.muted)));
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              itemCount: customers.length,
              itemBuilder: (context, i) {
                final c = customers[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.ink,
                      child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700)),
                    ),
                    title: Text(c.name.isEmpty ? 'Client sans nom' : c.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    subtitle: Text(c.phone.isEmpty ? c.email : c.phone, style: const TextStyle(fontSize: 11.5)),
                    trailing: Text('${c.loyaltyPoints} pts', style: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700)),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c))),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
