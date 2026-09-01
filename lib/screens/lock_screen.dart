import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme.dart';
import 'root_shell.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String buffer = '';
  String error = '';
  bool shake = false;

  void _onKey(String key) {
    if (key == '⌫') {
      if (buffer.isNotEmpty) {
        setState(() => buffer = buffer.substring(0, buffer.length - 1));
      }
      return;
    }
    if (buffer.length >= 4) return;
    setState(() => buffer += key);
    if (buffer.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), _checkPin);
    }
  }

  void _checkPin() {
    final appState = ref.read(appStateProvider);
    if (buffer == appState.pin) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RootShell()),
      );
    } else {
      setState(() {
        error = 'PIN salah, coba lagi.';
        shake = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        setState(() {
          buffer = '';
          shake = false;
        });
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() => error = '');
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.emerald,
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
              Text('Masukkan PIN untuk membuka KasKu',
                  style: TextStyle(color: context.inkSoft, fontSize: 14)),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < buffer.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (shake ? Theme.of(context).colorScheme.error : AppColors.emerald)
                          : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? (shake ? Theme.of(context).colorScheme.error : AppColors.emerald)
                            : context.inkFaint,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 16,
                child: Text(error,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 24),
              _Keypad(onKey: _onKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  const _Keypad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    const keys = ['1','2','3','4','5','6','7','8','9','','0','⌫'];
    return SizedBox(
      width: 3 * 84,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: keys.map((k) {
          if (k.isEmpty) return const SizedBox();
          return InkWell(
            onTap: () => onKey(k),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: k == '⌫' ? null : Border.all(color: context.lineColor),
              ),
              alignment: Alignment.center,
              child: Text(
                k,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: k == '⌫' ? context.inkFaint : null,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
