import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  bool _notificationSoundEnabled = true;
  bool _notificationPermissionGranted = false;
  bool _isBatteryUnrestricted = false;
  bool _locationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkNotificationPermission();
    _checkBatteryOptimization();
    _checkLocationPermission();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationSoundEnabled = prefs.getBool('notification_sound') ?? true;
    });
  }

  Future<void> _setNotificationSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sound', value);
    setState(() {
      _notificationSoundEnabled = value;
    });
  }

  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      setState(() {
        _notificationPermissionGranted = status.isGranted;
      });
    } else {
      setState(() {
        _notificationPermissionGranted = true;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final newStatus = await Permission.notification.request();
        setState(() {
          _notificationPermissionGranted = newStatus.isGranted;
        });

        if (!newStatus.isGranted) {
          _showSettingsDialog(
            title: 'Autorizzazione richiesta',
            message:
                'Per ricevere notifiche, abilita i permessi nelle impostazioni di sistema.',
          );
        }
      } else {
        setState(() {
          _notificationPermissionGranted = true;
        });
      }
    } else {
      setState(() {
        _notificationPermissionGranted = true;
      });
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    setState(() {
      _isBatteryUnrestricted = status.isGranted;
    });
  }

  Future<void> _requestIgnoreBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    _checkBatteryOptimization();
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    setState(() {
      _locationPermissionGranted =
          permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
    });
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      _showSettingsDialog(
        title: 'Permesso posizione richiesto',
        message:
            'Per abilitare le funzionalità GPS, consenti l\'accesso alla posizione nelle impostazioni.',
      );
      setState(() => _locationPermissionGranted = false);
      return;
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() => _locationPermissionGranted = true);
    } else {
      setState(() => _locationPermissionGranted = false);
    }
  }

  void _showSettingsDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (!mounted) return;
              // ignore: use_build_context_synchronously
              Navigator.pop(context);
            },
            child: const Text('IMPOSTAZIONI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestione Notifiche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Abilita notifiche'),
                subtitle: Text(
                  _notificationPermissionGranted
                      ? 'Autorizzazione concessa'
                      : 'Richiedi autorizzazione per le notifiche',
                ),
                value: _notificationPermissionGranted,
                onChanged: (_) => _requestNotificationPermission(),
                secondary: Icon(
                  Icons.notifications,
                  color: _notificationPermissionGranted
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Suono di notifica'),
                subtitle: const Text(
                  'Riproduci un suono quando arriva un nuovo messaggio',
                ),
                value: _notificationSoundEnabled,
                onChanged: _setNotificationSound,
                secondary: Icon(
                  Icons.notifications_active,
                  color: _notificationSoundEnabled ? Colors.blue : Colors.grey,
                ),
              ),
            ),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Esecuzione in background'),
                subtitle: Text(
                  _isBatteryUnrestricted
                      ? 'Ottimizzazione batteria disattivata'
                      : 'L\'app potrebbe non ricevere notifiche in background',
                ),
                value: _isBatteryUnrestricted,
                onChanged: (_) => _requestIgnoreBatteryOptimization(),
                secondary: Icon(
                  Icons.battery_alert,
                  color: _isBatteryUnrestricted ? Colors.blue : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Le notifiche in background richiedono che l\'ottimizzazione batteria sia disattivata per questa app.',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Gestione GPS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: SwitchListTile(
                title: const Text('Abilita accesso alla posizione'),
                subtitle: Text(
                  _locationPermissionGranted
                      ? 'Accesso alla posizione abilitato'
                      : 'Richiedi autorizzazione GPS',
                ),
                value: _locationPermissionGranted,
                onChanged: (_) => _requestLocationPermission(),
                secondary: Icon(
                  Icons.location_on,
                  color: _locationPermissionGranted ? Colors.blue : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Center(
              child: Text(
                'Versione App: $appVersion',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
