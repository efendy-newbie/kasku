import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/budget_sheet.dart';
import '../widgets/common_widgets.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key});

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

enum _StatsTab { grafik, anggaran, ringkasan }

class _StatsScreenState extends ConsumerState<StatsScreen> {
  _StatsTab tab = _StatsTab.grafik;

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final now = DateTime.now();
    final monthTx = appState.transactionsForMonth(now);
    final income = appState.sumType(monthTx, TxType.income);
    final expense = appState.sumType(monthTx, TxType.expense);

    final byCategory = <String, double>{};
    for (final t in monthTx.where((t) => t.type == TxType.expense)) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
    }
    final catEntries = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final trend = <_MonthPoint>[];
    for (int i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final list = appState.transactionsForMonth(m);
      trend.add(_MonthPoint(
        label: _monthShort(m.month),
        income: appState.sumType(list, TxType.income),
        expense: appState.sumType(list, TxType.expense),
      ));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        const Text('Statistik', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Bulan ini: pemasukan ${fmtRp(income)}, pengeluaran ${fmtRp(expense)}',
            style: TextStyle(fontSize: 11.5, color: context.inkFaint)),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: context.surface2, borderRadius: BorderRadius.circular(100)),
          child: Row(
            children: _StatsTab.values.map((t) {
              final active = tab == t;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => tab = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: active ? Theme.of(context).cardTheme.color : Colors.transparent,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    alignment: Alignment.center,
                    child: Text(_tabLabel(t),
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: active ? null : context.inkSoft)),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
        if (tab == _StatsTab.grafik) ..._buildGrafik(context, trend, catEntries),
        if (tab == _StatsTab.anggaran) ..._buildAnggaran(context, appState.budgets, byCategory),
        if (tab == _StatsTab.ringkasan) ..._buildRingkasan(context, appState),
      ],
    );
  }

  String _tabLabel(_StatsTab t) {
    switch (t) {
      case _StatsTab.grafik:
        return 'Grafik';
      case _StatsTab.anggaran:
        return 'Anggaran';
      case _StatsTab.ringkasan:
        return 'Ringkasan';
    }
  }

  String _monthShort(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final idx = ((month - 1) % 12 + 12) % 12;
    return names[idx];
  }

  List<Widget> _buildGrafik(BuildContext context, List<_MonthPoint> trend, List<MapEntry<String, double>> catEntries) {
    final maxVal = trend.fold<double>(0, (m, p) => [m, p.income, p.expense].reduce((a, b) => a > b ? a : b));
    return [
      _card(
        context,
        title: 'Income vs Expense (6 bulan)',
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: maxVal <= 0 ? 100 : maxVal * 1.2,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= trend.length) return const SizedBox();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(trend[idx].label, style: TextStyle(fontSize: 10.5, color: context.inkFaint)),
                      );
                    },
                  ),
                ),
              ),
              barGroups: List.generate(trend.length, (i) {
                final p = trend[i];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: p.income, color: AppColors.emerald, width: 8, borderRadius: BorderRadius.circular(4)),
                  BarChartRodData(toY: p.expense, color: AppColors.coral, width: 8, borderRadius: BorderRadius.circular(4)),
                ], barsSpace: 4);
              }),
            ),
          ),
        ),
      ),
      const SizedBox(height: 14),
      _card(
        context,
        title: 'Pengeluaran per Kategori',
        child: catEntries.isEmpty
            ? const EmptyState(glyph: '📊', text: 'Belum ada pengeluaran bulan ini.')
            : SizedBox(
                height: 200,
                child: Row(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 44,
                          sections: catEntries.map((e) {
                            final cat = findCategory(expenseCategories, e.key);
                            return PieChartSectionData(
                              value: e.value,
                              color: Color(cat.colorValue),
                              radius: 46,
                              showTitle: false,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ListView(
                        children: catEntries.take(6).map((e) {
                          final cat = findCategory(expenseCategories, e.key);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Container(width: 8, height: 8, decoration: BoxDecoration(color: Color(cat.colorValue), shape: BoxShape.circle)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(e.key, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    ];
  }

  List<Widget> _buildAnggaran(BuildContext context, List<Budget> budgets, Map<String, double> byCategory) {
    return [
      ...budgets.map((b) {
        final used = byCategory[b.category] ?? 0;
        final pct = b.limit > 0 ? (used / b.limit * 100).round() : 0;
        final over = pct >= 90;
        final cat = findCategory(expenseCategories, b.category);
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.lineColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Text(cat.emoji),
                    const SizedBox(width: 8),
                    Text(b.category, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ]),
                  Text('$pct%', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: over ? AppColors.coral : context.inkSoft)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0, 1).toDouble(),
                  minHeight: 8,
                  backgroundColor: context.surface2,
                  valueColor: AlwaysStoppedAnimation(over ? AppColors.coral : AppColors.emerald),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${fmtRp(used)} terpakai', style: TextStyle(fontSize: 11.5, color: context.inkFaint)),
                  Text('batas ${fmtRp(b.limit)}', style: TextStyle(fontSize: 11.5, color: context.inkFaint)),
                ],
              ),
            ],
          ),
        );
      }),
      const SizedBox(height: 6),
      SizedBox(
        width: double.infinity,
        child: Builder(builder: (context) {
          return OutlinedButton(
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            onPressed: () => showBudgetSheet(context),
            child: const Text('+ Atur Anggaran Kategori'),
          );
        }),
      ),
    ];
  }

  List<Widget> _buildRingkasan(BuildContext context, dynamic appState) {
    final List<AppTransaction> all = appState.transactions;
    final totalCount = all.length;
    final double totalIncome = appState.sumType(all, TxType.income);
    final double totalExpense = appState.sumType(all, TxType.expense);
    final double totalTransfer = appState.sumType(all, TxType.transfer);

    AppTransaction? biggestExpense;
    AppTransaction? biggestIncome;
    for (final t in all) {
      if (t.type == TxType.expense && (biggestExpense == null || t.amount > biggestExpense!.amount)) biggestExpense = t;
      if (t.type == TxType.income && (biggestIncome == null || t.amount > biggestIncome!.amount)) biggestIncome = t;
    }

    final catCount = <String, double>{};
    for (final t in all.where((t) => t.type == TxType.expense)) {
      catCount[t.category] = (catCount[t.category] ?? 0) + t.amount;
    }
    MapEntry<String, double>? favCat;
    if (catCount.isNotEmpty) {
      final sorted = catCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      favCat = sorted.first;
    }

    final accUsage = <String, int>{};
    for (final t in all) {
      accUsage[t.accountId] = (accUsage[t.accountId] ?? 0) + 1;
    }
    String favAccName = '-';
    if (accUsage.isNotEmpty) {
      final sorted = accUsage.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final favId = sorted.first.key;
      final List accounts = appState.accounts;
      final found = accounts.where((a) => a.id == favId);
      if (found.isNotEmpty) favAccName = found.first.name as String;
    }

    final nonTransfer = all.where((t) => t.type != TxType.transfer).toList();
    final dayCount = nonTransfer.map((t) => t.date).toSet().length;
    final avgPerDay = dayCount == 0 ? 0.0 : nonTransfer.length / dayCount;
    final avgAmount = nonTransfer.isEmpty ? 0.0 : nonTransfer.fold<double>(0, (s, t) => s + t.amount) / nonTransfer.length;

    Widget row(String k, String v, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(k, style: TextStyle(fontSize: 13.5, color: context.inkSoft)),
              Text(v, style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13.5, color: color)),
            ],
          ),
        );

    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.lineColor),
        ),
        child: Column(
          children: [
            row('Total transaksi', '$totalCount'),
            const Divider(height: 1),
            row('Total pemasukan', fmtRp(totalIncome), color: AppColors.emerald),
            const Divider(height: 1),
            row('Total pengeluaran', fmtRp(totalExpense), color: AppColors.coral),
            const Divider(height: 1),
            row('Total transfer', fmtRp(totalTransfer), color: AppColors.azure),
            const Divider(height: 1),
            row('Pengeluaran terbesar', biggestExpense != null ? fmtRp(biggestExpense!.amount) : '-'),
            const Divider(height: 1),
            row('Pemasukan terbesar', biggestIncome != null ? fmtRp(biggestIncome!.amount) : '-'),
            const Divider(height: 1),
            row('Kategori favorit', favCat?.key ?? '-'),
            const Divider(height: 1),
            row('Akun tersering', favAccName),
            const Divider(height: 1),
            row('Rata-rata transaksi/hari', avgPerDay.toStringAsFixed(1)),
            const Divider(height: 1),
            row('Rata-rata nominal', fmtRp(avgAmount)),
          ],
        ),
      ),
    ];
  }

  Widget _card(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MonthPoint {
  final String label;
  final double income;
  final double expense;
  _MonthPoint({required this.label, required this.income, required this.expense});
}
