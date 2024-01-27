import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile/database.dart';
import 'package:mobile/models/category.dart';
import 'package:mobile/models/transaction.dart';

class CreateTransactionPage extends StatefulWidget {
  final CatchupCategory category;

  const CreateTransactionPage(this.category, {super.key});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionState();
}

class _CreateTransactionState extends State<CreateTransactionPage> {
  final numberController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Create transaction"),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: <Widget>[
            Flexible(
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            disabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)),
                            filled: true,
                            labelText: "Category name"),
                        initialValue: widget.category.name,
                        readOnly: true,
                        enableInteractiveSelection: false,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(), labelText: "Amount"),
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
                            return "Please enter a valid amount";
                          }
                          return null;
                        },
                      ),
                    ],
                  )),
            ),
            // The ElevatedButton is used to submit the form
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // convert the number to cents
                  int amount =
                      (double.parse(numberController.text) * 100).round();
                  await CatchupDatabase.instance.createTransaction(
                      CatchupTransaction(
                          amount: amount,
                          date: DateTime.now(),
                          categoryId: widget.category.id!));
                  // close the page and return to the previous page
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(16)),
              child: const Icon(Icons.add),
            )
          ]),
        ));
  }
}
