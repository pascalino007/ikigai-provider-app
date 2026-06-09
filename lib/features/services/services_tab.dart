import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/entities/service_item.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/onboarding/shop_onboarding_page.dart';
import 'package:ikigai_provider_app/features/services/cubit/services_cubit.dart';
import 'package:ikigai_provider_app/features/services/create_service_sheet.dart';

class ServicesTab extends StatelessWidget {
  const ServicesTab({super.key, required this.user});

  final AuthUser user;

  @override
  Widget build(BuildContext context) {
    final shopId = user.shopId;
    return BlocProvider(
      create: (_) => ServicesCubit(context.read<PartnerRepository>())..load(shopId ?? -1),
      child: KeyedSubtree(
        key: const ValueKey('services'),
        child: Builder(
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Services',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (shopId != null)
                          FilledButton.icon(
                            onPressed: () => _openSheet(context, shopId),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('New'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Offerings with photos appear richer in the client app.',
                      style: GoogleFonts.dmSans(color: AppColors.muted, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    if (shopId == null)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.store_mall_directory_outlined, size: 48, color: AppColors.muted),
                              const SizedBox(height: 12),
                              Text('Create your shop first.', style: GoogleFonts.dmSans()),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const ShopOnboardingPage()),
                                  );
                                },
                                child: const Text('Open shop onboarding'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: BlocBuilder<ServicesCubit, ServicesState>(
                          builder: (context, state) {
                            if (state is ServicesLoading || state is ServicesInitial) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (state is ServicesError) {
                              return Center(child: Text(state.message));
                            }
                            if (state is ServicesLoaded) {
                              if (state.items.isEmpty) {
                                return Center(
                                  child: Text('No services yet.', style: GoogleFonts.dmSans(color: AppColors.muted)),
                                );
                              }
                              return _GroupedServiceList(
                                items: state.items,
                                shopId: shopId,
                                onEdit: (s) => _openSheet(context, shopId, service: s),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, int shopId, {ServiceItem? service}) {
    final cubit = context.read<ServicesCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: cubit,
        child: CreateServiceSheet(shopId: shopId, user: user, service: service),
      ),
    );
  }
}

class _GroupedServiceList extends StatelessWidget {
  const _GroupedServiceList({
    required this.items,
    required this.shopId,
    required this.onEdit,
  });

  final List<ServiceItem> items;
  final int shopId;
  final void Function(ServiceItem) onEdit;

  @override
  Widget build(BuildContext context) {
    // Group by category -> sous-category
    final grouped = <String, Map<String, List<ServiceItem>>>{};
    for (final item in items) {
      final cat = item.category.trim().isEmpty ? 'Sans catégorie' : item.category.trim();
      final sous = item.sousCategory.trim().isEmpty ? 'Sans sous-catégorie' : item.sousCategory.trim();
      grouped.putIfAbsent(cat, () => {});
      grouped[cat]!.putIfAbsent(sous, () => []);
      grouped[cat]![sous]!.add(item);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: grouped.length,
      itemBuilder: (_, catIndex) {
        final category = grouped.keys.elementAt(catIndex);
        final sousCats = grouped[category]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(width: 4, height: 20, decoration: BoxDecoration(color: AppColors.dashboardGreen, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(width: 10),
                  Text(
                    category,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.dashboardGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${sousCats.values.expand((l) => l).length}',
                      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.dashboardGreenDeep),
                    ),
                  ),
                ],
              ),
            ),
            // Sous-categories
            ...sousCats.entries.map((entry) {
              final sousCat = entry.key;
              final services = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 18, bottom: 8),
                      child: Text(
                        sousCat,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(left: 18),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: services.length,
                      itemBuilder: (_, i) => _ServiceCard(
                        item: services[i],
                        shopId: shopId,
                        onEdit: () => onEdit(services[i]),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const Divider(height: 24, indent: 4, endIndent: 4),
          ],
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.item, required this.shopId, required this.onEdit});

  final ServiceItem item;
  final int shopId;
  final VoidCallback onEdit;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete service?'),
        content: Text('"${item.name}" will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<ServicesCubit>().delete(item.id, shopId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = item.name;
    final price = item.price;
    final duration = item.duration;
    final url = item.imageUrl;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 1,
      shadowColor: Colors.black12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: url.isNotEmpty
                  ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, width: double.infinity)
                  : Container(
                      color: AppColors.accentGoldSoft.withValues(alpha: 0.5),
                      child: const Icon(Icons.spa_outlined, size: 40),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            child: Text(
              '$duration \u2022 $price',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
