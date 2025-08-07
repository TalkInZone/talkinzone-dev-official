// ███████████████████████████████████████
// ►►► NOTIFICATION SERVICE CLASS ◄◄◄
// ███████████████████████████████████████
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // 🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿
  // ►►► SINGLETON PATTERN ◄◄◄
  // 🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿🌿

  // 🧩 [Istanza Singleton]
  // ↪️ Funzione: Garantisce un'unica istanza globale
  // 🔄 Logica: Costruttore privato + factory constructor
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // ════════════════════════════════════════
  // ►►► NOTIFICATION PLUGIN INSTANCE ◄◄◄
  // ════════════════════════════════════════

  // 🧩 [Plugin Notifiche]
  // ↪️ Funzione: Gestore operazioni notifiche native
  // 📤 Output: Istanza condivisa del plugin
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ███████████████████████████████████████
  // ►►► INITIALIZE METHOD ◄◄◄
  // ███████████████████████████████████████
  Future<void> initialize() async {
    // 🧩 [Configurazione Android]
    // ↪️ Funzione: Imposta icona predefinita per notifiche
    // ⚡ Input: Nome risorsa drawable
    // 🔄 Logica: Carica l'icona dell'app dalle risorse
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 🧩 [Configurazione Multi-Piattaforma]
    // ↪️ Funzione: Unifica impostazioni Android/iOS
    // 🔄 Logica: Combina le configurazioni specifiche per OS
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidInitializationSettings,
          iOS: DarwinInitializationSettings(),
        );

    // 🧩 [Inizializzazione Plugin]
    // ↪️ Funzione: Avvia il sistema di notifiche
    // ⚡ Input: Impostazioni + callback interazione
    // 🔄 Logica: Registra gestore click notifiche
    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // 💡 Side-effect: Triggerato al tap notifica
      },
    );
  }

  // ════════════════════════════════════════
  // ►►► SHOW NOTIFICATION METHOD ◄◄◄
  // ════════════════════════════════════════
  Future<void> showNewMessageNotification({
    required String category,
    required String messageId,
  }) async {
    // 🧩 [Dettagli Android]
    // ↪️ Funzione: Configura comportamento notifica Android
    // ⚡ Input: Suono personalizzato e priorità alta
    // 🔄 Logica: Canale dedicato per messaggi vocali
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'new_voice_message', // ID canale
          'Nuovi messaggi vocali', // Nome canale
          channelDescription:
              'Notifiche per nuovi messaggi vocali nella tua zona',
          importance: Importance.high, // Priorità visiva
          priority: Priority.high, // Priorità sistema
          playSound: true,
          sound: RawResourceAndroidNotificationSound(
            'notification',
          ), // Suono personalizzato
        );

    // 🧩 [Dettagli iOS]
    // ↪️ Funzione: Configurazione base per iOS
    const DarwinNotificationDetails iOSNotificationDetails =
        DarwinNotificationDetails();

    // 🧩 [Unificazione Impostazioni]
    // ↪️ Funzione: Adatta configurazione al SO target
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iOSNotificationDetails,
    );

    // 🧩 [Visualizzazione Notifica]
    // ↪️ Funzione: Mostra notifica con payload personalizzato
    // ⚡ Input: ID univoco (hash del messaggio)
    // 📤 Output: Notifica visibile nel sistema
    // 🔄 Logica: Titolo dinamico basato sulla categoria
    await _notificationsPlugin.show(
      messageId.hashCode, // ID univoco
      'Nuovo messaggio ${category.toLowerCase()}', // Titolo
      'Clicca per ascoltare', // Corpo
      notificationDetails,
      payload: messageId, // Dato per gestione click
    );
  }

  // ███████████████████████████████████████
  // ►►► CANCEL NOTIFICATION METHOD ◄◄◄
  // ███████████████████████████████████████
  Future<void> cancelNotification(int id) async {
    // 🧩 [Rimozione Notifica]
    // ↪️ Funzione: Elimina notifica specifica
    // ⚡ Input: ID della notifica da cancellare
    // 🔄 Logica: Chiamata diretta al plugin
    await _notificationsPlugin.cancel(id);
  }
}
