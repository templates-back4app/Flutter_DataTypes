import 'dart:async';
import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'ThXBjb9HNe0LhOx8IZDCo4fCdwaewGwwgQVzVTAc';
  const keyClientKey = 'IbY5x4ZF1RCjxi3oHBvOKTvqfC7X4EyMgXUGCHM4';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(const MaterialApp(
    home: HomePage(),
  ));
}

// ignore: constant_identifier_names
enum RegistrationType { GENRE, PUBLISHER, AUTHOR }

extension RegistrationTypeMembers on RegistrationType {
  String get description => const {
        RegistrationType.GENRE: 'Genre',
        RegistrationType.PUBLISHER: 'Publisher',
        RegistrationType.AUTHOR: 'Author',
      }[this]!;

  String get className => const {
        RegistrationType.GENRE: 'Genre',
        RegistrationType.PUBLISHER: 'Publisher',
        RegistrationType.AUTHOR: 'Author',
      }[this]!;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView(
          children: [
            SizedBox(
              height: 200,
              child: Image.network(
                  'https://blog.back4app.com/wp-content/uploads/2017/11/logo-b4a-1-768x175-1.png'),
            ),
            const Center(
              child: Text('Flutter on Back4app',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            buildButton(context, 'Add Genre', RegistrationType.GENRE),
            const SizedBox(height: 16),
            buildButton(context, 'Add Publisher', RegistrationType.PUBLISHER),
            const SizedBox(height: 16),
            buildButton(context, 'Add Author', RegistrationType.AUTHOR),
            const SizedBox(height: 16),
            buildNavigationButton(context, 'Add Book', const BookPage()),
            const SizedBox(height: 16),
            buildNavigationButton(
                context, 'List Publisher/Book', const BookListPage()),
          ],
        ),
      ),
    );
  }

  // Function to build buttons for RegistrationType
  Widget buildButton(BuildContext context, String text, RegistrationType type) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue),
        child: Text(text),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RegistrationPage(registrationType: type),
            ),
          );
        },
      ),
    );
  }

  // Function to build navigation buttons
  Widget buildNavigationButton(BuildContext context, String text, Widget page) {
    return SizedBox(
      height: 50,
      width: double.infinity,
      child: TextButton(
        style: TextButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Colors.blue),
        child: Text(text),
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => page));
        },
      ),
    );
  }
}

class RegistrationPage extends StatefulWidget {
  final RegistrationType registrationType;

  const RegistrationPage({super.key, required this.registrationType});
  @override
  // ignore: library_private_types_in_public_api
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  RegistrationType get registrationType => widget.registrationType;
  final controller = TextEditingController();

