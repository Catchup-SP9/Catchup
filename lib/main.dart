import 'package:flutter/material.dart';

void main() {
  runApp(const CatchupApp());
}

class CatchupApp extends StatelessWidget {
  const CatchupApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catchup',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Catchup'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}
/*hui
huina
huevo
 */
class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Catchup",
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Catchup"),
        ),
        body: ListView(
          children: const <Widget>[
            Card(
              child: ListTile(
                title: Text('Groceries'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Education'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Nahui'),
              ),
            ),
            Card(
              child: ListTile(
                title: Text('Blyat'),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
            onPressed: () {}, child: const Icon(Icons.add)),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
