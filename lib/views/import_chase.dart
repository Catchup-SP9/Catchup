import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../database.dart';
import '../models/transaction.dart';

class ImportChaseTransactionsPage extends StatefulWidget {
  const ImportChaseTransactionsPage({Key? key}) : super(key: key);

  @override
  State<ImportChaseTransactionsPage> createState() =>
      _ImportChaseTransactionsState();
}

class _ImportChaseTransactionsState extends State<ImportChaseTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Import Chase transactions"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text("Import transactions from Chase"),
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: <Widget>[
                    Expanded(
                        child: ElevatedButton(
                            onPressed: () {
                              final Uri url = Uri.parse(
                                  "https://secure.chase.com/web/auth/dashboard#/dashboard/documents/myDocs/index;mode=documents");
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
                                allowedExtensions: ['pdf'],
                              );

                              if (result != null) {
                                final file = File(result.files.single.path!)
                                    .readAsBytesSync();

                                final uri = Uri.parse(
                                    "http://35.21.132.37:8000/parse/chase");

                                var dio = Dio();
                                FormData formData = FormData.fromMap({
                                  "file": MultipartFile.fromBytes(file,
                                      filename: result.files.single.name),
                                });
                                Response<Map> response =
                                    await dio.postUri(uri, data: formData);
                                Map<dynamic, dynamic> data = response.data!;
                                for (final transaction in data['data']) {
                                  await CatchupDatabase.instance
                                      .createTransaction(CatchupTransaction(
                                          amount: transaction["amount"],
                                          date: DateTime
                                              .fromMillisecondsSinceEpoch(
                                                  transaction["date"]),
                                          categoryId: 1,
                                          description:
                                              transaction["description"],
                                          originalTransactionId:
                                              transaction["hash"]));
                                }
                              }
                            },
                            child: const Text("Import"))),
                  ],
                ),
                const Text("Instructions:"),
                const Text(
                    "Download account statements from Chase in the PDF format. The 'Download' button will open the Chase website in a new tab. Once you have downloaded the file, click 'Import' to import the transactions into Catchup."),
              ],
            )));
  }
}
