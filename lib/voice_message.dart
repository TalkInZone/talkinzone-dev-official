// =============================================================================
// 📦 FILE: voice_message.dart
// =============================================================================
// Modello dati per un messaggio (vocale o testo) della bacheca.
// - Supporta categorie (enum MessageCategory)
// - Gestisce messaggi "custom" con nome categoria personalizzato
// - Contiene info per riproduzione audio (localPath) e statistiche (views)
// =============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_utils.dart'; // per MessageCategory

class VoiceMessage {
  // 🔑 Identificatori e meta
  final String id;
  final DateTime timestamp;

  // 📍 Posizione
  final double latitude;
  final double longitude;

  // ⏱️ Durata audio (0 per messaggi testuali)
  final int duration;

  // 🏷️ Categoria enum + (🆕) nome custom salvato su Firestore
  final MessageCategory category;
  final String? customCategoryName; // es. "provolonebaby" se category == custom

  // ☁️ Storage remoto (vuoto per testo)
  final String storjObjectKey;

  // 👤 Mittente
  final String senderId;
  final String name; // nome mittente (denormalizzato per praticità UI)

  // 👀 Statistiche
  int views;
  List<String> viewedBy;

  // 📝 Testo (null per messaggi vocali)
  final String? text;

  // 💾 Percorso locale file audio (download temporaneo)
  String? localPath;

  // 🔤 Tipo messaggio ('voice' | 'text')
  final String type;

  // 👀 Comodità
  bool get isText => type == 'text';
  bool get isVoice => !isText;

  VoiceMessage({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.duration,
    required this.category,
    this.customCategoryName,
    required this.storjObjectKey,
    required this.senderId,
    required this.views,
    required this.viewedBy,
    required this.name,
    required this.text,
    this.localPath,
    required this.type,
  });

  /// Factory: costruisce l'istanza a partire da un documento Firestore.
  factory VoiceMessage.fromFirestore(DocumentSnapshot doc) {
    final data =
        doc.data() as Map<String, dynamic>? ?? const <String, dynamic>{};

    // Timestamp
    final DateTime ts = (data['timestamp'] is Timestamp)
        ? (data['timestamp'] as Timestamp).toDate()
        : DateTime.now();

    // Categoria (fallback: free)
    final catRaw = (data['category'] as String? ?? 'free').toLowerCase();
    final MessageCategory cat = MessageCategory.values.firstWhere(
      (e) => e.name.toLowerCase() == catRaw,
      orElse: () => MessageCategory.free,
    );

    // Nome custom della categoria (se presente)
    final String? customName = (data['customCategoryName'] as String?)?.trim();

    // Tipo messaggio (fallback: voice)
    final String msgType =
        (data['type'] as String?)?.toLowerCase() == 'text' ? 'text' : 'voice';

    // Vista/letture
    final int v = (data['views'] as num?)?.toInt() ?? 0;
    final List<String> vb = ((data['viewedBy'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList();

    return VoiceMessage(
      id: doc.id,
      timestamp: ts,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      duration: (data['duration'] as num?)?.toInt() ?? 0,
      category: cat,
      customCategoryName:
          (customName != null && customName.isNotEmpty) ? customName : null,
      storjObjectKey: (data['storjObjectKey'] as String?) ?? '',
      senderId: (data['senderId'] as String?) ?? '',
      views: v,
      viewedBy: vb,
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String)
          : 'Anonimo',
      text: (data['text'] as String?),
      localPath: null,
      type: msgType,
    );
  }

  get reactions => null;

  /// copyWith minimale (usato dalla UI per aggiornare localPath senza ricreare tutto)
  VoiceMessage copyWith({
    String? localPath,
    int? views,
    List<String>? viewedBy,
  }) {
    return VoiceMessage(
      id: id,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      duration: duration,
      category: category,
      customCategoryName: customCategoryName,
      storjObjectKey: storjObjectKey,
      senderId: senderId,
      views: views ?? this.views,
      viewedBy: viewedBy ?? List<String>.from(this.viewedBy),
      name: name,
      text: text,
      localPath: localPath ?? this.localPath,
      type: type,
    );
  }

  @override
  String toString() {
    return 'VoiceMessage(id: $id, type: $type, category: ${category.name}, '
        'custom: $customCategoryName, views: $views, text? ${text != null})';
  }
}
