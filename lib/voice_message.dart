// voice_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/category_utils.dart';

/// Supporta sia VOCALI che TESTO
enum MessageType { voice, text }

/// Modello messaggio
class VoiceMessage {
  // Base
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;

  // VOCE (per i testi restano valori neutri)
  final Duration duration; // 0 per i messaggi testuali
  final String storjObjectKey; // "" per i messaggi testuali

  // TESTO (per i vocali resta null)
  final String? text;

  // Meta
  final MessageType type; // voice | text
  final MessageCategory category;
  final String senderId;
  final String name;

  // Local-only / stats
  String? localPath; // solo per voice (download locale)
  int views;
  List<String> viewedBy;

  bool get isVoice => type == MessageType.voice;
  bool get isText => type == MessageType.text;

  VoiceMessage({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.duration,
    required this.category,
    required this.storjObjectKey,
    required this.senderId,
    required this.name,
    required this.views,
    required this.viewedBy,
    required this.type,
    this.text,
    this.localPath,
  });

  /// Costruzione robusta da Firestore (retrocompat: default type=voice)
  factory VoiceMessage.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    // timestamp può essere null finché serverTimestamp() non è risolto
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final DateTime tsDt = ts?.toDate() ?? DateTime.now();

    // Cast numerici sicuri
    final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lon = (data['longitude'] as num?)?.toDouble() ?? 0.0;

    // Tipo: default "voice" per documenti vecchi
    final String rawType = (data['type'] as String?) ?? 'voice';
    final MessageType type =
        rawType == 'text' ? MessageType.text : MessageType.voice;

    final int durSec = (data['duration'] as num?)?.toInt() ?? 0;
    final String key = (data['storjObjectKey'] as String?) ?? '';
    final String? text = data['text'] as String?;

    // Categoria sicura
    final String catName = (data['category'] as String?) ?? 'free';
    final MessageCategory cat = MessageCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => MessageCategory.free,
    );

    // Campi basic
    final String sid = (data['senderId'] as String?) ?? 'unknown';

    // Statistiche
    final int views = (data['views'] as num?)?.toInt() ?? 0;
    final List<String> viewedBy =
        List<String>.from((data['viewedBy'] as List?) ?? const []);

    // Nome mittente salvato sul messaggio (fallback “Anonimo”)
    final String name = ((data['name'] as String?)?.trim().isNotEmpty ?? false)
        ? (data['name'] as String).trim()
        : 'Anonimo';

    return VoiceMessage(
      id: doc.id,
      timestamp: tsDt,
      latitude: lat,
      longitude: lon,
      duration:
          type == MessageType.voice ? Duration(seconds: durSec) : Duration.zero,
      category: cat,
      storjObjectKey: type == MessageType.voice ? key : '',
      senderId: sid,
      name: name,
      views: views,
      viewedBy: viewedBy,
      type: type,
      text: type == MessageType.text ? (text ?? '') : null,
    );
  }

  /// copyWith
  VoiceMessage copyWith({
    String? id,
    DateTime? timestamp,
    double? latitude,
    double? longitude,
    Duration? duration,
    MessageCategory? category,
    String? storjObjectKey,
    String? senderId,
    String? name,
    String? localPath,
    int? views,
    List<String>? viewedBy,
    MessageType? type,
    String? text,
  }) {
    return VoiceMessage(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      duration: duration ?? this.duration,
      category: category ?? this.category,
      storjObjectKey: storjObjectKey ?? this.storjObjectKey,
      senderId: senderId ?? this.senderId,
      name: name ?? this.name,
      localPath: localPath ?? this.localPath,
      views: views ?? this.views,
      viewedBy: viewedBy ?? this.viewedBy,
      type: type ?? this.type,
      text: text ?? this.text,
    );
  }
}
