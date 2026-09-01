import '../models.dart';

const List<CategoryDef> expenseCategories = [
  CategoryDef('Makan', '🍔', 0xFFD6491F),
  CategoryDef('Minum', '🥤', 0xFF2C9FB5),
  CategoryDef('Transport', '🚗', 0xFF2F6FED),
  CategoryDef('Jajan', '🍪', 0xFFDD8A1E),
  CategoryDef('Belanja', '🛍️', 0xFFC2447A),
  CategoryDef('Pendidikan', '📚', 0xFF6E4FB0),
  CategoryDef('Internet', '🌐', 0xFF1E9E85),
  CategoryDef('Pulsa', '📱', 0xFF4C5FBF),
  CategoryDef('Kesehatan', '💊', 0xFFD6432E),
  CategoryDef('Hiburan', '🎮', 0xFF9145A6),
  CategoryDef('Hadiah', '🎁', 0xFFD0508A),
  CategoryDef('Listrik', '💡', 0xFFC4941A),
  CategoryDef('Air', '💧', 0xFF2599B0),
  CategoryDef('Sewa', '🏠', 0xFF8A6350),
  CategoryDef('Pajak', '🧾', 0xFF69766E),
  CategoryDef('Lainnya', '📦', 0xFF7C877E),
];

const List<CategoryDef> incomeCategories = [
  CategoryDef('Gaji', '💼', 0xFF1B7A4D),
  CategoryDef('Uang Saku', '👝', 0xFF5FA23A),
  CategoryDef('Bonus', '🎉', 0xFFC4981E),
  CategoryDef('Freelance', '💻', 0xFF1E9BA6),
  CategoryDef('THR', '🎊', 0xFFD67A3E),
  CategoryDef('Penjualan', '🛒', 0xFF2E8FCC),
  CategoryDef('Investasi', '📈', 0xFF7052B0),
  CategoryDef('Hadiah', '🎁', 0xFFC24E82),
];

const List<CategoryDef> accountTypes = [
  CategoryDef('Tunai', '💵', 0xFF8A6350),
  CategoryDef('E-Wallet', '📲', 0xFF5C2D91),
  CategoryDef('Bank', '🏦', 0xFF1F5FA8),
  CategoryDef('Tabungan', '🐷', 0xFFC4801A),
  CategoryDef('Investasi', '📊', 0xFF6E4FB0),
];

CategoryDef findCategory(List<CategoryDef> list, String name) {
  return list.firstWhere(
    (c) => c.name == name,
    orElse: () => list.last,
  );
}

CategoryDef findAccountType(String typeName) {
  return accountTypes.firstWhere(
    (c) => c.name == typeName,
    orElse: () => accountTypes.first,
  );
}
