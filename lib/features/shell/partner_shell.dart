import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/constants/app_strings.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/features/appointments/appointments_tab.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/earnings/earnings_tab.dart';
import 'package:ikigai_provider_app/features/home/home_tab.dart';
import 'package:ikigai_provider_app/features/mi_services/mi_services_tab.dart';
import 'package:ikigai_provider_app/features/profile/profile_tab.dart';
import 'package:ikigai_provider_app/features/services/services_tab.dart';
import 'package:ikigai_provider_app/features/staff/staff_tab.dart';

/// Partner app shell: tablet uses dark rail; phone uses floating pill nav + center FAB (wallet-style).
class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key});

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int _index = 0;

  static const _destinations = [
    _NavSpec('Home', Icons.home_rounded),
    _NavSpec('Services', Icons.cut_rounded),
    _NavSpec('Bookings', Icons.calendar_month_rounded),
    _NavSpec('Team', Icons.groups_rounded),
    _NavSpec('Earnings', Icons.payments_rounded),
    _NavSpec('MI Services', Icons.auto_awesome_outlined),
    _NavSpec('Profile', Icons.person_rounded),
  ];

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    if (auth is! AuthAuthenticated) {
      return const SizedBox.shrink();
    }

    final pages = [
      HomeTab(user: auth.user, onNavigateToTab: _go),
      ServicesTab(user: auth.user),
      AppointmentsTab(user: auth.user),
      const StaffTab(),
      const EarningsTab(),
      const MiServicesTab(),
      ProfileTab(user: auth.user, onNavigateToTab: _go),
    ];

    final wide = MediaQuery.sizeOf(context).width >= 760;

    final content = DecoratedBox(
      decoration: const BoxDecoration(color: Colors.white),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: pages[_index],
        ),
      ),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            _DarkRail(
              selectedIndex: _index,
              onSelect: _go,
              destinations: _destinations,
            ),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: content),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                child: _FloatingPartnerNav(
                  selectedIndex: _index,
                  onSelect: _go,
                  onCenterTap: () => _go(2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingPartnerNav extends StatelessWidget {
  const _FloatingPartnerNav({
    required this.selectedIndex,
    required this.onSelect,
    required this.onCenterTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.dashboardGreen,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _BarItem(
              icon: Icons.home_rounded,
              label: 'Home',
              active: selectedIndex == 0,
              onTap: () => onSelect(0),
            ),
          ),
          Expanded(
            child: _BarItem(
              icon: Icons.cut_rounded,
              label: 'Services',
              active: selectedIndex == 1,
              onTap: () => onSelect(1),
            ),
          ),
          SizedBox(
            width: 78,
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -26),
                child: Material(
                  color: AppColors.accentLime,
                  elevation: 8,
                  shadowColor: Colors.black38,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onCenterTap,
                    child: SizedBox(
                      width: 58,
                      height: 58,
                      child: Icon(Icons.calendar_month_rounded, color: AppColors.dashboardGreenDeep, size: 28),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _BarItem(
              icon: Icons.groups_rounded,
              label: 'Team',
              active: selectedIndex == 3,
              onTap: () => onSelect(3),
            ),
          ),
          Expanded(
            child: _BarItem(
              icon: Icons.auto_awesome_outlined,
              label: 'MI Services',
              active: selectedIndex == 5,
              onTap: () => onSelect(5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accentLime : Colors.white54;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.accentLime : Colors.white38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavSpec {
  const _NavSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _DarkRail extends StatelessWidget {
  const _DarkRail({
    required this.selectedIndex,
    required this.onSelect,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final List<_NavSpec> destinations;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      color: AppColors.dashboardGreenDeep,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'I',
              style: GoogleFonts.playfairDisplay(
                color: AppColors.accentGold,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              AppStrings.appName,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: destinations.length,
                itemBuilder: (context, i) {
                  final d = destinations[i];
                  final sel = i == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: sel ? AppColors.dashboardGreen.withValues(alpha: 0.9) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onSelect(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Column(
                            children: [
                              Icon(d.icon, color: sel ? AppColors.accentLime : Colors.white54, size: 24),
                              const SizedBox(height: 4),
                              Text(
                                d.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? Colors.white : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
