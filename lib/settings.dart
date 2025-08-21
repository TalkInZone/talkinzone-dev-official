// lib/settings.dart
import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_constants.dart';
import 'app_theme.dart';

// Piccolo modello per la UI della lista bloccati.
class BlockedUser {
  final String uid;
  final String name;
  final String? photoUrl;

  BlockedUser({required this.uid, required this.name, this.photoUrl});
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  // Notifiche / Permessi
  bool _notificationSoundEnabled = true;
  bool _notificationPermissionGranted = false;
  bool _isBatteryUnrestricted = false;
  bool _locationPermissionGranted = false;

  // Tema
  AppTheme _currentTheme = AppTheme.light;

  // Categoria personalizzata
  String? _customCategoryName;

  // Firestore / Auth
  final _auth = FirebaseAuth.instance;
  final _fs = FirebaseFirestore.instance;

  String? _myUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _myDocSub;

  // Bloccati
  bool _loadingBlocked = true;
  List<BlockedUser> _blockedUsers = [];
  final Map<String, String> _volatileNameCache = {};

  @override
  void initState() {
    super.initState();
    _currentTheme = AppThemeController.instance.theme;
    _loadSettings();
    _checkNotificationPermission();
    _checkBatteryOptimization();
    _checkLocationPermission();
    _attachBlockedListener();
  }

  @override
  void dispose() {
    _myDocSub?.cancel();
    super.dispose();
  }

