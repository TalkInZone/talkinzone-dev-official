// voice_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/category_utils.dart';

// ══════════════════════════════════════════════════════════════════════════
// 🎙️ CLASSE PRINCIPALE - MODELLO MESSAGGIO VOCALE
// ══════════════════════════════════════════════════════════════════════════
/// Rappresenta un messaggio vocale con metadati geografici e statistiche d'uso
class VoiceMessage {
  // 🔐 PROPRIETA' FONDAMENTALI
  final String id; // ID univoco documento Firestore
  final DateTime timestamp; // Momento della registrazione
  final double latitude; // Coordinata geografica
  final double longitude;
  final Duration duration; // Durata registrazione
  final MessageCategory category; // Categoria tematica
  final String storjObjectKey; // Chiave oggetto in Storj
  final String senderId; // ID utente mittente

  // 🔄 PROPRIETA' MUTABILI
  String? localPath; // Percorso locale file (se scaricato)
  int views; // Contatore visualizzazioni
  List<String> viewedBy; // ID utenti che hanno visualizzato

  VoiceMessage({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.duration,
    required this.category,
    required this.storjObjectKey,
    required this.senderId,
    this.localPath,
    required this.views,
    required this.viewedBy,
  });

  // ██████████████████████████████████████████████████████████████████████
  // 🏭 FACTORY: COSTRUZIONE DA FIRESTORE
  // ██████████████████████████████████████████████████████████████████████
  factory VoiceMessage.fromFirestore(DocumentSnapshot doc) {
    // 🧩 Estrazione dati documento
    // ↪️ Funzione: Convertire snapshot Firestore in oggetto Dart
    // ⚡ Input: DocumentSnapshot con dati voce
    // 📤 Output: Istanza VoiceMessage
    // 🔄 Logica: Mappatura campi con conversione tipi
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return VoiceMessage(
      id: doc.id, // 🆔 ID documento come identificatore primario
      // 🕒 Conversione timestamp
      // 🔄 Necessario poiché Firestore usa Timestamp
      timestamp: (data['timestamp'] as Timestamp).toDate(),

      // 📍 Coordinate geografiche
      latitude: data['latitude'],
      longitude: data['longitude'],

      // ⏱️ Conversione durata
      // 🔄 Firestore salva secondi come intero
      duration: Duration(seconds: data['duration']),

      // 🏷️ Ricerca categoria enumerata
      // ⚠️ Fallback a 'free' se mancante
      category: MessageCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => MessageCategory.free,
      ),

      // 🔑 Chiave oggetto storage decentralizzato
      storjObjectKey: data['storjObjectKey'],

      // 👤 Gestione mittente con fallback
      senderId: data['senderId'] ?? 'unknown',

      // 👀 Contatore visualizzazioni (default 0)
      views: data['views'] ?? 0,

      // 👥 Lista utenti che hanno visualizzato
      // 🔄 Conversione esplicita per tipo List<String>
      viewedBy: List<String>.from(data['viewedBy'] ?? []),
    );
  }

  // ██████████████████████████████████████████████████████████████████████
  // ✂️ METODO COPY-WITH
  // ██████████████████████████████████████████████████████████████████████
  /// Genera copia dell'oggetto con campi aggiornati (pattern builder)
  VoiceMessage copyWith({
    String? id,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    Duration? duration,
    MessageCategory? category,
    String? storjObjectKey,
    String? senderId,
    String? localPath,
    int? views,
    List<String>? viewedBy,
  }) {
    // 🧩 Costruzione copia selettiva
    // ↪️ Funzione: Creazione istanza modificata
    // ⚡ Input: Parametri opzionali per override
    // 📤 Output: Nuova istanza con valori sovrascritti
    // 🔄 Logica: Mantiene valori originali dove non specificato
    return VoiceMessage(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      storjObjectKey: storjObjectKey ?? this.storjObjectKey,
      senderId: senderId ?? this.senderId,

      // 💾 Percorso file locale (nullable)
      localPath: localPath ?? this.localPath,

      // 📊 Statistiche visualizzazioni
      views: views ?? this.views,
      viewedBy: viewedBy ?? this.viewedBy,
    );
  }
}
