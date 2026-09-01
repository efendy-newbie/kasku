class SafetyScoreResult {
  final int score;
  final String status; // Sangat Aman / Aman / Perlu Waspada / Berisiko
  final List<String> reasons;

  SafetyScoreResult({
    required this.score,
    required this.status,
    required this.reasons,
  });
}

/// income/expense are for the current month; totalBalance is across all
/// accounts; daysWithTx is the number of distinct days this month that have
/// at least one transaction; dayOfMonth is today's day-of-month number.
SafetyScoreResult computeSafetyScore({
  required double income,
  required double expense,
  required double totalBalance,
  required int daysWithTx,
  required int dayOfMonth,
}) {
  final saving = (income - expense) < 0 ? 0.0 : (income - expense);
  final reasons = <String>[];

  double savingScore;
  if (income > 0) {
    savingScore = ((saving / income) / 0.3).clamp(0.0, 1.0) * 40;
  } else {
    savingScore = 20;
  }
  if (income > 0 && (saving / income) < 0.15) {
    reasons.add('Tabunganmu di bawah 15% dari pemasukan bulan ini.');
  }

  double expenseScore = 30;
  if (income > 0) {
    final ratio = expense / income;
    if (ratio <= 0.7) {
      expenseScore = 30;
    } else if (ratio >= 1.3) {
      expenseScore = 0;
    } else {
      expenseScore = 30 * (1 - (ratio - 0.7) / 0.6);
    }
    if (ratio > 0.9) {
      reasons.add('Pengeluaran sudah mendekati atau melebihi pemasukan bulan ini.');
    }
  }

  final consistency =
      (daysWithTx / (dayOfMonth * 0.3).clamp(1, double.infinity)).clamp(0.0, 1.0) * 15;
  if (consistency < 8) {
    reasons.add('Konsistensi mencatat masih rendah, coba catat tiap hari.');
  }

  final avgExpense = expense > 0 ? expense : 1;
  final emergencyMonths = totalBalance / avgExpense;
  final emergencyScore = (emergencyMonths / 3).clamp(0.0, 1.0) * 15;
  if (emergencyMonths < 1) {
    reasons.add('Dana daruratmu kurang dari 1 bulan pengeluaran.');
  }

  int score = (savingScore + expenseScore + consistency + emergencyScore).round();
  score = score.clamp(0, 100);

  String status;
  if (score >= 90) {
    status = 'Sangat Aman';
  } else if (score >= 70) {
    status = 'Aman';
  } else if (score >= 50) {
    status = 'Perlu Waspada';
  } else {
    status = 'Berisiko';
  }

  if (reasons.isEmpty) {
    reasons.add('Kondisi keuanganmu bulan ini terlihat sehat. Pertahankan!');
  }

  return SafetyScoreResult(
    score: score,
    status: status,
    reasons: reasons.take(2).toList(),
  );
}
