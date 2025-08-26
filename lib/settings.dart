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
import 'package:myapp/gen_l10n/app_localizations.dart';

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

  // Lingua (UI locale corrente)
  Locale _currentLocale = AppThemeController.instance.locale;
  late final VoidCallback _localeListener;

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

    // ⬇️ ascolta cambi lingua per aggiornare le Radio
    _localeListener = () {
      if (mounted) {
        setState(() => _currentLocale = AppThemeController.instance.locale);
      }
    };
    AppThemeController.instance.addListener(_localeListener);
  }

  @override
  void dispose() {
    _myDocSub?.cancel();
    AppThemeController.instance.removeListener(_localeListener);
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
        if (mounted) {
          setState(() => _notificationPermissionGranted = ns.isGranted);
        }
        if (!ns.isGranted && mounted) {
          final l10n = AppLocalizations.of(context);
          _showSettingsDialog(
            title: l10n.permissionRequired,
            message: l10n.notificationPermissionMessage,
          );
                }
      } else if (mounted) {
        setState(() => _notificationPermissionGranted = true);
      }
    } else if (mounted) {
      setState(() => _notificationPermissionGranted = true);
    }
  }

  Future<void> _checkBatteryOptimization() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (mounted) {
      setState(() => _isBatteryUnrestricted = status.isGranted);
    }
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
    if (mounted) {
      setState(() {
        _locationPermissionGranted =
            permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever && mounted) {
      final l10n = AppLocalizations.of(context);
      _showSettingsDialog(
        title: l10n.locationPermissionRequired,
        message: l10n.locationPermissionMessage,
      );
          setState(() => _locationPermissionGranted = false);
      return;
    }
    if (mounted) {
      setState(() {
        _locationPermissionGranted =
            permission == LocationPermission.whileInUse ||
                permission == LocationPermission.always;
      });
    }
  }

  void _showSettingsDialog({required String title, required String message}) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
     TextButton(
  onPressed: () async {
    final nav = Navigator.of(context);
    final canPop = Navigator.canPop(context);
    
    await openAppSettings();
    
    if (!mounted || !canPop) return;
    nav.pop();
  },
  child: Text(l10n.settings),
)
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
    if (mounted) {
      setState(() {
        _myUid = null;
        _loadingBlocked = false;
        _blockedUsers = [];
      });
    }
    return;
  }

  if (mounted) {
    setState(() {
      _myUid = myUid;
      _loadingBlocked = true;
    });
  }

  _myDocSub?.cancel();
  _myDocSub =
      _fs.collection('utenti').doc(myUid).snapshots().listen((snap) async {
    // Verifica se il widget è ancora montato prima di procedere
    if (!mounted) return;
    
    final data = snap.data() ?? <String, dynamic>{};

    final rawIds = (data['id_bloccati'] as List<dynamic>?) ?? const [];
    final blockedIds =
        rawIds.map((e) => e.toString()).where((e) => e.isNotEmpty).toSet();
    blockedIds.remove(myUid);

    // Ottieni le localizzazioni solo dopo aver verificato che il widget è montato
    final l10n = AppLocalizations.of(context);
    final initial = blockedIds
        .map((uid) => BlockedUser(
              uid: uid,
              name: _volatileNameCache[uid] ?? (l10n.anonymous),
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

    // Ottieni le localizzazioni in modo sicuro controllando mounted
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    
    final Map<String, String> found = {};
    for (final d in q.docs) {
      final m = d.data();
      final sid = (m['senderId'] as String?) ?? '';
      if (!missing.contains(sid)) continue;
      if (found.containsKey(sid)) continue;

      final rawName = (m['name'] as String?)?.trim() ?? '';
      final anonymousText = l10n.anonymous;
      if (rawName.isNotEmpty && rawName.toLowerCase() != anonymousText.toLowerCase()) {
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
      if (mounted) {
        setState(() {
          _blockedUsers = _blockedUsers.where((x) => x.uid != u.uid).toList();
        });
      }

      await _fs.collection('utenti').doc(_myUid!).set({
        'id_bloccati': FieldValue.arrayRemove([u.uid])
      }, SetOptions(merge: true));

      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.unblock} ${u.name}')),
      );
        } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.genericError)),
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
    final l10n = AppLocalizations.of(context);
    
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- Tema ----------
            Text(
              l10n.themeLabel,
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
                    title: Text(l10n.lightTheme),
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
                    title: Text(l10n.darkTheme),
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
                    title: Text(l10n.greyTheme),
                    subtitle: Text(l10n.greyThemeDescription),
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

            // ---------- Lingua ----------
            Text(
              l10n.languageLabel,
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
                  RadioListTile<Locale>(
                    title: Text(l10n.english),
                    value: const Locale('en'),
                    groupValue: _currentLocale,
                    onChanged: (l) {
                      if (l == null) return;
                      AppThemeController.instance.setLocale(l);
                    },
                  ),
                  const Divider(height: 1),
                  RadioListTile<Locale>(
                    title: Text(l10n.italian),
                    value: const Locale('it'),
                    groupValue: _currentLocale,
                    onChanged: (l) {
                      if (l == null) return;
                      AppThemeController.instance.setLocale(l);
                    },
                  ),
                   const Divider(height: 1),
                  // Tedesco 
                   RadioListTile<Locale>(
                   title: Text(l10n.german),
                   value: const Locale('de'),
                   groupValue: _currentLocale,
                   onChanged: (l) {
                   if (l == null) return;
                   AppThemeController.instance.setLocale(l);
        },
      ),           
                   const Divider(height: 1),
                // Spagnolo
                   RadioListTile<Locale>(
                   title: Text(l10n.spanish),
                   value: const Locale('es'),
                   groupValue: _currentLocale,
                   onChanged: (l) {
                   if (l == null) return;
                   AppThemeController.instance.setLocale(l);
  },
),                
               const Divider(height: 1),
                // Francese (nuova lingua aggiunta)
                   RadioListTile<Locale>(
                   title: Text(l10n.french),
                   value: const Locale('fr'),
                   groupValue: _currentLocale,
                   onChanged: (l) {
                  if (l == null) return;
                  AppThemeController.instance.setLocale(l);
                  },
                 ),
                 const Divider(height: 1),
                 // Ucraino
                 RadioListTile<Locale>(
                 title: Text(l10n.ukrainian),
                 value: const Locale('uk'),
                 groupValue: _currentLocale,
                 onChanged: (l) {
                 if (l == null) return;
                 AppThemeController.instance.setLocale(l);
    },
),
               const Divider(height: 1),
              // Russo
              RadioListTile<Locale>(
              title: Text(l10n.russian),
              value: const Locale('ru'),
              groupValue: _currentLocale,
              onChanged: (l) {
              if (l == null) return;
              AppThemeController.instance.setLocale(l);
  },
),
              const Divider(height: 1),
              // Portoghese 
              RadioListTile<Locale>(
              title: Text(l10n.portuguese),
              value: const Locale('pt'),
              groupValue: _currentLocale,
              onChanged: (l) {
              if (l == null) return;
              AppThemeController.instance.setLocale(l);
  },
),

           const Divider(height: 1),
              // Arabo
          RadioListTile<Locale>(
           title: Text(l10n.arabic),
           value: const Locale('ar'),
           groupValue: _currentLocale,
           onChanged: (l) {
          if (l == null) return;
          AppThemeController.instance.setLocale(l);
  },
),

         const Divider(height: 1),
        // Cinese
        RadioListTile<Locale>(
       title: Text(l10n.chinese),
       value: const Locale('zh'),
      groupValue: _currentLocale,
       onChanged: (l) {
      if (l == null) return;
      AppThemeController.instance.setLocale(l);
  },
),

const Divider(height: 1),
// Giapponese
RadioListTile<Locale>(
  title: Text(l10n.japanese),
  value: const Locale('ja'),
  groupValue: _currentLocale,
  onChanged: (l) {
    if (l == null) return;
    AppThemeController.instance.setLocale(l);
  },
),





               
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ---------- Notifiche ----------
            Text(
              l10n.notificationsLabel,
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
                title: Text(l10n.enableNotifications),
                subtitle: Text(
                  _notificationPermissionGranted
                      ? l10n.authorizationGranted
                      : l10n.requestAuthorization,
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
                title: Text(l10n.notificationSound),
                subtitle: Text(l10n.notificationSoundDescription),
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
                title: Text(l10n.backgroundExecution),
                subtitle: Text(
                  _isBatteryUnrestricted
                      ? l10n.batteryOptimizationDisabled
                      : l10n.batteryOptimizationWarning,
                ),
                value: _isBatteryUnrestricted,
                onChanged: (_) => _requestIgnoreBatteryOptimization(),
                secondary: const Icon(Icons.battery_alert),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                l10n.batteryOptimizationWarning,
                style: const TextStyle(fontSize: 14),
              ),
            ),

            const SizedBox(height: 28),

            // ---------- GPS ----------
            Text(
              l10n.gpsManagement,
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
                title: Text(l10n.enableLocation),
                subtitle: Text(
                  _locationPermissionGranted
                      ? l10n.locationAccessEnabled
                      : l10n.requestGpsAuthorization,
                ),
                value: _locationPermissionGranted,
                onChanged: (_) => _requestLocationPermission(),
                secondary: const Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 28),

            // ---------- Categoria personalizzata ----------
            Text(
              l10n.customCategory,
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
                title: Text(l10n.customCategoryName),
                subtitle: Text(
                  (_customCategoryName == null ||
                          (_customCategoryName ?? '').isEmpty)
                      ? l10n.noCategorySet
                      : '${l10n.activeCategory}: ${_customCategoryName ?? ''}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if ((_customCategoryName ?? '').isNotEmpty)
                      IconButton(
                        tooltip: l10n.remove,
                        onPressed: () => _saveCustomCategoryName(null),
                        icon: const Icon(Icons.clear),
                      ),
                    IconButton(
                      tooltip: l10n.edit,
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
              l10n.blockedUsers,
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
                        ? ListTile(
                            leading: const Icon(Icons.info_outline),
                            title: Text(l10n.noBlockedUsers),
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
                                  label: Text(l10n.unblock),
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
            Center(
              child: Text(
                '${l10n.appVersion}: $appVersion',
                style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    
    final prefs = await SharedPreferences.getInstance();
    final trimmed = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (trimmed.isEmpty) {
      await prefs.remove('custom_category_name');
      if (mounted) {
        setState(() => _customCategoryName = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.customCategoryDisabled)),
        );
      }
      return;
    }
    final limited = trimmed.length > 32 ? trimmed.substring(0, 32) : trimmed;
    await prefs.setString('custom_category_name', limited);
    if (mounted) {
      setState(() => _customCategoryName = limited);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.customCategorySet}: $limited')),
      );
    }
  }

  // ---------- Categoria personalizzata: dialog ----------
  Future<void> _showCustomNameDialog() async {
    final l10n = AppLocalizations.of(context);
    
    final controller = TextEditingController(text: _customCategoryName ?? '');
    String? errorText;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text(l10n.customCategoryDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.customCategoryDialogDescription),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 32,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: l10n.customCategoryHint,
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
              child: Text(l10n.remove),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final v = controller.text.trim();
                if (v.isEmpty) {
                  setLocalState(() => errorText = l10n.nameCannotBeEmpty);
                  return;
                }
                Navigator.of(context).pop();
                _saveCustomCategoryName(v);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}