import 'dart:io';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database.dart';
import '../models/transaction.dart';

class ImportPaypalTransactionsPage extends StatefulWidget {
  const ImportPaypalTransactionsPage({Key? key}) : super(key: key);

  @override
  State<ImportPaypalTransactionsPage> createState() =>
      _ImportPaypalTransactionsState();
}

class _ImportPaypalTransactionsState
    extends State<ImportPaypalTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Import Paypal transactions"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text("Import transactions from PayPal"),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () {
                              final Uri url = Uri.parse(
                                  "https://www.paypal.com/reports/preview/statements");
                              launchUrl(url);
                            },
                            child: const Text("Download"))),
                    const SizedBox(
                      width: 16,
                    ),
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () async {
                              FilePickerResult? result =
                                  await FilePicker.platform.pickFiles(
                                type: FileType.custom,
                                allowedExtensions: ['csv'],
                              );

                              if (result != null) {
                                final file =
                                    File(result.files.single.path!).openRead();
                                List<List<dynamic>> lines = await file
                                    .transform(utf8.decoder)
                                    .transform(const LineSplitter())
                                    .map((s) => '$s\n')
                                    .skip(1)
                                    .transform(
                                        const CsvToListConverter(eol: '\n'))
                                    .toList();

                                for (final line in lines) {
                                  double amount = double.parse(
                                      line[7].replaceAll(',', ''));

                                  if (amount < 0) {
                                    amount = amount.abs();
                                    String dateString = line[0];
                                    String timeString = line[1];
                                    String dateTimeString =
                                        "$dateString $timeString";
                                    DateTime parsedDate =
                                        DateFormat("M/d/yyyy h:mm:ss")
                                            .parse(dateTimeString);
                                    String originalTransactionId = line[9];
                                    String name = line[11];
                                    await CatchupDatabase.instance
                                        .createTransaction(CatchupTransaction(
                                            amount: (amount * 100).round(),
                                            date: parsedDate,
                                            categoryId: 1,
                                            description: name,
                                            originalTransactionId:
                                                originalTransactionId));
                                    //
                                  }
                                }
                              }
                            },
                            child: const Text("Import"))),
                  ],
                ),
                const Text("Instructions:"),
                const Text(
                    "Download the transaction record from PayPal under the CSV format. The 'Download' button will open the PayPal website in a new tab. Once you have downloaded the file, click 'Import' to import the transactions into Catchup."),
              ],
            )));
  }
}
