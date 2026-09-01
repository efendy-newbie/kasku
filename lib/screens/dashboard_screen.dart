import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models.dart';
import '../providers/providers.dart';
import '../theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';
import '../widgets/account_sheet.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/common_widgets.dart';
import '../widgets/transfer_sheet.dart';
import '../widgets/tx_action_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final now = DateTime.now();
    final monthTx = appState.transactionsForMonth(now);
    final income = appState.sumType(monthTx, TxType.income);
    final expense = appState.sumType(monthTx, TxType.expense);
    final saving = income - expense;
    final balance = appState.totalBalance;
    final score = appState.safetyScore;

    final recent = [...appState.transactions]
      ..sort((a, b) => (b.date + b.time).compareTo(a.date + a.time));
    final recentTop = recent.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        // Balance hero card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.emerald, Color(0xFF145C3A)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TOTAL SALDO',
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
              const SizedBox(height: 6),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: balance),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => Text(
                  fmtRp(value),
                  style: const TextStyle(
                      color: Colors.white, fontSize: 34, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '${saving >= 0 ? '↑' : '↓'} ${income > 0 ? (saving.abs() / income * 100).round() : 0}% dr pemasukan bulan ini',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Stat row
        SizedBox(
          height: 84,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              SizedBox(width: 152, child: _StatPill(label: 'Income', value: income, color: AppColors.emerald)),
              const SizedBox(width: 10),
              SizedBox(width: 152, child: _StatPill(label: 'Expense', value: expense, color: AppColors.coral)),
              const SizedBox(width: 10),
              SizedBox(width: 152, child: _StatPill(label: 'Saving', value: saving, color: AppColors.amber)),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Safety score card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: context.lineColor),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(96, 96),
                      painter: GaugePainter(
                        fraction: score.score / 100,
                        color: _scoreColor(score.status),
                        trackColor: context.surface2,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${score.score}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
                        Text('/ 100', style: TextStyle(fontSize: 10, color: context.inkFaint)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: _scoreColor(score.status)),
                        const SizedBox(width: 6),
                        Text(score.status,
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15, color: _scoreColor(score.status))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(score.reasons.join(' '),
                        style: TextStyle(fontSize: 12.5, color: context.inkSoft, height: 1.5)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Quick actions
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Expanded(
                  child: _QuickBtn(
                      icon: Icons.add,
                      label: 'Pemasukan',
                      color: AppColors.emerald,
                      onTap: () => showAddTransactionSheet(context, initialIsIncome: true))),
              const SizedBox(width: 8),
              Expanded(
                  child: _QuickBtn(
                      icon: Icons.remove,
                      label: 'Pengeluaran',
                      color: AppColors.coral,
                      onTap: () => showAddTransactionSheet(context, initialIsIncome: false))),
              const SizedBox(width: 8),
              Expanded(
                  child: _QuickBtn(
                      icon: Icons.swap_horiz,
                      label: 'Transfer',
                      color: AppColors.azure,
                      onTap: () => showTransferSheet(context))),
              const SizedBox(width: 8),
              Expanded(
                  child: _QuickBtn(
                      icon: Icons.bar_chart,
                      label: 'Laporan',
                      color: AppColors.violet,
                      onTap: () => ref.read(currentTabProvider.notifier).state = 3)),
            ],
          ),
        ),

        SectionHeader(title: 'Akun Saya'),
        SizedBox(
          height: 92,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ...appState.accounts.map((a) {
                final t = findAccountType(a.type);
                return GestureDetector(
                  onTap: () => showAccountSheet(context, existing: a),
                  child: Container(
                    width: 138,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.lineColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Color(t.colorValue).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(t.emoji, style: const TextStyle(fontSize: 16)),
                        ),
                        const Spacer(),
                        Text(a.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.inkSoft)),
                        Text(fmtRp(a.balance),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 13.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              }),
              GestureDetector(
                onTap: () => showAccountSheet(context),
                child: Container(
                  width: 92,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.lineColor, style: BorderStyle.solid),
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, color: context.inkFaint),
                      const SizedBox(height: 4),
                      Text('Akun', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.inkFaint)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        SectionHeader(
          title: 'Transaksi Terbaru',
          actionLabel: recentTop.isNotEmpty ? 'Lihat semua' : null,
          onAction: () => ref.read(currentTabProvider.notifier).state = 1,
        ),
        if (recentTop.isEmpty)
          const EmptyState(glyph: '📝', text: 'Belum ada transaksi. Ketuk tombol + untuk mulai mencatat.')
        else
          ...recentTop.map((t) => TxListTile(
                tx: t,
                accounts: appState.accounts,
                onTap: () => showTxActionSheet(context, t),
              )),
      ],
    );
  }

  Color _scoreColor(String status) {
    if (status == 'Sangat Aman' || status == 'Aman') return AppColors.emerald;
    if (status == 'Perlu Waspada') return AppColors.amber;
    return AppColors.coral;
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _StatPill({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.lineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: context.inkFaint, letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 6),
          Text(fmtRp(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 13.5, color: color)),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.lineColor),
        ),
        child: Column(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 7),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.inkSoft)),
          ],
        ),
      ),
    );
  }
}
