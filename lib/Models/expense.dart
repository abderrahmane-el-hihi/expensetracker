import 'package:isar/isar.dart';

part 'expense.g.dart';

@Collection()
class Expense {
  Id id = Isar.autoIncrement;
  final String name;
  final DateTime date;
  final double amount;
  Expense({
    required this.name,
    required this.date,
    required this.amount,
  });
}
