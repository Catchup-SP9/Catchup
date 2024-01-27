import 'package:flutter/material.dart';
import 'package:mobile/database.dart';
import 'package:mobile/views/category_details.dart';
import 'package:mobile/views/create_category.dart';
import 'package:mobile/views/create_transaction.dart';

import 'models/category.dart';

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff18453B)),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xff18453B),
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(title: 'Catchup'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late List<CatchupCategory> categories;
  bool isLoading = false;

  // Override initState to call refreshCategories when the app starts
  @override
  void initState() {
    super.initState();
    refreshCategories();
  }

  // Override dispose to close the database when the app is closed
  @override
  void dispose() {
    CatchupDatabase.instance.close();
    super.dispose();
  }

  // refreshCategories is a method that will refresh the categories list
  // the isLoading variable is used to show a loading indicator
  // and prevent the user from interacting with the app while the database is being queried
  Future refreshCategories() async {
    setState(() => isLoading = true);

    categories = await CatchupDatabase.instance.getAllCategories();

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catchup"),
        actions: <Widget>[
          IconButton(
              onPressed: () {}, icon: const Icon(Icons.upload_file_outlined))
        ],
      ),
      // If the app is loading, show a loading text
      body: isLoading
          ? const Center(child: Text("Loading"))
          // then check if the categories list is empty
          : categories.isEmpty
              // if it is empty, show a text to add a category
              ? const Center(
                  child: Text("It is lonely here, maybe add a category?"),
                )
              // if it is not empty, show the list of categories
              // ListView.builder is used to build a list of widgets from a list of data
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 100),
                  itemCount: categories.length,
                  itemBuilder: buildCategories),
      // The floating button at the bottom of the screen
      floatingActionButton: FloatingActionButton(
          shape: const CircleBorder(),
          onPressed: () async {
            // When the button is pressed, navigate to the CreateCategoryPage
            // and wait for the user to return
            await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const CreateCategoryPage()),
            );
            // When the user returns, refresh the categories list
            refreshCategories();
          },
          child: const Icon(Icons.add)),
      // The position of the floating button
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  double spentPercentage = 0;

  Widget buildCategories(BuildContext context, int index) {
    double spentPercentage;
    if (categories[index].spendLimit != 0) {
      spentPercentage = 1000 /
          (categories[index].spendLimit /
              100); //replace 1000 with transaction sum
    } else {
      spentPercentage = 0;
    } //decide later what to do when limit not set
    // InkWell is a widget that allows us to add a tap event to a widget
    return InkWell(
      child: Card(
          child: ListTile(
        title: Text(categories[index].name),
        subtitle:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Spent: ${(spentPercentage * 100).toStringAsFixed(2)}%'),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: spentPercentage, // Set the progress value here.
            color: Colors.lightGreen, //set logic for color of progress here
          )
        ]),
        trailing: IconButton(
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          CreateTransactionPage(categories[index])));
              // When the user returns, refresh the categories list
              refreshCategories();
            },
            icon: const Icon(Icons.add)),
        onTap: () async {
          // When the category is tapped, navigate to the CategoryDetailsPage
          // and wait for the user to return
          await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      CategoryDetailsPage(categories[index])));
          // When the user returns, refresh the categories list
          refreshCategories();
        },
      )),
    );
  }
}
