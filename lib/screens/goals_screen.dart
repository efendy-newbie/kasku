import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';
import '../widgets/goal_sheet.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final goals = appState.goals;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Target Tabungan', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            TextButton(
              onPressed: () => showGoalSheet(context),
              child: const Text('+ Tambah', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (goals.isEmpty)
          const EmptyState(
            glyph: '🎯',
            text: 'Belum ada target tabungan. Buat target pertamamu, misalnya untuk laptop atau liburan.',
          )
        else
          ...goals.map((g) {
            final pct = (g.current / g.target * 100).clamp(0, 100).round();
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.lineColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5)),
                            const SizedBox(height: 2),
                            Text(g.deadline.isEmpty ? 'Tanpa batas waktu' : 'Target: ${g.deadline}',
                                style: TextStyle(fontSize: 11.5, color: context.inkFaint)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: AppColors.amberSoftLight, borderRadius: BorderRadius.circular(100)),
                        child: Text('$pct%', style: const TextStyle(color: AppColors.amber, fontWeight: FontWeight.w700, fontSize: 12.5)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: pct / 100,
                      minHeight: 10,
                      backgroundColor: context.surface2,
                      valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(fmtRp(g.current), style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 12.5)),
                      Text('dari ${fmtRp(g.target)}', style: TextStyle(fontFamily: 'monospace', fontSize: 12.5, color: context.inkFaint)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => showGoalSheet(context, existing: g),
                          child: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: AppColors.emerald),
                          onPressed: () => showFundGoalSheet(context, g),
                          child: const Text('+ Tambah Dana'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
