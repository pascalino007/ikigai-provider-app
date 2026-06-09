import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/data/local/availability_storage.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/entities/shop.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/home/dashboard_header_clipper.dart';
import 'package:ikigai_provider_app/features/onboarding/shop_onboarding_page.dart';

/// Wallet-style dashboard: curved green header, hero metric, quick actions, recent list.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.user, this.onNavigateToTab});

  final AuthUser user;
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _hideMetrics = false;
  List<Booking> _bookings = [];
  bool _loadingBookings = true;
  String? _bookingsError;
  Shop? _shop;
  bool _loadingShop = false;

  /// `true` = En ligne / disponible, `false` = Occupé / occupé
  bool _available = true;

  static const _bottomReserve = 110.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _available = await AvailabilityStorage.isAvailable(widget.user.id);
      if (mounted) setState(() {});
      await _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingBookings = true;
      _bookingsError = null;
      if (widget.user.shopId != null) _loadingShop = true;
    });
    try {
      final repo = context.read<PartnerRepository>();
      final shopId = widget.user.shopId;
      if (shopId == null) {
        setState(() {
          _bookings = [];
          _loadingBookings = false;
          _loadingShop = false;
        });
        return;
      }
      final list = await repo.fetchBookingsForProvider('$shopId');
      list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      Shop? shop;
      if (widget.user.shopId != null) {
        shop = await repo.fetchShopById(widget.user.shopId!);
      }
      if (mounted) {
        setState(() {
          _bookings = list.take(8).toList();
          _loadingBookings = false;
          _shop = shop;
          _loadingShop = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingsError = '$e';
          _loadingBookings = false;
          _loadingShop = false;
        });
      }
    }
  }

  Future<void> _setAvailability(bool v) async {
    await AvailabilityStorage.setAvailable(widget.user.id, v);
    if (mounted) setState(() => _available = v);
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final first = widget.user.firstname.isNotEmpty ? widget.user.firstname : 'Partner';
    final pendingCount = _bookings.where((b) => b.bookingStatus == 0).length;
    final heroValue = widget.user.shopId != null
        ? (_hideMetrics ? '•••' : '$pendingCount')
        : '—';
    final heroLabel = widget.user.shopId != null ? 'Pending booking requests' : 'Complete studio setup';

    return KeyedSubtree(
      key: const ValueKey('home'),
      child: ColoredBox(
        color: Colors.white,
        child: RefreshIndicator(
          color: AppColors.accentLime,
          onRefresh: _loadDashboard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: ClipPath(
                  clipper: DashboardHeaderClipper(curveHeight: 20),
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.dashboardGreenDeep,
                          AppColors.dashboardGreen,
                          Color(0xFF0D5C52),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.accentLime.withValues(alpha: 0.25),
                                  backgroundImage: widget.user.image.isNotEmpty ? NetworkImage(widget.user.image) : null,
                                  child: widget.user.image.isEmpty
                                      ? Text(
                                          first.substring(0, 1).toUpperCase(),
                                          style: GoogleFonts.dmSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 18,
                                          ),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        greet,
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Hello, $first',
                                        style: GoogleFonts.dmSans(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (widget.user.shopId != null) ...[
                                  GestureDetector(
                                    onTap: () {
                                      setState(() => _available = !_available);
                                      _setAvailability(_available);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _available
                                            ? const Color(0xFF4ADE80).withValues(alpha: 0.2)
                                            : const Color(0xFFFFB020).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: _available
                                              ? const Color(0xFF4ADE80)
                                              : const Color(0xFFFFB020),
                                          width: 2,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (pendingCount > 0)
                                            TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0.4, end: 1.0),
                                              duration: const Duration(milliseconds: 600),
                                              curve: Curves.easeInOut,
                                              builder: (context, value, child) => Opacity(
                                                opacity: value,
                                                child: child,
                                              ),
                                              child: const Icon(
                                                Icons.notifications_active_rounded,
                                                color: Color(0xFFFFB020),
                                                size: 24,
                                              ),
                                            ),
                                          if (pendingCount > 0) const SizedBox(width: 8),
                                          // Pulsing status dot with continuous animation
                                          _PulsingDot(isOnline: _available),
                                          const SizedBox(width: 10),
                                          Text(
                                            _available ? 'En ligne' : 'Occupé',
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                ],
                                Material(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(10),
                                    onTap: () {},
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _StatItem(
                                    value: '${_bookings.map((b) => b.userId).toSet().length}',
                                    label: 'Clients',
                                    icon: Icons.people_outline_rounded,
                                  ),
                                  Container(width: 1, height: 28, color: Colors.white24),
                                  _StatItem(
                                    value: '${_bookings.length}',
                                    label: 'Bookings',
                                    icon: Icons.calendar_today_rounded,
                                  ),
                                  Container(width: 1, height: 28, color: Colors.white24),
                                  // TODO: Replace 5000 with actual service prices when API includes price data
                                  _StatItem(
                                    value: '${_bookings.where((b) => b.bookingStatus == 1).length * 5000} F',
                                    label: 'Earned today',
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, _bottomReserve),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 15),
                        Text(
                          'Quick actions',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.white,
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _RoundQuickAction(
                                  icon: Icons.calendar_month_rounded,
                                  color: const Color(0xFF2E7D32),
                                  label: 'Bookings',
                                  onTap: () => widget.onNavigateToTab?.call(2),
                                ),
                                _RoundQuickAction(
                                  icon: Icons.content_cut_rounded,
                                  color: const Color(0xFFC62828),
                                  label: 'Services',
                                  onTap: () => widget.onNavigateToTab?.call(1),
                                ),
                                _RoundQuickAction(
                                  icon: Icons.groups_rounded,
                                  color: const Color(0xFF1565C0),
                                  label: 'Team',
                                  onTap: () => widget.onNavigateToTab?.call(3),
                                ),
                                _RoundQuickAction(
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: AppColors.accentGold,
                                  label: 'Wallet',
                                  onTap: () => widget.onNavigateToTab?.call(4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent activity',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: AppColors.primary,
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.onNavigateToTab?.call(2),
                              child: Text(
                                'See all',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.accentLimeMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (widget.user.shopId == null)
                          _setupBanner(context)
                        else if (_loadingBookings)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_bookingsError != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              _bookingsError!,
                              style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 13),
                            ),
                          )
                        else if (_bookings.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No appointments yet. When clients book you, they appear here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSans(color: AppColors.muted, height: 1.5),
                              ),
                            ),
                          )
                        else
                          ..._bookings.map((b) => _ActivityTile(b)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await context.read<AuthCubit>().logout();
                            if (context.mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _setupBanner(BuildContext context) {
    return Material(
      color: AppColors.canvas.withValues(alpha: 0.9),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        leading: const Icon(Icons.storefront_outlined, color: AppColors.primary),
        title: Text('Finish your public listing', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        subtitle: Text(
          'Same details as the admin “Add shop” flow.',
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ShopOnboardingPage()),
          );
        },
      ),
    );
  }
}

class _HeroPillButton extends StatelessWidget {
  const _HeroPillButton({
    required this.label,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color foreground;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: Colors.white60,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _StudioChip extends StatelessWidget {
  const _StudioChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.accentLime : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: selected ? AppColors.dashboardGreenDeep : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundQuickAction extends StatelessWidget {
  const _RoundQuickAction({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.muted),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTile extends StatefulWidget {
  const _ActivityTile(this.booking);

  final Booking booking;

  @override
  State<_ActivityTile> createState() => _ActivityTileState();
}

class _ActivityTileState extends State<_ActivityTile> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeRemaining());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      widget.booking.bookingDate.year,
      widget.booking.bookingDate.month,
      widget.booking.bookingDate.day,
      widget.booking.bookingTime.hour,
      widget.booking.bookingTime.minute,
    );
    final difference = appointmentDateTime.difference(now);
    if (mounted) {
      setState(() => _timeRemaining = difference);
    }
  }

  bool get _isOverdue => _timeRemaining.isNegative;

  Duration get _absTimeRemaining => _timeRemaining.abs();

  String get _countdownText {
    if (_isOverdue) {
      // Appointment time has passed - show overdue time
      final days = _absTimeRemaining.inDays;
      final hours = _absTimeRemaining.inHours % 24;
      final minutes = _absTimeRemaining.inMinutes % 60;

      if (days > 0) {
        return '+${days}j ${hours}h';
      } else if (hours > 0) {
        return '+${hours}h ${minutes}m';
      } else {
        return '+${_absTimeRemaining.inMinutes}m';
      }
    }

    // Future appointment - countdown to it
    if (_timeRemaining.inDays > 0) {
      return '${_timeRemaining.inDays}j ${_timeRemaining.inHours % 24}h';
    } else if (_timeRemaining.inHours > 0) {
      return '${_timeRemaining.inHours}h ${_timeRemaining.inMinutes % 60}m';
    } else if (_timeRemaining.inMinutes > 0) {
      return '${_timeRemaining.inMinutes}m ${_timeRemaining.inSeconds % 60}s';
    } else {
      return '${_timeRemaining.inSeconds}s';
    }
  }

  Color get _countdownColor {
    if (_isOverdue) return const Color(0xFFDC2626); // Dark red - overdue
    if (_timeRemaining.inHours < 1) return const Color(0xFFEF4444); // Red - urgent
    if (_timeRemaining.inHours < 24) return const Color(0xFFFFB020); // Amber - soon
    return const Color(0xFF10B981); // Green - later
  }

  Color get _statusColor {
    switch (widget.booking.bookingStatus) {
      case 0: return const Color(0xFFFFB020); // Pending - amber
      case 1: return const Color(0xFF4ADE80); // Confirmed - green
      case 2: return const Color(0xFFEF4444); // Cancelled - red
      case 3: return const Color(0xFF6B7280); // Payment failed - gray
      default: return const Color(0xFF6B7280);
    }
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _BookingActionSheet(booking: widget.booking),
    );
  }

  Booking get booking => widget.booking;

  @override
  Widget build(BuildContext context) {
    final fullDateStr = DateFormat.yMMMEd().format(booking.bookingDate);
    final brandColors = [const Color(0xFF1DB954), const Color(0xFF6D4AFF), const Color(0xFFFF9800)];
    final c = brandColors[booking.id % brandColors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, const Color(0xFFF9FAFB)],
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '#${booking.id}',
                        style: GoogleFonts.dmSans(
                          color: c,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName ?? 'Service ${booking.serviceId}',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF1F2937),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.phone_outlined, size: 14, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(
                              booking.clientPhone ?? booking.clientName ?? 'Client #${booking.userId}',
                              style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _statusColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          booking.statusLabel,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DetailItem(
                      icon: Icons.calendar_today_outlined,
                      label: fullDateStr,
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFD1D5DB)),
                    _DetailItem(
                      icon: Icons.hourglass_bottom_rounded,
                      label: _countdownText,
                      color: _countdownColor,
                    ),
                    Container(width: 1, height: 20, color: const Color(0xFFD1D5DB)),
                    _DetailItem(
                      icon: booking.paymentStatus == 1 ? Icons.check_circle_outline : Icons.pending_outlined,
                      label: booking.paymentStatus == 1 ? 'Paid' : 'Unpaid',
                      color: booking.paymentStatus == 1 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showActionSheet(context),
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  label: Text(
                    'Actions',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.dashboardGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? const Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.muted),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppColors.muted,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }
}

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit({
    required this.value,
    required this.label,
    required this.isOverdue,
  });

  final int value;
  final String label;
  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isOverdue
                ? const Color(0xFFDC2626)
                : const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.toString().padLeft(2, '0'),
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isOverdue
                ? const Color(0xFFDC2626)
                : const Color(0xFF10B981),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _CountdownSeparator extends StatelessWidget {
  const _CountdownSeparator({required this.isOverdue});

  final bool isOverdue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: isOverdue
              ? const Color(0xFFDC2626)
              : const Color(0xFF10B981),
        ),
      ),
    );
  }
}

class _BookingActionSheet extends StatefulWidget {
  const _BookingActionSheet({required this.booking});

  final Booking booking;

  @override
  State<_BookingActionSheet> createState() => _BookingActionSheetState();
}

class _BookingActionSheetState extends State<_BookingActionSheet> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeRemaining());
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    final now = DateTime.now();
    final appointmentDateTime = DateTime(
      widget.booking.bookingDate.year,
      widget.booking.bookingDate.month,
      widget.booking.bookingDate.day,
      widget.booking.bookingTime.hour,
      widget.booking.bookingTime.minute,
    );
    final difference = appointmentDateTime.difference(now);
    if (mounted) {
      setState(() => _timeRemaining = difference);
    }
  }

  bool get _isOverdue => _timeRemaining.isNegative;
  Duration get _absTimeRemaining => _timeRemaining.abs();

  Color get _statusColor {
    switch (widget.booking.bookingStatus) {
      case 0: return const Color(0xFFFFB020);
      case 1: return const Color(0xFF4ADE80);
      case 2: return const Color(0xFFEF4444);
      case 3: return const Color(0xFF6B7280);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Rendez-vous #${widget.booking.id}',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.booking.serviceName ?? 'Service ${widget.booking.serviceId}',
              style: GoogleFonts.dmSans(
                fontSize: 15,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 16),
            // Countdown Display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _isOverdue
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOverdue
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF10B981),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    _isOverdue ? 'En retard depuis' : 'Temps restant',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isOverdue
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CountdownUnit(
                        value: _absTimeRemaining.inDays,
                        label: 'JOURS',
                        isOverdue: _isOverdue,
                      ),
                      _CountdownSeparator(isOverdue: _isOverdue),
                      _CountdownUnit(
                        value: _absTimeRemaining.inHours % 24,
                        label: 'HEURES',
                        isOverdue: _isOverdue,
                      ),
                      _CountdownSeparator(isOverdue: _isOverdue),
                      _CountdownUnit(
                        value: _absTimeRemaining.inMinutes % 60,
                        label: 'MIN',
                        isOverdue: _isOverdue,
                      ),
                      _CountdownSeparator(isOverdue: _isOverdue),
                      _CountdownUnit(
                        value: _absTimeRemaining.inSeconds % 60,
                        label: 'SEC',
                        isOverdue: _isOverdue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Booking Details Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Détails du rendez-vous',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: DateFormat.yMMMEd().format(widget.booking.bookingDate),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.access_time_rounded,
                    label: 'Heure',
                    value: DateFormat.Hm().format(widget.booking.bookingTime),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.person_outline,
                    label: 'Client',
                    value: widget.booking.clientName ?? 'Client #${widget.booking.userId}',
                  ),
                  if (widget.booking.clientPhone != null) ...[
                    const SizedBox(height: 10),
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: widget.booking.clientPhone!,
                    ),
                  ],
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.payment_outlined,
                    label: 'Paiement',
                    value: widget.booking.paymentStatus == 1 ? 'Payé' : 'En attente',
                    valueColor: widget.booking.paymentStatus == 1
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 10),
                  _DetailRow(
                    icon: Icons.info_outline,
                    label: 'Statut',
                    value: widget.booking.statusLabel,
                    valueColor: _statusColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Action Buttons
            if (widget.booking.bookingStatus == 0) ...[
              _ActionButton(
                icon: Icons.check_circle_outline,
                label: 'Accepter le rendez-vous',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Accept booking API call
                },
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.cancel_outlined,
                label: 'Refuser le rendez-vous',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Refuse booking API call
                },
              ),
              const SizedBox(height: 10),
            ],
            if (widget.booking.bookingStatus == 1) ...[
              _ActionButton(
                icon: Icons.play_circle_outline,
                label: 'Commencer le service',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Start service API call
                },
              ),
              const SizedBox(height: 10),
            ],
            // Annuler button for pending and confirmed bookings
            if (widget.booking.bookingStatus == 0 || widget.booking.bookingStatus == 1) ...[
              _ActionButton(
                icon: Icons.delete_outline,
                label: 'Annuler le rendez-vous',
                color: const Color(0xFF6B7280),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Cancel booking API call
                },
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}


class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.isOnline});

  final bool isOnline;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFFB020);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: _animation.value),
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
        );
      },
    );
  }
}

