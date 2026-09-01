import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/providers.dart';
import 'screens/lock_screen.dart';
import 'screens/root_shell.dart';
import 'theme.dart';

void main() {
  runApp(const ProviderScope(child: KasKuApp()));
}

class KasKuApp extends ConsumerWidget {
  const KasKuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    return MaterialApp(
      title: 'KasKu',
      debugShowCheckedModeBanner: false,
      themeMode: appState.themeMode,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      home: !appState.isReady
          ? const _SplashScreen()
          : (appState.pin != null && appState.pin!.isNotEmpty)
              ? const LockScreen()
              : const RootShell(),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1B7A4D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Text('K',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
