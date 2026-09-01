import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';

void showTransferSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => const _TransferSheet(),
  );
}

class _TransferSheet extends ConsumerStatefulWidget {
  const _TransferSheet();

  @override
  ConsumerState<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends ConsumerState<_TransferSheet> {
  String? fromId;
  String? toId;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final accounts = appState.accounts;
    if (fromId == null && accounts.isNotEmpty) fromId = accounts.first.id;
    if (toId == null && accounts.length > 1) toId = accounts[1].id;

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
            const Text('Transfer Antar Akun', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            _label('Dari Akun'),
            _accountRow(accounts, fromId, (id) => setState(() => fromId = id)),
            const SizedBox(height: 8),
            const Center(child: Icon(Icons.swap_vert, color: AppColors.azure)),
            const SizedBox(height: 8),
            _label('Ke Akun'),
            _accountRow(accounts, toId, (id) => setState(() => toId = id)),
            _label('Nominal'),
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
                      controller: amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 24, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
                    ),
                  ),
                ],
              ),
            ),
            _label('Catatan (opsional)'),
            TextField(
              controller: noteCtrl,
              decoration: InputDecoration(
                hintText: 'Tulis catatan...',
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.lineColor),
                ),
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
                  backgroundColor: AppColors.azure,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) {
                    setState(() => errorText = 'Masukkan nominal yang valid');
                    return;
                  }
                  if (fromId == null || toId == null || fromId == toId) {
                    setState(() => errorText = 'Akun asal dan tujuan harus berbeda');
                    return;
                  }
                  await ref.read(appStateProvider).addTransfer(
                        fromAccountId: fromId!,
                        toAccountId: toId!,
                        amount: amount,
                        note: noteCtrl.text.trim(),
                      );
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Kirim Transfer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
      );

  Widget _accountRow(List<Account> accounts, String? selectedId, void Function(String) onSelect) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: accounts.map<Widget>((a) {
          final t = findAccountType(a.type);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('${t.emoji} ${a.name}'),
              selected: selectedId == a.id,
              onSelected: (_) => onSelect(a.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}
