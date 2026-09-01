import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';

void showBudgetSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => const _BudgetSheet(),
  );
}

class _BudgetSheet extends ConsumerStatefulWidget {
  const _BudgetSheet();

  @override
  ConsumerState<_BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<_BudgetSheet> {
  String? selectedCategory;
  final limitCtrl = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    limitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text('Atur Anggaran Kategori', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text('KATEGORI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: expenseCategories.map((c) {
                final selected = selectedCategory == c.name;
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = c.name),
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
                          decoration: BoxDecoration(color: Color(c.colorValue).withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                          alignment: Alignment.center,
                          child: Text(c.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 5),
                        Text(c.name, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('BATAS BULANAN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
            const SizedBox(height: 8),
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
                      controller: limitCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w600),
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
                  if (selectedCategory == null) {
                    setState(() => errorText = 'Pilih kategori dulu');
                    return;
                  }
                  final limit = double.tryParse(limitCtrl.text);
                  if (limit == null || limit <= 0) {
                    setState(() => errorText = 'Masukkan batas anggaran yang valid');
                    return;
                  }
                  ref.read(appStateProvider).setBudget(selectedCategory!, limit);
                  Navigator.pop(context);
                },
                child: const Text('Simpan Anggaran'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
