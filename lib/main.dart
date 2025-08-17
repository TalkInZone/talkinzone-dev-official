// main.dart — completo (Material 3, no composer duplicato, listener ottimizzato)
// 🔧 Patch già incluse:
// - In backgroundNotificationHandler(): se type == 'text' non cancellare su Storj.
// - In _cleanupOldMessages(): cancella su Storj solo se message.isVoice.
// - In _runStartupCleanup(): se type == 'text' non cancellare su Storj.
// ✅ Reazioni: toggle su campo Firestore `reactions.<emoji>` (array di uid).
// ✅ Fix welcome: pannello profilo e barra input NON compaiono quando è visibile il welcome.
// ✅ Material 3 + dark mode.
// ✅ Rimosso composer overlay in basso (ora solo dentro HomeScreenUI).
// 🆕 Age Gate: se `data_di_nascita` è null, mostra form obbligatorio all’avvio (età minima 16 anni).
//    Testi/modifiche centralizzati in AgeGateConfig/AgeGateStrings. Avviso sospensione per dati falsi.
// ✅ Categorie personalizzate: scrittura/lettura di `customCategoryName` su Firestore.
// ✅ VISIBILITÀ: listener Firestore senza filtro WHERE su timestamp (vede subito i messaggi nuovi).

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/app_constants.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'settings.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'services/storj_service.dart';
import 'update_required_screen.dart';
import 'category_utils.dart';
import 'home_screen_ui.dart';
import 'voice_message.dart';
import 'services/user_profile.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await backgroundNotificationHandler();
    return true;
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("🔄 Inizio processo autenticazione Google...");
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
        debugPrint("✅ Logout effettuato con successo");
      } catch (e) {
        debugPrint("⚠️ Errore durante il logout: $e");
      }

      final GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint("❌ L'utente ha annullato l'accesso");
          return null;
        }
        debugPrint("✅ Account selezionato: ${googleUser.email}");
      } on PlatformException catch (e) {
        if (e.code == 'sign_in_canceled') {
          debugPrint("❌ Accesso annullato dall'utente");
          return null;
        }
        debugPrint("❌ PlatformException durante signIn: ${e.message}");
        return null;
      } catch (e) {
        debugPrint("❌ Errore imprevisto durante signIn: $e");
        return null;
      }

      final GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication;
        debugPrint("✅ Token di autenticazione ottenuti");
      } catch (e) {
        debugPrint("❌ Errore durante l'autenticazione: $e");
        return null;
      }

      if (googleAuth.idToken == null) {
        debugPrint("❌ ID Token mancante");
        return null;
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        final UserCredential userCredential =
            await _auth.signInWithCredential(credential);

        if (userCredential.user == null) {
          debugPrint("❌ Nessun utente restituito da Firebase");
          return null;
        }

        debugPrint("🎉 Accesso riuscito! UID: ${userCredential.user!.uid}");

        // Upsert + schema reconciliation del profilo
        await _saveUserData(userCredential.user!);

        return userCredential.user;
      } on FirebaseAuthException catch (e) {
        debugPrint("🔥 FirebaseAuthException: [${e.code}] ${e.message}");
        return null;
      } catch (e) {
        debugPrint("❌ Errore durante signInWithCredential: $e");
        return null;
      }
    } catch (e, stack) {
      debugPrint("💥 ERRORE GLOBALE: $e\n$stack");
      return null;
    }
  }

  Future<void> _saveUserData(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);

      await UserProfile.upsertOnAuth(user,
          provider: 'google', pruneUnknownKeys: true);

      debugPrint(
          "✅ Dati utente (upsert) salvati/aggiornati per UID: ${user.uid}");

      final userDoc =
          FirebaseFirestore.instance.collection('utenti').doc(user.uid);
      final docSnapshot = await userDoc.get();
      if (docSnapshot.exists) {
        debugPrint("🎉 Verificato: documento utente esiste in Firestore");
      } else {
        debugPrint("❌ Documento non trovato dopo il salvataggio");
      }
    } catch (e, stack) {
      debugPrint('💥 ERRORE CRITICO salvataggio dati utente: $e');
      debugPrint('🔥 Stack trace: $stack');
      if (e is FirebaseException) {
        debugPrint("🔥 FIREBASE ERROR CODE: ${e.code}");
        debugPrint("🔥 FIREBASE MESSAGE: ${e.message}");
      }
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      debugPrint("✅ Disconnessione effettuata con successo");
    } catch (e, stack) {
      debugPrint("❌ Errore durante la disconnessione: $e\n$stack");
    }
  }

  void debugAuthConfiguration() {
    try {
      debugPrint("🔧 DEBUG CONFIGURAZIONE AUTH");
      debugPrint("🔥 Firebase project ID: ${Firebase.app().options.projectId}");
    } catch (e) {
      debugPrint("❌ Errore debug configurazione: $e");
    }
  }
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidInitializationSettings);

    await _notificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNewMessageNotification({
    required String category,
    required String messageId,
    required bool isText,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'new_message',
      'Nuovi messaggi',
      channelDescription: 'Notifiche per nuovi messaggi',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _notificationsPlugin.show(
      messageId.hashCode,
      'Nuovo messaggio ${category.toLowerCase()}',
      isText ? 'Clicca per leggere' : 'Clicca per ascoltare',
      notificationDetails,
      payload: messageId,
    );
  }
}

