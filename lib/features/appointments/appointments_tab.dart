import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/appointments/booking_detail_page.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key, required this.user});

  final AuthUser user;

  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab> {
  Future<List<Booking>>? _future;

  void _reload(BuildContext context) {
    final shopId = widget.user.shopId;
    if (shopId == null) return;
    setState(() {
      _future = context.read<PartnerRepository>().fetchBookingsForProvider('$shopId');
    });
  }

  Color _statusColor(int status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.blue.shade700;
      case 2:
        return Colors.red.shade700;
      case 3:
        return Colors.red.shade400;
      case 4:
        return Colors.orange.shade700;
      case 5:
        return Colors.green.shade700;
      case 6:
        return Colors.amber.shade700;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopId = widget.user.shopId;
    if (shopId == null) {
      return const Center(child: Text('No shop attached'));
    }
    _future ??= context.read<PartnerRepository>().fetchBookingsForProvider('$shopId');
    return SafeArea(
      child: KeyedSubtree(
        key: const ValueKey('bookings'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rendez-vous',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _reload(context),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('${snap.error}', textAlign: TextAlign.center));
                    }
                    final list = snap.data ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Text('Aucun rendez-vous.', style: GoogleFonts.dmSans(color: AppColors.muted)),
                      );
                    }
                    return ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final b = list[i];
                        final df = DateFormat('d MMM yyyy').format(b.bookingDate);
                        final tf = DateFormat('HH:mm').format(b.bookingTime);
                        final sColor = _statusColor(b.bookingStatus);
                        return Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          elevation: 1,
                          shadowColor: Colors.black12,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingDetailPage(booking: b),
                                ),
                              );
                              _reload(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: b.serviceImageUrl != null && b.serviceImageUrl!.isNotEmpty
                                          ? CachedNetworkImage(
                                              imageUrl: b.serviceImageUrl!,
                                              fit: BoxFit.cover,
                                              placeholder: (_, __) => Container(
                                                color: sColor.withValues(alpha: 0.1),
                                                child: Icon(Icons.spa_outlined, color: sColor, size: 24),
                                              ),
                                              errorWidget: (_, __, ___) => Container(
                                                color: sColor.withValues(alpha: 0.1),
                                                child: Icon(Icons.spa_outlined, color: sColor, size: 24),
                                              ),
                                            )
                                          : Container(
                                              color: sColor.withValues(alpha: 0.1),
                                              child: Icon(Icons.spa_outlined, color: sColor, size: 24),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b.serviceName ?? 'Service #${b.serviceId}',
                                          style: GoogleFonts.dmSans(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.person_outline, size: 14, color: AppColors.muted),
                                            const SizedBox(width: 4),
                                            Text(
                                              b.clientName ?? 'Client',
                                              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 14, color: AppColors.muted),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$df à $tf',
                                              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: sColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      b.statusLabel,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: sColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 20),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
