import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/constants/api_constants.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/entities/category.dart';
import 'package:ikigai_provider_app/domain/entities/geoville.dart';
import 'package:ikigai_provider_app/domain/entities/shop_payload.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ikigai_provider_app/core/geo/reverse_geocode.dart';
import 'package:ikigai_provider_app/features/shell/partner_shell.dart';
import 'package:image_picker/image_picker.dart';

class ShopOnboardingPage extends StatefulWidget {
  const ShopOnboardingPage({super.key});

  @override
  State<ShopOnboardingPage> createState() => _ShopOnboardingPageState();
}

class _ShopOnboardingPageState extends State<ShopOnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _description = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  String _type = 'Salon';
  String _categoryName = '';
  String _pays = '';
  String _region = '';
  String _ville = '';
  String _district = '';
  String _quartier = '';

  final _tags = <String>{};
  final _hours = List<List<String>>.from(const [
    ['Monday', '09:00 - 18:00'],
    ['Tuesday', '09:00 - 18:00'],
    ['Wednesday', '09:00 - 18:00'],
    ['Thursday', '09:00 - 18:00'],
    ['Friday', '09:00 - 18:00'],
    ['Saturday', '10:00 - 16:00'],
  ]);

  String? _profilePath;
  final List<String> _galleryPaths = [];
  String? _certPath;
  String? _cfePath;

  double? _latitude;
  double? _longitude;
  bool _gpsLoading = false;

  List<Category> _categories = [];
  List<Geoville> _zones = [];
  bool _loadingMeta = true;
  bool _submitting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final auth = context.read<AuthCubit>().state;
    if (auth is AuthAuthenticated) {
      _phone.text = auth.user.phone;
      _email.text = auth.user.email;
    }
    try {
      final partner = context.read<PartnerRepository>();
      final cats = await partner.fetchCategories();
      final geo = await partner.fetchGeovilles();
      setState(() {
        _categories = cats;
        _zones = geo;
        _loadingMeta = false;
        if (_categories.isNotEmpty && _categoryName.isEmpty) {
          _categoryName = _categories.first.name;
        }
      });
    } catch (e) {
      setState(() {
        _loadError = '$e';
        _loadingMeta = false;
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _landmark.dispose();
    _description.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Iterable<String> get _countries => {..._zones.map((z) => z.countryId)}.where((c) => c.isNotEmpty);
  Iterable<String> get _regions => {
        ..._zones.where((z) => _pays.isEmpty || z.countryId == _pays).map((z) => z.regionId)
      }.where((c) => c.isNotEmpty);

  Iterable<String> get _cities => {
        ..._zones
            .where((z) => z.cityId != null && (_region.isEmpty || z.regionId == _region))
            .map((z) => z.cityId!)
      };

  Iterable<String> get _districts => {
        ..._zones
            .where((z) => z.districtId != null && (_ville.isEmpty || z.cityId == _ville))
            .map((z) => z.districtId!)
      };

  Iterable<String> get _quartierNames => {
        ..._zones
            .where((z) => _district.isEmpty || z.districtId == _district)
            .map((z) => z.name)
      };

  Future<void> _useMyLocation() async {
    setState(() => _gpsLoading = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Activez la localisation pour enregistrer le salon sur la carte.')),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      final rev = await ReverseGeocode.reverse(pos.latitude, pos.longitude);
      if (rev != null && mounted && _address.text.trim().isEmpty) {
        _address.text = rev.displayName;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position GPS enregistrée. Vérifiez le pays / ville ci-dessous.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GPS: $e')));
      }
    } finally {
      if (mounted) setState(() => _gpsLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La position GPS est obligatoire — utilisez « Ma position » (comme le dashboard).'),
        ),
      );
      return;
    }
    if (_tags.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least 3 service tags.')),
      );
      return;
    }
    if (_profilePath == null || _galleryPaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a profile photo and at least one gallery image.')),
      );
      return;
    }

    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _submitting = true);
    final partner = context.read<PartnerRepository>();
    final token = context.read<AuthRepository>().storedToken;

    try {
      String profileUrl = '';
      try {
        profileUrl = await partner.uploadImage(_profilePath!, bearer: token);
      } catch (_) {}

      List<String> galleryUrls = [];
      try {
        if (_galleryPaths.isNotEmpty) {
          galleryUrls = await partner.uploadImages(_galleryPaths, bearer: token);
        }
      } catch (_) {
        galleryUrls = [];
      }

      String certUrl = '';
      if (_certPath != null) {
        try {
          certUrl = await partner.uploadImage(_certPath!, bearer: token);
        } catch (_) {}
      }

      String cfeUrl = '';
      if (_cfePath != null) {
        try {
          cfeUrl = await partner.uploadImage(_cfePath!, bearer: token);
        } catch (_) {}
      }

      final payload = ShopPayload(
        name: _name.text.trim(),
        category: _categoryName,
        type: _type,
        address: _address.text.trim().isEmpty ? _quartier : _address.text.trim(),
        pays: _pays,
        ville: _ville,
        quartier: _quartier,
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        nonLoinDe: _landmark.text.trim(),
        descriptionShop: _description.text.trim(),
        profileImageUrl: profileUrl,
        certificationImage: certUrl,
        galleryImages: galleryUrls,
        cfeImageUrl: cfeUrl,
        workingHours: _hours.map((e) => [e[0], e[1]]).toList(),
        tags: _tags.join(','),
        owner: authState.user.email,
        registeredBy: '${authState.user.id}',
        latitude: _latitude,
        longitude: _longitude,
      );

      if (profileUrl.isEmpty || galleryUrls.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Uploads failed — configure DigitalOcean Spaces on the API or try again.'),
            ),
          );
        }
        return;
      }

      final id = await partner.createShop(payload, bearer: token);
      if (!mounted) return;
      await context.read<AuthCubit>().attachShop(id);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const PartnerShell()),
          (r) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingMeta) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Shop setup')),
        body: Center(child: Text(_loadError!, textAlign: TextAlign.center)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Studio profile', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(
              'Mirrors the dashboard “Add shop” modal — tuned for providers on mobile.',
              style: GoogleFonts.dmSans(color: AppColors.muted),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Shop name *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Venue type *'),
              items: const [
                DropdownMenuItem(value: 'Salon', child: Text('Salon')),
                DropdownMenuItem(value: 'Institut', child: Text('Institut')),
                DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
              ],
              onChanged: (v) => setState(() => _type = v ?? 'Salon'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _categoryName.isEmpty ? null : _categoryName,
              decoration: const InputDecoration(labelText: 'Category *'),
              items: _categories
                  .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                  .toList(),
              onChanged: (v) => setState(() => _categoryName = v ?? ''),
            ),
            const SizedBox(height: 16),
            Text('Service tags *', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in ApiConstants.serviceTags)
                  FilterChip(
                    label: Text(t, style: const TextStyle(fontSize: 12)),
                    selected: _tags.contains(t),
                    onSelected: (s) => setState(() {
                      if (s) {
                        _tags.add(t);
                      } else {
                        _tags.remove(t);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Localisation & GPS', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Latitude et longitude sont requises (identique au flux « Use my location » du dashboard web).',
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _gpsLoading ? null : _useMyLocation,
              icon: _gpsLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(_gpsLoading ? 'Recherche position…' : 'Utiliser ma position'),
            ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'GPS: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                  style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success),
                ),
              ),
            const SizedBox(height: 16),
            Text('Zones administratives', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _pays.isEmpty ? null : _pays,
              decoration: const InputDecoration(labelText: 'Country *'),
              items: _countries
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() {
                _pays = v ?? '';
                _region = '';
                _ville = '';
                _district = '';
                _quartier = '';
              }),
            ),
            DropdownButtonFormField<String>(
              value: _region.isEmpty ? null : _region,
              decoration: const InputDecoration(labelText: 'Region'),
              items: _regions.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                _region = v ?? '';
                _ville = '';
                _district = '';
                _quartier = '';
              }),
            ),
            DropdownButtonFormField<String>(
              value: _ville.isEmpty ? null : _ville,
              decoration: const InputDecoration(labelText: 'City *'),
              items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                _ville = v ?? '';
                _district = '';
                _quartier = '';
              }),
            ),
            DropdownButtonFormField<String>(
              value: _district.isEmpty ? null : _district,
              decoration: const InputDecoration(labelText: 'District'),
              items: _districts.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() {
                _district = v ?? '';
                _quartier = '';
              }),
            ),
            DropdownButtonFormField<String>(
              value: _quartier.isEmpty ? null : _quartier,
              decoration: const InputDecoration(labelText: 'Neighborhood *'),
              items: _quartierNames.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _quartier = v ?? ''),
            ),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Full address (optional)',
                hintText: 'Street, building, references',
              ),
            ),
            TextFormField(
              controller: _landmark,
              decoration: const InputDecoration(labelText: 'Landmark * — “near…”'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Studio description *'),
              maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Public phone *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _email,
              decoration: const InputDecoration(labelText: 'Public email *'),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            Text('Working hours', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              _hours.map((e) => '${e[0]}: ${e[1]}').join(' · '),
              style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            Text('Imagery', style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            _PhotoRow(
              label: 'Profile cover *',
              path: _profilePath,
              onPick: () async {
                final x = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => _profilePath = x.path);
              },
            ),
            _PhotoRow(
              label: 'Gallery (pick multiple on subsequent taps) *',
              path: _galleryPaths.isEmpty ? null : _galleryPaths.last,
              onPick: () async {
                final x = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => _galleryPaths.add(x.path));
              },
            ),
            if (_galleryPaths.isNotEmpty)
              Text('${_galleryPaths.length} file(s) queued', style: GoogleFonts.dmSans(fontSize: 12)),
            _PhotoRow(
              label: 'Certification (optional)',
              path: _certPath,
              onPick: () async {
                final x = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => _certPath = x.path);
              },
            ),
            _PhotoRow(
              label: 'CFE / registration (optional)',
              path: _cfePath,
              onPick: () async {
                final x = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (x != null) setState(() => _cfePath = x.path);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Publish studio'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({required this.label, required this.path, required this.onPick});

  final String label;
  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: GoogleFonts.dmSans())),
          TextButton(onPressed: onPick, child: Text(path == null ? 'Pick' : 'Change')),
        ],
      ),
    );
  }
}