Future<void> backgroundNotificationHandler() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;
  final prefs = await SharedPreferences.getInstance();

  try {
    final now = DateTime.now();
    final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

    final expiredMessages = await firestore
        .collection('messages')
        .where('timestamp', isLessThan: Timestamp.fromDate(fiveMinutesAgo))
        .get();

    final storjService = StorjService();
    await storjService.initialize();

    for (final doc in expiredMessages.docs) {
      try {
        final data = doc.data();
        final String type = (data['type'] as String?) ?? 'voice';
        final objectKey = data['storjObjectKey'] as String? ?? '';
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp == null) continue;

        final expirationTime = timestamp.toDate().add(
              const Duration(minutes: 5),
            );
        if (DateTime.now().isBefore(expirationTime)) {
          debugPrint('⏱️ [BACKGROUND] Messaggio non ancora scaduto, salto');
          continue;
        }

        debugPrint('🗑️ [BACKGROUND] Cancellazione messaggio scaduto: ${doc.id}'
            ' (Inviato: ${timestamp.toDate()}, Scaduto: $expirationTime)');

        // ✅ Skip cancellazione Storj per messaggi testuali
        if (type != 'text' && objectKey.isNotEmpty) {
          try {
            await storjService.deleteFile(objectKey);
            debugPrint('✅ [BACKGROUND] File audio cancellato su Storj');
          } catch (e) {
            debugPrint('⚠️ [BACKGROUND] Errore Storj: $e');
          }
        }

        await doc.reference.delete();
        debugPrint('✅ [BACKGROUND] Metadati Firestore cancellati');
      } catch (e) {
        debugPrint('❌ [BACKGROUND] Errore cancellazione: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ [BACKGROUND] Errore pulizia: $e');
  }

  final notificationEnabled = prefs.getBool('notification_sound') ?? true;
  if (!notificationEnabled) return;

  final currentUserIdPrefs = prefs.getString('user_id') ?? '';
  final currentUserIdAuth = FirebaseAuth.instance.currentUser?.uid ?? '';
  final currentUserId =
      (currentUserIdAuth.isNotEmpty ? currentUserIdAuth : currentUserIdPrefs);

  final selectedRadius = prefs.getDouble('selected_radius') ?? 500.0;

  Position? lastKnownPosition;
  try {
    lastKnownPosition = await Geolocator.getLastKnownPosition();
  } catch (e) {
    debugPrint('📍 Errore posizione: $e');
  }

  final lastLatitude =
      lastKnownPosition?.latitude ?? prefs.getDouble('last_latitude');
  final lastLongitude =
      lastKnownPosition?.longitude ?? prefs.getDouble('last_longitude');

  final now = DateTime.now();
  final lastRunTime = prefs.getInt('lastRunTime') ?? 0;
  final lastRunDateTime = DateTime.fromMillisecondsSinceEpoch(lastRunTime);

  try {
    final messages = await firestore
        .collection('messages')
        .where(
          'timestamp',
          isGreaterThan: Timestamp.fromDate(lastRunDateTime),
        )
        .get();

    final notificationService = NotificationService();
    await notificationService.initialize();

    for (final doc in messages.docs) {
      final data = doc.data();
      final senderId = data['senderId'] as String? ?? '';

      if (senderId == currentUserId) continue;

      if (lastLatitude != null && lastLongitude != null) {
        final messageLat = data['latitude'] as double? ?? 0.0;
        final messageLon = data['longitude'] as double? ?? 0.0;

        final distance = Geolocator.distanceBetween(
          lastLatitude,
          lastLongitude,
          messageLat,
          messageLon,
        );

        if (distance <= selectedRadius) {
          // 🆕 Categoria personalizzata: mostra il nome reale nelle notifiche
          String category = data['category'] as String? ?? 'free';
          if (category.toLowerCase() == 'custom' ||
              category.toLowerCase() == 'special' ||
              category.toLowerCase() == 'personalizzata') {
            final cn = (data['customCategoryName'] as String?)?.trim();
            if (cn != null && cn.isNotEmpty) category = cn;
          }
          final String type = (data['type'] as String?) ?? 'voice';
          final bool isText = type == 'text';

          notificationService.showNewMessageNotification(
            category: category,
            messageId: doc.id,
            isText: isText,
          );
        }
      }
    }

    prefs.setInt('lastRunTime', now.millisecondsSinceEpoch);
  } catch (e) {
    debugPrint('❌ Errore notifiche: $e');
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', width: 120, height: 120),
            const SizedBox(height: 40),
            const Text(
              'Benvenuto in TalkInZone',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Per iniziare, accedi con il tuo account Google',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),

            // Pulsante Google (Material 3)
            FilledButton.icon(
              onPressed: () async {
                debugPrint("👉 Bottone di accesso premuto (Google)");
                final user = await authService.signInWithGoogle();
                if (user == null) {
                  debugPrint("❌ Accesso Google fallito");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Accesso fallito. Riprova.')),
                    );
                  }
                } else {
                  debugPrint("✅ Accesso Google riuscito, navigazione...");
                }
              },
              icon:
                  Image.asset('assets/google_logo.png', width: 20, height: 20),
              label: const Text('Accedi con Google'),
              style: FilledButton.styleFrom(minimumSize: const Size(280, 48)),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const VoiceChatApp();
        }

        return const MaterialApp(home: LoginScreen());
      },
    );
  }
}

class VoiceChatHome extends StatefulWidget {
  const VoiceChatHome({super.key});

  @override
  State<VoiceChatHome> createState() => _VoiceChatHomeState();
}

