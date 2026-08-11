import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/return_request.dart';
import '../services/return_service.dart';
import '../theme/app_colors.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _service = ReturnRequestService();
  late Future<List<ReturnRequest>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.fetchAll();
  }

  Future<void> _reload() async {
    setState(() => _future = _service.fetchAll());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retours & remboursements')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<ReturnRequest>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final requests = snap.data!;
            if (requests.isEmpty) {
              return const Center(child: Text('Aucune demande de retour pour le moment.', style: TextStyle(color: AppColors.muted)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, i) => _ReturnCard(request: requests[i], service: _service, onChanged: _reload),
            );
          },
        ),
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final ReturnRequest request;
  final ReturnRequestService service;
  final VoidCallback onChanged;
  const _ReturnCard({required this.request, required this.service, required this.onChanged});

  Color get _color {
    switch (request.status) {
      case ReturnStatus.approuve: return AppColors.sand;
      case ReturnStatus.refuse: return AppColors.danger;
      case ReturnStatus.rembourse: return AppColors.success;
      case ReturnStatus.enAttente: return AppColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Commande #${request.orderId.substring(0, 6).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
            child: Text(request.status.label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: _color)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(request.userName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text(DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(request.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.muted)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(10)),
          child: Text(request.reason, style: const TextStyle(fontSize: 12)),
        ),
        if (request.status == ReturnStatus.enAttente) ...[
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () async { await service.updateStatus(request.id, ReturnStatus.approuve); onChanged(); },
                child: const Text('Approuver'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () async { await service.updateStatus(request.id, ReturnStatus.refuse); onChanged(); },
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
                child: const Text('Refuser'),
              ),
            ),
          ]),
        ],
        if (request.status == ReturnStatus.approuve) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async { await service.updateStatus(request.id, ReturnStatus.rembourse); onChanged(); },
              child: const Text('Marquer comme remboursé'),
            ),
          ),
        ],
      ]),
    );
  }
}
