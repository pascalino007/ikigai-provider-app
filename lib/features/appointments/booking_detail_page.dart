import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/booking.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';

class BookingDetailPage extends StatefulWidget {
  const BookingDetailPage({super.key, required this.booking});
  final Booking booking;

  @override
  State<BookingDetailPage> createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  late Booking _booking;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking;
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

  IconData _statusIcon(int status) {
    switch (status) {
      case 0:
        return Icons.hourglass_empty;
      case 1:
        return Icons.check_circle_outline;
      case 2:
        return Icons.cancel_outlined;
      case 3:
        return Icons.error_outline;
      case 4:
        return Icons.play_circle_outline;
      case 5:
        return Icons.task_alt;
      case 6:
        return Icons.warning_amber_rounded;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> _scanClientQR() async {
    final result = await Navigator.push<Booking>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProviderQrScannerPage(
          repo: context.read<PartnerRepository>(),
          expectedBookingId: _booking.id,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _booking = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service démarré !'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showCheckoutQR() {
    final token = _booking.qrCheckoutToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun QR de check-out disponible'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              "QR Check-out",
              style: GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Montrez ce QR code au client pour terminer le service.",
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: jsonEncode({'bookingId': _booking.id, 'token': token}),
                version: QrVersions.auto,
                size: 220,
                gapless: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Fermer",
                  style: GoogleFonts.dmSans(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _booking;
    final df = DateFormat('EEEE d MMMM yyyy').format(b.bookingDate);
    final tf = DateFormat('HH:mm').format(b.bookingTime);
    final statusColor = _statusColor(b.bookingStatus);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text(
          'Détail du rendez-vous',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(_statusIcon(b.bookingStatus), color: statusColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b.statusLabel,
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: statusColor,
                          ),
                        ),
                        if (b.bookingStatus == 4 && b.checkedInAt != null)
                          Text(
                            'Démarré à ${DateFormat('HH:mm').format(b.checkedInAt!)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: statusColor.withOpacity(0.8),
                            ),
                          ),
                        if (b.bookingStatus == 5 && b.checkedOutAt != null)
                          Text(
                            'Terminé à ${DateFormat('HH:mm').format(b.checkedOutAt!)}',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              color: statusColor.withOpacity(0.8),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Booking info card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _infoRow(Icons.spa, 'Service', b.serviceName ?? 'Service #${b.serviceId}'),
                  const Divider(height: 24),
                  _infoRow(Icons.person, 'Client', b.clientName ?? 'Client #${b.userId}'),
                  if (b.clientPhone != null && b.clientPhone!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow(Icons.phone, 'Téléphone', b.clientPhone!),
                  ],
                  const Divider(height: 24),
                  _infoRow(Icons.calendar_today, 'Date', df),
                  const Divider(height: 24),
                  _infoRow(Icons.access_time, 'Heure', tf),
                  if (b.shopName != null && b.shopName!.isNotEmpty) ...[
                    const Divider(height: 24),
                    _infoRow(Icons.storefront, 'Salon', b.shopName!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action buttons ──
            // CONFIRMED → "Scan QR Client" to start service
            if (b.bookingStatus == 1) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _processing ? null : _scanClientQR,
                  icon: const Icon(Icons.qr_code_scanner, size: 22),
                  label: Text(
                    'Scanner QR Client',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scannez le QR code du client pour démarrer le service.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 12),
              ),
            ],

            // IN_SERVICE → "Show QR Check-out" for client to scan
            if (b.bookingStatus == 4) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showCheckoutQR,
                  icon: const Icon(Icons.qr_code, size: 22),
                  label: Text(
                    'Afficher QR Check-out',
                    style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Montrez ce QR au client pour qu\'il termine le service.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 12),
              ),
            ],

            // NO_SHOW → missed appointment info
            if (b.bookingStatus == 6) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Le rendez-vous est passé sans action. Le client peut le reporter.',
                        style: GoogleFonts.dmSans(
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // DONE → success info
            if (b.bookingStatus == 5) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ce service est terminé avec succès.',
                        style: GoogleFonts.dmSans(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.dmSans(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QR SCANNER PAGE — Provider scans client's QR to start service
// ═══════════════════════════════════════════════════════════════════════

class _ProviderQrScannerPage extends StatefulWidget {
  const _ProviderQrScannerPage({required this.repo, required this.expectedBookingId});
  final PartnerRepository repo;
  final int expectedBookingId;

  @override
  State<_ProviderQrScannerPage> createState() => _ProviderQrScannerPageState();
}

class _ProviderQrScannerPageState extends State<_ProviderQrScannerPage> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Scanner QR Client',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) async {
              if (_processing) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code == null || code.isEmpty) return;

              setState(() => _processing = true);
              try {
                final decoded = jsonDecode(code);
                final payload = decoded is Map<String, dynamic> ? decoded : null;
                if (payload == null) throw Exception('Invalid QR: not a valid JSON object');
                final scannedBookingId = payload['bookingId'];
                final token = payload['token']?.toString();
                if (scannedBookingId == null || token == null || token.isEmpty) {
                  throw Exception('QR invalide : données manquantes');
                }
                if (scannedBookingId != widget.expectedBookingId) {
                  throw Exception('QR ne correspond pas à cette réservation (ID ${widget.expectedBookingId})');
                }
                final updatedBooking = await widget.repo.qrCheckin(token);
                if (!mounted) return;
                Navigator.pop(context, updatedBooking);
              } catch (e) {
                if (!mounted) return;
                setState(() => _processing = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
          if (_processing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Scannez le QR du client',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