class _VoiceChatHomeState extends State<VoiceChatHome>
    with WidgetsBindingObserver {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  final StorjService storjService = StorjService();

  bool _isRecording = false;
  bool _isPlaying = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  Timer? _cleanupTimer;
  Timer? _countdownTimer;
  String? _currentRecordingPath;
  Position? _currentPosition;

  Timer? _gpsUpdateTimer;
  bool _isAppInForeground = true;

  final List<VoiceMessage> _messages = [];
  String? _playingMessageId;

  MessageCategory _selectedCategory = MessageCategory.free;
  final Set<MessageCategory> _activeFilters = MessageCategory.values.toSet();
  bool _showCategorySelector = false;
  bool _showFilterSelector = false;
  bool _isInitialized = false;

  double _selectedRadius = 500;
  final List<double> _radiusOptions = [500, 1000, 2000, 3000, 5000];
  bool _showRadiusSelector = false;

  bool _notificationSoundEnabled = true;
  final CollectionReference _firestoreMessages =
      FirebaseFirestore.instance.collection('messages');

  StreamSubscription<QuerySnapshot>? _messagesSubscription;
  String? _currentUserId;

  bool _showWelcomeMessage = false;

  Timer? _longPressTimer;
  bool _isLongPressRecording = false;
  bool _isWaitingForRelease = false;

  Map<String, dynamic>? _currentUserData;
  bool _showUserInfo = false;

  bool _isDisposed = false;

  // NEW: testo
  final TextEditingController _textController = TextEditingController();
  bool _isSendingText = false;

  // NEW: debounce locale per “testo visto”
  final Set<String> _textSeenOnce = {};

  // 🔧 NEW: evita sync multiple dello schema profilo
  bool _didSchemaSync = false;

  // 🆕 Categoria personalizzata — stato utente (nome scelto in Settings)
  String? _customCategoryName; // SharedPreferences: 'custom_category_name'
  MessageCategory?
      _customEnum; // valore enum per la categoria personalizzata (se presente)
  final Map<String, String> _msgCustomNames = {}; // idMsg -> nome custom su doc

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _textController.addListener(() {
      if (mounted) setState(() {});
    });

    _loadSettings();
    _initializeApp();
    _touchLastAccessIfLoggedIn();
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);

    _messagesSubscription?.cancel();
    _recordingTimer?.cancel();
    _cleanupTimer?.cancel();
    _countdownTimer?.cancel();
    _longPressTimer?.cancel();
    _gpsUpdateTimer?.cancel();

    _textController.dispose();

    try {
      _recorder?.closeRecorder();
      _player?.closePlayer();
    } catch (e) {
      debugPrint('❌ Errore cleanup risorse: $e');
    }

    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    final uidAuth = FirebaseAuth.instance.currentUser?.uid;
    final uidPrefs = prefs.getString('user_id');
    final resolvedUid =
        (uidAuth != null && uidAuth.isNotEmpty) ? uidAuth : (uidPrefs ?? '');

    setState(() {
      _notificationSoundEnabled = prefs.getBool('notification_sound') ?? true;
      _currentUserId = resolvedUid;
      _selectedRadius = prefs.getDouble('selected_radius') ?? 500.0;

      final isFirstLaunch = prefs.getBool('first_launch') ?? true;
      _showWelcomeMessage = isFirstLaunch;
      if (isFirstLaunch) prefs.setBool('first_launch', false);

      // 🆕 Categoria personalizzata: carica nome scelto
      final rawName = (prefs.getString('custom_category_name') ?? '').trim();
      _customCategoryName = rawName.isEmpty ? null : rawName;

      _customEnum = _findCustomEnum();
    });

    // 🔧 NEW: sincronizza lo schema del profilo
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && uid.isNotEmpty && !_didSchemaSync) {
        await UserProfile.syncSchemaWithDatabase(uid, pruneUnknownKeys: true);
        _didSchemaSync = true;
        debugPrint("✅ Schema profilo sincronizzato per UID: $uid");
      }
    } catch (e) {
      debugPrint("❌ Sync schema fallita: $e");
    }

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      await _loadUserData();
    }
  }

  MessageCategory? _findCustomEnum() {
    for (final c in MessageCategory.values) {
      final n = c.name.toLowerCase();
      if (n == 'custom' || n == 'special' || n == 'personalizzata') {
        return c;
      }
    }
    return null;
  }

  bool _isCustomCategoryEnum(MessageCategory c) =>
      _customEnum != null && c.name == _customEnum!.name;

  bool _matchesMyCustomName(VoiceMessage m) {
    if (_customEnum == null) return true;
    if (m.category.name != _customEnum!.name) return true;
    final myName = (_customCategoryName ?? '').trim();
    if (myName.isEmpty) return false;
    final msgName =
        (_msgCustomNames[m.id] ?? m.customCategoryName ?? '').trim();
    return msgName.isNotEmpty && msgName.toLowerCase() == myName.toLowerCase();
  }

  bool _requireCustomNameOrWarn() {
    if (_customEnum == null) return true;
    if (_selectedCategory.name != _customEnum!.name) return true;
    if ((_customCategoryName ?? '').trim().isNotEmpty) return true;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Imposta il nome della categoria personalizzata nelle Impostazioni.'),
      ),
    );
    return false;
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(_currentUserId!)
          .get();

      if (userDoc.exists) {
        setState(() {
          _currentUserData = userDoc.data() as Map<String, dynamic>;
        });
        debugPrint("✅ Dati utente caricati: $_currentUserData");
      } else {
        debugPrint("⚠️ Documento utente non trovato per ID: $_currentUserId");
      }
    } catch (e) {
      debugPrint('❌ Errore caricamento dati utente: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() => _isAppInForeground = true);
      _getCurrentLocation();
      _startGpsTimer();
      _touchLastAccessIfLoggedIn();
    } else if (state == AppLifecycleState.paused) {
      setState(() => _isAppInForeground = false);
      _gpsUpdateTimer?.cancel();
    }
  }

  Future<void> _touchLastAccessIfLoggedIn() async {
    try {
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('utenti')
            .doc(_currentUserId!)
            .set(UserProfile.touchLastAccess(), SetOptions(merge: true));
        debugPrint("🕒 ultimo_accesso aggiornato per UID: $_currentUserId");
      }
    } catch (e) {
      debugPrint('❌ Errore aggiornamento ultimo_accesso: $e');
    }
  }

  void _startGpsTimer() {
    _gpsUpdateTimer?.cancel();
    _gpsUpdateTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (_isAppInForeground) _getCurrentLocation();
    });
  }

  Future<void> _initializeApp() async {
    await _initializeAudio();
    await storjService.initialize();
    await _getCurrentLocation();
    _startTimers();

    _initializeFirestoreListener();

    setState(() => _isInitialized = true);
  }

  void _startTimers() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (!_isDisposed) _cleanupOldMessages();
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed) setState(() {});
    });
  }

  void _initializeFirestoreListener() {
    // 🔧 FIX VISIBILITÀ:
    // RIMOSSO il WHERE sul timestamp (i documenti con serverTimestamp() null non passavano il filtro).
    // Manteniamo solo l'ORDER BY + LIMIT; l'expiry (5 min) viene gestito in locale.
    _messagesSubscription = _firestoreMessages
        .orderBy('timestamp', descending: true)
        .limit(200)
        .snapshots()
        .listen(
      (snapshot) {
        _processFirestoreSnapshot(snapshot);
      },
      onError: (error) {
        debugPrint('🔥 Errore Firestore: $error');
      },
    );
  }

  Future<String> _resolveCurrentUserDisplayName() async {
    try {
      final cached = _currentUserData?['nome'];
      if (cached is String && cached.trim().isNotEmpty) {
        return cached.trim();
      }

      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        final snap = await FirebaseFirestore.instance
            .collection('utenti')
            .doc(_currentUserId!)
            .get();
        final nome = snap.data()?['nome'];
        if (nome is String && nome.trim().isNotEmpty) {
          return nome.trim();
        }
      }

      final authName =
          FirebaseAuth.instance.currentUser?.displayName?.trim() ?? '';
      if (authName.isNotEmpty) return authName;

      final email = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
      if (email.isNotEmpty) return email.split('@').first;

      return 'Anonimo';
    } catch (_) {
      return 'Anonimo';
    }
  }

  Future<void> _ensureMessageHasName(DocumentSnapshot doc) async {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final hasName = (data['name'] as String?)?.trim().isNotEmpty == true;
      final senderId = (data['senderId'] as String?) ?? '';

      if (hasName || senderId.isEmpty) return;

      final userSnap = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(senderId)
          .get();
      String? nome = (userSnap.data()?['nome'] as String?)?.trim();

      if (nome == null || nome.isEmpty) {
        nome = 'Anonimo';
      }

      await doc.reference.update({'name': nome});
      debugPrint('✍️ Aggiornato name su messaggio ${doc.id}: $nome');
    } catch (e) {
      debugPrint('ℹ️ Skip ensure name for ${doc.id}: $e');
    }
  }

  void _processFirestoreSnapshot(QuerySnapshot snapshot) {
    final now = DateTime.now();
    final newMessages = <VoiceMessage>[];
    final removedMessages = <String>[];
    final updatedMessages = <VoiceMessage>[];

    for (var doc in snapshot.docs) {
      try {
        _ensureMessageHasName(doc);

        final newMessage = VoiceMessage.fromFirestore(doc);
        final isExpired = now.difference(newMessage.timestamp).inMinutes >= 5;

        // 🆕 salva il nome custom della categoria per filtri locali
        try {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final cn = (data['customCategoryName'] as String?)?.trim();
          if (cn != null && cn.isNotEmpty) _msgCustomNames[doc.id] = cn;
        } catch (_) {}

        if (isExpired) {
          removedMessages.add(newMessage.id);
        } else {
          final existingIndex =
              _messages.indexWhere((m) => m.id == newMessage.id);
          if (existingIndex != -1) {
            final updatedMessage = newMessage.copyWith(
              localPath: _messages[existingIndex].localPath,
            );
            updatedMessages.add(updatedMessage);
          } else {
            newMessages.add(newMessage);
            if (_notificationSoundEnabled &&
                _isMessageInRange(newMessage) &&
                _activeFilters.contains(newMessage.category) &&
                _matchesMyCustomName(newMessage) &&
                newMessage.senderId != _currentUserId) {
              SystemSound.play(SystemSoundType.alert);
            }
          }
        }
      } catch (e) {
        debugPrint('❌ Errore conversione documento: $e');
      }
    }

    if (!_isDisposed) {
      setState(() {
        _messages.removeWhere((msg) => removedMessages.contains(msg.id));
        for (final mid in removedMessages) {
          _msgCustomNames.remove(mid);
        }

        for (final updated in updatedMessages) {
          final index = _messages.indexWhere((m) => m.id == updated.id);
          if (index != -1) _messages[index] = updated;
        }

        if (newMessages.isNotEmpty) _messages.addAll(newMessages);
        _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }

  Future<void> _resetRecorder() async {
    try {
      if (_recorder != null) {
        if (_recorder!.isRecording) await _recorder!.stopRecorder();
        await _recorder!.closeRecorder();
        await Future.delayed(const Duration(milliseconds: 200));
        await _recorder!.openRecorder();
      }
    } catch (e) {
      debugPrint('❌ Errore reset recorder: $e');
    }
  }

  Future<void> _initializeAudio() async {
    try {
      _recorder = FlutterSoundRecorder();
      _player = FlutterSoundPlayer();
      await _recorder!.openRecorder();
      await _player!.openPlayer();
    } catch (e) {
      debugPrint('❌ Errore inizializzazione audio: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('📍 Permesso localizzazione negato');
        return;
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setDouble(
          'last_latitude',
          _currentPosition?.latitude ?? 0.0,
        );
        await prefs.setDouble(
          'last_longitude',
          _currentPosition?.longitude ?? 0.0,
        );
        await prefs.setDouble(
          'notification_latitude',
          _currentPosition?.latitude ?? 0.0,
        );
        await prefs.setDouble(
          'notification_longitude',
          _currentPosition?.longitude ?? 0.0,
        );
      }
    } catch (e) {
      debugPrint('❌ Errore posizione: $e');
    }
  }

  Future<void> _cleanupOldMessages() async {
    if (_isDisposed) return;

    final now = DateTime.now();
    final messagesToRemove = <VoiceMessage>[];

    for (final message in _messages) {
      final elapsedMinutes = now.difference(message.timestamp).inMinutes;
      if (elapsedMinutes >= 5) messagesToRemove.add(message);
    }

    if (messagesToRemove.isEmpty) return;

    for (final message in messagesToRemove) {
      try {
        final expirationTime =
            message.timestamp.add(const Duration(minutes: 5));
        if (DateTime.now().isBefore(expirationTime)) {
          debugPrint('⏱️ Messaggio non ancora scaduto, salto');
          continue;
        }

        debugPrint(
            '🗑️ [${DateTime.now()}] Cancellazione messaggio scaduto: ${message.id}');

        // ✅ Cancella su Storj SOLO se è un vocale
        if (message.isVoice && message.storjObjectKey.isNotEmpty) {
          try {
            await storjService.deleteFile(message.storjObjectKey);
            debugPrint('✅ File audio cancellato su Storj');
          } catch (e) {
            debugPrint('⚠️ Errore Storj: $e');
          }
        }

        await _firestoreMessages.doc(message.id).delete();
        debugPrint('✅ Metadati Firestore cancellati');

        if (!_isDisposed) {
          setState(() => _messages.remove(message));
        }
      } catch (e) {
        debugPrint('❌ Errore cancellazione: $e');
      }
    }
  }

  Future<void> _startRecording() async {
    if (!_isInitialized || _recorder == null || _isRecording) return;

    try {
      await _resetRecorder();
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) return;

      if (_isPlaying) {
        await _player!.stopPlayer();
        setState(() {
          _isPlaying = false;
          _playingMessageId = null;
        });
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.aac';

      await _recorder!.startRecorder(toFile: filePath, codec: Codec.aacADTS);

      await Future.delayed(const Duration(milliseconds: 100));
      final file = File(filePath);
      if (!await file.exists()) {
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
          _currentRecordingPath = null;
        });
        return;
      }

      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
        _currentRecordingPath = filePath;
        _showCategorySelector = false;
        _showRadiusSelector = false;
        _showFilterSelector = false;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isDisposed && _isRecording) {
          setState(() => _recordingSeconds++);
          if (_recordingSeconds >= 15) _stopRecording();
        }
      });
    } catch (e) {
      debugPrint('❌ Errore avvio registrazione: $e');
      setState(() {
        _isRecording = false;
        _recordingSeconds = 0;
        _currentRecordingPath = null;
      });
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _recorder == null) return;

    try {
      // 🆕 Se selezionata "custom" ma non impostato il nome, blocca invio
      if (!_requireCustomNameOrWarn()) {
        _recordingTimer?.cancel();
        await _recorder!.stopRecorder();
        await _resetRecorder();
        if (_currentRecordingPath != null) {
          try {
            await File(_currentRecordingPath!).delete();
          } catch (_) {}
        }
        if (mounted) {
          setState(() {
            _isRecording = false;
            _recordingSeconds = 0;
            _currentRecordingPath = null;
            _isLongPressRecording = false;
            _isWaitingForRelease = false;
          });
        }
        return;
      }

      _recordingTimer?.cancel();
      await _recorder!.stopRecorder();
      await _resetRecorder();

      if (_currentRecordingPath != null &&
          _currentPosition != null &&
          _recordingSeconds > 0) {
        try {
          final objectKey =
              await storjService.uploadFile(_currentRecordingPath!);

          final String senderName = await _resolveCurrentUserDisplayName();
          final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

          final Map<String, dynamic> payload = {
            'type': 'voice',
            'timestamp': FieldValue.serverTimestamp(),
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
            'duration': _recordingSeconds,
            'category': _isCustomCategoryEnum(_selectedCategory)
                ? (_customEnum!.name)
                : _selectedCategory.name,
            if (_isCustomCategoryEnum(_selectedCategory))
              'customCategoryName': (_customCategoryName ?? '').trim(),
            'storjObjectKey': objectKey,
            'senderId': currentUid ?? (_currentUserId ?? ''),
            'views': 0,
            'viewedBy': <String>[],
            'name': senderName,
            'text': null,
          };
          await _firestoreMessages.add(payload);
        } catch (e) {
          debugPrint('❌ Errore salvataggio messaggio: $e');
          try {
            await File(_currentRecordingPath!).delete();
          } catch (_) {}
        }
      } else {
        if (_currentRecordingPath != null) {
          try {
            await File(_currentRecordingPath!).delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('❌ Errore stop registrazione: $e');
    } finally {
      if (!_isDisposed) {
        setState(() {
          _isRecording = false;
          _recordingSeconds = 0;
          _currentRecordingPath = null;
          _isLongPressRecording = false;
          _isWaitingForRelease = false;
        });
      }
    }
  }

  Future<void> _sendTextMessage() async {
    final raw = _textController.text.trim();
    if (raw.isEmpty) return;

    // 🆕 Blocca invio se custom senza nome impostato
    if (!_requireCustomNameOrWarn()) return;

    if (raw.characters.length > 250) {
      _textController.text = raw.characters.take(250).toString();
    }

    if (_currentPosition == null) {
      await _getCurrentLocation();
    }

    try {
      setState(() => _isSendingText = true);

      final String senderName = await _resolveCurrentUserDisplayName();
      final String? currentUid = FirebaseAuth.instance.currentUser?.uid;

      final Map<String, dynamic> payload = {
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
        'duration': 0,
        'category': _isCustomCategoryEnum(_selectedCategory)
            ? (_customEnum!.name)
            : _selectedCategory.name,
        if (_isCustomCategoryEnum(_selectedCategory))
          'customCategoryName': (_customCategoryName ?? '').trim(),
        'storjObjectKey': '',
        'senderId': currentUid ?? (_currentUserId ?? ''),
        'views': 0,
        'viewedBy': <String>[],
        'name': senderName,
        'text': _textController.text.trim(),
      };

      await _firestoreMessages.add(payload);

      _textController.clear();
    } catch (e) {
      debugPrint('❌ Errore invio testo: $e');
    } finally {
      if (mounted) setState(() => _isSendingText = false);
    }
  }

  List<VoiceMessage> _getPlayableMessages() {
    final now = DateTime.now();
    final list = _messages.where((m) {
      final expired = now.difference(m.timestamp).inMinutes >= 5;
      if (expired) return false;
      if (!_isMessageInRange(m)) return false;
      if (!_activeFilters.contains(m.category)) return false;
      if (!_matchesMyCustomName(m)) return false;
      return true;
    }).toList();

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  Future<void> _playNextAfter(String justPlayedId) async {
    if (_isDisposed) return;
    final playable = _getPlayableMessages();
    final idx = playable.indexWhere((m) => m.id == justPlayedId);

    if (idx == -1 || idx == playable.length - 1) {
      if (!_isDisposed) {
        setState(() {
          _isPlaying = false;
          _playingMessageId = null;
        });
      }
      return;
    }

    final next = playable[idx + 1];
    await _playMessageInternal(next, fromAuto: true);
  }

  Future<void> _playMessage(VoiceMessage message) =>
      _playMessageInternal(message, fromAuto: false);

  Future<void> _playMessageInternal(VoiceMessage message,
      {bool fromAuto = false}) async {
    if (_player == null) return;

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? myUid = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : _currentUserId;
    if (myUid == null || myUid.isEmpty) return;

    if (message.isText) return;

    final bool alreadyViewed = message.viewedBy.contains(myUid);

    if (!fromAuto && _isPlaying && _playingMessageId == message.id) {
      try {
        await _player!.stopPlayer();
      } catch (_) {}
      if (!_isDisposed) {
        setState(() {
          _isPlaying = false;
          _playingMessageId = null;
        });
      }
      return;
    }

    try {
      if (!fromAuto && _isPlaying) {
        await _player!.stopPlayer();
        if (!_isDisposed) {
          setState(() {
            _isPlaying = false;
            _playingMessageId = null;
          });
        }
      }

      String audioPath = message.localPath ?? '';
      if (audioPath.isEmpty || !await File(audioPath).exists()) {
        try {
          audioPath = await storjService.downloadFile(message.storjObjectKey);
          message.localPath = audioPath;
          if (!_isDisposed) setState(() {});
        } catch (e) {
          debugPrint('❌ Errore download audio: $e');
          return;
        }
      }

      await _player!.startPlayer(
        fromURI: audioPath,
        whenFinished: () {
          if (_isDisposed) return;
          Future.microtask(() => _playNextAfter(message.id));
        },
      );

      if (!_isDisposed) {
        setState(() {
          _isPlaying = true;
          _playingMessageId = message.id;
        });
      }

      if (message.senderId != myUid && !alreadyViewed) {
        try {
          await _firestoreMessages.doc(message.id).update({
            'views': FieldValue.increment(1),
            'viewedBy': FieldValue.arrayUnion([myUid]),
          });
          if (!_isDisposed) {
            setState(() {
              message.views++;
              message.viewedBy.add(myUid);
            });
          }
        } catch (e) {
          debugPrint('❌ Errore aggiornamento visualizzazioni: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Errore riproduzione: $e');
      if (!_isDisposed) {
        setState(() {
          _isPlaying = false;
          _playingMessageId = null;
        });
      }
    }
  }

  bool _isMessageInRange(VoiceMessage message) {
    if (_currentPosition == null) return true;
    final distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      message.latitude,
      message.longitude,
    );
    return distance <= _selectedRadius;
  }

  void _handlePressStart() {
    if (!_isRecording && _isInitialized) {
      _longPressTimer = Timer(const Duration(milliseconds: 800), () {
        _isLongPressRecording = true;
        _isWaitingForRelease = true;
        _startRecording();
      });
    }
  }

  void _handlePressEnd() {
    _longPressTimer?.cancel();
    if (_isRecording) {
      if (_isLongPressRecording && _isWaitingForRelease) {
        if (!_isDisposed) {
          setState(() => _isWaitingForRelease = false);
        }
      } else {
        _stopRecording();
      }
    } else if (!_isLongPressRecording) {
      _startRecording();
    }
  }

  Future<void> _refreshAndToggleUserInfo() async {
    try {
      await _loadUserData();
    } catch (_) {}
    if (!_isDisposed) {
      setState(() {
        _showUserInfo = !_showUserInfo;
      });
    }
  }

  // NEW: marca "letto" per TESTO quando la bolla è visibile
  Future<void> _markTextMessageViewed(VoiceMessage message) async {
    if (!message.isText) return;

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? myUid = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : _currentUserId;

    if (myUid == null || myUid.isEmpty) return;
    if (message.senderId == myUid) return;
    if (message.viewedBy.contains(myUid)) return;
    if (_textSeenOnce.contains(message.id)) return;

    _textSeenOnce.add(message.id);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final docRef = _firestoreMessages.doc(message.id);
        final snap = await txn.get(docRef);
        final data = snap.data() as Map<String, dynamic>? ?? {};

        final List<dynamic> viewedByDyn =
            (data['viewedBy'] as List<dynamic>?) ?? const [];
        final viewedBy = viewedByDyn.map((e) => e.toString()).toList();

        if (!viewedBy.contains(myUid)) {
          txn.update(docRef, {
            'views': FieldValue.increment(1),
            'viewedBy': FieldValue.arrayUnion([myUid]),
          });
        }
      });

      if (!_isDisposed) {
        setState(() {
          if (!message.viewedBy.contains(myUid)) {
            message.views++;
            message.viewedBy.add(myUid);
          }
        });
      }
    } catch (e) {
      debugPrint('❌ Errore aggiornamento visualizzazioni testo: $e');
      _textSeenOnce.remove(message.id);
    }
  }

  // ✅ Reazioni: toggle su Firestore
  Future<void> _toggleReaction(VoiceMessage message, String emoji) async {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? myUid = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : _currentUserId;

    if (myUid == null || myUid.isEmpty) return;

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final docRef = _firestoreMessages.doc(message.id);
        final snap = await txn.get(docRef);
        if (!snap.exists) return;

        final data = (snap.data() as Map<String, dynamic>? ?? {});
        final Map<String, dynamic> rxRaw =
            (data['reactions'] as Map<String, dynamic>?) ?? {};
        final List<dynamic> usersDyn =
            (rxRaw[emoji] as List<dynamic>?) ?? const [];
        final Set<String> users = usersDyn.map((e) => e.toString()).toSet();

        if (users.contains(myUid)) {
          txn.update(docRef, {
            'reactions.$emoji': FieldValue.arrayRemove([myUid])
          });
        } else {
          txn.update(docRef, {
            'reactions.$emoji': FieldValue.arrayUnion([myUid])
          });
        }
      });
      // 🔄 UI si aggiorna via listener
    } catch (e) {
      debugPrint('❌ Errore toggle reazione: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filteredMessages = _messages.where((message) {
      return !(now.difference(message.timestamp).inMinutes >= 5) &&
          _isMessageInRange(message) &&
          _activeFilters.contains(message.category) &&
          _matchesMyCustomName(message);
    }).toList();

    final canSend = _textController.text.trim().isNotEmpty &&
        _textController.text.characters.length <= 250 &&
        !_isSendingText;

    return Scaffold(
      body: Stack(
        children: [
          HomeScreenUI(
            showWelcomeMessage: _showWelcomeMessage,
            isInitialized: _isInitialized,
            showRadiusSelector: _showRadiusSelector,
            showFilterSelector: _showFilterSelector,
            activeFilters: _activeFilters,
            showCategorySelector: _showCategorySelector,
            selectedCategory: _selectedCategory,
            filteredMessages: filteredMessages,
            currentUserId: _currentUserId,
            currentPosition: _currentPosition,
            selectedRadius: _selectedRadius,
            isRecording: _isRecording,
            recordingSeconds: _recordingSeconds,
            isLongPressRecording: _isLongPressRecording,
            isWaitingForRelease: _isWaitingForRelease,
            playingMessageId: _playingMessageId,
            radiusOptions: _radiusOptions,

            // Stato invio testo
            isSendingText: _isSendingText,

            onPlayMessage: _playMessage,
            onToggleRadiusSelector: () => setState(() {
              _showRadiusSelector = !_showRadiusSelector;
              if (_showRadiusSelector) {
                _showFilterSelector = false;
                _showCategorySelector = false;
              }
            }),
            onFilterToggled: (category) => setState(() {
              if (_activeFilters.contains(category)) {
                _activeFilters.remove(category);
              } else {
                _activeFilters.add(category);
              }
            }),
            onToggleFilterSelector: () => setState(() {
              _showFilterSelector = !_showFilterSelector;
              if (_showFilterSelector) {
                _showCategorySelector = false;
                _showRadiusSelector = false;
              }
            }),
            onCategorySelected: (category) => setState(() {
              if (_isCustomCategoryEnum(category) &&
                  ((_customCategoryName ?? '').trim().isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Seleziona un nome per la categoria personalizzata nelle Impostazioni.'),
                  ),
                );
              }
              _selectedCategory = category;
              _showCategorySelector = false;
            }),
            onToggleCategorySelector: () => setState(() {
              _showCategorySelector = !_showCategorySelector;
              if (_showCategorySelector) {
                _showFilterSelector = false;
                _showRadiusSelector = false;
              }
            }),
            onSettingsPressed: () async {
              await Navigator.pushNamed(context, '/settings');
              await _loadSettings();
              setState(() {});
            },
            onProfilePressed: _refreshAndToggleUserInfo,
            onPressStart: _handlePressStart,
            onPressEnd: _handlePressEnd,
            onStopRecording: _stopRecording,
            onStartRecording: _startRecording,
            onWelcomeDismissed: () =>
                setState(() => _showWelcomeMessage = false),
            onRadiusChanged: (double r) async {
              setState(() {
                _selectedRadius = r;
                _showRadiusSelector = false;
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('selected_radius', r);
            },

            // Input testo
            textController: _textController,
            textError: (_textController.text.characters.length > 250)
                ? 'Max 250 caratteri'
                : '',
            onSendText: () {
              if (canSend) _sendTextMessage();
            },

            // Visibilità testo (per conteggio "visto")
            onTextVisible: (m) => _markTextMessageViewed(m),

            // Reazioni
            onToggleReaction: (m, emoji) => _toggleReaction(m, emoji),
          ),

          // Pannello profilo (non se c'è il welcome)
          if (!_showWelcomeMessage && _showUserInfo && _currentUserData != null)
            Positioned(
              top: 60,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Il tuo account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: _refreshAndToggleUserInfo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    (() {
                      final fotoUrl =
                          (_currentUserData!['foto_url'] as String?)?.trim();
                      final nome =
                          (_currentUserData!['nome'] as String?)?.trim();
                      if (fotoUrl != null && fotoUrl.isNotEmpty) {
                        return CircleAvatar(
                          backgroundImage: NetworkImage(fotoUrl),
                          radius: 30,
                        );
                      }
                      // fallback: iniziali
                      String initials = 'A';
                      if (nome != null && nome.isNotEmpty) {
                        final parts = nome
                            .split(RegExp(r'\s+'))
                            .where((p) => p.isNotEmpty)
                            .toList();
                        if (parts.isNotEmpty) {
                          initials = parts
                              .take(2)
                              .map((p) => p.characters.first)
                              .join()
                              .toUpperCase();
                        }
                      }
                      return CircleAvatar(
                        radius: 30,
                        child: Text(
                          initials,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    })(),
                    const SizedBox(height: 10),
                    Text(
                      'ID utente:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SelectableText(
                      _currentUserId ?? 'Nessun ID',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Nome: ${_currentUserData!['nome'] ?? 'Nessun nome'}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Email: ${_currentUserData!['email'] ?? 'Nessuna email'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Provider: ${_currentUserData!['provider'] ?? 'N/D'}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final authService = AuthService();
                        await authService.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const AuthWrapper()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Esci',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🔒 Age Gate (Data di nascita obbligatoria, minimo 16 anni)
// ============================================================================
class AgeGateConfig {
  static const int minAgeYears = 16;
}

class AgeGateErrors {
  const AgeGateErrors();

  final String missingDate = 'Seleziona una data di nascita.';
  String tooYoung(int years) =>
      'Per usare l’app devi avere almeno $years anni.';
  final String mustAccept =
      'Devi confermare che i dati forniti sono veritieri.';
  final String generic = 'Si è verificato un errore. Riprova.';
}

class AgeGateStrings {
  static const String title = 'Completa il profilo';
  static String subtitle() =>
      'Per continuare ad usare TalkInZone devi indicare la tua data di nascita '
      '(età minima: ${AgeGateConfig.minAgeYears} anni).';
  static const String dateLabel = 'Data di nascita';
  static const String datePlaceholder = 'Seleziona una data';
  static const String datePickerHelp = 'Seleziona la tua data di nascita';
  static const String declaration =
      'Dichiaro che i dati forniti sono veritieri.';
  static const String falseWarning =
      'Attenzione: dichiarazioni false possono comportare la sospensione dell’account.';
  static const String cta = 'Conferma e continua';
  static const String logout = 'Esci';

  static AgeGateErrors get errors => const AgeGateErrors();
}

class AgeGateWrapper extends StatelessWidget {
  final Widget child;
  const AgeGateWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return child;
    }

    final ref = FirebaseFirestore.instance.collection('utenti').doc(uid);
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data?.data() ?? const <String, dynamic>{};
        final ts = data[UserProfileKeys.dataDiNascita] as Timestamp?;

        if (ts == null) {
          return const DateOfBirthScreen();
        }

        return child;
      },
    );
  }
}

class DateOfBirthScreen extends StatefulWidget {
  const DateOfBirthScreen({super.key});

  @override
  State<DateOfBirthScreen> createState() => _DateOfBirthScreenState();
}

class _DateOfBirthScreenState extends State<DateOfBirthScreen> {
  DateTime? _dob;
  bool _accepted = false;
  bool _saving = false;
  String? _error;

  DateTime get _cutoff {
    final now = DateTime.now();
    return DateTime(now.year - AgeGateConfig.minAgeYears, now.month, now.day);
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(1900);
    final lastDate = _cutoff;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(lastDate) ? initial : lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: AgeGateStrings.datePickerHelp,
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (_dob == null) {
      setState(() => _error = AgeGateStrings.errors.missingDate);
      return;
    }
    if (_dob!.isAfter(_cutoff)) {
      setState(() =>
          _error = AgeGateStrings.errors.tooYoung(AgeGateConfig.minAgeYears));
      return;
    }
    if (!_accepted) {
      setState(() => _error = AgeGateStrings.errors.mustAccept);
      return;
    }

    try {
      setState(() => _saving = true);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('Utente non autenticato');
      }

      await FirebaseFirestore.instance.collection('utenti').doc(uid).set(
            UserProfile.setDataDiNascita(_dob!),
            SetOptions(merge: true),
          );
    } catch (e) {
      setState(() => _error = AgeGateStrings.errors.generic);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDob(DateTime? d) {
    if (d == null) return AgeGateStrings.datePlaceholder;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.cake_outlined, size: 64),
                  const SizedBox(height: 12),
                  const Text(
                    AgeGateStrings.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AgeGateStrings.subtitle(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  const Text(AgeGateStrings.dateLabel),
                  const SizedBox(height: 8),
                  TextFormField(
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      hintText: _formatDob(_dob),
                      suffixIcon: const Icon(Icons.calendar_today_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _accepted,
                        onChanged: (v) =>
                            setState(() => _accepted = v ?? false),
                      ),
                      const Expanded(child: Text(AgeGateStrings.declaration)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AgeGateStrings.falseWarning,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AgeGateStrings.cta),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AuthWrapper()),
                          (_) => false,
                        );
                      }
                    },
                    child: const Text(AgeGateStrings.logout),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class VoiceChatApp extends StatelessWidget {
  const VoiceChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TalkInZone',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,

      // 🔒 MOSTRA la Home SOLO se data_di_nascita è valorizzata.
      home: const AgeGateWrapper(child: VoiceChatHome()),

      routes: {'/settings': (context) => const SettingsScreen()},
    );
  }
}

Future<bool> _checkAppVersion() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final doc = await firestore
        .collection('applicazioneversione')
        .doc('informazione')
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      final dynamic versionData = data['version'];
      String? serverVersion;

      if (versionData is String) {
        serverVersion = versionData;
      } else if (versionData is double) {
        serverVersion = versionData.toString();
      } else if (versionData is int) {
        serverVersion = versionData.toString();
      }

      if (serverVersion != null) {
        final currentParts = appVersion.split('.').map(int.parse).toList();
        final serverParts = serverVersion.split('.').map(int.parse).toList();

        for (int i = 0; i < serverParts.length; i++) {
          final serverPart = i < serverParts.length ? serverParts[i] : 0;
          final currentPart = i < currentParts.length ? currentParts[i] : 0;
          if (serverPart > currentPart) return false;
          if (serverPart < currentPart) break;
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('⚠️ Errore controllo versione: $e');
    return true;
  }
}

Future<void> _runStartupCleanup() async {
  final firestore = FirebaseFirestore.instance;
  final now = DateTime.now();
  final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));

  try {
    final expiredMessages = await firestore
        .collection('messages')
        .where('timestamp', isLessThan: Timestamp.fromDate(fiveMinutesAgo))
        .get();

    final storjService = StorjService();
    await storjService.initialize();

    for (final doc in expiredMessages.docs) {
      try {
        final data = doc.data();
        final String type = (data['type'] as String?) ?? 'voice';
        final objectKey = data['storjObjectKey'] as String? ?? '';
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp == null) continue;

        final expirationTime = timestamp.toDate().add(
              const Duration(minutes: 5),
            );
        if (DateTime.now().isBefore(expirationTime)) continue;

        debugPrint('🗑️ [STARTUP] Cancellazione messaggio scaduto: ${doc.id}');

        // ✅ Skip cancellazione Storj per messaggi testuali
        if (type != 'text' && objectKey.isNotEmpty) {
          try {
            await storjService.deleteFile(objectKey);
            debugPrint('✅ [STARTUP] File audio cancellato su Storj');
          } catch (e) {
            debugPrint('⚠️ [STARTUP] Errore Storj: $e');
          }
        }

        await doc.reference.delete();
        debugPrint('✅ [STARTUP] Metadati Firestore cancellati');
      } catch (e) {
        debugPrint('❌ [STARTUP] Errore cancellazione: $e');
      }
    }
  } catch (e) {
    debugPrint('❌ [STARTUP] Errore pulizia iniziale: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  AuthService().debugAuthConfiguration();
  await NotificationService().initialize();

  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false,
  );

  final versionCheck = await _checkAppVersion();
  if (!versionCheck) {
    runApp(const UpdateRequiredScreen());
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  if (prefs.getInt('lastRunTime') == null) {
    prefs.setInt('lastRunTime', DateTime.now().millisecondsSinceEpoch);
  }

  await Workmanager().registerPeriodicTask(
    "background-task",
    "backgroundNotificationHandler",
    frequency: const Duration(minutes: 1),
    constraints: Constraints(networkType: NetworkType.connected),
    initialDelay: Duration.zero,
  );

  await _runStartupCleanup();
  runApp(const AuthWrapper());
}
