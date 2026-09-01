import 'package:flutter/material.dart';

import '../models.dart';
import '../providers/app_state.dart';
import '../theme.dart';
import '../utils/categories.dart';
import '../utils/formatters.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({super.key, required this.title, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String glyph;
  final String text;
  const EmptyState({super.key, required this.glyph, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Column(
        children: [
          Text(glyph, style: const TextStyle(fontSize: 38)),
          const SizedBox(height: 10),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, color: context.inkFaint, height: 1.5)),
        ],
      ),
    );
  }
}

class TxListTile extends StatelessWidget {
  final AppTransaction tx;
  final List<Account> accounts;
  final VoidCallback onTap;

  const TxListTile({super.key, required this.tx, required this.accounts, required this.onTap});

  Account? _acc(String id) {
    try {
      return accounts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tx.type == TxType.transfer) {
      final from = _acc(tx.accountId);
      final to = tx.toAccountId != null ? _acc(tx.toAccountId!) : null;
      return _tile(
        context,
        icon: const Icon(Icons.swap_horiz, color: AppColors.azure, size: 18),
        iconBg: AppColors.azureSoftLight,
        title: 'Transfer',
        subtitle: '${from?.name ?? '?'} → ${to?.name ?? '?'}${tx.note.isNotEmpty ? ' · ${tx.note}' : ''}',
        amountText: fmtRp(tx.amount),
        amountColor: AppColors.azure,
      );
    }
    final isIncome = tx.type == TxType.income;
    final cat = findCategory(isIncome ? incomeCategories : expenseCategories, tx.category);
    final acc = _acc(tx.accountId);
    final color = Color(cat.colorValue);
    return _tile(
      context,
      icon: Text(cat.emoji, style: const TextStyle(fontSize: 17)),
      iconBg: color.withOpacity(0.12),
      title: cat.name,
      subtitle: '${acc?.name ?? ''}${tx.note.isNotEmpty ? ' · ${tx.note}' : ''}',
      amountText: '${isIncome ? '+' : '-'}${fmtRp(tx.amount)}',
      amountColor: isIncome ? AppColors.emerald : AppColors.coral,
      timeText: tx.time,
    );
  }

  Widget _tile(
    BuildContext context, {
    required Widget icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String amountText,
    required Color amountColor,
    String? timeText,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.lineColor),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 1),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.inkFaint)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amountText,
                    style: TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: amountColor)),
                if (timeText != null)
                  Text(timeText, style: TextStyle(fontSize: 10.5, color: context.inkFaint)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular arc gauge used for the Safety Score, matching the web app.
class GaugePainter extends CustomPainter {
  final double fraction; // 0..1
  final Color color;
  final Color trackColor;

  GaugePainter({required this.fraction, required this.color, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 10) / 2;
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    const startAngle = 0.75 * 3.14159265; // 135deg
    const sweepFull = 1.5 * 3.14159265; // 270deg
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepFull, false, trackPaint);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepFull * fraction, false, fgPaint);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
