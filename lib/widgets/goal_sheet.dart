import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';

const _uuid = Uuid();

void showGoalSheet(BuildContext context, {Goal? existing}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => _GoalSheet(existing: existing),
  );
}

class _GoalSheet extends ConsumerStatefulWidget {
  final Goal? existing;
  const _GoalSheet({this.existing});

  @override
  ConsumerState<_GoalSheet> createState() => _GoalSheetState();
}

class _GoalSheetState extends ConsumerState<_GoalSheet> {
  final nameCtrl = TextEditingController();
  final targetCtrl = TextEditingController();
  final currentCtrl = TextEditingController();
  DateTime? deadline;
  String? errorText;

  @override
  void initState() {
    super.initState();
    final g = widget.existing;
    if (g != null) {
      nameCtrl.text = g.name;
      targetCtrl.text = g.target.round().toString();
      currentCtrl.text = g.current.round().toString();
      if (g.deadline.isNotEmpty) deadline = DateTime.tryParse(g.deadline);
    } else {
      currentCtrl.text = '0';
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    targetCtrl.dispose();
    currentCtrl.dispose();
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
            Text(isEdit ? 'Edit Target' : 'Target Tabungan Baru', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            _label('Nama Target'),
            _input(nameCtrl, hint: 'Misal: Liburan ke Bali'),
            _label('Target Dana'),
            _amountInput(targetCtrl),
            _label('Sudah Terkumpul'),
            _amountInput(currentCtrl),
            _label('Target Tanggal (opsional)'),
            OutlinedButton(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: deadline ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => deadline = picked);
              },
              child: Text(deadline == null ? 'Pilih tanggal' : '${deadline!.day}/${deadline!.month}/${deadline!.year}'),
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
                  final target = double.tryParse(targetCtrl.text);
                  final current = double.tryParse(currentCtrl.text) ?? 0;
                  if (name.isEmpty) {
                    setState(() => errorText = 'Nama target tidak boleh kosong');
                    return;
                  }
                  if (target == null || target <= 0) {
                    setState(() => errorText = 'Masukkan target dana yang valid');
                    return;
                  }
                  final deadlineStr = deadline == null
                      ? ''
                      : '${deadline!.year.toString().padLeft(4, '0')}-${deadline!.month.toString().padLeft(2, '0')}-${deadline!.day.toString().padLeft(2, '0')}';
                  final appState = ref.read(appStateProvider);
                  if (isEdit) {
                    appState.updateGoal(Goal(id: widget.existing!.id, name: name, target: target, current: current, deadline: deadlineStr));
                  } else {
                    appState.addGoal(Goal(id: _uuid.v4(), name: name, target: target, current: current, deadline: deadlineStr));
                  }
                  Navigator.pop(context);
                },
                child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Target'),
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
                  onPressed: () {
                    ref.read(appStateProvider).deleteGoal(widget.existing!.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Hapus Target'),
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

  Widget _input(TextEditingController ctrl, {required String hint}) => TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Theme.of(context).cardTheme.color,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: context.lineColor)),
        ),
      );

  Widget _amountInput(TextEditingController ctrl) => Container(
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
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 22, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(border: InputBorder.none, hintText: '0'),
              ),
            ),
          ],
        ),
      );
}

// ---------------- Fund Goal Sheet ----------------

void showFundGoalSheet(BuildContext context, Goal goal) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => _FundGoalSheet(goal: goal),
  );
}

class _FundGoalSheet extends ConsumerStatefulWidget {
  final Goal goal;
  const _FundGoalSheet({required this.goal});

  @override
  ConsumerState<_FundGoalSheet> createState() => _FundGoalSheetState();
}

class _FundGoalSheetState extends ConsumerState<_FundGoalSheet> {
  String? accountId;
  final amountCtrl = TextEditingController();
  String? errorText;

  @override
  void dispose() {
    amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(appStateProvider).accounts;
    if (accountId == null && accounts.isNotEmpty) accountId = accounts.first.id;

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
            Text('Tambah Dana ke "${widget.goal.name}"', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 18),
            Text('AMBIL DARI AKUN',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: accounts.map((a) {
                  final t = findAccountType(a.type);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${t.emoji} ${a.name}'),
                      selected: accountId == a.id,
                      onSelected: (_) => setState(() => accountId = a.id),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('NOMINAL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.4)),
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
                      controller: amountCtrl,
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
                  backgroundColor: AppColors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text);
                  if (amount == null || amount <= 0) {
                    setState(() => errorText = 'Masukkan nominal yang valid');
                    return;
                  }
                  final ok = await ref.read(appStateProvider).fundGoal(widget.goal.id, accountId!, amount);
                  if (!ok) {
                    setState(() => errorText = 'Saldo akun tidak cukup');
                    return;
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Tambahkan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
