import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';

class EarningsTab extends StatelessWidget {
  const EarningsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KeyedSubtree(
        key: const ValueKey('earnings'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Earnings',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Wire this screen to your Nest `transactions` module (provider payouts, wallet history). '
                'The dashboard already lists transactions for admins — expose a filtered provider endpoint when ready.',
                style: GoogleFonts.dmSans(height: 1.5, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              _PlaceholderCard(
                title: 'Pending payouts',
                value: '—',
              ),
              const SizedBox(height: 12),
              _PlaceholderCard(
                title: 'This month (gross)',
                value: '—',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  const _PlaceholderCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(value, style: GoogleFonts.playfairDisplay(fontSize: 26, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const Icon(Icons.trending_up_rounded, color: AppColors.accentGold),
          ],
        ),
      ),
    );
  }
}
