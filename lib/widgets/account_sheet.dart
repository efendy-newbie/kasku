import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';

const _uuid = Uuid();

void showAccountSheet(BuildContext context, {Account? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _AccountSheet(existing: existing),
  );
}

class _AccountSheet extends ConsumerStatefulWidget {
  final Account? existing;
  const _AccountSheet({this.existing});

  @override
  ConsumerState<_AccountSheet> createState() => _AccountSheetState();
}

class _AccountSheetState extends ConsumerState<_AccountSheet> {
  final nameCtrl = TextEditingController();
  final balanceCtrl = TextEditingController();
  late String selectedType;
  String? errorText;

  @override
  void initState() {
    super.initState();
    selectedType = widget.existing?.type ?? accountTypes.first.name;
    if (widget.existing != null) {
      nameCtrl.text = widget.existing!.name;
      balanceCtrl.text = widget.existing!.balance.round().toString();
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    balanceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
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
            Text(isEdit ? 'Edit Akun' : 'Tambah Akun', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            _label('Nama Akun'),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'Misal: Bank Jago',
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.lineColor)),
              ),
            ),
            _label('Jenis Akun'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: accountTypes.map((t) {
                final selected = selectedType == t.name;
                return GestureDetector(
                  onTap: () => setState(() => selectedType = t.name),
                  child: Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.emeraldSoftLight : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.emerald : context.lineColor, width: selected ? 1.5 : 1),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(color: Color(t.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(t.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 5),
                        Text(t.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            _label(isEdit ? 'Saldo' : 'Saldo Awal'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border.all(color: context.lineColor),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text('Rp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: context.inkFaint)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: balanceCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                    ),
                  ),
                ],
              ),
            ),
            if (errorText != null) ...[
              const SizedBox(height: 8),
              Text(errorText!, style: const TextStyle(color: AppColors.coral, fontSize: 12.5)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    setState(() => errorText = 'Nama akun tidak boleh kosong');
                    return;
                  }
                  final balance = double.tryParse(balanceCtrl.text) ?? 0;
                  final appState = ref.read(appStateProvider);
                  if (isEdit) {
                    appState.updateAccount(Account(id: widget.existing!.id, name: name, type: selectedType, balance: balance));
                  } else {
                    appState.addAccount(Account(id: _uuid.v4(), name: name, type: selectedType, balance: balance));
                  }
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Tambah Akun'),
              ),
            ),
            if (isEdit) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.coral,
                    side: const BorderSide(color: AppColors.coral),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final ok = await ref.read(appStateProvider).deleteAccount(widget.existing!.id);
                    if (!ok) {
                      setState(() => errorText = 'Akun ini punya riwayat transaksi, tidak bisa dihapus.');
                    } else if (context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Hapus Akun'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
      );
}
