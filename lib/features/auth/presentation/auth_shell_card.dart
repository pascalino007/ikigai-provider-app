import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';

/// Yellow header + overlapping white card (reference auth UI).
class AuthShellCard extends StatelessWidget {
  const AuthShellCard({
    super.key,
    required this.headerTitle,
    required this.headerSubtitle,
    required this.child,
  });

  final String headerTitle;
  final String headerSubtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      color: AppColors.authAmber,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 200 + topInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.authAmber,
                    AppColors.authAmberDeep,
                  ],
                ),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(28, topInset + 28, 28, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1A),
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      headerSubtitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF1A1A1A).withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: topInset + 118,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x25000000),
                    blurRadius: 24,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
