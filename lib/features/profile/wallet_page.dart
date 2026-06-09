import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key, required this.user});
  final AuthUser user;
  @override State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _withdrawing = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _amountCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<PartnerRepository>();
      final s = widget.user.shopId;
      final summary = s != null ? await repo.fetchShopWalletSummary(s) : await repo.fetchWalletSummary(widget.user.id);
      final txns = s != null ? await repo.fetchShopWalletTransactions(s) : await repo.fetchWalletTransactions(widget.user.id);
      if (mounted) setState(() {
        _balance = summary['balance'] is num ? (summary['balance'] as num).toInt() : 0;
        _transactions = txns.map((e) => Map<String, dynamic>.from(e)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _balance = 0; _transactions = []; _loading = false; });
    }
  }

  Future<void> _requestWithdrawal() async {
    final amt = int.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) { _snack('Montant invalide'); return; }
    if (amt > _balance) { _snack('Solde insuffisant'); return; }
    setState(() => _withdrawing = true);
    try {
      final repo = context.read<PartnerRepository>();
      final shopId = widget.user.shopId;
      if (shopId != null) {
        await repo.requestShopWithdrawal(shopId, amt, _phoneCtrl.text.trim());
      } else {
        await repo.requestWithdrawal(widget.user.id, amt, _phoneCtrl.text.trim());
      }
      if (mounted) { _snack('Demande de retrait envoyee'); _amountCtrl.clear(); _phoneCtrl.clear(); _load(); }
    } catch (e) { if (mounted) _snack('$e'); }
    finally { if (mounted) setState(() => _withdrawing = false); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso).toLocal();
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text('Portefeuille', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
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
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.profileNavy, AppColors.profileNavyLight]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    Text('Solde disponible', style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text('$_balance FCFA', style: GoogleFonts.dmSans(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Demander un retrait', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant (FCFA)',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Numero Mobile Money',
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _withdrawing ? null : _requestWithdrawal,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _withdrawing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Retirer', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              const SizedBox(height: 24),
              Text('Historique', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 12),
              if (_transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_outlined, color: Colors.grey.shade400, size: 40),
                      const SizedBox(height: 8),
                      Text('Aucune transaction', style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14)),
                    ],
                  ),
                )
              else
                ..._transactions.take(10).map((t) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Icon(t['transactionMotifId'] == 8 ? Icons.arrow_upward : Icons.arrow_downward,
                          color: t['transactionMotifId'] == 8 ? Colors.red : Colors.green, size: 18),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['label'] ?? '', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('${t["amount"]} FCFA', style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted)),
                            if (t['createdAt'] != null)
                              Text(
                                _formatDate(t['createdAt'].toString()),
                                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            ],
          ),
        ),
      ),
    );
  }
}

