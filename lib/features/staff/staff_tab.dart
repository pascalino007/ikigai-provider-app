import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/staff/create_worker_sheet.dart';
import 'package:ikigai_provider_app/services/worker_service.dart';

class StaffTab extends StatefulWidget {
  const StaffTab({super.key});

  @override
  State<StaffTab> createState() => _StaffTabState();
}

class _StaffTabState extends State<StaffTab> {
  List<WorkerModel> _workers = [];
  bool _loading = true;
  String? _error;

  WorkerService? _service;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated && auth.user.shopId != null) {
      _service ??= WorkerService(tokenProvider: () => auth.token);
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated || auth.user.shopId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service!.fetchByShop(auth.user.shopId!);
      if (mounted) {
        setState(() {
          _workers = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _openCreate() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is! AuthAuthenticated || auth.user.shopId == null) return;

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateWorkerSheet(
        shopId: auth.user.shopId!,
        workerService: _service!,
      ),
    );
    if (created == true) _load();
  }

  static const _dayLabels = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: KeyedSubtree(
        key: const ValueKey('staff'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Équipe & disponibilités',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openCreate,
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text(
                      'Ajouter',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6D4AFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, style: GoogleFonts.dmSans(color: AppColors.muted)),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: const Text('Réessayer')),
                      ],
                    ),
                  ),
                )
              else if (_workers.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_rounded, size: 56, color: AppColors.muted.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text('Aucun collaborateur', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: AppColors.muted)),
                        const SizedBox(height: 4),
                        Text('Ajoutez votre premier membre.', style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: _workers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _WorkerCard(
                      worker: _workers[i],
                      workerService: _service!,
                      onAnalytics: () => _showWorkerBookings(_workers[i]),
                      onToggleActive: () => _toggleWorkerActive(_workers[i]),
                      onDelete: () async {
                        final w = _workers[i];
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Supprimer ?'),
                            content: Text('Supprimer ${w.displayName} ?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Supprimer'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          try {
                            await _service!.delete(w.id);
                            _load();
                          } catch (_) {}
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleWorkerActive(WorkerModel w) async {
    try {
      await _service!.update(id: w.id, isActive: !(w.isActive ?? false));
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _showWorkerBookings(WorkerModel w) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WorkerBookingsSheet(worker: w, workerService: _service!),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  _WorkerCard({
    required this.worker,
    required this.workerService,
    required this.onAnalytics,
    required this.onToggleActive,
    required this.onDelete,
  });

  final WorkerModel worker;
  final WorkerService workerService;
  final VoidCallback onAnalytics;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6D4AFF).withValues(alpha: 0.12),
            backgroundImage: worker.avatarUrl != null && worker.avatarUrl!.isNotEmpty
                ? CachedNetworkImageProvider(worker.avatarUrl!)
                : null,
            child: worker.avatarUrl == null || worker.avatarUrl!.isEmpty
                ? Text(
                    '${worker.firstName.isNotEmpty ? worker.firstName[0] : ''}${worker.lastName.isNotEmpty ? worker.lastName[0] : ''}',
                    style: GoogleFonts.dmSans(color: const Color(0xFF6D4AFF), fontWeight: FontWeight.w800, fontSize: 16),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  worker.displayName,
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15, color: const Color(0xFF1F2937)),
                ),
                if (worker.speciality != null && worker.speciality!.isNotEmpty)
                  Text(worker.speciality!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted)),
                if (worker.schedules != null && worker.schedules!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      worker.schedules!.map((s) => _StaffTabState._dayLabels[s.dayOfWeek]).join(', '),
                      style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.analytics_outlined, size: 20, color: Color(0xFF6D4AFF)),
                onPressed: onAnalytics,
                tooltip: 'Voir les réservations',
              ),
              IconButton(
                icon: Icon(
                  worker.isActive == true ? Icons.toggle_on : Icons.toggle_off,
                  size: 20,
                  color: worker.isActive == true ? const Color(0xFF4ADE80) : Colors.grey,
                ),
                onPressed: onToggleActive,
                tooltip: worker.isActive == true ? 'Mettre indisponible' : 'Rendre disponible',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFEF4444)),
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkerBookingsSheet extends StatefulWidget {
  _WorkerBookingsSheet({required this.worker, required this.workerService});

  final WorkerModel worker;
  final WorkerService workerService;

  @override
  State<_WorkerBookingsSheet> createState() => _WorkerBookingsSheetState();
}

class _WorkerBookingsSheetState extends State<_WorkerBookingsSheet> {
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await widget.workerService.getWorkerBookings(widget.worker.id);
      if (mounted) setState(() { _bookings = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tf = DateFormat('HH:mm');
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(width: 44, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(99))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.worker.avatarUrl != null && widget.worker.avatarUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(widget.worker.avatarUrl!)
                      : null,
                  child: widget.worker.avatarUrl == null || widget.worker.avatarUrl!.isEmpty
                      ? Text(widget.worker.firstName.isNotEmpty ? widget.worker.firstName[0] : '?',
                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: const Color(0xFF6D4AFF)))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.worker.displayName, style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 16)),
                      Text('${_bookings.length} réservation(s)', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted)),
                    ],
                  ),
                ),
                IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _loading
                ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                : _error != null
                    ? Padding(padding: const EdgeInsets.all(24), child: Text(_error!, textAlign: TextAlign.center))
                    : _bookings.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text('Aucune réservation.', style: GoogleFonts.dmSans(color: AppColors.muted)),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 36),
                            itemCount: _bookings.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final b = _bookings[i];
                              final date = b['booking_date'] ?? '';
                              final time = b['booking_time'] != null ? DateTime.tryParse('${b['booking_time']}') : null;
                              final status = b['booking_status'] ?? 0;
                              const statusLabels = ['En attente', 'Confirmé', 'Annulé', 'Échoué', 'En cours', 'Terminé', 'No-show'];
                              const statusColors = [Colors.grey, Colors.blue, Colors.red, Colors.red, Colors.orange, Colors.green, Colors.amber];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: (statusColors[status] ?? Colors.grey).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(Icons.calendar_today_rounded, size: 18, color: statusColors[status]),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b['service_name'] ?? 'Service #${b['service_id']}',
                                              style: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text('$date${time != null ? ' à ${tf.format(time)}' : ''}',
                                              style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.muted)),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (statusColors[status] ?? Colors.grey).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(statusLabels[status] ?? '?',
                                          style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: statusColors[status])),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
