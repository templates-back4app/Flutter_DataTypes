import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyApplicationId = 'YOUR_APP_ID_HERE';
  const keyClientKey = 'YOUR_CLIENT_KEY_HERE';
  const keyParseServerUrl = 'https://parseapi.back4app.com';

  await Parse().initialize(keyApplicationId, keyParseServerUrl,
      clientKey: keyClientKey, debug: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            Image.network(
              'https://blog.back4app.com/wp-content/uploads/2017/11/logo-b4a-1-768x175-1.png',
              height: 200,
            ),
            const Center(
              child: Text(
                'Flutter on Back4app',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            _buildNavigationButton(
              context,
              'Add Genre',
              const RegistrationPage(registrationType: RegistrationType.genre),
            ),
            _buildNavigationButton(
              context,
              'Add Publisher',
              const RegistrationPage(
                  registrationType: RegistrationType.publisher),
            ),
            _buildNavigationButton(
              context,
              'Add Author',
              const RegistrationPage(registrationType: RegistrationType.author),
            ),
            _buildNavigationButton(
              context,
              'Add Book',
              const BookPage(),
            ),
            _buildNavigationButton(
              context,
              'List Publisher/Book',
              const BookListPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(
      BuildContext context, String text, Widget page) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: Colors.blue,
        ),
        child: Text(text),
      ),
    );
  }
}

enum RegistrationType { genre, publisher, author }

extension RegistrationTypeExtension on RegistrationType {
  String get description {
    switch (this) {
      case RegistrationType.genre:
        return 'Genre';
      case RegistrationType.publisher:
        return 'Publisher';
      case RegistrationType.author:
        return 'Author';
      default:
        return '';
    }
  }

  String get className {
    switch (this) {
      case RegistrationType.genre:
        return 'Genre';
      case RegistrationType.publisher:
        return 'Publisher';
      case RegistrationType.author:
        return 'Author';
      default:
        return '';
    }
  }
}

class RegistrationPage extends StatefulWidget {
  final RegistrationType registrationType;

  const RegistrationPage({super.key, required this.registrationType});

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New ${widget.registrationType.description}'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'New ${widget.registrationType.description}',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addRegistration,
              child: const Text('ADD'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<ParseObject>>(
                future: _listRegistration(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text('Error loading data'),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text('No data found'),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final item = snapshot.data![index];
                        return ListTile(
                          title: Text(item.get<String>('name') ?? ''),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addRegistration() async {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Empty ${widget.registrationType.description}',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
        ),
      );
      return;
    }

    final newRegistration = ParseObject(widget.registrationType.className)
      ..set('name', _controller.text.trim());
    await newRegistration.save();

    _controller.clear();
    setState(() {});
  }

  Future<List<ParseObject>> _listRegistration() async {
    final query = QueryBuilder<ParseObject>(
      ParseObject(widget.registrationType.className),
    );
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    } else {
      return [];
    }
  }
}

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  _BookPageState createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  ParseObject? _genre;
  ParseObject? _publisher;
  List<ParseObject>? _authors;

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
            _buildTextField(_titleController, 'Title'),
            const SizedBox(height: 16),
            _buildTextField(
              _yearController,
              'Year',
              keyboardType: TextInputType.number,
              maxLength: 4,
            ),
            const SizedBox(height: 16),
            const Text('Publisher', style: TextStyle(fontSize: 16)),
            CheckBoxGroupWidget(
              registrationType: RegistrationType.publisher,
              onChanged: (value) =>
                  _publisher = value.isNotEmpty ? value.first : null,
            ),
            const SizedBox(height: 16),
            const Text('Genre', style: TextStyle(fontSize: 16)),
            CheckBoxGroupWidget(
              registrationType: RegistrationType.genre,
              onChanged: (value) =>
                  _genre = value.isNotEmpty ? value.first : null,
            ),
            const SizedBox(height: 16),
            const Text('Author', style: TextStyle(fontSize: 16)),
            CheckBoxGroupWidget(
              registrationType: RegistrationType.author,
              multipleSelection: true,
              onChanged: (value) => _authors = value.isNotEmpty ? value : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveBook,
              child: const Text('Save Book'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType keyboardType = TextInputType.text, int? maxLength}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _saveBook() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackbar('Empty Book Title');
      return;
    }

    if (_yearController.text.trim().length != 4) {
      _showSnackbar('Invalid Year');
      return;
    }

    if (_genre == null) {
      _showSnackbar('Select Genre');
      return;
    }

    if (_publisher == null) {
      _showSnackbar('Select Publisher');
      return;
    }

    final newBook = ParseObject('Book')
      ..set('title', _titleController.text.trim())
      ..set('year', int.parse(_yearController.text.trim()))
      ..set('genre', _genre)
      ..set('publisher', _publisher)
      ..addRelation('author', _authors!);

    await newBook.save();

    _titleController.clear();
    _yearController.clear();
    setState(() {
      _genre = null;
      _publisher = null;
      _authors = null;
    });
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
    );
  }
}

