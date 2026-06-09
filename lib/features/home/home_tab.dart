import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/entities/shop.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/home/dashboard_header_clipper.dart';
import 'package:ikigai_provider_app/features/onboarding/shop_onboarding_page.dart';
import 'package:ikigai_provider_app/features/appointments/booking_detail_page.dart';

/// Wallet-style dashboard: curved green header, hero metric, quick actions, recent list.
class HomeTab extends StatefulWidget {
  const HomeTab({super.key, required this.user, this.onNavigateToTab});

  final AuthUser user;
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Booking> _bookings = [];
  bool _loadingBookings = true;
  String? _bookingsError;
  Shop? _shop;
  bool _loadingShop = false;

  /// Backend shop status: ouvert | occupé | free | closed
  String _shopStatus = 'ouvert';
  bool _updatingStatus = false;

  static const _bottomReserve = 110.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
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
      final rawList = await repo.fetchBookingsForProvider('$shopId');
      // Only show paid/confirmed bookings (exclude pending=0 and payment_failed=3)
      final list = rawList.where((b) => b.bookingStatus >= 1 && b.bookingStatus != 3).toList();
      list.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      Shop? shop;
      if (widget.user.shopId != null) {
        shop = await repo.fetchShopById(widget.user.shopId!);
      }
      if (mounted) {
        setState(() {
          _bookings = list.take(5).toList();
          _loadingBookings = false;
          _shop = shop;
          _loadingShop = false;
          if (shop != null) _shopStatus = shop.status;
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

  Future<void> _changeStatus(String status) async {
    final shopId = widget.user.shopId;
    if (shopId == null) return;
    setState(() => _updatingStatus = true);
    try {
      final repo = context.read<PartnerRepository>();
      await repo.updateShopStatus(shopId, status);
      if (mounted) setState(() => _shopStatus = status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingStatus = false);
    }
  }

  void _showStatusSelector() {
    final options = [
      _StatusOption('ouvert', 'Ouvert', const Color(0xFF4ADE80)),
      _StatusOption('free', 'Libre', const Color(0xFF60A5FA)),
      _StatusOption('occupé', 'Occupé', const Color(0xFFFFB020)),
      _StatusOption('closed', 'Fermé', const Color(0xFFEF4444)),
    ];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Votre disponibilité',
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Les clients voient ce statut en temps réel.',
              style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            ...options.map((o) {
              final selected = o.value == _shopStatus;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _changeStatus(o.value);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? o.color.withValues(alpha: 0.1) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? o.color : Colors.grey.shade200,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: o.color),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          o.label,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selected ? o.color : Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        if (selected) Icon(Icons.check_circle, color: o.color),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  void _showCalendarBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingCalendarSheet(
        bookings: _bookings,
        onBookingTap: (booking) {
          Navigator.of(ctx).pop();
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => BookingDetailPage(booking: booking),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greet = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
    final first = widget.user.firstname.isNotEmpty ? widget.user.firstname : 'Partner';
    final pendingCount = _bookings.where((b) => b.bookingStatus == 0).length;

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
                                InkWell(
                                  onTap: () => widget.onNavigateToTab?.call(6),
                                  customBorder: const CircleBorder(),
                                  child: CircleAvatar(
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
                                    onTap: _updatingStatus ? null : _showStatusSelector,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: _statusColor(_shopStatus).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: _statusColor(_shopStatus),
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
                                          if (pendingCount > 0) const SizedBox(width: 6),
                                          _PulsingDot(status: _shopStatus),
                                          const SizedBox(width: 8),
                                          Text(
                                            _statusLabel(_shopStatus),
                                            style: GoogleFonts.dmSans(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(Icons.keyboard_arrow_down, color: Colors.white.withValues(alpha: 0.8), size: 16),
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
                                    onTap: _showCalendarBottomSheet,
                                    child: const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Icon(Icons.calendar_month_outlined, color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                  _StatItem(
                                    value: '${_bookings.where((b) => b.bookingStatus == 5 && _isToday(b.bookingDate)).length * 5000} F',
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
                        const SizedBox(height: 15),
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
      case 0: return const Color(0xFFF59E0B); // Pending - amber
      case 1: return const Color(0xFF4ADE80); // Confirmed - green
      case 2: return const Color(0xFFEF4444); // Cancelled - red
      case 3: return const Color(0xFF6B7280); // Payment failed - gray
      case 4: return const Color(0xFFFF9800); // In service - orange
      case 5: return const Color(0xFF10B981); // Done - green
      case 6: return const Color(0xFF92400E); // No show - brown
      default: return const Color(0xFF6B7280);
    }
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
                  ClipOval(
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: booking.serviceImageUrl != null && booking.serviceImageUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: booking.serviceImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: c.withValues(alpha: 0.12),
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
                              errorWidget: (context, url, error) => Container(
                                color: c.withValues(alpha: 0.12),
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
                            )
                          : Container(
                              color: c.withValues(alpha: 0.12),
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingDetailPage(booking: booking),
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_rounded, size: 18),
                  label: Text(
                    'Voir détails',
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
      case 0: return const Color(0xFFF59E0B);
      case 1: return const Color(0xFF4ADE80);
      case 2: return const Color(0xFFEF4444);
      case 3: return const Color(0xFF6B7280);
      case 4: return const Color(0xFFFF9800);
      case 5: return const Color(0xFF10B981);
      case 6: return const Color(0xFF92400E);
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
  const _PulsingDot({required this.status});
  final String status;
  @override State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.repeat(reverse: true);
  }
  @override void dispose() { _controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final color = _statusColor(widget.status);
    return AnimatedBuilder(animation: _animation, builder: (context, child) => Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: _animation.value), border: Border.all(color: color, width: 2))));
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'ouvert':
    case 'open':
      return const Color(0xFF4ADE80);
    case 'free':
      return const Color(0xFF60A5FA);
    case 'occupé':
      return const Color(0xFFFFB020);
    case 'closed':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFF4ADE80);
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'ouvert':
    case 'open':
      return 'Ouvert';
    case 'free':
      return 'Libre';
    case 'occupé':
      return 'Occupé';
    case 'closed':
      return 'Fermé';
    default:
      return 'Ouvert';
  }
}

class _StatusOption {
  final String value;
  final String label;
  final Color color;
  _StatusOption(this.value, this.label, this.color);
}

/// Calendar bottom sheet: green dots on days with bookings,
/// tap a day to see service list, tap a service to see details.
class _BookingCalendarSheet extends StatefulWidget {
  final List<Booking> bookings;
  final ValueChanged<Booking> onBookingTap;

  const _BookingCalendarSheet({
    required this.bookings,
    required this.onBookingTap,
  });

  @override
  State<_BookingCalendarSheet> createState() => _BookingCalendarSheetState();
}

class _BookingCalendarSheetState extends State<_BookingCalendarSheet> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Set<DateTime> get _bookingDays {
    return widget.bookings.map((b) {
      return DateTime(b.bookingDate.year, b.bookingDate.month, b.bookingDate.day);
    }).toSet();
  }

  List<Booking> _bookingsForDay(DateTime day) {
    return widget.bookings.where((b) {
      return b.bookingDate.year == day.year &&
          b.bookingDate.month == day.month &&
          b.bookingDate.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsForSelected = _selectedDay != null ? _bookingsForDay(_selectedDay!) : <Booking>[];

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Planning des réservations',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.bookings.length} réservation(s) au total',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TableCalendar(
                    firstDay: DateTime.utc(2024, 1, 1),
                    lastDay: DateTime.utc(2026, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    calendarFormat: CalendarFormat.month,
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                    },
                    headerStyle: HeaderStyle(
                      titleCentered: true,
                      formatButtonVisible: false,
                      titleTextStyle: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                      leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
                      rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
                    ),
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: AppColors.accentLime.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      todayTextStyle: GoogleFonts.dmSans(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                      selectedDecoration: const BoxDecoration(
                        color: AppColors.dashboardGreenDeep,
                        shape: BoxShape.circle,
                      ),
                      selectedTextStyle: GoogleFonts.dmSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      defaultTextStyle: GoogleFonts.dmSans(color: AppColors.primary),
                      weekendTextStyle: GoogleFonts.dmSans(color: AppColors.primary),
                      outsideTextStyle: GoogleFonts.dmSans(color: Colors.grey),
                      markersMaxCount: 3,
                      markerSize: 6,
                      markerDecoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        final hasBooking = _bookingDays.any((d) => isSameDay(d, day));
                        if (!hasBooking) return const SizedBox.shrink();
                        return Positioned(
                          bottom: 1,
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF22C55E),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                    },
                    onPageChanged: (focusedDay) {
                      _focusedDay = focusedDay;
                    },
                  ),
                  if (_selectedDay != null && bookingsForSelected.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE d MMMM', 'fr').format(_selectedDay!),
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${bookingsForSelected.length} service(s)',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...bookingsForSelected.map((booking) {
                      final time = DateFormat('HH:mm').format(booking.bookingTime);
                      return InkWell(
                        onTap: () => widget.onBookingTap(booking),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.spa_outlined,
                                  color: Color(0xFF22C55E),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.serviceName ?? 'Service',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Client: ${booking.clientName ?? 'Non spécifié'}',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    if (booking.workerName != null && booking.workerName!.isNotEmpty)
                                      Text(
                                        'Coiffeur: ${booking.workerName}',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 12,
                                          color: AppColors.accentLimeMuted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    time,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: _statusColorForBooking(booking.bookingStatus).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      booking.statusLabel,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColorForBooking(booking.bookingStatus),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ] else if (_selectedDay != null) ...[
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Aucune réservation ce jour',
                        style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Color _statusColorForBooking(int status) {
  switch (status) {
    case 0: return const Color(0xFFFFB020);
    case 1: return const Color(0xFF4ADE80);
    case 2: return const Color(0xFFEF4444);
    case 3: return const Color(0xFF6B7280);
    case 4: return const Color(0xFFFF9800);
    case 5: return const Color(0xFF10B981);
    case 6: return const Color(0xFFFFB020);
    default: return const Color(0xFF6B7280);
  }
}
