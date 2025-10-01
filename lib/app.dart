import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'state/auth_state.dart';
import 'theme.dart';

class ProximityApp extends ConsumerWidget {
  const ProximityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Radius Social',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: authState.isAuthenticated ? const HomeScreen() : const AuthScreen(),
    );
  }
}


