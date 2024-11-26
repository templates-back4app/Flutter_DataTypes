import 'dart:async';

import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyParseApplicationId = 'YOUR_APPLICATION_ID';
  const keyParseClientKey = 'YOUR_CLIENT_KEY';
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
  final TextEditingController _pointerController = TextEditingController();
  final TextEditingController _objectIdController = TextEditingController();
  final TextEditingController _uniqueValueController = TextEditingController();
  final TextEditingController _removeValueController = TextEditingController();

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
              _buildTextField('Pointer Field (Object ID)', _pointerController),
              const SizedBox(height: 20),
              _buildImagePicker(),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                child: const Text('Save'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await _deleteData(_objectIdController.text);
                  // await dummyFunction();
                },
                child: const Text('Delete'),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                  'Object ID to Delete or Update', _objectIdController),
              ElevatedButton(
                onPressed: () async {
                  await _updateData(_objectIdController.text);
                },
                child: const Text('Update'),
              ),
              const SizedBox(height: 20),
              _buildIncrementDecrementButtons(),
              const SizedBox(height: 20),
              _buildListOperations(),
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
                  child: Text('Click here to pick image from GamePoint')),
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

  Widget _buildIncrementDecrementButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await _incrementField(_objectIdController.text);
            },
            child: const Text('+ Double'),
          ),
        ),
        const SizedBox(width: 10), // Adding some space between buttons
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              await _decrementField(_objectIdController.text);
            },
            child: const Text('- Double'),
          ),
        ),
      ],
    );
  }

  Widget _buildListOperations() {
    return Column(
      children: [
        _buildTextField('Unique Value to Add', _uniqueValueController),
        ElevatedButton(
          onPressed: () async {
            await _addUniqueToList(
                _objectIdController.text, _uniqueValueController.text);
          },
          child: const Text('Add Unique'),
        ),
        const SizedBox(height: 20),
        _buildTextField('Value to Remove', _removeValueController),
        ElevatedButton(
          onPressed: () async {
            await _removeFromList(
                _objectIdController.text, _removeValueController.text);
          },
          child: const Text('Remove'),
        ),
      ],
    );
  }

  Future<void> _saveData() async {
    //Parse values
    String stringValue = _stringController.text;
    List<String> listStringValue = _listStringController.text.isNotEmpty
        ? _listStringController.text
            .split(',') // Split by comma
            .map((e) =>
                e.trim()) // Remove any surrounding whitespace from each element
            .toList()
        : [];
    List<int> listtIntValue = _listIntController.text.isNotEmpty
        ? _listIntController.text
            .split(',') // Split by comma
            .map(
                (e) => int.parse(e.trim())) // Convert each string to an integer
            .toList()
        : [];
    double? doubleValue;
    if (_doubleController.text.isNotEmpty) {
      doubleValue = double.parse(_doubleController.text);
    }
    bool boolValue = _boolValue;
    DateTime selectedDate = _selectedDate;

    final gamePoint = ParseObject('GamePoint')
      ..set('bool', boolValue)
      ..set('date', selectedDate);
    if (stringValue.isNotEmpty) gamePoint.set('string', stringValue);
    if (doubleValue != null) gamePoint.set('double', doubleValue);
    if (listStringValue.isNotEmpty) {
      gamePoint.setAddAll('listString', listStringValue);
    }
    if (listtIntValue.isNotEmpty) gamePoint.setAddAll('listint', listtIntValue);
    if (_pointerController.text.isNotEmpty) {
      gamePoint.set('pointer', _parsePointer(_pointerController.text));
    }

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

      gamePoint.set('file', parseFile);
    }

    var apiResponse = await gamePoint.save();

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

  Future<void> _updateData(String objectId) async {
    final gamePoint = ParseObject('GamePoint')..objectId = objectId;
    // Update fields with new values
    if (_stringController.text.isNotEmpty) {
      gamePoint.set('string', _stringController.text);
    }

    if (_doubleController.text.isNotEmpty) {
      gamePoint.setIncrement('double', double.parse(_doubleController.text));
    }

    gamePoint.set('bool', _boolValue);
    gamePoint.set('date', _selectedDate);

    if (_listStringController.text.isNotEmpty) {
      List<String> listStringValue =
          _listStringController.text.split(',').map((e) => e.trim()).toList();
      gamePoint.setAddAll('listString', listStringValue);
    }

    if (_listIntController.text.isNotEmpty) {
      List<int> listIntValue = _listIntController.text
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();
      gamePoint.setAddUnique('listint', listIntValue);
    }

    if (_pointerController.text.isNotEmpty) {
      gamePoint.set('pointer', _parsePointer(_pointerController.text));
    }

    if (pickedFile != null) {
      ParseFileBase? parseFile;
      if (kIsWeb) {
        parseFile =
            ParseWebFile(await pickedFile!.readAsBytes(), name: 'file.jpg');
      } else {
        parseFile = ParseFile(File(pickedFile!.path));
      }
      await parseFile.save();
      gamePoint.set('file', parseFile);
    }

    // Save the updated object
    var response = await gamePoint.save();

    if (response.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data updated successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error updating data: ${response.error!.message}')),
      );
    }
  }

  Future<void> _incrementField(String objectId) async {
    final gamePoint = ParseObject('GamePoint')
      ..objectId = objectId
      ..setIncrement('double', 1);
    await gamePoint.save();
  }

  Future<void> _decrementField(String objectId) async {
    final gamePoint = ParseObject('GamePoint')
      ..objectId = objectId
      ..setIncrement('double', -1);
    await gamePoint.save();
  }

  Future<void> _addUniqueToList(String objectId, String value) async {
    final gamePoint = ParseObject('GamePoint')
      ..objectId = objectId
      ..setAddUnique('listString', value);
    await gamePoint.save();
  }

  Future<void> _removeFromList(String objectId, String value) async {
    final gamePoint = ParseObject('GamePoint')
      ..objectId = objectId
      ..setRemove('listString', value);
    await gamePoint.save();
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

  Future<void> _deleteData(String objectId) async {
    // Delete data logic
    final parseObject = ParseObject('GamePoint')
      ..objectId = objectId
      ..unset("listString");

    await parseObject.save();

    // final QueryBuilder<ParseObject> queryGamePoints =
    //     QueryBuilder<ParseObject>(ParseObject('GamePoint'));

    // final ParseResponse response = await queryGamePoints.query();

    // if (response.success && response.results != null) {
    //   for (var gamePoint in response.results!) {
    //     final score = gamePoint.get<double>('double');
    //     final playerName = gamePoint.get<String>('string');
    //     final cheatMode = gamePoint.get<bool>('bool');
    //   }
    // }
  }

  // Convert Pointer field to a suitable format
  ParseObject _parsePointer(String objectId) {
    final bookPointer = ParseObject('Book')..objectId = objectId;
    return bookPointer;
  }
}

// dummyFunction() async {}

// ParseFileBase? varFile = gamePoint.get<ParseFileBase>('file');

// if (varFile != null) {
//   return Image.network(
//     varFile.url!,
//     width: 200,
//     height: 200,
//     fit: BoxFit.fitHeight,
//   );
// }

