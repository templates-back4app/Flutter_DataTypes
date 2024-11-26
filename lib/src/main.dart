import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:geolocator/geolocator.dart';

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
      title: 'Save Location to Back4App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LocationSaver(),
    );
  }
}

class LocationSaver extends StatefulWidget {
  const LocationSaver({super.key});

  @override
  State<LocationSaver> createState() => _LocationSaverState();
}

class _LocationSaverState extends State<LocationSaver> {
  String? _locationMessage;
  bool _isLoading = false;

  Future<void> _getLocationAndSave() async {
    setState(() {
      _isLoading = true;
      _locationMessage = null;
    });

    try {
      // Check and request location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationMessage = 'Location services are disabled.';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationMessage = 'Location permissions are denied.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage =
              'Location permissions are permanently denied. Please enable them in settings.';
          _isLoading = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print(position);

      // Create ParseGeoPoint
      final geoPoint = ParseGeoPoint(
          latitude: position.latitude, longitude: position.longitude);

      // Create and save the ParseObject
      final gamePoint = ParseObject('GamePoint')
        ..set('name', 'Current Location')
        ..set('location', geoPoint);

      final response = await gamePoint.save();

      if (response.success) {
        setState(() {
          _locationMessage =
              'Location saved successfully!\nLatitude: ${position.latitude}\nLongitude: ${position.longitude}';
        });
      } else {
        setState(() {
          _locationMessage =
              'Failed to save location: ${response.error?.message}';
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Save Location to Back4App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _getLocationAndSave,
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    : const Text('Get Location and Save'),
              ),
              const SizedBox(height: 20),
              if (_locationMessage != null)
                Text(
                  _locationMessage!,
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
