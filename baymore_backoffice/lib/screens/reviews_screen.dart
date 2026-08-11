import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../theme/app_colors.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});
  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _service = ReviewModerationService();
  late Future<List<Review>> _future;

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
      appBar: AppBar(title: const Text('Avis clients')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Review>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final reviews = snap.data!;
            if (reviews.isEmpty) return const Center(child: Text('Aucun avis pour le moment.', style: TextStyle(color: AppColors.muted)));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reviews.length,
              itemBuilder: (context, i) {
                final r = reviews[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.line)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                        const SizedBox(width: 8),
                        Row(children: List.generate(5, (i) => Icon(i < r.rating.round() ? Icons.star : Icons.star_border, size: 13, color: AppColors.gold))),
                      ]),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                        onPressed: () => _confirmDelete(context, r.id),
                      ),
                    ]),
                    Text(DateFormat('dd MMM yyyy', 'fr_FR').format(r.createdAt), style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r.comment, style: const TextStyle(fontSize: 12.5)),
                    ],
                  ]),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet avis ?'),
        content: const Text('Utile pour retirer un avis inapproprié ou frauduleux. La note moyenne de l\'article sera recalculée automatiquement.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async { await _service.delete(id); if (context.mounted) Navigator.pop(context); _reload(); },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
