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
import 'app_theme.dart';
import 'gen_l10n/app_localizations.dart';

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

        await UserProfile.upsertOnAuth(userCredential.user!,
            provider: 'google', pruneUnknownKeys: true);

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

        if (timestamp == null) {
          continue;
        }

        final expirationTime = timestamp.toDate().add(
              const Duration(minutes: 10),
            );
        if (DateTime.now().isBefore(expirationTime)) {
          debugPrint('⏱️ [BACKGROUND] Messaggio non ancora scaduto, salto');
          continue;
        }

        debugPrint('🗑️ [BACKGROUND] Cancellazione messaggio scaduto: ${doc.id}'
            ' (Inviato: ${timestamp.toDate()}, Scaduto: $expirationTime)');

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
  if (!notificationEnabled) {
    return;
  }

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

  Set<String> blocked = {};
  if (currentUserId.isNotEmpty) {
    try {
      final userSnap =
          await firestore.collection('utenti').doc(currentUserId).get();
      final List<dynamic> b =
          (userSnap.data()?['id_bloccati'] as List<dynamic>?) ?? const [];
      blocked = b.map((e) => e.toString()).toSet();
    } catch (e) {
      debugPrint('⚠️ [BACKGROUND] Impossibile leggere id_bloccati: $e');
    }
  }

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

      if (senderId == currentUserId) {
        continue;
      }

      if (blocked.contains(senderId)) {
        continue;
      }

      final List<dynamic> invDyn =
          (data['invisibleTo'] as List<dynamic>?) ?? const [];
      final Set<String> invisibleTo = invDyn.map((e) => e.toString()).toSet();
      if (currentUserId.isNotEmpty && invisibleTo.contains(currentUserId)) {
        continue;
      }

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
          String category = data['category'] as String? ?? 'free';
          if (category.toLowerCase() == 'custom' ||
              category.toLowerCase() == 'special' ||
              category.toLowerCase() == 'personalizzata') {
            final cn = (data['customCategoryName'] as String?)?.trim();
            if (cn != null && cn.isNotEmpty) category = cn;
          }
          final String type = (data['type'] as String?) ?? 'voice';
          final bool isText = type == 'text';

          await notificationService.showNewMessageNotification(
            category: category,
            messageId: doc.id,
            isText: isText,
          );
        }
      }
    }

    await prefs.setInt('lastRunTime', now.millisecondsSinceEpoch);
  } catch (e) {
    debugPrint('❌ Errore notifiche: $e');
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/app_logo.png', width: 120, height: 120),
            const SizedBox(height: 40),
            Text(
              l10n.welcomeTitle,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                l10n.welcomeSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),
            FilledButton.icon(
              onPressed: () async {
                debugPrint("👉 Bottone di accesso premuto (Google)");
                final user = await authService.signInWithGoogle();
                if (user == null) {
                  debugPrint("❌ Accesso Google fallito");
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.loginFailed)),
                  );
                } else {
                  debugPrint("✅ Accesso Google riuscito, navigazione...");
                }
              },
              icon:
                  Image.asset('assets/google_logo.png', width: 20, height: 20),
              label: Text(l10n.signInWithGoogle),
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
          return AnimatedBuilder(
            animation: Listenable.merge([
              AppThemeController.instance,
            ]),
            builder: (context, _) {
              final t = AppThemeController.instance.theme;
              return MaterialApp(
                title: 'TalkInZone',
                theme: AppThemes.light,
                darkTheme:
                    t == AppTheme.grey ? AppThemes.greyDark : AppThemes.dark,
                themeMode: t == AppTheme.light
                    ? ThemeMode.light
                    : (t == AppTheme.dark ? ThemeMode.dark : ThemeMode.system),
                locale: AppThemeController.instance.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
                routes: {'/settings': (context) => const SettingsScreen()},
              );
            },
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const VoiceChatApp();
        }

        return AnimatedBuilder(
          animation: Listenable.merge([
            AppThemeController.instance,
          ]),
          builder: (context, _) {
            final t = AppThemeController.instance.theme;
            final theme =
                t == AppTheme.grey ? AppThemes.greyLight : AppThemes.light;
            final darkTheme =
                t == AppTheme.grey ? AppThemes.greyDark : AppThemes.dark;
            final mode = t == AppTheme.light
                ? ThemeMode.light
                : (t == AppTheme.dark ? ThemeMode.dark : ThemeMode.system);

            return MaterialApp(
              title: 'TalkInZone',
              theme: theme,
              darkTheme: darkTheme,
              themeMode: mode,
              locale: AppThemeController.instance.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const LoginScreen(),
              routes: {'/settings': (context) => const SettingsScreen()},
            );
          },
        );
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

  final TextEditingController _textController = TextEditingController();
  bool _isSendingText = false;

  final Set<String> _textSeenOnce = {};

  bool _didSchemaSync = false;

  String? _customCategoryName;
  MessageCategory? _customEnum;
  final Map<String, String> _msgCustomNames = {};

  Set<String> _blockedIds = {};
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _textController.addListener(() {
      if (mounted) {
        setState(() {});
      }
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

    _userDocSub?.cancel();

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
      if (isFirstLaunch) {
        prefs.setBool('first_launch', false);
      }

      final rawName = (prefs.getString('custom_category_name') ?? '').trim();
      _customCategoryName = rawName.isEmpty ? null : rawName;

      _customEnum = _findCustomEnum();
    });

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
      _attachUserDocListener();
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
    if (_customEnum == null) {
      return true;
    }
    if (m.category.name != _customEnum!.name) {
      return true;
    }
    final myName = (_customCategoryName ?? '').trim();
    if (myName.isEmpty) {
      return false;
    }
    final msgName =
        (_msgCustomNames[m.id] ?? m.customCategoryName ?? '').trim();
    return msgName.isNotEmpty && msgName.toLowerCase() == myName.toLowerCase();
  }

  bool _requireCustomNameOrWarn() {
    if (_customEnum == null) {
      return true;
    }
    if (_selectedCategory.name != _customEnum!.name) {
      return true;
    }
    if ((_customCategoryName ?? '').trim().isNotEmpty) {
      return true;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).customCategoryWarning),
      ),
    );
    return false;
  }

  Future<void> _loadUserData() async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> userDoc =
          await FirebaseFirestore.instance
              .collection('utenti')
              .doc(_currentUserId!)
              .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _currentUserData = data;
          final List<dynamic> b =
              (data?['id_bloccati'] as List<dynamic>?) ?? const [];
          _blockedIds = b.map((e) => e.toString()).toSet();
        });
        debugPrint("✅ Dati utente caricati: $_currentUserData");
      } else {
        debugPrint("⚠️ Documento utente non trovato per ID: $_currentUserId");
      }
    } catch (e) {
      debugPrint('❌ Errore caricamento dati utente: $e');
    }
  }

  void _attachUserDocListener() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? _currentUserId;
    if (uid == null || uid.isEmpty) {
      return;
    }
    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('utenti')
        .doc(uid)
        .snapshots()
        .listen((snap) {
      final data = snap.data() ?? <String, dynamic>{};
      final List<dynamic> b =
          (data['id_bloccati'] as List<dynamic>?) ?? const [];
      setState(() {
        _blockedIds = b.map((e) => e.toString()).toSet();
      });
    });
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
      if (_isAppInForeground) {
        _getCurrentLocation();
      }
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
      if (!_isDisposed) {
        _cleanupOldMessages();
      }
    });

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isDisposed) {
        setState(() {});
      }
    });
  }

  void _initializeFirestoreListener() {
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
        final DocumentSnapshot<Map<String, dynamic>> snap =
            await FirebaseFirestore.instance
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
      if (authName.isNotEmpty) {
        return authName;
      }

      final email = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';
      if (email.isNotEmpty) {
        return email.split('@').first;
      }
      if (!mounted) return 'Anonymous';
      return AppLocalizations.of(context).anonymous;
    } catch (_) {
      if (!mounted) return 'Anonymous';
      return AppLocalizations.of(context).anonymous;
    }
  }

  Future<void> _ensureMessageHasName(
      DocumentSnapshot<Map<String, dynamic>> doc) async {
    try {
      final data = doc.data() ?? <String, dynamic>{};
      final hasName = (data['name'] as String?)?.trim().isNotEmpty == true;
      final senderId = (data['senderId'] as String?) ?? '';

      if (hasName || senderId.isEmpty) {
        return;
      }

      final userSnap = await FirebaseFirestore.instance
          .collection('utenti')
          .doc(senderId)
          .get();
        
        if (!mounted) return;

      String? nome = (userSnap.data()?['nome'] as String?)?.trim();

      if (nome == null || nome.isEmpty) {
        nome = AppLocalizations.of(context).anonymous;
      }

      await doc.reference.update({'name': nome});
      debugPrint('✍️ Aggiornato name su messaggio ${doc.id}: $nome');
    } catch (e) {
      debugPrint('ℹ️ Skip ensure name for ${doc.id}: $e');
    }
  }

  void _processFirestoreSnapshot(QuerySnapshot snapshotRaw) {
    final snapshot = snapshotRaw as QuerySnapshot<Map<String, dynamic>>;

    final now = DateTime.now();
    final newMessages = <VoiceMessage>[];
    final removedMessages = <String>[];
    final updatedMessages = <VoiceMessage>[];

    for (final doc in snapshot.docs) {
      try {
        _ensureMessageHasName(doc);

        final newMessage = VoiceMessage.fromFirestore(doc);
        final isExpired = now.difference(newMessage.timestamp).inMinutes >= 10;

        try {
          final data = doc.data();
          final cn = (data['customCategoryName'] as String?)?.trim();
          if (cn != null && cn.isNotEmpty) {
            _msgCustomNames[doc.id] = cn;
          }
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
                !_isHiddenByBlock(newMessage) &&
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
          if (index != -1) {
            _messages[index] = updated;
          }
        }

        if (newMessages.isNotEmpty) {
          _messages.addAll(newMessages);
        }
        _messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      });
    }
  }

  bool _isHiddenByBlock(VoiceMessage m) {
    final myUid =
        FirebaseAuth.instance.currentUser?.uid ?? _currentUserId ?? '';
    if (_blockedIds.contains(m.senderId)) {
      return true;
    }
    if (myUid.isNotEmpty && m.invisibleTo.contains(myUid)) {
      return true;
    }
    return false;
  }

  Future<void> _resetRecorder() async {
    try {
      if (_recorder != null) {
        if (_recorder!.isRecording) {
          await _recorder!.stopRecorder();
        }
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
      var permission = await Geolocator.checkPermission();
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
    if (_isDisposed) {
      return;
    }

    final now = DateTime.now();
    final messagesToRemove = <VoiceMessage>[];

    for (final message in _messages) {
      final elapsedMinutes = now.difference(message.timestamp).inMinutes;
      if (elapsedMinutes >= 5) {
        messagesToRemove.add(message);
      }
    }

    if (messagesToRemove.isEmpty) {
      return;
    }

    for (final message in messagesToRemove) {
      try {
        final expirationTime =
            message.timestamp.add(const Duration(minutes: 10));
        if (DateTime.now().isBefore(expirationTime)) {
          debugPrint('⏱️ Messaggio non ancora scaduto, salto');
          continue;
        }

        debugPrint(
            '🗑️ [${DateTime.now()}] Cancellazione messaggio scaduto: ${message.id}');

        if (message.isVoice && message.storjObjectKey.isNotEmpty) {
          try {
            await storjService.deleteFile(message.storjObjectKey);
            debugPrint('✅ File audio cancellato su Storj');
          } catch (e) {
            debugPrint('⚠️ Errore Storj: $e');
          }
        }

        await FirebaseFirestore.instance
            .collection('messages')
            .doc(message.id)
            .delete();
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
    if (!_isInitialized || _recorder == null || _isRecording) {
      return;
    }

    try {
      await _resetRecorder();
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        return;
      }

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
          if (_recordingSeconds >= 15) {
            _stopRecording();
          }
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
    if (!_isRecording || _recorder == null) {
      return;
    }

    try {
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
            'invisibleTo': _blockedIds.toList(),
          };
          await FirebaseFirestore.instance.collection('messages').add(payload);
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
    if (raw.isEmpty) {
      return;
    }

    if (!_requireCustomNameOrWarn()) {
      return;
    }

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
        'invisibleTo': _blockedIds.toList(),
      };

      await FirebaseFirestore.instance.collection('messages').add(payload);

      _textController.clear();
    } catch (e) {
      debugPrint('❌ Errore invio testo: $e');
    } finally {
      if (mounted) {
        setState(() => _isSendingText = false);
      }
    }
  }

  List<VoiceMessage> _getPlayableMessages() {
    final now = DateTime.now();
    final list = _messages.where((m) {
      final expired = now.difference(m.timestamp).inMinutes >= 10;
      if (expired) {
        return false;
      }
      if (_isHiddenByBlock(m)) {
        return false;
      }
      if (!_isMessageInRange(m)) {
        return false;
      }
      if (!_activeFilters.contains(m.category)) {
        return false;
      }
      if (!_matchesMyCustomName(m)) {
        return false;
      }
      return true;
    }).toList();

    list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return list;
  }

  Future<void> _playNextAfter(String justPlayedId) async {
    if (_isDisposed) {
      return;
    }
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
    if (_player == null) {
      return;
    }

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? myUid = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : _currentUserId;
    if (myUid == null || myUid.isEmpty) {
      return;
    }

    if (message.isText) {
      return;
    }

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
          if (!_isDisposed) {
            setState(() {});
          }
        } catch (e) {
          debugPrint('❌ Errore download audio: $e');
          return;
        }
      }

      await _player!.startPlayer(
        fromURI: audioPath,
        whenFinished: () {
          if (_isDisposed) {
            return;
          }
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
          await FirebaseFirestore.instance
              .collection('messages')
              .doc(message.id)
              .update({
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
          debugPrint(" ❌ Errore aggiornamento visualizzazioni: $e");
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
    if (_currentPosition == null) {
      return true;
    }
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

  Future<void> _markTextMessageViewed(VoiceMessage message) async {
    if (!message.isText) {
      return;
    }

    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? myUid = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : _currentUserId;

    if (myUid == null || myUid.isEmpty) {
      return;
    }
    if (message.senderId == myUid) {
      return;
    }
    if (message.viewedBy.contains(myUid)) {
      return;
    }
    if (_textSeenOnce.contains(message.id)) {
      return;
    }

    _textSeenOnce.add(message.id);

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final docRef =
            FirebaseFirestore.instance.collection('messages').doc(message.id);
        final snap = await txn.get(docRef);
        final data = snap.data() ?? {};

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

  Future<void> _toggleReaction(VoiceMessage message, String emoji) async {
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    final String? myUid = (currentUid != null && currentUid.isNotEmpty)
        ? currentUid
        : _currentUserId;

    if (myUid == null || myUid.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((txn) async {
        final docRef =
            FirebaseFirestore.instance.collection('messages').doc(message.id);
        final snap = await txn.get(docRef);
        if (!snap.exists) {
          return;
        }

        final data = snap.data() ?? {};
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
    } catch (e) {
      debugPrint('❌ Errore toggle reazione: $e');
    }
  }

  Future<void> _blockUserById(String targetUid) async {
    final myUid =
        FirebaseAuth.instance.currentUser?.uid ?? _currentUserId ?? '';
    if (targetUid.isEmpty || myUid.isEmpty || targetUid == myUid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).invalidOperation)),
        );
      }
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('utenti').doc(myUid).set({
        'id_bloccati': FieldValue.arrayUnion([targetUid])
      }, SetOptions(merge: true));

      setState(() => _blockedIds = {..._blockedIds, targetUid});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).userBlocked)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).blockError)),
        );
      }
    }
  }

  Future<void> _confirmAndBlock(VoiceMessage m) async {
    final targetUid = m.senderId;
    if (targetUid.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.block, color: Colors.red),
        title: Text(l10n.blockUser),
        content: Text(l10n.blockUserConfirmation),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.block),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _blockUserById(targetUid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filteredMessages = _messages.where((message) {
      return !(now.difference(message.timestamp).inMinutes >= 10) &&
          !_isHiddenByBlock(message) &&
          _isMessageInRange(message) &&
          _activeFilters.contains(message.category) &&
          _matchesMyCustomName(message);
    }).toList();

    final canSend = _textController.text.trim().isNotEmpty &&
        _textController.text.characters.length <= 250 &&
        !_isSendingText;

    final cs = Theme.of(context).colorScheme;

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
                  SnackBar(
                    content: Text(AppLocalizations.of(context).customCategoryWarning),
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
              if (!context.mounted) {
                return;
              }
              await _loadSettings();
              if (!context.mounted) {
                return;
              }
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
            textController: _textController,
            textError: (_textController.text.characters.length > 250)
                ? AppLocalizations.of(context).maxCharsError(250)
                : '',
            onSendText: () {
              if (canSend) {
                _sendTextMessage();
              }
            },
            onTextVisible: (m) => _markTextMessageViewed(m),
            onToggleReaction: (m, emoji) => _toggleReaction(m, emoji),
            onRequestBlockUser: _confirmAndBlock,
          ),

          if (!_showWelcomeMessage && _currentUserData != null && _showUserInfo)
            Positioned(
              top: 60,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  boxShadow: [
                    BoxShadow(
               color: Colors.black.withValues(alpha: 0.15),        
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant,
                    width: 1,
                  ),
                ),
                width: 250,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context).yourAccount,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        IconButton(
                          icon:
                              Icon(Icons.close, size: 20, color: cs.onSurface),
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
                      AppLocalizations.of(context).userId,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    SelectableText(
                      _currentUserId ?? AppLocalizations.of(context).noId,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${AppLocalizations.of(context).name}: ${_currentUserData!['nome'] ?? AppLocalizations.of(context).noName}',
                      style: TextStyle(fontSize: 16, color: cs.onSurface),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${AppLocalizations.of(context).email}: ${_currentUserData!['email'] ?? AppLocalizations.of(context).noEmail}',
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${AppLocalizations.of(context).provider}: ${_currentUserData!['provider'] ?? 'N/D'}',
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                      ),
                      onPressed: () async {
                        final authService = AuthService();
                        await authService.signOut();
                        if (!context.mounted) {
                          return;
                        }
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AuthWrapper()),
                        );
                      },
                      child: Text(AppLocalizations.of(context).logout),
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

