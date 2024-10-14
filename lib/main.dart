import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const keyParseApplicationId = 'YOUR_APP_ID';
  const keyParseClientKey = 'YOUR_CLIENT_KEY';
  const keyParseServerUrl = 'https://parseapi.back4app.com';
  await Parse().initialize(
    keyParseApplicationId,
    keyParseServerUrl,
    clientKey: keyParseClientKey,
    autoSendSessionId: true,
    debug: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DataTypes',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _objectIdController = TextEditingController();
  final TextEditingController _stringController = TextEditingController();
  final TextEditingController _doubleController = TextEditingController();
  final TextEditingController _jsonController = TextEditingController();
  final TextEditingController _listStringController = TextEditingController();
  final TextEditingController _listIntController = TextEditingController();
  final TextEditingController _listBoolController = TextEditingController();
  final TextEditingController _listJsonController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _polygonController =
      TextEditingController(); // Polygon field
  final TextEditingController _pointerController =
      TextEditingController(); // Pointer field
  final TextEditingController _relationController =
      TextEditingController(); // Relation field

  bool _boolValue = false;
  DateTime _selectedDate = DateTime.now();
  String _responseMessage = '';
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
              _buildTextField('Object ID', _objectIdController),
              const SizedBox(height: 20),
              _buildLatitudeLongitudeFields(),
              const SizedBox(height: 20),
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
              _buildTextField('JSON Field', _jsonController),
              const SizedBox(height: 20),
              _buildTextField(
                  'List String Field (comma-separated)', _listStringController),
              const SizedBox(height: 20),
              _buildTextField(
                  'List Int Field (comma-separated)', _listIntController),
              const SizedBox(height: 20),
              _buildTextField(
                  'List Bool Field (comma-separated)', _listBoolController),
              const SizedBox(height: 20),
              _buildTextField(
                  'List JSON Field (pipe-separated)', _listJsonController),
              const SizedBox(height: 20),
              _buildTextField(
                  'Polygon Field (JSON)', _polygonController), // Polygon input
              const SizedBox(height: 20),
              _buildTextField('Pointer Field (Object ID)',
                  _pointerController), // Pointer input
              const SizedBox(height: 20),
              _buildTextField('Relation Field (comma-separated Object IDs)',
                  _relationController), // Relation input
              const SizedBox(height: 20),
              _buildImagePicker(), // Image Picker added
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveData,
                child: const Text('Save'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _updateData,
                child: const Text('Update'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _deleteData,
                child: const Text('Delete'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchData,
                child: const Text('Fetch'),
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
        border: OutlineInputBorder(),
        labelText: label,
      ),
    );
  }

  Widget _buildLatitudeLongitudeFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTextField('Latitude', _latitudeController, isNumeric: true),
        const SizedBox(height: 20),
        _buildTextField('Longitude', _longitudeController, isNumeric: true),
      ],
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
              child: Center(
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
        ..set('file', parseFile)
        ..set('polygon', _parsePolygon(_polygonController.text))
        ..set('pointer', _parsePointer(_pointerController.text))
        ..set('relation', _parseRelation(_relationController.text));

      await gallery.save();

      setState(() {
        isLoading = false;
        pickedFile = null;
      });

      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(
            'File saved successfully on Back4app',
            style: TextStyle(color: Colors.white),
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.blue,
        ));
    }
  }

  Future<void> _updateData() async {
    // Update data logic
  }

  Future<void> _deleteData() async {
    // Delete data logic
  }

  Future<void> _fetchData() async {
    // Fetch data logic
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate)
      setState(() {
        _selectedDate = picked;
      });
  }

  // Convert Polygon field to a suitable format
  ParseObject _parsePolygon(String polygonJson) {
    // Example: {"type": "Polygon", "coordinates": [[[lng, lat], [lng, lat], [lng, lat]]]}
    return ParseObject('Polygon')..set('data', polygonJson);
  }

  // Convert Pointer field to a suitable format
  ParseObject _parsePointer(String objectId) {
    return ParseObject('Pointer')..set('objectId', objectId);
  }

  // Convert Relation field to a suitable format
  List<ParseObject> _parseRelation(String objectIds) {
    final ids = objectIds
        .split(',')
        .map((id) => ParseObject('Pointer')..set('objectId', id.trim()))
        .toList();
    return ids;
  }
}
