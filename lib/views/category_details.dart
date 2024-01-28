import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/models/transaction.dart';
import 'package:fl_chart/fl_chart.dart';
import '../database.dart';
import 'create_transaction.dart';

class CategoryDetailsPage extends StatefulWidget {
  // Receive the category as a parameter
  final CatchupCategory category;

  const CategoryDetailsPage(this.category, {super.key});

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsState();
}

class _CategoryDetailsState extends State<CategoryDetailsPage> {
  late int amountSpent;
  late int maxDailyAmount;
  late List<CatchupTransaction> transactions;
  late List<int> transactionsByDate;
  bool isLoading = false;

  String selectedRange = "This month";

  @override
  void initState() {
    super.initState();
    refreshTransactions();
  }

  Future refreshTransactions() async {
    setState(() => isLoading = true);

    amountSpent =
        await CatchupDatabase.instance.getCurrentMonthSum(widget.category.id!);

    switch (selectedRange) {
      case "This month":
        // get first date of current month
        DateTime now = DateTime.now();
        DateTime firstDate = DateTime(now.year, now.month, 1);

        // get last date of current month
        DateTime lastDate = DateTime(now.year, now.month + 1, 0);

        transactions = await CatchupDatabase.instance
            .getTransactionFromToDate(widget.category.id!, firstDate, lastDate);
        break;
      case "Last month":
        // get first date of last month
        DateTime now = DateTime.now();
        DateTime firstDate = DateTime(now.year, now.month - 1, 1);

        // get last date of last month
        DateTime lastDate = DateTime(now.year, now.month, 0);

        transactions = await CatchupDatabase.instance
            .getTransactionFromToDate(widget.category.id!, firstDate, lastDate);
        break;
      case "Custom range":
        DateTime? startDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            helpText: "Select start date");
        DateTime? endDate = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            helpText: "Select end date");

        transactions = await CatchupDatabase.instance.getTransactionFromToDate(
            widget.category.id!, startDate!, endDate!);
    }

    transactionsByDate = await CatchupDatabase.instance
        .getCurrentMonthTransactionSumByDay(widget.category.id!);

    maxDailyAmount = transactionsByDate.reduce(max);

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          (widget.category.spendLimit != 0)
              ? Text(
                  "Limit: \$${(widget.category.spendLimit / 100).toStringAsFixed(2)}")
              : const Text("No limit set"),
          isLoading
              ? const Text("Amount spent: Loading")
              : Text(
                  "Amount spent: \$${(amountSpent / 100).toStringAsFixed(2)}"),
          Visibility(
            visible: widget.category.id != 1,
            child: isLoading
                ? const Text("Loading chart")
                : SizedBox(
                    height: 300,
                    width: 500,
                    child: LineChart(LineChartData(
                      minX: 0,
                      maxX: 31,
                      minY: 0,
                      maxY: maxDailyAmount / 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (final (index, value)
                                in transactionsByDate.indexed)
                              FlSpot(index.toDouble(), value / 100)
                          ],
                          belowBarData:
                              BarAreaData(show: true, color: Colors.green),
                        ),
                      ],
                    )),
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[300],
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Transactions')),
                DropdownButton(
                    value: selectedRange,
                    items: <String>['This month', 'Last month', 'Custom range']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        isLoading = true;
                        selectedRange = value.toString();
                        refreshTransactions();
                        isLoading = false;
                      });
                    }),
              ],
            ),
          ),
          const SizedBox(
            height: 8,
          ),
          isLoading
              ? const ListTile(title: Text("Loading"))
              : Expanded(
                  child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: transactions.length,
                  itemBuilder: buildTransactions,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                )),
        ],
      ),
      appBar: AppBar(title: Text(widget.category.name), actions: <Widget>[
        IconButton(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CreateTransactionPage(widget.category)));
              // When the user returns, refresh the categories list
              refreshTransactions();
            },
            icon: const Icon(Icons.add)),
        Visibility(
          visible: widget.category.id != 1,
          child: IconButton(
              icon: const Icon(Icons.delete),
              // When the delete button is pressed, show a dialog to confirm the action
              // If the user confirms, delete the category and go back to the previous page
              onPressed: () async {
                String? action = await showDialog<String>(
                  context: context,
                  builder: (BuildContext context) => AlertDialog(
                    title: const Text("Confirmation"),
                    content: Text(
                        "Are you sure that you want to delete the ${widget.category.name} category?"),
                    actions: <Widget>[
                      TextButton(
                          onPressed: () => Navigator.pop(context, "cancel"),
                          child: const Text("Cancel")),
                      TextButton(
                          onPressed: () => Navigator.pop(context, "delete"),
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          )),
                    ],
                  ),
                );
                if (action == "delete") {
                  await CatchupDatabase.instance
                      .deleteCategory(widget.category.id!);
                  Navigator.pop(context);
                }
              }),
        ),
      ]),
    );
  }

  Widget buildTransactions(BuildContext context, int index) {
    String transactionDate =
        DateFormat("yyyy-MM-dd - HH:mm:ss").format(transactions[index].date);

    String transactionAmount =
        (transactions[index].amount / 100).toStringAsFixed(2);

    return Card(
        child: ListTile(
      title: Text("\$$transactionAmount"),
      subtitle: Text(transactionDate),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: () async {
          String? action = await showDialog<String>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text("Confirmation"),
              content: Text(
                  "Are you sure that you want to delete the \$$transactionAmount transaction on $transactionDate?"),
              actions: <Widget>[
                TextButton(
                    onPressed: () => Navigator.pop(context, "cancel"),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(context, "delete"),
                    child: const Text(
                      "Delete",
                      style: TextStyle(color: Colors.red),
                    )),
              ],
            ),
          );
          if (action == "delete") {
            await CatchupDatabase.instance
                .deleteTransaction(transactions[index].id!);
            refreshTransactions();
          }
        },
      ),
    ));
  }
}
