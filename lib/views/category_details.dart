import 'dart:math';

import 'package:dio/dio.dart';
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
  late List<CatchupCategory> categories;
  late List<int> transactionsByDate;
  late int numOfDays;
  bool isLoading = false;
  DateTime firstDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime lastDate =
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0);

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

    transactions = await CatchupDatabase.instance
        .getTransactionFromToDate(widget.category.id!, firstDate, lastDate);
    transactionsByDate = await CatchupDatabase.instance
        .getAggregateSumFromToDate(widget.category.id!, firstDate, lastDate);

    maxDailyAmount = transactionsByDate.reduce(max);
    numOfDays = transactionsByDate.length;
    categories = await CatchupDatabase.instance.getAllCategories();
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
          isLoading
              ? const Text("Loading graph")
              : Container(
                  height: 300,
                  width: 500,
                  padding: const EdgeInsets.only(right: 8, top: 8, left: 8),
                  child: BarChart(BarChartData(
                    maxY: maxDailyAmount / 100 * 1.1,
                    titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              if (transactionsByDate[value.toInt()] == 0 &&
                                  value.toInt() != 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                DateFormat("MM/dd").format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        value.toInt() * 1000)),
                                style: const TextStyle(color: Colors.black),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              return Text("\$${value.toInt()}");
                            },
                          ),
                        )),
                    barGroups: [
                      for (final (index, value) in transactionsByDate.indexed)
                        BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value / 100,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        ),
                    ],
                  )),
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
                    onChanged: (value) async {
                      setState(() {
                        isLoading = true;
                      });
                      selectedRange = value.toString();

                      switch (selectedRange) {
                        case "This month":
                          // get first date of current month
                          DateTime now = DateTime.now();
                          firstDate = DateTime(now.year, now.month, 1);

                          // get last date of current month
                          lastDate = DateTime(now.year, now.month + 1, 0);

                          break;
                        case "Last month":
                          // get first date of last month
                          DateTime now = DateTime.now();
                          firstDate = DateTime(now.year, now.month - 1, 1);

                          // get last date of last month
                          lastDate = DateTime(now.year, now.month, 0);
                          break;
                        case "Custom range":
                          DateTimeRange? picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                              helpText: "Select date range");

                          firstDate = picked!.start;
                          lastDate = picked.end;
                          break;
                      }

                      refreshTransactions();

                      setState(() {
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

    return GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => SwitchCategoryPopup(
                transactions[index], widget.category, refreshTransactions),
          );
        },
        child: Card(
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
        )));
  }
}

class SwitchCategoryPopup extends StatefulWidget {
  final CatchupTransaction transaction;
  final CatchupCategory category;
  final Function refreshTransactions;

  const SwitchCategoryPopup(
      this.transaction, this.category, this.refreshTransactions,
      {super.key});

  @override
  _SwitchCategoryPopupState createState() => _SwitchCategoryPopupState();
}

class _SwitchCategoryPopupState extends State<SwitchCategoryPopup> {
  late List<CatchupCategory> categories;
  String suggestedCategory = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadSuggestions();
  }

  Future loadSuggestions() async {
    setState(() => isLoading = true);
    categories = await CatchupDatabase.instance.getAllCategories();

    final uri = Uri.parse("http://35.21.132.37:8000/recommendation");
    var dio = Dio();

    Response<Map> response = await dio.postUri(uri, data: {
      "description": widget.transaction.description,
      "categories": categories.map((e) => e.name).toList()
    });

    Map<dynamic, dynamic> data = response.data!;
    suggestedCategory = data["data"];
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const AlertDialog(
        title: Text("Loading"),
      );
    }

    return AlertDialog(
      title: Text(widget.transaction.description),
      content: SizedBox(
        height: 300.0,
        width: 300.0,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: categories.length,
          itemBuilder: (context, catIndex) {
            // ignore the current category and the "Uncategorized" category
            if (categories[catIndex].id == widget.category.id ||
                categories[catIndex].id == 1) {
              return const SizedBox.shrink();
            }
            return ListTile(
              title: Text(categories[catIndex].name),
              tileColor: categories[catIndex].name.contains(suggestedCategory)
                  ? Colors.green
                  : null,
              onTap: () async {
                await CatchupDatabase.instance.updateTransactionCategory(
                    widget.transaction.id!, categories[catIndex].id!);
                await widget.refreshTransactions();
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    );
  }
}
