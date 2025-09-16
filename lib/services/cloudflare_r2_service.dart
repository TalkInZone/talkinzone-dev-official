// ======================================================================================
// 🧩 IMPORTAZIONI NECESSARIE
// ======================================================================================
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:minio/minio.dart'; // ☁️ Client per servizi S3-compatibili (ora Cloudflare R2)
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// ======================================================================================
// 🚀 CLASSE PRINCIPALE CLOUDFLARER2SERVICE (SINGLETON)
// ======================================================================================
class CloudflareR2Service {
  // 🔒 IMPLEMENTAZIONE DEL PATTERN SINGLETON
  static final CloudflareR2Service _instance = CloudflareR2Service._internal();
  factory CloudflareR2Service() => _instance;
  CloudflareR2Service._internal();

  // ====================================================================================
  // 🔐 CONFIGURAZIONE CREDENZIALI PER CLOUDFLARE R2
  // ====================================================================================
  // 🌐 Endpoint del tuo account Cloudflare R2 (sostituisci <ACCOUNT_ID> con il tuo ID)
  static const String endpoint = '52fd9ac382dfe1f593eb25de2b257857.r2.cloudflarestorage.com';
  
  // 🔑 Chiave di accesso (generata dal dashboard Cloudflare R2 - API Tokens)
  static const String accessKey = '9e9cac48fea911f64bccbc2ed732a247';
  
  // 🗝️ Chiave segreta (generata dal dashboard Cloudflare R2 - API Tokens)
  static const String secretKey = '82f1d3302e78133c78d72223af706103fa7da9f8b72aedc19313361f35943d70';
  
  // 📦 Nome del bucket creato su Cloudflare R2
  static const String bucketName = 'talkinzone-audio';

  // ====================================================================================
  // 💾 STATO INTERNO DEL SERVIZIO
  // ====================================================================================
  Minio? _minio;
  final Map<String, String> _audioCache = {};
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  // ====================================================================================
  // ⚙️ INIZIALIZZAZIONE DEL SERVIZIO
  // ====================================================================================
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 🏗️ Creazione dell'istanza del client Minio per Cloudflare R2
      _minio = Minio(
        endPoint: endpoint,
        accessKey: accessKey,
        secretKey: secretKey,
        useSSL: true, // 🔐 Cloudflare R2 richiede HTTPS
        region: 'auto', // ⚠️ IMPORTANTE: Cloudflare R2 richiede region 'auto'
      );

      // 🔍 Verifica che il bucket esista (operazione leggera)
      try {
        await _minio!.bucketExists(bucketName);
      } catch (e) {
        // ❌ Se il bucket non esiste, crealo
        if (e.toString().contains('404') || e.toString().contains('NoSuchBucket')) {
          await _minio!.makeBucket(bucketName);
          if (kDebugMode) {
            debugPrint('📦 Bucket creato: $bucketName');
          }
        } else {
          rethrow;
        }
      }

      if (kDebugMode) {
        debugPrint('''
✅ CONNESSIONE CLOUDFLARE R2 STABILITA CON SUCCESSO!
   • Endpoint: $endpoint
   • Bucket: $bucketName''');
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('''
🚨 ERRORE CRITICO DURANTE L'INIZIALIZZAZIONE!
   • Tipo errore: ${e.runtimeType}
   • Dettagli: $e''');
      }
      rethrow;
    }
  }

  // ====================================================================================
  // ⬆️ UPLOAD DI FILE SU CLOUDFLARE R2
  // ====================================================================================
  Future<String> uploadFile(String filePath) async {
    if (_minio == null) {
      throw Exception('Servizio non inizializzato! Chiamare initialize() prima di usare i metodi');
    }

    try {
      final file = File(filePath);
      final fileName = p.basename(file.path);

      if (!await file.exists()) {
        throw Exception('File non trovato al percorso specificato: $filePath');
      }

      final fileBytes = await file.readAsBytes();
      final stream = Stream.value(fileBytes);

      // 🚀 Upload a Cloudflare R2
      await _minio!.putObject(
        bucketName,
        fileName,
        stream,
       //length: fileBytes.length, // ⚠️ Per Cloudflare R2 è meglio specificare la lunghezza
      );

      if (kDebugMode) {
        debugPrint('''
📤 UPLOAD COMPLETATO CON SUCCESSO SU CLOUDFLARE R2!
   • File: $fileName
   • Dimensione: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB
   • Bucket: $bucketName''');
      }

      return fileName;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('''
🚨 ERRORE DURANTE L'UPLOAD SU CLOUDFLARE R2!
   • Percorso file: $filePath
   • Dettagli errore: $e''');
      }
      rethrow;
    }
  }

  // ====================================================================================
  // ⬇️ DOWNLOAD DI FILE DA CLOUDFLARE R2
  // ====================================================================================
  Future<String> downloadFile(String objectKey) async {
    if (_minio == null) throw Exception('Servizio non inizializzato!');

    if (_audioCache.containsKey(objectKey)) {
      if (kDebugMode) {
        debugPrint('♻️ File recuperato dalla cache RAM: $objectKey');
      }
      return _audioCache[objectKey]!;
    }

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/$objectKey';
      final localFile = File(localPath);

      if (await localFile.exists()) {
        _audioCache[objectKey] = localPath;
        return localPath;
      }

      // 🌐 Download da Cloudflare R2
      final stream = await _minio!.getObject(bucketName, objectKey);
      final bytesBuilder = BytesBuilder();

      await for (var chunk in stream) {
        bytesBuilder.add(chunk);
      }

      await localFile.writeAsBytes(bytesBuilder.toBytes());
      _audioCache[objectKey] = localPath;

      if (kDebugMode) {
        debugPrint('''
📥 DOWNLOAD COMPLETATO CON SUCCESSO DA CLOUDFLARE R2!
   • Oggetto: $objectKey
   • Percorso locale: $localPath''');
      }

      return localPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('''
🚨 ERRORE DURANTE IL DOWNLOAD DA CLOUDFLARE R2!
   • Object key: $objectKey
   • Dettagli errore: $e''');
      }
      rethrow;
    }
  }

  // ====================================================================================
  // 🗑️ CANCELLAZIONE DI FILE DA CLOUDFLARE R2
  // ====================================================================================
  Future<void> deleteFile(String objectKey) async {
    if (_minio == null) throw Exception('Servizio non inizializzato!');

    try {
      await _minio!.removeObject(bucketName, objectKey);

      if (kDebugMode) {
        debugPrint('''
🗑️ FILE CANCELLATO DA CLOUDFLARE R2!
   • Oggetto: $objectKey
   • Bucket: $bucketName''');
      }
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        if (kDebugMode) {
          debugPrint('⚠️ Oggetto non trovato (probabilmente già cancellato): $objectKey');
        }
      } else {
        if (kDebugMode) {
          debugPrint('''
🚨 ERRORE DURANTE LA CANCELLAZIONE DA CLOUDFLARE R2!
   • Oggetto: $objectKey
   • Errore: $e''');
        }
        rethrow;
      }
    }
  }

  // ====================================================================================
  // 🧹 PULIZIA CACHE LOCALE
  // ====================================================================================
  void clearCache() {
    _audioCache.clear();
    if (kDebugMode) {
      debugPrint('🧹 Cache locale svuotata con successo');
    }
  }
}