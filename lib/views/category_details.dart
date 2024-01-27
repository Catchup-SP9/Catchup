import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/models/transaction.dart';

import '../database.dart';

class CategoryDetailsPage extends StatefulWidget {
  // Receive the category as a parameter
  final CatchupCategory category;

  const CategoryDetailsPage(this.category, {super.key});

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsState();
}

class _CategoryDetailsState extends State<CategoryDetailsPage> {
  late int amountSpent;
  late List<CatchupTransaction> transactions;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    refreshAmountSpent();
  }

  Future refreshAmountSpent() async {
    setState(() => isLoading = true);

    amountSpent =
        await CatchupDatabase.instance.getCurrentMonthSum(widget.category.id!);

    transactions = await CatchupDatabase.instance
        .getCurrentMonthTransactions(widget.category.id!);

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
          const Text("Transactions:"),
          const ListTile(
            title: Text('Transaction Details'),
            selectedTileColor: Colors.grey,
            selectedColor: Colors.white,
            selected: true,
          ),
          const SizedBox(
            height: 8,
          ),
          isLoading
              ? const ListTile(title: Text("Loading"))
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: transactions.length,
                  itemBuilder: buildTransactions,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                ),
        ],
      ),
      appBar: AppBar(title: Text(widget.category.name), actions: <Widget>[
        IconButton(
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
            refreshAmountSpent();
          }
        },
      ),
    ));
  }
}