class AgeGateConfig {
  static const int minAgeYears = 16;
}

class AgeGateStrings {
  static String title(BuildContext context) => AppLocalizations.of(context).ageGateTitle;
  static String subtitle(BuildContext context) => AppLocalizations.of(context).ageGateSubtitle(AgeGateConfig.minAgeYears);
  static String dateLabel(BuildContext context) => AppLocalizations.of(context).birthDate;
  static String datePlaceholder(BuildContext context) => AppLocalizations.of(context).selectDate;
  static String datePickerHelp(BuildContext context) => AppLocalizations.of(context).selectBirthDate;
  static String declaration(BuildContext context) => AppLocalizations.of(context).truthDeclaration;
  static String falseWarning(BuildContext context) => AppLocalizations.of(context).falseWarning;
  static String cta(BuildContext context) => AppLocalizations.of(context).confirmAndContinue;
  static String logout(BuildContext context) => AppLocalizations.of(context).logout;

  static String missingDate(BuildContext context) => AppLocalizations.of(context).missingDate;
  static String tooYoung(BuildContext context, int years) => AppLocalizations.of(context).tooYoung(years);
  static String mustAccept(BuildContext context) => AppLocalizations.of(context).mustAccept;
  static String generic(BuildContext context) => AppLocalizations.of(context).genericError;
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
      stream: ref.snapshots(includeMetadataChanges: true),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting || !snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snap.data!;
        final data = doc.data() ?? <String, dynamic>{};
        final ts = data[UserProfileKeys.dataDiNascita] as Timestamp?;
        final bool pending = doc.metadata.hasPendingWrites;
        final bool fromCache = doc.metadata.isFromCache;

