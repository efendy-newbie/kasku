import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';

void showAddTransactionSheet(
  BuildContext context, {
  bool initialIsIncome = false,
  AppTransaction? existing,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => _AddTransactionSheet(
      initialIsIncome: initialIsIncome,
      existing: existing,
    ),
  );
}

class _AddTransactionSheet extends ConsumerStatefulWidget {
  final bool initialIsIncome;
  final AppTransaction? existing;
  const _AddTransactionSheet({required this.initialIsIncome, this.existing});

  @override
  ConsumerState<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  late bool isIncome;
  String? selectedCategory;
  String? selectedAccountId;
  final amountCtrl = TextEditingController();
  final noteCtrl = TextEditingController();
  DateTime date = DateTime.now();
  TimeOfDay time = TimeOfDay.now();
  String? errorText;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    isIncome = e != null ? e.type == TxType.income : widget.initialIsIncome;
    selectedCategory = e?.category;
    selectedAccountId = e?.accountId;
    if (e != null) {
      amountCtrl.text = e.amount.round().toString();
      noteCtrl.text = e.note;
      date = DateTime.parse(e.date);
      final parts = e.time.split(':');
      time = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  }

  @override
  void dispose() {
    amountCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  List<CategoryDef> get _cats {
    final appState = ref.read(appStateProvider);
    return isIncome
        ? [...incomeCategories, ...appState.customIncomeCats]
        : [...expenseCategories, ...appState.customExpenseCats];
  }

  void _openNewCategoryDialog() {
    final nameCtrl = TextEditingController();
    final emojiCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kategori Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama kategori')),
            const SizedBox(height: 10),
            TextField(
              controller: emojiCtrl,
              maxLength: 2,
              decoration: const InputDecoration(labelText: 'Emoji (opsional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final emoji = emojiCtrl.text.trim().isEmpty ? '🏷️' : emojiCtrl.text.trim();
              final cat = CategoryDef(name, emoji, 0xFF5C6BC0);
              ref.read(appStateProvider).addCustomCategory(isIncome, cat);
              setState(() => selectedCategory = name);
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(amountCtrl.text);
    if (amount == null || amount <= 0) {
      setState(() => errorText = 'Masukkan nominal yang valid');
      return;
    }
    if (selectedCategory == null) {
      setState(() => errorText = 'Pilih kategori dulu');
      return;
    }
    if (selectedAccountId == null) {
      setState(() => errorText = 'Pilih akun dulu');
      return;
    }
    final appState = ref.read(appStateProvider);
    final dateStr =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    if (widget.existing != null) {
      final updated = AppTransaction(
        id: widget.existing!.id,
        type: isIncome ? TxType.income : TxType.expense,
        amount: amount,
        category: selectedCategory!,
        note: noteCtrl.text.trim(),
        accountId: selectedAccountId!,
        date: dateStr,
        time: timeStr,
      );
      appState.updateTransaction(updated);
    } else {
      final t = AppTransaction(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: isIncome ? TxType.income : TxType.expense,
        amount: amount,
        category: selectedCategory!,
        note: noteCtrl.text.trim(),
        accountId: selectedAccountId!,
        date: dateStr,
        time: timeStr,
      );
      appState.addTransaction(t);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    if (selectedAccountId == null && appState.accounts.isNotEmpty) {
      selectedAccountId = appState.accounts.first.id;
    }
    final accentColor = isIncome ? AppColors.emerald : AppColors.coral;

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
              Text(widget.existing != null ? 'Edit Transaksi' : 'Tambah Transaksi',
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
              const SizedBox(height: 18),

              // Type segment
              Container(
                decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegBtn(
                        label: 'Pemasukan',
                        active: isIncome,
                        color: AppColors.emerald,
                        onTap: () => setState(() {
                          isIncome = true;
                          selectedCategory = null;
                        }),
                      ),
                    ),
                    Expanded(
                      child: _SegBtn(
                        label: 'Pengeluaran',
                        active: !isIncome,
                        color: AppColors.coral,
                        onTap: () => setState(() {
                          isIncome = false;
                          selectedCategory = null;
                        }),
                      ),
                    ),
                  ],
                ),
              ),

              _fieldLabel('Nominal'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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

              _fieldLabel('Kategori'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._cats.map((c) => _CategoryChip(
                        cat: c,
                        selected: selectedCategory == c.name,
                        onTap: () => setState(() => selectedCategory = c.name),
                      )),
                  _CategoryChip(
                    cat: const CategoryDef('Baru', '➕', 0xFF8A9389),
                    selected: false,
                    onTap: _openNewCategoryDialog,
                  ),
                ],
              ),

              _fieldLabel('Akun'),
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: appState.accounts.map((a) {
                    final t = findAccountType(a.type);
                    final selected = selectedAccountId == a.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('${t.emoji} ${a.name}'),
                        selected: selected,
                        onSelected: (_) => setState(() => selectedAccountId = a.id),
                      ),
                    );
                  }).toList(),
                ),
              ),

              _fieldLabel('Catatan (opsional)'),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Tulis catatan singkat...',
                  filled: true,
                  fillColor: Theme.of(context).cardTheme.color,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: context.lineColor),
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Tanggal'),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: date,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => date = picked);
                          },
                          child: Text('${date.day}/${date.month}/${date.year}'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel('Jam'),
                        OutlinedButton(
                          onPressed: () async {
                            final picked = await showTimePicker(context: context, initialTime: time);
                            if (picked != null) setState(() => time = picked);
                          },
                          child: Text(time.format(context)),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    backgroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _save,
                  child: Text(widget.existing != null ? 'Simpan Perubahan' : 'Simpan Transaksi'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
      );
}

class _SegBtn extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;
  const _SegBtn({required this.label, required this.active, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: active ? Colors.white : context.inkSoft)),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryDef cat;
  final bool selected;
  final VoidCallback onTap;
  const _CategoryChip({required this.cat, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Color(cat.colorValue);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              alignment: Alignment.center,
              child: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 5),
            Text(cat.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: context.inkSoft)),
          ],
        ),
      ),
    );
  }
}
