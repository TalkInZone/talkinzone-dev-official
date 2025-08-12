// main.dart — completo
// 🔧 Patch minima:
// - In backgroundNotificationHandler(): se type == 'text' non cancellare su Storj.
// - In _cleanupOldMessages(): cancella su Storj solo se message.isVoice.
// - In _runStartupCleanup(): se type == 'text' non cancellare su Storj.

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
import 'services/user_profile.dart'; // profilo

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
        final String type = (data['type'] as String?) ?? 'voice'; // ✅ NEW
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
          final category = data['category'] as String? ?? 'free';
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
            ElevatedButton(
              onPressed: () async {
                debugPrint("👉 Bottone di accesso premuto");
                final user = await authService.signInWithGoogle();
                if (user == null) {
                  debugPrint("❌ Accesso fallito");
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Accesso fallito. Riprova.'),
                      ),
                    );
                  }
                } else {
                  debugPrint("✅ Accesso riuscito, navigazione...");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/google_logo.png', width: 24, height: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Accedi con Google',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
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

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
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
    });

    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      await _loadUserData();
    }
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
    _messagesSubscription = _firestoreMessages
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true)
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

          await _firestoreMessages.add({
            'type': 'voice',
            'timestamp': FieldValue.serverTimestamp(),
            'latitude': _currentPosition!.latitude,
            'longitude': _currentPosition!.longitude,
            'duration': _recordingSeconds,
            'category': _selectedCategory.name,
            'storjObjectKey': objectKey,
            'senderId': currentUid ?? (_currentUserId ?? ''),
            'views': 0,
            'viewedBy': <String>[],
            'name': senderName,
            'text': null,
          });
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

      await _firestoreMessages.add({
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': _currentPosition?.latitude ?? 0.0,
        'longitude': _currentPosition?.longitude ?? 0.0,
        'duration': 0,
        'category': _selectedCategory.name,
        'storjObjectKey': '',
        'senderId': currentUid ?? (_currentUserId ?? ''),
        'views': 0,
        'viewedBy': <String>[],
        'name': senderName,
        'text': _textController.text.trim(),
      });

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

    // ✅ Testo: niente azioni qui (il visto avviene su visibilità viewport)
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

  // NEW: marca "letto" per MESSAGGI TESTUALI quando la bolla è visibile (callback da UI)
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
      debugPrint('❌ Errore aggiornamento visualizzazioni testo (viewport): $e');
      _textSeenOnce.remove(message.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filteredMessages = _messages.where((message) {
      return !(now.difference(message.timestamp).inMinutes >= 5) &&
          _isMessageInRange(message) &&
          _activeFilters.contains(message.category);
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
            onSettingsPressed: () => Navigator.pushNamed(context, '/settings'),
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
          ),

          // Pannellino profilo (come prima)
          if (_showUserInfo && _currentUserData != null)
            Positioned(
              top: 60,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
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
                              builder: (context) => const AuthWrapper(),
                            ),
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

          // Barra input testo (overlay in basso)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Chip categoria (tap per cambiare)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _showCategorySelector = !_showCategorySelector;
                          if (_showCategorySelector) {
                            _showFilterSelector = false;
                            _showRadiusSelector = false;
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategory.color.withAlpha(25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _selectedCategory.color),
                        ),
                        child: Row(
                          children: [
                            Icon(_selectedCategory.icon,
                                size: 16, color: _selectedCategory.color),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCategory.label,
                              style: TextStyle(color: _selectedCategory.color),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Campo testo
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLines: 3,
                        minLines: 1,
                        maxLength: 250,
                        decoration: const InputDecoration(
                          hintText: 'Scrivi un messaggio (max 250)',
                          counterText: '',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) {
                          final txt = _textController.text.trim();
                          if (txt.isNotEmpty &&
                              txt.characters.length <= 250 &&
                              !_isSendingText) {
                            _sendTextMessage();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Bottone invio
                    SizedBox(
                      height: 40,
                      width: 48,
                      child: ElevatedButton(
                        onPressed: (_textController.text.trim().isNotEmpty &&
                                _textController.text.characters.length <= 250 &&
                                !_isSendingText)
                            ? () => _sendTextMessage()
                            : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: _isSendingText
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const VoiceChatHome(),
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
        final String type = (data['type'] as String?) ?? 'voice'; // ✅ NEW
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
