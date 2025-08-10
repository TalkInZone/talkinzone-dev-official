// voice_message.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/category_utils.dart';

/// Modello messaggio vocale
class VoiceMessage {
  // Base
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final Duration duration;
  final MessageCategory category;
  final String storjObjectKey;
  final String senderId;

  // Aggiunte
  final String name; // <<--- Nome mittente salvato nel documento
  String? localPath;
  int views;
  List<String> viewedBy;

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
    this.localPath,
    required this.views,
    required this.viewedBy,
  });

  /// Costruzione robusta da Firestore
  factory VoiceMessage.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>? ?? {});

    // timestamp può essere null finché serverTimestamp() non è risolto
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final DateTime tsDt = ts?.toDate() ?? DateTime.now();

    // Cast numerici sicuri
    final double lat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
    final double lon = (data['longitude'] as num?)?.toDouble() ?? 0.0;
    final int durSec = (data['duration'] as num?)?.toInt() ?? 0;

    // Categoria sicura
    final String catName = (data['category'] as String?) ?? 'free';
    final MessageCategory cat = MessageCategory.values.firstWhere(
      (e) => e.name == catName,
      orElse: () => MessageCategory.free,
    );

    // Campi basic
    final String key = (data['storjObjectKey'] as String?) ?? '';
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
      duration: Duration(seconds: durSec),
      category: cat,
      storjObjectKey: key,
      senderId: sid,
      name: name,
      views: views,
      viewedBy: viewedBy,
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
    );
  }
}
