import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/tx_action_sheet.dart';

enum _Period { hari, minggu, bulan, semua }

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  _Period period = _Period.bulan;
  TxType? typeFilter; // null = semua
  String sort = 'terbaru';
  String search = '';

  List<AppTransaction> _apply(List<AppTransaction> all) {
    var list = List<AppTransaction>.from(all);
    final now = DateTime.now();

    if (period == _Period.hari) {
      final iso = todayIso();
      list = list.where((t) => t.date == iso).toList();
    } else if (period == _Period.minggu) {
      final monday = now.subtract(Duration(days: (now.weekday - 1)));
      final mondayIso = '${monday.year.toString().padLeft(4, '0')}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
      list = list.where((t) => t.date.compareTo(mondayIso) >= 0).toList();
    } else if (period == _Period.bulan) {
      list = list.where((t) {
        final d = DateTime.parse(t.date);
        return d.year == now.year && d.month == now.month;
      }).toList();
    }

    if (typeFilter != null) {
      list = list.where((t) => t.type == typeFilter).toList();
    }

    if (search.trim().isNotEmpty) {
      final q = search.toLowerCase();
      list = list.where((t) =>
          t.category.toLowerCase().contains(q) ||
          t.note.toLowerCase().contains(q) ||
          t.amount.round().toString().contains(q)).toList();
    }

    list.sort((a, b) {
      switch (sort) {
        case 'terlama':
          return (a.date + a.time).compareTo(b.date + b.time);
        case 'terbesar':
          return b.amount.compareTo(a.amount);
        case 'terkecil':
          return a.amount.compareTo(b.amount);
        default:
          return (b.date + b.time).compareTo(a.date + a.time);
      }
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final filtered = _apply(appState.transactions);

    final groups = <String, List<AppTransaction>>{};
    for (final t in filtered) {
      groups.putIfAbsent(t.date, () => []).add(t);
    }
    final dateKeys = groups.keys.toList()
      ..sort((a, b) => sort == 'terlama' ? a.compareTo(b) : b.compareTo(a));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const Text('Riwayat', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        TextField(
          onChanged: (v) => setState(() => search = v),
          decoration: InputDecoration(
            hintText: 'Cari nominal, kategori, catatan...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: Theme.of(context).cardTheme.color,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: context.lineColor)),
          ),
        ),
        const SizedBox(height: 10),
        _chipRow([
          _ChipData('Hari', period == _Period.hari, () => setState(() => period = _Period.hari)),
          _ChipData('Minggu', period == _Period.minggu, () => setState(() => period = _Period.minggu)),
          _ChipData('Bulan', period == _Period.bulan, () => setState(() => period = _Period.bulan)),
          _ChipData('Semua', period == _Period.semua, () => setState(() => period = _Period.semua)),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _ChipData('Semua Jenis', typeFilter == null, () => setState(() => typeFilter = null)),
          _ChipData('Pemasukan', typeFilter == TxType.income, () => setState(() => typeFilter = TxType.income)),
          _ChipData('Pengeluaran', typeFilter == TxType.expense, () => setState(() => typeFilter = TxType.expense)),
          _ChipData('Transfer', typeFilter == TxType.transfer, () => setState(() => typeFilter = TxType.transfer)),
        ]),
        const SizedBox(height: 8),
        _chipRow([
          _ChipData('Terbaru', sort == 'terbaru', () => setState(() => sort = 'terbaru')),
          _ChipData('Terlama', sort == 'terlama', () => setState(() => sort = 'terlama')),
          _ChipData('Terbesar', sort == 'terbesar', () => setState(() => sort = 'terbesar')),
          _ChipData('Terkecil', sort == 'terkecil', () => setState(() => sort = 'terkecil')),
        ]),
        const SizedBox(height: 8),
        if (dateKeys.isEmpty)
          const EmptyState(glyph: '🔍', text: 'Tidak ada transaksi yang cocok dengan filter ini.')
        else
          ...dateKeys.map((dk) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(fmtDateLabel(dk),
                          style: TextStyle(
                              fontSize: 11.5, fontWeight: FontWeight.w700, color: context.inkFaint, letterSpacing: 0.5)),
                    ),
                    ...groups[dk]!.map((t) => TxListTile(
                          tx: t,
                          accounts: appState.accounts,
                          onTap: () => showTxActionSheet(context, t),
                        )),
                  ],
                ),
              )),
      ],
    );
  }

  Widget _chipRow(List<_ChipData> chips) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: chips
            .map((c) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(c.label),
                    selected: c.selected,
                    onSelected: (_) => c.onTap(),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _ChipData {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  _ChipData(this.label, this.selected, this.onTap);
}
