import 'package:flutter/material.dart';
import 'package:mobile/views/import_chase.dart';
import 'package:mobile/views/import_paypal.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ImportTransactionsPage extends StatefulWidget {
  const ImportTransactionsPage({super.key});

  @override
  State<ImportTransactionsPage> createState() => _ImportTransactionsState();
}

class _ImportTransactionsState extends State<ImportTransactionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Import transactions"),
        ),
        body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text("Import transactions from third party apps"),
                const SizedBox(
                  height: 8,
                ),
                ListTile(
                  leading: const Icon(Icons.paypal),
                  title: const Text("Import from Paypal"),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ImportPaypalTransactionsPage()));
                  },
                ),
                ListTile(
                  title: const Text("Import from Chase"),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const ImportChaseTransactionsPage()));
                  },
                  leading: SvgPicture.asset(
                    "assets/chase.svg",
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                        Colors.black, BlendMode.srcIn),
                  ),
                ),
              ],
            )));
  }
}
