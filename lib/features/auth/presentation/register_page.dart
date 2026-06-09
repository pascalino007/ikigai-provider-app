import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/auth/presentation/auth_shell_card.dart';
import 'package:ikigai_provider_app/features/auth/presentation/otp_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstname = TextEditingController();
  final _lastname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _firstname.dispose();
    _lastname.dispose();
    _phone.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8F9FB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.authAmberDeep, width: 1.8),
      ),
      suffixIcon: suffix,
    );
  }

  Future<void> _submit() async {
    if (_firstname.text.trim().isEmpty ||
        _lastname.text.trim().isEmpty ||
        _phone.text.trim().isEmpty ||
        _email.text.trim().isEmpty ||
        _password.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Merci de remplir tous les champs.')),
      );
      return;
    }

    setState(() => _busy = true);
    await context.read<AuthCubit>().register(
          firstname: _firstname.text.trim(),
          lastname: _lastname.text.trim(),
          phone: _phone.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    final s = context.read<AuthCubit>().state;
    if (s is AuthAuthenticated) {
      final debugOtp = context.read<AuthRepository>().pendingOtpDebug;
      if (kDebugMode && debugOtp != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Code démo: $debugOtp')),
        );
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const OtpPage()),
      );
    } else if (s is AuthFailure) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthShellCard(
        headerTitle: 'Join Us',
        headerSubtitle: 'Create free account',
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _firstname,
                        decoration: _field('First Name'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _lastname,
                        decoration: _field('Last Name'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _field('Email Address', suffix: const Icon(Icons.alternate_email_rounded)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  decoration: _field('Phone', suffix: const Icon(Icons.phone_android_rounded)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  decoration: _field('Password', suffix: const Icon(Icons.lock_outline_rounded)),
                ),
                const SizedBox(height: 28),
                Text(
                  'Après validation OTP, vous créerez votre salon (adresse + GPS comme le dashboard admin).',
                  style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.authAmber,
                      foregroundColor: const Color(0xFF1A1A1A),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1A1A)),
                          )
                        : Text(
                            'Save & Continue',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
