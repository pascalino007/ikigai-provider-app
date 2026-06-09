import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/entities/shop.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/profile/change_password_page.dart';
import 'package:ikigai_provider_app/features/profile/wallet_page.dart';
import 'package:ikigai_provider_app/features/profile/subscription_page.dart';
import 'package:ikigai_provider_app/features/onboarding/shop_onboarding_page.dart';

/// Profile inspired by fintech / cards UI: hero header, stats card, quick actions, GENERAL list.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key, required this.user, this.onNavigateToTab});

  final AuthUser user;
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Shop? _shop;
  List<Booking> _bookings = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = context.read<PartnerRepository>();
      Shop? shop;
      if (widget.user.shopId != null) {
        shop = await repo.fetchShopById(widget.user.shopId!);
      }
      final shopId = widget.user.shopId;
      final b = shopId != null 
          ? await repo.fetchBookingsForProvider('$shopId')
          : <Booking>[];
      if (mounted) {
        setState(() {
          _shop = shop;
          _bookings = b;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = '${widget.user.firstname} ${widget.user.lastname}'.trim();
    final pending = _bookings.where((x) => x.bookingStatus == 0).length;
    final confirmed = _bookings.where((x) => x.bookingStatus == 1).length;

    return ColoredBox(
      color: const Color(0xFFF5F6FA),
      child: KeyedSubtree(
        key: const ValueKey('profile'),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      MediaQuery.paddingOf(context).top + 16,
                      24,
                      88,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.profileNavy, AppColors.profileNavyLight],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shop?.name ?? 'Mon studio',
                          style: GoogleFonts.dmSans(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _shop?.displayAddressLine ?? widget.user.email,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(color: Colors.white54, fontSize: 12, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    top: MediaQuery.paddingOf(context).top + 72,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentGold, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white,
                            backgroundImage: widget.user.image.isNotEmpty ? NetworkImage(widget.user.image) : null,
                            child: widget.user.image.isEmpty
                                ? Text(
                                    widget.user.firstname.isNotEmpty ? widget.user.firstname[0].toUpperCase() : '?',
                                    style: GoogleFonts.dmSans(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.profileNavy),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (widget.user.shopId != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.verified_rounded, color: AppColors.accentGold, size: 24),
                            ],
                          ],
                        ),
                        Text(
                          widget.user.email,
                          style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else
                          _StatsCard(pending: pending, confirmed: confirmed),
                        const SizedBox(height: 28),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'GENERAL',
                            style: GoogleFonts.dmSans(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _MenuCard(
                          children: [
                            _MenuTile(
                              icon: Icons.storefront_outlined,
                              title: 'Fiche salon & GPS',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const ShopOnboardingPage()),
                                );
                              },
                            ),
                            _divider(),
                            _MenuTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Mot de passe',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage()),
                                );
                              },
                            ),
                            _divider(),
                            _MenuTile(
                              icon: Icons.notifications_none_rounded,
                              title: 'Notifications',
                              onTap: () {},
                            ),
                            _divider(),
                            _MenuTile(
                              icon: Icons.history_rounded,
                              title: 'Historique des réservations',
                              onTap: () => widget.onNavigateToTab?.call(2),
                            ),
                            _divider(),
                            _MenuTile(
                              icon: Icons.card_membership_outlined,
                              title: 'Mon Abonnement',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => SubscriptionPage(user: widget.user),
                                  ),
                                );
                              },
                            ),
                            _divider(),
                            _MenuTile(
                              icon: Icons.account_balance_wallet_outlined,
                              title: 'Portefeuille',
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => WalletPage(user: widget.user),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          tileColor: Colors.white,
                          leading: Icon(Icons.logout_rounded, color: Colors.red.shade700),
                          title: Text('Déconnexion', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
                          onTap: () async {
                            await context.read<AuthCubit>().logout();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                            }
                          },
                        ),
                        SizedBox(height: MediaQuery.paddingOf(context).bottom + 120),
                      ],
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

  Widget _divider() => Divider(height: 1, color: Colors.grey.shade200);
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({required this.pending, required this.confirmed});

  final int pending;
  final int confirmed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up_rounded, color: Colors.green.shade600, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'Confirmées',
                        style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$confirmed',
                    style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
                  ),
                ],
              ),
            ),
            Container(width: 1, height: 48, color: Colors.grey.shade200),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'En attente',
                        style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.trending_down_rounded, color: Colors.orange.shade700, size: 18),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$pending',
                    style: GoogleFonts.dmSans(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF1E293B)),
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

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Column(children: children),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.profileNavyLight),
      title: Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15)),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }
}