        if (pending || fromCache) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (ts != null) {
          return child;
        }

        return const DateOfBirthScreen();
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
      helpText: AgeGateStrings.datePickerHelp(context),
    );
    if (picked != null) {
      setState(() => _dob = picked);
    }
  }

  Future<void> _save() async {
    setState(() => _error = null);

    if (_dob == null) {
      setState(() => _error = AgeGateStrings.missingDate(context));
      return;
    }
    if (_dob!.isAfter(_cutoff)) {
      setState(() =>
          _error = AgeGateStrings.tooYoung(context, AgeGateConfig.minAgeYears));
      return;
    }
    if (!_accepted) {
      setState(() => _error = AgeGateStrings.mustAccept(context));
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
      setState(() => _error = AgeGateStrings.generic(context));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String _formatDob(DateTime? d, BuildContext context) {
    if (d == null) {
      return AgeGateStrings.datePlaceholder(context);
    }
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                  Icon(Icons.cake_outlined, size: 64, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    AgeGateStrings.title(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AgeGateStrings.subtitle(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Text(AgeGateStrings.dateLabel(context)),
                  const SizedBox(height: 8),
                  TextFormField(
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      hintText: _formatDob(_dob, context),
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
                      Expanded(child: Text(AgeGateStrings.declaration(context))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AgeGateStrings.falseWarning(context),
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
                        : Text(AgeGateStrings.cta(context)),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await AuthService().signOut();
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthWrapper()),
                        (_) => false,
                      );
                    },
                    child: Text(AgeGateStrings.logout(context)),
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
    return AnimatedBuilder(
      animation: Listenable.merge([
        AppThemeController.instance,
      ]),
      builder: (context, _) {
        final choice = AppThemeController.instance.theme;

        switch (choice) {
          case AppTheme.light:
            return MaterialApp(
              title: 'TalkInZone',
              theme: AppThemes.light,
              darkTheme: AppThemes.dark,
              themeMode: ThemeMode.light,
              locale: AppThemeController.instance.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const AgeGateWrapper(child: VoiceChatHome()),
              routes: {'/settings': (context) => const SettingsScreen()},
            );

          case AppTheme.dark:
            return MaterialApp(
              title: 'TalkInZone',
              theme: AppThemes.light,
              darkTheme: AppThemes.dark,
              themeMode: ThemeMode.dark,
              locale: AppThemeController.instance.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const AgeGateWrapper(child: VoiceChatHome()),
              routes: {'/settings': (context) => const SettingsScreen()},
            );

          case AppTheme.grey:
            return MaterialApp(
              title: 'TalkInZone',
              theme: AppThemes.greyLight,
              darkTheme: AppThemes.greyDark,
              themeMode: ThemeMode.system,
              locale: AppThemeController.instance.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: const AgeGateWrapper(child: VoiceChatHome()),
              routes: {'/settings': (context) => const SettingsScreen()},
            );
        }
      },
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
      final data = doc.data();
      final dynamic versionData = data?['version'];
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
          if (serverPart > currentPart) {
            return false;
          }
          if (serverPart < currentPart) {
            break;
          }
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

        if (timestamp == null) {
          continue;
        }

        final expirationTime = timestamp.toDate().add(
              const Duration(minutes: 5),
            );
        if (DateTime.now().isBefore(expirationTime)) {
          continue;
        }

        debugPrint('🗑️ [STARTUP] Cancellazione messaggio scaduto: ${doc.id}');

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

  await AppThemeController.instance.load();

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
    await prefs.setInt('lastRunTime', DateTime.now().millisecondsSinceEpoch);
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