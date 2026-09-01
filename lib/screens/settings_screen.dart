import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/account_sheet.dart';

void showSettingsSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends ConsumerStatefulWidget {
  const _SettingsSheet();

  @override
  ConsumerState<_SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends ConsumerState<_SettingsSheet> {
  String? feedback;

  Future<void> _exportBackup() async {
    final appState = ref.read(appStateProvider);
    final data = appState.exportToJson();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/kasku-backup-${todayIso()}.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles([XFile(file.path)], text: 'Backup data KasKu');
  }

  Future<void> _importBackup() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    try {
      final content = await file.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final ok = await ref.read(appStateProvider).importFromJson(data);
      setState(() => feedback = ok ? 'Data berhasil dipulihkan.' : 'File backup tidak valid.');
    } catch (_) {
      setState(() => feedback = 'Gagal membaca file backup.');
    }
  }

  void _confirmReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Semua Data?'),
        content: const Text(
            'Semua transaksi, akun, dan target akan dihapus permanen (nominal kembali ke 0) dan tidak bisa dikembalikan. Pastikan sudah ekspor backup jika perlu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.coral),
            onPressed: () async {
              await ref.read(appStateProvider).resetAllData();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Ya, Reset'),
          ),
        ],
      ),
    );
  }

  void _togglePin(bool enable) {
    if (!enable) {
      ref.read(appStateProvider).setPin(null);
      return;
    }
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 200), () => _openPinSetupDialog());
  }

  void _openPinSetupDialog() {
    String first = '';
    String buffer = '';
    String stage = 'enter'; // enter | confirm
    String? err;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setLocal) {
        void onKey(String k) {
          if (k == '⌫') {
            if (buffer.isNotEmpty) setLocal(() => buffer = buffer.substring(0, buffer.length - 1));
            return;
          }
          if (buffer.length >= 4) return;
          setLocal(() => buffer += k);
          if (buffer.length == 4) {
            if (stage == 'enter') {
              first = buffer;
              setLocal(() {
                buffer = '';
                stage = 'confirm';
              });
            } else {
              if (buffer == first) {
                ref.read(appStateProvider).setPin(buffer);
                Navigator.pop(ctx);
              } else {
                setLocal(() {
                  err = 'PIN tidak cocok, ulangi.';
                  buffer = '';
                  stage = 'enter';
                });
              }
            }
          }
        }

        return AlertDialog(
          title: Text(stage == 'enter' ? 'Buat PIN baru (4 digit)' : 'Ulangi PIN untuk konfirmasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < buffer.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.emerald : Colors.transparent,
                      border: Border.all(color: filled ? AppColors.emerald : context.inkFaint, width: 2),
                    ),
                  );
                }),
              ),
              if (err != null) Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(err!, style: const TextStyle(color: AppColors.coral, fontSize: 12)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 3 * 64,
                child: GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: ['1','2','3','4','5','6','7','8','9','','0','⌫'].map((k) {
                    if (k.isEmpty) return const SizedBox();
                    return InkWell(
                      onTap: () => onKey(k),
                      borderRadius: BorderRadius.circular(32),
                      child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: context.lineColor)),
                        alignment: Alignment.center,
                        child: Text(k, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: context.lineColor, borderRadius: BorderRadius.circular(100)),
                ),
              ),
              const Text('Pengaturan', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),

              _groupTitle('Tampilan'),
              Row(
                children: [
                  Expanded(child: _themeOpt(context, '☀️ Terang', appState.themeMode == ThemeMode.light, () => appState.setThemeMode(ThemeMode.light))),
                  const SizedBox(width: 8),
                  Expanded(child: _themeOpt(context, '🌙 Gelap', appState.themeMode == ThemeMode.dark, () => appState.setThemeMode(ThemeMode.dark))),
                  const SizedBox(width: 8),
                  Expanded(child: _themeOpt(context, '⚙️ Sistem', appState.themeMode == ThemeMode.system, () => appState.setThemeMode(ThemeMode.system))),
                ],
              ),

              _groupTitle('Keamanan'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Kunci PIN', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: Text(appState.pin != null && appState.pin!.isNotEmpty ? 'Aktif · 4 digit' : 'Nonaktif'),
                value: appState.pin != null && appState.pin!.isNotEmpty,
                activeThumbColor: AppColors.emerald,
                onChanged: _togglePin,
              ),

              _groupTitle('Akun & Kategori'),
              _settingsRow(context, '💳 Kelola Akun', () => _manageAccounts(context)),

              _groupTitle('Data'),
              _settingsRow(context, '⬇️ Ekspor Backup (JSON)', _exportBackup),
              _settingsRow(context, '⬆️ Impor Backup', _importBackup),
              _settingsRow(context, '🗑️ Reset Semua Data', _confirmReset, danger: true),
              if (feedback != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(feedback!, style: TextStyle(fontSize: 12, color: context.inkSoft)),
                ),

              _groupTitle('Tentang'),
              Text(
                'KasKu v1.0 — Aplikasi pencatat keuangan offline-first.\nSemua data tersimpan hanya di perangkatmu.',
                style: TextStyle(fontSize: 12, color: context.inkFaint, height: 1.6),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _manageAccounts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => Consumer(builder: (ctx, ref, __) {
        final accounts = ref.watch(appStateProvider).accounts;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Kelola Akun', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...accounts.map((a) {
                  final t = findAccountType(a.type);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: Color(t.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: Text(t.emoji, style: const TextStyle(fontSize: 17)),
                    ),
                    title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    subtitle: Text(fmtRp(a.balance)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(ctx);
                      showAccountSheet(context, existing: a);
                    },
                  );
                }),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      showAccountSheet(context);
                    },
                    child: const Text('+ Tambah Akun Baru'),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _groupTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.6)),
      );

  Widget _themeOpt(BuildContext context, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.emeraldSoftLight : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? AppColors.emerald : context.lineColor, width: active ? 1.5 : 1),
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: active ? AppColors.emerald : context.inkSoft)),
      ),
    );
  }

  Widget _settingsRow(BuildContext context, String label, VoidCallback onTap, {bool danger = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: context.lineColor))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: danger ? AppColors.coral : null)),
            Icon(Icons.chevron_right, size: 18, color: context.inkFaint),
          ],
        ),
      ),
    );
  }
}
