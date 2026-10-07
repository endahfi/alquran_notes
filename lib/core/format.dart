const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Contoh: 6 Okt 2026
String formatDate(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';