  void addRegistration() async {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            'Empty ${registrationType.description}',
            style: const TextStyle(color: Colors.white),
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ));
      return;
    }
    await doSaveRegistration(controller.text.trim());
    controller.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New ${registrationType.description}'),
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    autocorrect: true,
                    textCapitalization: TextCapitalization.sentences,
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: "New ${registrationType.description}",
                      labelStyle: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                ElevatedButton(
                    onPressed: addRegistration, child: const Text("ADD")),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ParseObject>>(
              future: doListRegistration(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: SizedBox(
                          width: 100,
                          height: 100,
                          child: CircularProgressIndicator()),
                    );
                  default:
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error..."),
                      );
                    } else {
                      return ListView.builder(
                        padding: const EdgeInsets.only(top: 10.0),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text(
                                snapshot.data![index].get<String>('name')!),
                          );
                        },
                      );
                    }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Function to list registrations
  Future<List<ParseObject>> doListRegistration() async {
    QueryBuilder<ParseObject> queryRegistration =
        QueryBuilder<ParseObject>(ParseObject(registrationType.className));
    final ParseResponse apiResponse = await queryRegistration.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  // Function to save registration
  Future<void> doSaveRegistration(String name) async {
    final registration = ParseObject(registrationType.className)
      ..set('name', name);
    await registration.save();
  }
}

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final controllerTitle = TextEditingController();
  final controllerYear = TextEditingController();
  ParseObject? genre;
  ParseObject? publisher;
  List<ParseObject>? authors;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Book'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            buildTextField('Title', controllerTitle, false),
            const SizedBox(height: 16),
            buildTextField('Year', controllerYear, true, 4),
            const SizedBox(height: 16),
            buildSectionTitle('Publisher'),
            CheckBoxGroupWidget(
              registrationType: RegistrationType.PUBLISHER,
              onChanged: (value) {
                if (value != null && value.isNotEmpty) {
                  publisher = value.first;
                } else {
                  publisher = null;
                }
              },
            ),
            const SizedBox(height: 16),
            buildSectionTitle('Genre'),
            CheckBoxGroupWidget(
              registrationType: RegistrationType.GENRE,
              onChanged: (value) {
                if (value != null && value.isNotEmpty) {
                  genre = value.first;
                } else {
                  genre = null;
                }
              },
            ),
            const SizedBox(height: 16),
            buildSectionTitle('Author'),
            CheckBoxGroupWidget(
              multipleSelection: true,
              registrationType: RegistrationType.AUTHOR,
              onChanged: (value) {
                if (value != null && value.isNotEmpty) {
                  authors = value;
                } else {
                  authors = null;
                }
              },
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 50,
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue),
                onPressed: saveBook,
                child: const Text('Save Book'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Function to build text fields
  Widget buildTextField(
      String label, TextEditingController controller, bool isNumeric,
      [int? maxLength]) {
    return TextField(
      autocorrect: false,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLength: maxLength,
      controller: controller,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    );
  }

  // Function to build section titles
  Widget buildSectionTitle(String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: const TextStyle(
          fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
    );
  }

  // Function to save book
  void saveBook() async {
    if (controllerTitle.text.trim().isEmpty ||
        controllerYear.text.trim().isEmpty) {
      showSnackBarMessage('Title or Year cannot be empty.');
      return;
    }

    if (publisher == null) {
      showSnackBarMessage('Please select a Publisher.');
      return;
    }

    if (genre == null) {
      showSnackBarMessage('Please select a Genre.');
      return;
    }

    if (authors == null || authors!.isEmpty) {
      showSnackBarMessage('Please select at least one Author.');
      return;
    }

    await doSaveBook();
    clearFields();
    showSnackBarMessage('Book saved successfully.');
  }

  // Function to display snack bar messages
  void showSnackBarMessage(String message) {
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.blue,
      ));
  }

  // Function to clear text fields
  void clearFields() {
    controllerTitle.clear();
    controllerYear.clear();
    setState(() {
      publisher = null;
      genre = null;
      authors = [];
    });
  }

  // Function to save book to Parse server
  Future<void> doSaveBook() async {
    final book = ParseObject('Book')
      ..set('title', controllerTitle.text.trim())
      ..set('year', int.parse(controllerYear.text.trim()))
      //the objectId will be converted to a Pointer on the save() method
      ..set('genre', ParseObject('Genre')..objectId = genre?.objectId)
      //you can also convert to a Pointer object before the saving using the .toPointer() method
      ..set(
          'publisher',
          (ParseObject('Publisher')..objectId = publisher?.objectId)
              .toPointer());

    await book.save();
  }
}

class CheckBoxGroupWidget extends StatefulWidget {
  final RegistrationType registrationType;
  final Function(List<ParseObject>?) onChanged;
  final bool multipleSelection;

  const CheckBoxGroupWidget({
    super.key,
    required this.registrationType,
    required this.onChanged,
    this.multipleSelection = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _CheckBoxGroupWidgetState createState() => _CheckBoxGroupWidgetState();
}

class _CheckBoxGroupWidgetState extends State<CheckBoxGroupWidget> {
  List<ParseObject> selectedItems = [];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ParseObject>>(
      future: doListRegistration(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: snapshot.data!.map((item) {
            bool isSelected = selectedItems.contains(item);
            return CheckboxListTile(
              title: Text(item.get<String>('name')!),
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    if (!widget.multipleSelection) {
                      selectedItems.clear();
                    }
                    selectedItems.add(item);
                  } else {
                    selectedItems.remove(item);
                  }
                });
                widget.onChanged(selectedItems);
              },
            );
          }).toList(),
        );
      },
    );
  }

  // Function to list registrations
  Future<List<ParseObject>> doListRegistration() async {
    QueryBuilder<ParseObject> queryRegistration = QueryBuilder<ParseObject>(
        ParseObject(widget.registrationType.className));
    final ParseResponse apiResponse = await queryRegistration.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }
}

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Books and Publishers'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<ParseObject>>(
        future: doListBooks(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final book = snapshot.data![index];
              final publisher = book.get<ParseObject>('publisher');
              return ListTile(
                title: Text(book.get<String>('title')!),
                subtitle: Text(
                    'Publisher: ${publisher?.get<String>('name') ?? 'Unknown'}'),
              );
            },
          );
        },
      ),
    );
  }

  // Function to list books
  Future<List<ParseObject>> doListBooks() async {
    QueryBuilder<ParseObject> queryBooks =
        QueryBuilder<ParseObject>(ParseObject('Book'))
          ..includeObject(['publisher']);
    final ParseResponse apiResponse = await queryBooks.query();

    if (apiResponse.success && apiResponse.results != null) {
      return apiResponse.results as List<ParseObject>;
    } else {
      return [];
    }
  }
}
