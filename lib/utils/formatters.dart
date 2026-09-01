import 'package:intl/intl.dart';

String _thousands(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  final len = s.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

String fmtRp(num value) {
  final isNeg = value < 0;
  final rounded = value.abs().round();
  return (isNeg ? '-Rp' : 'Rp') + _thousands(rounded);
}

String fmtNum(num value) => _thousands(value.round());

String todayIso() {
  final d = DateTime.now();
  return DateFormat('yyyy-MM-dd').format(d);
}

String nowTimeString() {
  final d = DateTime.now();
  return DateFormat('HH:mm').format(d);
}

String fmtDateLabel(String iso) {
  final d = DateTime.parse(iso);
  final today = DateTime.now();
  final todayIsoStr = DateFormat('yyyy-MM-dd').format(today);
  final yesterday = today.subtract(const Duration(days: 1));
  final yestIsoStr = DateFormat('yyyy-MM-dd').format(yesterday);

  if (iso == todayIsoStr) return 'Hari Ini';
  if (iso == yestIsoStr) return 'Kemarin';

  const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  return '${days[d.weekday % 7]}, ${d.day} ${months[d.month - 1]} ${d.year}';
}

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Selamat pagi 👋';
  if (h < 15) return 'Selamat siang ☀️';
  if (h < 18) return 'Selamat sore 🌤️';
  return 'Selamat malam 🌙';
}

String topBarDateLabel() {
  final now = DateTime.now();
  const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
  const months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli',
    'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];
  final dayName = days[now.weekday % 7];
  final timeStr = DateFormat('HH:mm').format(now);
  return '$dayName, ${now.day} ${months[now.month - 1]} · $timeStr';
}