  // --------------------------- Settings ------------------------
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationSoundEnabled = prefs.getBool('notification_sound') ?? true;
      final raw = (prefs.getString('custom_category_name') ?? '').trim();
      _customCategoryName = raw.isEmpty ? null : raw;
    });
  }

  Future<void> _setNotificationSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sound', value);
    setState(() => _notificationSoundEnabled = value);
  }

  // -------------------------- Permessi -------------------------
  Future<void> _checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      setState(() => _notificationPermissionGranted = status.isGranted);
    } else {
      setState(() => _notificationPermissionGranted = true);
    }
  }

  Future<void> _requestNotificationPermission() async {
    if (Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final ns = await Permission.notification.request();
        setState(() => _notificationPermissionGranted = ns.isGranted);
        if (!ns.isGranted) {
          _showSettingsDialog(
            title: 'Autorizzazione richiesta',
            message:
                'Per ricevere notifiche, abilita i permessi nelle impostazioni di sistema.',
          );
        }
      } else {
        setState(() => _notificationPermissionGranted = true);
      }
    } else {
      setState(() => _notificationPermissionGranted = true);
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    setState(() => _isBatteryUnrestricted = status.isGranted);
  }

  Future<void> _requestIgnoreBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (!status.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }
    _checkBatteryOptimization();
  }

  Future<void> _checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    setState(() {
      _locationPermissionGranted =
          permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
    });
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
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
    setState(() {
      _locationPermissionGranted =
          permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always;
    });
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

  // ----------------- Listener su `utenti/<me>` -----------------
  Future<void> _attachBlockedListener() async {
    final prefs = await SharedPreferences.getInstance();
    final authUid = _auth.currentUser?.uid;
    final prefsUid = prefs.getString('user_id') ?? '';

    late final String myUid;
    if (authUid != null && authUid.isNotEmpty) {
      myUid = authUid;
    } else {
      myUid = prefsUid;
    }

    if (myUid.isEmpty) {
      setState(() {
        _myUid = null;
        _loadingBlocked = false;
        _blockedUsers = [];
      });
      return;
    }

    setState(() {
      _myUid = myUid;
      _loadingBlocked = true;
    });

    _myDocSub?.cancel();
    _myDocSub =
        _fs.collection('utenti').doc(myUid).snapshots().listen((snap) async {
      final data = snap.data() ?? <String, dynamic>{};

      final rawIds = (data['id_bloccati'] as List<dynamic>?) ?? const [];
      final blockedIds =
          rawIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
      blockedIds.remove(myUid);

      final initial = blockedIds
          .map((uid) => BlockedUser(
                uid: uid,
                name: _volatileNameCache[uid] ?? 'Anonimo',
                photoUrl: null,
              ))
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _blockedUsers = initial;
        _loadingBlocked = false;
      });

      await _backfillNamesFromRecentMessages(blockedIds);
    }, onError: (e) {
      if (!mounted) return;
      setState(() {
        _loadingBlocked = false;
        _blockedUsers = [];
      });
    });
  }

  Future<void> _backfillNamesFromRecentMessages(Set<String> targetUids) async {
    if (targetUids.isEmpty) return;

    final missing = targetUids
        .where((uid) => (_volatileNameCache[uid] ?? '').isEmpty)
        .toSet();
    if (missing.isEmpty) return;

    try {
      final q = await _fs
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      final Map<String, String> found = {};
      for (final d in q.docs) {
        final m = d.data();
        final sid = (m['senderId'] as String?) ?? '';
        if (!missing.contains(sid)) continue;
        if (found.containsKey(sid)) continue;

        final rawName = (m['name'] as String?)?.trim() ?? '';
        if (rawName.isNotEmpty && rawName.toLowerCase() != 'anonimo') {
          found[sid] = rawName;
          if (found.length == missing.length) break;
        }
      }

      if (found.isEmpty) return;

      found.forEach((uid, name) {
        _volatileNameCache[uid] = name;
      });

      if (!mounted) return;
      setState(() {
        _blockedUsers = _blockedUsers.map((u) {
          final cached = _volatileNameCache[u.uid];
          if (cached != null && cached.isNotEmpty) {
            return BlockedUser(uid: u.uid, name: cached, photoUrl: u.photoUrl);
          }
          return u;
        }).toList()
          ..sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
    } catch (_) {/* Ignore */}
  }

  Future<void> _unblockUser(BlockedUser u) async {
    if (_myUid == null || _myUid!.isEmpty) return;
    try {
      setState(() {
        _blockedUsers = _blockedUsers.where((x) => x.uid != u.uid).toList();
      });

      await _fs.collection('utenti').doc(_myUid!).set({
        'id_bloccati': FieldValue.arrayRemove([u.uid])
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hai sbloccato ${u.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Errore durante lo sblocco. Riprova.')),
      );
    }
  }

  Widget _avatarFor(BlockedUser u) {
    String initials = 'A';
    final raw = u.name.trim();
    if (raw.isNotEmpty) {
      final parts =
          raw.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final a = parts[0];
        final b = (parts.length > 1) ? parts[1] : '';
        final f1 = a.isNotEmpty ? a[0] : '';
        final f2 = b.isNotEmpty ? b[0] : '';
        final joined = (f1 + f2).toUpperCase().trim();
        if (joined.isNotEmpty) initials = joined;
      }
    }
    return CircleAvatar(child: Text(initials));
  }

  // ------------------------------ UI ---------------------------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Impostazioni'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Tema ----------
            Text(
              'Tema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  RadioListTile<AppTheme>(
                    title: const Text('Light'),
                    value: AppTheme.light,
                    groupValue: _currentTheme,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _currentTheme = v);
                      await AppThemeController.instance.setTheme(v);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<AppTheme>(
                    title: const Text('Dark'),
                    value: AppTheme.dark,
                    groupValue: _currentTheme,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _currentTheme = v);
                      await AppThemeController.instance.setTheme(v);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<AppTheme>(
                    title: const Text('Grey'),
                    subtitle: const Text('Palette neutra in chiaro/scuro'),
                    value: AppTheme.grey,
                    groupValue: _currentTheme,
                    onChanged: (v) async {
                      if (v == null) return;
                      setState(() => _currentTheme = v);
                      await AppThemeController.instance.setTheme(v);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------- Notifiche ----------
            Text(
              'Gestione Notifiche',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
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
                secondary: const Icon(Icons.notifications),
              ),
            ),
            Card(
              elevation: 2,
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
                secondary: const Icon(Icons.notifications_active),
              ),
            ),
            Card(
              elevation: 2,
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
                secondary: const Icon(Icons.battery_alert),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Le notifiche in background richiedono di disattivare l’ottimizzazione batteria per questa app.',
                style: TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 28),

            // ---------- GPS ----------
            Text(
              'Gestione GPS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
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
                secondary: const Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 28),

            // ---------- Categoria personalizzata ----------
            Text(
              'Categoria personalizzata',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(Icons.tag),
                title: const Text('Nome categoria personalizzata'),
                subtitle: Text(
                  (_customCategoryName == null ||
                          (_customCategoryName ?? '').isEmpty)
                      ? 'Nessuna — tocca per impostare'
                      : 'Attiva: ${_customCategoryName ?? ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((_customCategoryName ?? '').isNotEmpty)
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

            const SizedBox(height: 28),

            // ---------- Utenti bloccati ----------
            Text(
              'Utenti bloccati',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
                child: _loadingBlocked
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : (_blockedUsers.isEmpty
                        ? const ListTile(
                            leading: Icon(Icons.info_outline),
                            title: Text('Nessun utente bloccato.'),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _blockedUsers.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final u = _blockedUsers[i];
                              return ListTile(
                                leading: _avatarFor(u),
                                title: Text(
                                  u.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                trailing: TextButton.icon(
                                  onPressed: () => _unblockUser(u),
                                  icon: const Icon(Icons.block),
                                  label: const Text('Sblocca'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                              );
                            },
                          )),
              ),
            ),

            const SizedBox(height: 28),
            const Center(
              child: Text(
                'Versione App: $appVersion',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Categoria personalizzata: salva ----------
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
    final limited = trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
    await prefs.setString('custom_category_name', limited);
    setState(() => _customCategoryName = limited);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Categoria personalizzata impostata: $limited')),
      );
    }
  }

  // ---------- Categoria personalizzata: dialog ----------
  Future<void> _showCustomNameDialog() async {
    final controller = TextEditingController(text: _customCategoryName ?? '');
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
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
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.of(context).pop();
                _saveCustomCategoryName(null);
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
                      () => errorText = 'Il nome non può essere vuoto');
                  return;
                }
                Navigator.of(context).pop();
                _saveCustomCategoryName(v);
              },
              child: const Text('SALVA'),
            ),
          ],
        ),
      ),
    );
  }
}
