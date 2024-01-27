import 'package:flutter/material.dart';
import 'package:mobile/models/category.dart';

import '../database.dart';

class CategoryDetailsPage extends StatefulWidget {
  final CatchupCategory category;

  const CategoryDetailsPage(this.category, {super.key});

  @override
  State<CategoryDetailsPage> createState() => _CategoryDetailsState();
}

class _CategoryDetailsState extends State<CategoryDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.category.name), actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {},
        ),
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
}
