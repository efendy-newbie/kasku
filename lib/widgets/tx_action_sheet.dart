import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'add_transaction_sheet.dart';

void showTxActionSheet(BuildContext context, AppTransaction tx) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _TxActionSheet(tx: tx),
  );
}

class _TxActionSheet extends ConsumerWidget {
  final AppTransaction tx;
  const _TxActionSheet({required this.tx});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = tx.type == TxType.income
        ? AppColors.emerald
        : tx.type == TxType.expense
            ? AppColors.coral
            : AppColors.azure;
    final title = tx.type == TxType.transfer ? 'Transfer' : tx.category;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(fmtRp(tx.amount),
                style: TextStyle(fontFamily: 'monospace', fontSize: 26, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 4),
            Text(
              '${fmtDateLabel(tx.date)} · ${tx.time}${tx.note.isNotEmpty ? ' · ${tx.note}' : ''}',
              style: TextStyle(color: context.inkFaint, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () {
                      Navigator.pop(context);
                      if (tx.type == TxType.transfer) return;
                      Future.delayed(const Duration(milliseconds: 150),
                          () => showAddTransactionSheet(context, existing: tx));
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.coralSoftLight,
                      foregroundColor: AppColors.coral,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ref.read(appStateProvider).deleteTransaction(tx.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
