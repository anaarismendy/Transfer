import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injection.dart';
import 'core/theme.dart';
import 'domain/usecases/seed_default_user.dart';
import 'presentation/blocs/auth_bloc.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/login_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  await getIt<SeedDefaultUser>()();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp(
        title: 'Transfer',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) => switch (state) {
        AuthUnknown() => const Scaffold(
          backgroundColor: bgTop,
          body: Center(child: CircularProgressIndicator(color: violet)),
        ),
        Authenticated(:final user) => HomePage(user: user),
        _ => const LoginPage(),
      },
    );
  }
}
