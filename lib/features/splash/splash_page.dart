import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/constants/app_strings.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/shell/partner_shell.dart';

/// Hero image — salon / beauty atmosphere (replace with branded asset in `assets/images/` if you prefer offline).
const _kSplashImage =
    'https://images.unsplash.com/photo-1560066984-138dadb4c035?w=1200&q=80';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _boot());
  }

  Future<void> _boot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    await context.read<AuthCubit>().init();
    if (!mounted) return;
    final s = context.read<AuthCubit>().state;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    final authRepo = context.read<AuthRepository>();
    if (s is AuthAuthenticated && authRepo.isSessionRecent) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const PartnerShell()),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _kSplashImage,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.primary),
            errorWidget: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.shellRail, Color(0xFF0A0C10)],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      AppStrings.appName.toUpperCase(),
                      style: GoogleFonts.dmSans(
                        color: AppColors.accentGold,
                        letterSpacing: 4,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your studio,\nelevated.',
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontSize: 40,
                        height: 1.05,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.providerTagline,
                      style: GoogleFonts.dmSans(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Center(
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.accentGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