class BookListPage extends StatefulWidget {
  const BookListPage({super.key});

  @override
  _BookListPageState createState() => _BookListPageState();
}

class _BookListPageState extends State<BookListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book List'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder<List<ParseObject>>(
          future: _listBooks(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text('Error loading data'),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text('No data found'),
              );
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data![index];
                  return ListTile(
                    title: Text(item.get<String>('title') ?? ''),
                    subtitle: Text(
                        'Published by: ${item.get<ParseObject>('publisher')?.get<String>('name') ?? 'Unknown'}'),
                    onTap: () async {
                      final relatedBooks = await _listRelatedBooks(item);
                      _showRelatedBooksDialog(context, relatedBooks);
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }

  Future<List<ParseObject>> _listBooks() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Book'));
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  Future<List<ParseObject>> _listRelatedBooks(ParseObject book) async {
    final relatedQuery = QueryBuilder<ParseObject>(ParseObject('Book'))
      ..whereRelatedTo('publisher', 'Publisher', book as String);
    final response = await relatedQuery.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  void _showRelatedBooksDialog(BuildContext context, List<ParseObject> books) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Related Books'),
          content: SizedBox(
            height: 200,
            width: 300,
            child: ListView.builder(
              itemCount: books.length,
              itemBuilder: (context, index) {
                final book = books[index];
                return ListTile(
                  title: Text(book.get<String>('title') ?? ''),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class CheckBoxGroupWidget extends StatefulWidget {
  final RegistrationType registrationType;
  final bool multipleSelection;
  final Function(List<ParseObject>) onChanged;

  const CheckBoxGroupWidget({
    super.key,
    required this.registrationType,
    this.multipleSelection = false,
    required this.onChanged,
  });

  @override
  _CheckBoxGroupWidgetState createState() => _CheckBoxGroupWidgetState();
}

class _CheckBoxGroupWidgetState extends State<CheckBoxGroupWidget> {
  late Future<List<ParseObject>> _dataFuture;
  final List<ParseObject> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _dataFuture = _fetchData();
  }

  Future<List<ParseObject>> _fetchData() async {
    final query = QueryBuilder<ParseObject>(
        ParseObject(widget.registrationType.className));
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ParseObject>>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.hasError) {
          return const Center(
            child: Text('Error loading data'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No data found'),
          );
        } else {
          final items = snapshot.data!;
          return Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: items.map((item) {
              return FilterChip(
                label: Text(item.get<String>('name') ?? ''),
                selected: _selectedItems.contains(item),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (!widget.multipleSelection) {
                        _selectedItems.clear();
                      }
                      _selectedItems.add(item);
                    } else {
                      _selectedItems.remove(item);
                    }
                    widget.onChanged(_selectedItems);
                  });
                },
              );
            }).toList(),
          );
        }
      },
    );
  }
}
