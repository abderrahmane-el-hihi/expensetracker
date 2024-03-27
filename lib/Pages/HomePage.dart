import 'package:expensetracker/Database/expense_database.dart';
import 'package:expensetracker/Models/expense.dart';
import 'package:expensetracker/graph/bar_graph.dart';
import 'package:expensetracker/utils/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //text controllers
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  Future<Map<String, double>>? _monthlyTotalsFuture;
  Future<double>? _claculateCurrentMonthTotal;

  @override
  void initState() {
    //read db
    Provider.of<ExpenseDatabase>(context, listen: false).readExpenses();

    //load  futures
    refreshGraphData();
    super.initState();
  }

  void refreshGraphData() {
    _monthlyTotalsFuture = Provider.of<ExpenseDatabase>(context, listen: false)
        .calculateMonthlyTotals();
    _claculateCurrentMonthTotal =
        Provider.of<ExpenseDatabase>(context, listen: false)
            .calculateCurrentMonthTotals();
  }

  //new expense box
  void openNewExpenseBox() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("new Expense"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(hintText: 'Name'),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(hintText: 'Amount'),
                  ),
                ],
              ),
              actions: [
                //cancel
                _cancelButton(),
                //save
                _createNewExpenseButton(),
              ],
            ));
  }

  void onEditPressed(Expense expense) {
    String existingname = expense.name;
    String existingamount = expense.amount.toString();

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Edit Expense"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(hintText: existingname),
                  ),
                  TextField(
                    controller: amountController,
                    decoration: InputDecoration(hintText: existingamount),
                  ),
                ],
              ),
              actions: [
                //cancel
                _cancelButton(),
                //save
                _editExpenseButton(expense),
              ],
            ));
  }

  void onDeletePressed(Expense expense) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text("Delete Expense"),
              actions: [
                //cancel
                _cancelButton(),
                //save
                _deleteExpenseButton(expense.id),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExpenseDatabase>(builder: (context, value, child) {
      int startMonth = value.getStartMonth();
      int startYear = value.getStartYear();
      int currentMonth = DateTime.now().month;
      int currentYear = DateTime.now().year;
      int monthCount =
          claculateMonthCount(startYear, startMonth, currentYear, currentMonth);
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        appBar: AppBar(
          centerTitle: true,
          elevation: 1,
          title: FutureBuilder<double>(
            future: _claculateCurrentMonthTotal,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(snapshot.data!.toStringAsFixed(2) + "MAD"),
                    Text(getCurrentMonthName()),
                  ],
                );
              } else {
                return const Text("Loading...");
              }
            },
          ),
          backgroundColor: Colors.deepPurple.shade50,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: openNewExpenseBox,
          child: const Icon(Icons.add),
        ),
        body: SafeArea(
          child: Column(
            children: [
              //Graph UI
              SizedBox(
                height: MediaQuery.of(context).size.height * .015,
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .2,
                child: FutureBuilder(
                  future: _monthlyTotalsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      Map<String, double> monthlyTotals = snapshot.data ?? {};
                      List<double> monthlySummary =
                          List.generate(monthCount, (index) {
                        int year = startYear + (startMonth + index - 1) ~/ 12;
                        int month = (startMonth + index - 1) % 12 + 1;
                        String yearMonthKey = '$year-$month';
                        return monthlyTotals[yearMonthKey] ?? 0.0;
                      });

                      return BarGraph(
                          monthlySummary: monthlySummary,
                          startMonth: startMonth);
                    } else {
                      return const Center(
                        child: Text("Loading..."),
                      );
                    }
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height * .04,
              ),
              //Expanses List UI
              Expanded(
                child: ListView.builder(
                  itemBuilder: (context, index) {
                    Expense individualExpense = value.allExpense[index];
                    return Slidable(
                      endActionPane: ActionPane(
                        motion: const StretchMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (context) =>
                                onEditPressed(individualExpense),
                            icon: Icons.settings,
                            foregroundColor: Colors.orange,
                            backgroundColor:
                                const Color.fromARGB(27, 255, 153, 0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          SlidableAction(
                            onPressed: (context) =>
                                onDeletePressed(individualExpense),
                            icon: Icons.delete,
                            foregroundColor: Colors.red,
                            backgroundColor:
                                const Color.fromARGB(27, 244, 67, 54),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 25),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(individualExpense.name),
                            trailing:
                                Text(formatAmount(individualExpense.amount)),
                          ),
                        ),
                      ),
                    );
                  },
                  itemCount: value.allExpense.length,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _createNewExpenseButton() {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty &&
            amountController.text.isNotEmpty) {
          Navigator.pop(context);
          Expense newExpense = Expense(
              name: nameController.text,
              date: DateTime.now(),
              amount: convertingToDouble(amountController.text));

          await context.read<ExpenseDatabase>().createNewExpense(newExpense);
          refreshGraphData();
          nameController.clear();
          amountController.clear();
        }
      },
      child: Text('Save'),
    );
  }

  Widget _cancelButton() {
    return MaterialButton(
      onPressed: () {
        Navigator.pop(context);
        nameController.clear();
        amountController.clear();
      },
      child: Text('Cancel'),
    );
  }

  Widget _editExpenseButton(Expense expense) {
    return MaterialButton(
      onPressed: () async {
        if (nameController.text.isNotEmpty ||
            amountController.text.isNotEmpty) {
          Navigator.pop(context);
          Expense updatedExpense = Expense(
            name: nameController.text.isNotEmpty
                ? nameController.text
                : expense.name,
            date: DateTime.now(),
            amount: amountController.text.isNotEmpty
                ? convertingToDouble(amountController.text)
                : expense.amount,
          );
          int existingId = expense.id;
          await context
              .read<ExpenseDatabase>()
              .updateExpense(existingId, updatedExpense);
          refreshGraphData();
          nameController.clear();
          amountController.clear();
        }
      },
      child: Text('Edit'),
    );
  }

  Widget _deleteExpenseButton(int id) {
    return MaterialButton(
      onPressed: () async {
        Navigator.pop(context);
        await context.read<ExpenseDatabase>().deleteExpense(id);
        refreshGraphData();
      },
      child: Text('Delete'),
    );
  }
}
