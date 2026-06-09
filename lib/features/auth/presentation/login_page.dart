import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ikigai_provider_app/core/theme/app_colors.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/auth/presentation/auth_shell_card.dart';
import 'package:ikigai_provider_app/features/auth/presentation/forgot_password_page.dart';
import 'package:ikigai_provider_app/features/auth/presentation/register_page.dart';
import 'package:ikigai_provider_app/features/shell/partner_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _savePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _showErrorDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.authAmber.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline_rounded, color: AppColors.authAmberDeep, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A1A)),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.authAmber,
                    foregroundColor: const Color(0xFF1A1A1A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    elevation: 0,
                  ),
                  child: Text('OK', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty && password.isEmpty) {
      await _showErrorDialog('Missing Information', 'Please enter your email and password to continue.');
      return;
    }
    if (email.isEmpty) {
      await _showErrorDialog('Missing Email', 'Please enter your email address.');
      return;
    }
    if (password.isEmpty) {
      await _showErrorDialog('Missing Password', 'Please enter your password.');
      return;
    }

    setState(() => _busy = true);
    await context.read<AuthCubit>().login(email: email, password: password);
    if (!mounted) return;
    setState(() => _busy = false);

    final s = context.read<AuthCubit>().state;
    if (s is AuthAuthenticated) {
      if (s.user.role == 'provider' && s.user.shopId == null) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Shop Not Linked'),
            content: const Text(
              'Your provider account is active but no shop is linked yet. Please contact your administrator to create and link your shop.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const PartnerShell()),
      );
    } else if (s is AuthFailure) {
      final msg = s.message.toLowerCase();
      if (msg.contains('401') || msg.contains('invalid credentials') || msg.contains('unauthorized') || msg.contains('user not found')) {
        await _showErrorDialog('Invalid Credentials', 'The email or password you entered is incorrect. Please try again.');
      } else if (msg.contains('socketexception') || msg.contains('connection refused') || msg.contains('cannot reach the server')) {
        await _showErrorDialog('Connection Error', 'Unable to reach the server. Please check your internet connection and try again.');
      } else {
        await _showErrorDialog('Login Failed', s.message);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return AuthShellCard(
            headerTitle: 'Hello',
            headerSubtitle: 'Welcome back !',
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _field('Email', suffix: const Icon(Icons.person_outline_rounded)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      decoration: _field('Password', suffix: const Icon(Icons.lock_outline_rounded)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _savePassword,
                          onChanged: (v) => setState(() => _savePassword = v ?? false),
                        ),
                        Expanded(
                          child: Text('Save password', style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(builder: (_) => const ForgotPasswordPage()),
                            );
                          },
                          child: Text(
                            'Forgot password?',
                            style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: AppColors.primary),
                          ),
                        ),
                      ],
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
                                'Login Account',
                                style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: Text(
                          'Create New Account',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
