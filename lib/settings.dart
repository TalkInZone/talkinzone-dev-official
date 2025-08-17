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

  // 🆕 Categoria personalizzata: nome salvato nelle preferenze
  String? _customCategoryName; // null = disattivata

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
      // 🆕 Categoria personalizzata: carica il nome (se vuoto -> null)
      final raw = (prefs.getString('custom_category_name') ?? '').trim();
      _customCategoryName = raw.isEmpty ? null : raw;
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

  // 🆕 Categoria personalizzata: salva/rimuovi il nome nelle preferenze
  Future<void> _saveCustomCategoryName(String? value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      await prefs.remove('custom_category_name');
      setState(() => _customCategoryName = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Categoria personalizzata disattivata')),
        );
      }
      return;
    }
    // Limite lunghezza semplice per evitare nomi eccessivi
    final limited = trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
    await prefs.setString('custom_category_name', limited);
    setState(() => _customCategoryName = limited);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoria personalizzata impostata: $limited')),
      );
    }
  }

  // 🆕 Categoria personalizzata: dialog per inserire/modificare il nome
  Future<void> _showCustomNameDialog() async {
    final controller = TextEditingController(text: _customCategoryName ?? '');
    String? error;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Categoria personalizzata'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Imposta il nome della tua categoria personalizzata. '
                    'Solo i messaggi con esattamente lo stesso nome saranno visibili nei filtri.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    maxLength: 32,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Es. “Runner Milano Nord”',
                      counterText: '',
                      errorText: error,
                      border: const OutlineInputBorder(),
                    ),
                    onSubmitted: (_) {},
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    controller.clear();
                    Navigator.of(context).pop(); // chiude il dialog
                    _saveCustomCategoryName(null); // disattiva
                  },
                  child: const Text('RIMUOVI'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ANNULLA'),
                ),
                FilledButton(
                  onPressed: () {
                    final v = controller.text.trim();
                    if (v.isEmpty) {
                      setLocalState(
                          () => error = 'Il nome non può essere vuoto');
                      return;
                    }
                    Navigator.of(context).pop();
                    _saveCustomCategoryName(v);
                  },
                  child: const Text('SALVA'),
                ),
              ],
            );
          },
        );
      },
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
            // 🆕 Sezione: Categoria personalizzata
            const Text(
              'Categoria personalizzata',
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
              child: ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Nome categoria personalizzata'),
                subtitle: Text(
                  _customCategoryName == null || _customCategoryName!.isEmpty
                      ? 'Nessuna — tocca per impostare'
                      : 'Attiva: ${_customCategoryName!}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_customCategoryName != null &&
                        _customCategoryName!.isNotEmpty)
                      IconButton(
                        tooltip: 'Rimuovi',
                        onPressed: () => _saveCustomCategoryName(null),
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: 'Modifica',
                      onPressed: _showCustomNameDialog,
                      icon: const Icon(Icons.edit),
                    ),
                  ],
                ),
                onTap: _showCustomNameDialog,
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
