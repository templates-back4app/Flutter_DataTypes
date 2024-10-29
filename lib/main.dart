import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyParseApplicationId = 'ThXBjb9HNe0LhOx8IZDCo4fCdwaewGwwgQVzVTAc';
  const keyParseClientKey = 'IbY5x4ZF1RCjxi3oHBvOKTvqfC7X4EyMgXUGCHM4';
  const keyParseServerUrl = 'https://parseapi.back4app.com';
  await Parse().initialize(
    keyParseApplicationId,
    keyParseServerUrl,
    clientKey: keyParseClientKey,
    autoSendSessionId: true,
    debug: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataTypes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _stringController = TextEditingController();
  final TextEditingController _doubleController = TextEditingController();
  final TextEditingController _listStringController = TextEditingController();
  final TextEditingController _listIntController = TextEditingController();
  final TextEditingController _pointerController =
      TextEditingController(); // Pointer field

  bool _boolValue = false;
  DateTime _selectedDate = DateTime.now();
  final String _responseMessage = '';
  XFile? pickedFile;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DataTypes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildTextField('String Field', _stringController),
              const SizedBox(height: 20),
              _buildTextField('Double Field', _doubleController,
                  isNumeric: true),
              const SizedBox(height: 20),
              _buildSwitch('Bool Field', _boolValue, (value) {
                setState(() {
                  _boolValue = value;
                });
              }),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                    'Select Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                  'List String Field (comma-separated)', _listStringController),
              const SizedBox(height: 20),
              _buildTextField(
                  'List Int Field (comma-separated)', _listIntController),
              const SizedBox(height: 20),
              _buildTextField('Pointer Field (Object ID)',
                  _pointerController), // Pointer input
              const SizedBox(height: 20),
              _buildImagePicker(), // Image Picker added
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                child: const Text('Save'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await _deleteData('yourObjectId'); // Pass your argument here
                },
                child: const Text('Delete'),
              ),
              const SizedBox(height: 20),
              Text(_responseMessage),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      child: pickedFile != null
          ? Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
              child: kIsWeb
                  ? Image.network(pickedFile!.path)
                  : Image.file(File(pickedFile!.path)),
            )
          : Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(border: Border.all(color: Colors.blue)),
              child: const Center(
                child: Text('Click here to pick image from Gallery'),
              ),
            ),
      onTap: () async {
        final picker = ImagePicker();
        XFile? image = (await picker.pickImage(source: ImageSource.gallery));
        if (image != null) {
          setState(() {
            pickedFile = image;
          });
        }
      },
    );
  }

  Future<void> _saveData() async {
    //Parse values
    String stringValue = _stringController.text;
    List<String> listStringValue = _listStringController.text
        .split(',') // Split by comma
        .map((e) =>
            e.trim()) // Remove any surrounding whitespace from each element
        .toList();
    List<int> listtIntValue = _listIntController.text
        .split(',') // Split by comma
        .map((e) => int.parse(e.trim())) // Convert each string to an integer
        .toList();
    double? doubleValue;
    doubleValue = double.parse(_doubleController.text);
    bool boolValue = _boolValue;
    DateTime selectedDate = _selectedDate;

    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });

      ParseFileBase? parseFile;

      if (kIsWeb) {
        parseFile =
            ParseWebFile(await pickedFile!.readAsBytes(), name: 'file.jpg');
      } else {
        parseFile = ParseFile(File(pickedFile!.path));
      }
      await parseFile.save();

      final gallery = ParseObject('Gallery')
        ..set('string', stringValue)
        ..set('double', doubleValue)
        ..set('bool', boolValue)
        ..set('date', selectedDate)
        ..setAddAll('listString', listStringValue)
        ..setAddAll('listint', listtIntValue)
        ..set('pointer', _parsePointer(_pointerController.text))
        ..set('file', parseFile);

      var apiResponse = await gallery.save();

      if (apiResponse.success && apiResponse.results != null) {
        setState(() {
          isLoading = false;
          pickedFile = null;
        });

        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(const SnackBar(
            content: Text(
              'File saved successfully on Back4app',
              style: TextStyle(color: Colors.white),
            ),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.blue,
          ));
      } else {
        print("This is your request error: ${apiResponse.error}");
      }
    }
  }

  Future<void> _deleteData(String objectId) async {
    // Delete data logic
    final parseObject = ParseObject('Gallery')
      ..objectId = objectId
      ..unset("listString");

    var parseResponse = await parseObject.save();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Convert Pointer field to a suitable format
  ParseObject _parsePointer(String objectId) {
    final bookPointer = ParseObject('Book');
    bookPointer.objectId = objectId;
    return bookPointer;
  }
}
