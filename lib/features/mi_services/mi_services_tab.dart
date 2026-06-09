import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';

/// MI Services — placeholder page for the provider app.
class MiServicesTab extends StatelessWidget {
  const MiServicesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MI Services',
              style: GoogleFonts.dmSans(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gérez vos services premium et offres spéciales ici.',
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.construction_outlined,
                    size: 64,
                    color: AppColors.muted.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Page en construction',
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cette section sera disponible prochainement.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
