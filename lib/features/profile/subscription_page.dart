import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key, required this.user});
  final AuthUser user;
  @override State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool _loading = true;
  Map<String, dynamic>? _subscription;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<PartnerRepository>();
      final s = widget.user.shopId;
      final sub = s != null ? await repo.fetchShopSubscription(s) : await repo.fetchSubscription(widget.user.id);
      if (mounted) setState(() { _subscription = sub; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _subscription = null; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Mon Abonnement', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: _loading ? const Center(child: CircularProgressIndicator()) : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlanCard(),
              const SizedBox(height: 24),
              _buildDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard() {
    final plan = _subscription?['plan'] ?? 'Aucun abonnement';
    final active = _subscription != null && _subscription!['status'] == 'active';
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6D4AFF), Color(0xFF9B7BFF)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Icon(Icons.card_membership, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          Text(plan, style: GoogleFonts.dmSans(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: active ? Colors.green : Colors.grey, borderRadius: BorderRadius.circular(20)),
            child: Text(active ? 'Actif' : 'Inactif', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    if (_subscription == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Icon(Icons.info_outline, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 8),
            Text('Aucun abonnement actif. Contactez l administrateur pour souscrire a un forfait.', textAlign: TextAlign.center, style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14)),
          ],
        ),
      );
    }
    final price = _subscription!['price'] ?? 0;
    final interval = _subscription!['interval'] ?? 'mois';
    final next = _subscription!['next_billing'] != null
        ? _formatDate(_subscription!['next_billing'].toString())
        : 'N/A';
    final max = _subscription!['max_bookings']?.toString() ?? 'Illimite';
    final features = _subscription!['features']?.toString() ?? '';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Details du forfait', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          _row('Prix', '${price} FCFA / ${interval}'),
          _row('Prochaine facturation', next),
          _row('Reservations max', max),
          if (features.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Fonctionnalites', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            Text(features, style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return iso;
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14)),
          Text(value, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
