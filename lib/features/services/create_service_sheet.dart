import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/auth_user.dart';
import 'package:ikigai_provider_app/domain/entities/service_item.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/services/cubit/services_cubit.dart';
import 'package:image_picker/image_picker.dart';

class CreateServiceSheet extends StatefulWidget {
  const CreateServiceSheet({
    super.key,
    required this.shopId,
    required this.user,
    this.service,
  });

  final int shopId;
  final AuthUser user;
  final ServiceItem? service;

  @override
  State<CreateServiceSheet> createState() => _CreateServiceSheetState();
}

class _CreateServiceSheetState extends State<CreateServiceSheet> {
  late final TextEditingController _name;
  late final TextEditingController _desc;
  late final TextEditingController _category;
  late final TextEditingController _sousCategory;
  late final TextEditingController _price;
  late final TextEditingController _duration;
  late final TextEditingController _tags;
  String? _imagePath;
  bool _busy = false;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _name = TextEditingController(text: s?.name ?? '');
    _desc = TextEditingController(text: s?.description ?? '');
    _category = TextEditingController(text: s?.category ?? '');
    _sousCategory = TextEditingController(text: s?.sousCategory ?? '');
    _price = TextEditingController(text: s?.price ?? '');
    _duration = TextEditingController(text: s?.duration ?? '');
    _tags = TextEditingController(text: s?.tags ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _category.dispose();
    _sousCategory.dispose();
    _price.dispose();
    _duration.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (x != null) setState(() => _imagePath = x.path);
  }

  InputDecoration _dec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.dashboardGreen, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty ||
        _desc.text.trim().isEmpty ||
        _category.text.trim().isEmpty ||
        _price.text.trim().isEmpty ||
        _duration.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez les champs obligatoires.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final repo = context.read<PartnerRepository>();
      String imageUrl = widget.service?.imageUrl ?? '';
      if (_imagePath != null) {
        try {
          imageUrl = await repo.uploadImage(_imagePath!);
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Échec upload photo — vous pouvez réessayer.')),
            );
          }
        }
      }

      final providerName = '${widget.user.firstname} ${widget.user.lastname}'.trim();

      final cubit = context.read<ServicesCubit>();
      if (_isEdit) {
        await repo.updateService(
          id: widget.service!.id,
          shopId: widget.shopId,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          categoryName: _category.text.trim(),
          sousCategory: _sousCategory.text.trim(),
          price: _price.text.trim(),
          duration: _duration.text.trim(),
          tags: _tags.text.trim(),
          imageUrl: imageUrl,
          providerDisplayName: providerName,
        );
      } else {
        await repo.createService(
          shopId: widget.shopId,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          categoryName: _category.text.trim(),
          sousCategory: _sousCategory.text.trim(),
          price: _price.text.trim(),
          duration: _duration.text.trim(),
          tags: _tags.text.trim(),
          imageUrl: imageUrl,
          providerDisplayName: providerName,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        cubit.load(widget.shopId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [AppColors.dashboardGreenDeep, AppColors.dashboardGreen],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEdit ? 'Modifier le service' : 'Nouveau service',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Photo + détails = meilleure visibilité dans l\'app client.',
                                    style: GoogleFonts.dmSans(color: Colors.white70, fontSize: 13, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                            IconButton.filledTonal(
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white24,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 140,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.accentLime.withValues(alpha: 0.6), width: 2),
                            color: const Color(0xFFF3F6F4),
                          ),
                          child: _imagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity),
                                )
                              : (widget.service?.imageUrl ?? '').isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(18),
                                      child: CachedNetworkImage(
                                        imageUrl: widget.service!.imageUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppColors.dashboardGreen),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Ajouter une photo',
                                          style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.primary),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(controller: _name, decoration: _dec('Nom du service *')),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _desc,
                        decoration: _dec('Description *'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      TextField(controller: _category, decoration: _dec('Catégorie *')),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _sousCategory,
                        decoration: _dec('Sous-catégorie', hint: 'optionnel'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _price, decoration: _dec('Prix *', hint: 'ex. 25'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _duration, decoration: _dec('Durée *', hint: '45 min'))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(controller: _tags, decoration: _dec('Tags', hint: 'optionnel')),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accentLime,
                            foregroundColor: AppColors.dashboardGreenDeep,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: _busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _isEdit ? 'Enregistrer' : 'Publier le service',
                                  style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
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
