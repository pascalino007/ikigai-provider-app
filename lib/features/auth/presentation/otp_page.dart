import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/core/widgets/ikigai_primary_button.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';
import 'package:ikigai_provider_app/features/onboarding/shop_onboarding_page.dart';

class OtpPage extends StatefulWidget {
  const OtpPage({super.key});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _verify() {
    final ok = context.read<AuthRepository>().verifyOtp(_code.text.trim());
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const ShopOnboardingPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid code. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter OTP',
              style: GoogleFonts.playfairDisplay(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              'Until SMS/email is wired to Nest, we generate a one-time code locally after signup. '
              'Replace this screen with your provider OTP API.',
              style: GoogleFonts.dmSans(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                counterText: '',
              ),
            ),
            const SizedBox(height: 16),
            IkigaiPrimaryButton(label: 'Verify & continue', onPressed: _verify),
          ],
        ),
      ),
    );
  }
}
