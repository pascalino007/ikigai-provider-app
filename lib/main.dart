import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ikigai_provider_app/core/theme/app_theme.dart';
import 'package:ikigai_provider_app/data/repositories/auth_repository_impl.dart';
import 'package:ikigai_provider_app/data/repositories/partner_repository_impl.dart';
import 'package:ikigai_provider_app/domain/repositories/auth_repository.dart';
import 'package:ikigai_provider_app/domain/repositories/partner_repository.dart';
import 'package:ikigai_provider_app/features/auth/cubit/auth_cubit.dart';
import 'package:ikigai_provider_app/features/auth/presentation/login_page.dart';
import 'package:ikigai_provider_app/features/splash/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  final prefs = await SharedPreferences.getInstance();
  const secure = FlutterSecureStorage();
  final authRepository = AuthRepositoryImpl(secureStorage: secure, prefs: prefs);
  await authRepository.restoreSession();
  final partnerRepository = PartnerRepositoryImpl(
    tokenProvider: () => authRepository.storedToken,
  );

  runApp(
    IkigaiProviderBootstrap(
      authRepository: authRepository,
      partnerRepository: partnerRepository,
    ),
  );
}

class IkigaiProviderBootstrap extends StatelessWidget {
  const IkigaiProviderBootstrap({
    super.key,
    required this.authRepository,
    required this.partnerRepository,
  });

  final AuthRepository authRepository;
  final PartnerRepository partnerRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<PartnerRepository>.value(value: partnerRepository),
      ],
      child: BlocProvider(
        create: (_) => AuthCubit(authRepository),
        child: MaterialApp(
          title: 'Ikigai Pro',
          theme: AppTheme.light(),
          debugShowCheckedModeBanner: false,
          home: const SplashPage(),
          routes: {
            '/login': (_) => const LoginPage(),
          },
        ),
      ),
    );
  }
}
