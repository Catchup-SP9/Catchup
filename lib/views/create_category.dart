import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/database.dart';
import 'package:mobile/models/category.dart';

class CreateCategoryPage extends StatefulWidget {
  const CreateCategoryPage({super.key});

  @override
  State<CreateCategoryPage> createState() => _CreateCategoryState();
}

class _CreateCategoryState extends State<CreateCategoryPage> {
  // textController and numberController are used to get the values from the
  // text fields
  final textController = TextEditingController();
  final numberController = TextEditingController();

  // _formKey is used to validate the form
  final _formKey = GlobalKey<FormState>();

  // Override dispose to close the controllers when the page is closed
  @override
  void dispose() {
    textController.dispose();
    numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Create category"),
        ),
        body: Padding(
          // Padding is used to add some space around the form
          padding: const EdgeInsets.all(16),
          child: Column(children: <Widget>[
            Flexible(
              child: Form(
                  key: _formKey,
                  // The form contains two text fields
                  child: Column(
                    children: <Widget>[
                      // The TextFormField is used to get text input from the user
                      // for the category name
                      TextFormField(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: "Category name"),
                        controller: textController,
                        autofocus: true,
                        // Validate the input to make sure it is not empty
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter a category name";
                          }
                          return null;
                        },
                      ),
                      // SizedBox is used to add some space between the two text fields
                      const SizedBox(height: 8),
                      // The second TextFormField is used to get the spending limit
                      TextFormField(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: "Limit"),
                        controller: numberController,
                        // only allow numbers to be entered
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^[0-9]+\.?[0-9]{0,2}'))
                        ],
                        // ensure that the input is not empty
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            numberController.text = "0";
                          }
                          return null;
                        },
                      ),
                      const Text("Leave this field empty for no limit"),
                    ],
                  )),
            ),
            // The ElevatedButton is used to submit the form
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // convert the number to cents
                  int spendingLimit =
                      (double.parse(numberController.text) * 100).round();
                  // create the category
                  await CatchupDatabase.instance.createCategory(CatchupCategory(
                      name: textController.text.trim(),
                      spendLimit: spendingLimit));
                  // close the page and return to the previous page
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  foregroundColor: Colors.white,
                  backgroundColor: const Color(0xff18453B).withOpacity(0.90),
                  padding: const EdgeInsets.all(16)),
              child: const Icon(Icons.add),
            )
          ]),
        ));
  }
}
