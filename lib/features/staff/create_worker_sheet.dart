import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/services/worker_service.dart';

class CreateWorkerSheet extends StatefulWidget {
  const CreateWorkerSheet({
    super.key,
    required this.shopId,
    required this.workerService,
  });

  final int shopId;
  final WorkerService workerService;

  @override
  State<CreateWorkerSheet> createState() => _CreateWorkerSheetState();
}

class _CreateWorkerSheetState extends State<CreateWorkerSheet> {
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _speciality;
  late final TextEditingController _bufferMinutes;
  String _startTime = '09:00';
  String _endTime = '18:00';
  final Set<int> _workingDays = {1, 2, 3, 4, 5}; // Mon-Fri
  String? _avatarPath;
  bool _busy = false;

  static const _days = [
    'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim',
  ];

  @override
  void initState() {
    super.initState();
    _firstName = TextEditingController();
    _lastName = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _speciality = TextEditingController();
    _bufferMinutes = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _speciality.dispose();
    _bufferMinutes.dispose();
    super.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (picked != null && mounted) {
      setState(() => _avatarPath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (_firstName.text.trim().isEmpty || _lastName.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le prénom et le nom sont obligatoires.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      String? avatarUrl;
      if (_avatarPath != null) {
        try {
          avatarUrl = await widget.workerService.uploadImage(_avatarPath!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur upload image: $e')),
            );
          }
        }
      }

      final schedules = <Map<String, dynamic>>[];
      for (final day in _workingDays) {
        schedules.add({
          'day_of_week': day,
          'start_time': _startTime,
          'end_time': _endTime,
        });
      }

      await widget.workerService.create(
        shopId: widget.shopId,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        avatarUrl: avatarUrl,
        speciality: _speciality.text.trim().isEmpty ? null : _speciality.text.trim(),
        bufferMinutes: int.tryParse(_bufferMinutes.text.trim()) ?? 5,
        schedules: schedules,
      );

      if (mounted) Navigator.pop(context, true);
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
                            colors: [Color(0xFF6D4AFF), Color(0xFF8B5CF6)],
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nouveau collaborateur',
                                    style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ajoutez un membre à votre équipe avec ses horaires.',
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
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade300, width: 2),
                              image: _avatarPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(_avatarPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: _avatarPath == null
                                ? const Icon(Icons.camera_alt_outlined, size: 32, color: Color(0xFF6B7280))
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.photo_camera_back_outlined, size: 18),
                          label: Text(
                            _avatarPath == null ? 'Ajouter une photo' : 'Changer la photo',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _firstName, decoration: _dec('Prénom *'))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _lastName, decoration: _dec('Nom *'))),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(controller: _phone, decoration: _dec('Téléphone'), keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      TextField(controller: _email, decoration: _dec('Email'), keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      TextField(controller: _speciality, decoration: _dec('Spécialité', hint: 'ex. Coiffeur')),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _bufferMinutes,
                        decoration: _dec('Tampon (min)', hint: '5'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Horaires de travail',
                        style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _TimeField(
                              label: 'Début',
                              value: _startTime,
                              onChanged: (v) => setState(() => _startTime = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeField(
                              label: 'Fin',
                              value: _endTime,
                              onChanged: (v) => setState(() => _endTime = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(7, (i) {
                          final selected = _workingDays.contains(i);
                          return ChoiceChip(
                            label: Text(_days[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.muted)),
                            selected: selected,
                            selectedColor: const Color(0xFF6D4AFF),
                            backgroundColor: const Color(0xFFF3F4F6),
                            onSelected: (v) {
                              setState(() {
                                if (v) {
                                  _workingDays.add(i);
                                } else {
                                  _workingDays.remove(i);
                                }
                              });
                            },
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                            side: BorderSide.none,
                          );
                        }),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 54,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF6D4AFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          ),
                          child: _busy
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(
                                  'Ajouter le collaborateur',
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

class _TimeField extends StatelessWidget {
  const _TimeField({required this.label, required this.value, required this.onChanged});

  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController(text: value),
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.access_time, size: 20),
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
      ),
      onTap: () async {
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(value.split(':')[0]),
            minute: int.parse(value.split(':')[1]),
          ),
        );
        if (time != null) {
          onChanged('${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}');
        }
      },
    );
  }
}
