import 'package:flutter/material.dart';
import 'package:mobile/database.dart';
import 'package:mobile/views/category_details.dart';
import 'package:mobile/views/create_category.dart';
import 'package:mobile/views/create_transaction.dart';
import 'package:mobile/helpers.dart';
import 'package:mobile/views/import_transactions.dart';
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ImportTransactionsPage()),
                );
              },
              icon: const Icon(Icons.import_export)),
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
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xff18453B).withOpacity(0.90),
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

  Widget buildCategories(BuildContext context, int index) {
    return FutureBuilder<int>(
      future:
          CatchupDatabase.instance.getCurrentMonthSum(categories[index].id!),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(child: ListTile(title: Text("Loading")));
        } else if (snapshot.hasError) {
          debugPrint(snapshot.error.toString());
          return Text("Error: ${snapshot.error}");
        } else {
          int spentAmount = snapshot.data!;

          double spentPercentage = 0;

          if (categories[index].spendLimit != 0) {
            spentPercentage = spentAmount / categories[index].spendLimit;
          }

          return Card(
              child: ListTile(
            title: Text(categories[index].name),
            subtitle: categories[index].spendLimit != 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text('Spent: ${(spentPercentage * 100).round()}%'),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value:
                              spentPercentage, // Set the progress value here.
                          color: interpolateColour(
                              (spentPercentage * 100).round()),
                        ),
                      ])
                : Text('Spent: ${spentAmount / 100}'),
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
          ));
        }
      },
    );
  }
}
