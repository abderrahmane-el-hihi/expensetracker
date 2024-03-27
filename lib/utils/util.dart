import 'package:intl/intl.dart';

String formatAmount(double amount) {
  final format = NumberFormat.currency(decimalDigits: 2, symbol: "MAD");
  return format.format(amount);
}

double convertingToDouble(String source) {
  double? amount = double.tryParse(source);
  return amount ?? 0;
}

int claculateMonthCount(int startYear, startMonth, currentYear, currentMonth) {
  int monthCount =
      (currentYear - startYear) * 12 + currentMonth - startMonth + 1;
  return monthCount;
}

String getCurrentMonthName() {
  DateTime now = DateTime.now();
  List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "Mai",
    "Jui",
    "jul",
    "Aug",
    "Sep",
    "Oct",
    "Mov",
    "Dec",
  ];
  return months[now.month - 1];
}
