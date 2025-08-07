// ======================================================================================
// 🧩 IMPORTAZIONI NECESSARIE
// ======================================================================================
import 'dart:io'; // 🗂️ Fornisce classi per lavorare con file e directory
import 'dart:typed_data'; // 🧠 Gestione dati binari (liste di byte)
import 'package:flutter/foundation.dart'; // 📱 Funzionalità fondamentali Flutter + debug
import 'package:minio/minio.dart'; // ☁️ Client ufficiale per interagire con servizi S3-compatibili come Storj
import 'package:path/path.dart'
    as p; // 🗺️ Utility per manipolare percorsi di file
import 'package:path_provider/path_provider.dart'; // 📂 Ottiene percorsi di sistema per salvare file

// ======================================================================================
// 🚀 CLASSE PRINCIPALE STORJSERVICE (SINGLETON)
// ======================================================================================
class StorjService {
  // 🔒 IMPLEMENTAZIONE DEL PATTERN SINGLETON
  // ------------------------------------------------------------------------------------
  // Garantisce una sola istanza globale della classe
  static final StorjService _instance = StorjService._internal();

  // Factory constructor per accesso controllato all'istanza
  factory StorjService() => _instance;

  // Costruttore interno privato (impedisce creazioni esterne)
  StorjService._internal();

  // ====================================================================================
  // 🔐 CONFIGURAZIONE CREDENZIALI PER STORJ
  // ====================================================================================
  static const String endpoint =
      'gateway.storjshare.io'; // 🌐 Endpoint del gateway Storj
  static const String accessKey =
      'jxd2jggpnkye4wfsb6lalf4b6cia'; // 🔑 Chiave di accesso
  static const String secretKey =
      'jzh5ytpjdnh5p3divr2qrhc3qsbf4lj32z7wojrwa4uoh75yar6yk'; // 🗝️ Chiave segreta
  static const String bucketName =
      'voice-chat-audios'; // 📦 Nome del bucket predefinito

  // ====================================================================================
  // 💾 STATO INTERNO DEL SERVIZIO
  // ====================================================================================
  Minio?
  _minio; // 🧩 Istanza del client Minio (inizializzata solo dopo chiamata a initialize())
  final Map<String, String> _audioCache =
      {}; // 💿 Cache locale: objectKey -> percorso file locale
  bool _isInitialized =
      false; // 🚩 Flag che indica se il servizio è stato inizializzato

  // 🔍 Getter pubblico per verificare lo stato di inizializzazione
  bool get isInitialized => _isInitialized;

  // ====================================================================================
  // ⚙️ INIZIALIZZAZIONE DEL SERVIZIO
  // ====================================================================================
  Future<void> initialize() async {
    // Se già inizializzato, termina immediatamente
    if (_isInitialized) return;

    try {
      // 🏗️ Creazione dell'istanza del client Minio con le credenziali
      _minio = Minio(
        endPoint: endpoint,
        accessKey: accessKey,
        secretKey: secretKey,
        useSSL: true, // 🔐 Utilizza connessioni sicure HTTPS
      );

      // 🔍 TEST DI CONNESSIONE AL SERVIZIO STORJ
      // ----------------------------------------------------------------------------------
      // Operazione leggera per verificare la connettività
      final buckets = await _minio!.listBuckets();

      // 🐞 LOG DI DEBUG (solo in modalità sviluppo)
      if (kDebugMode) {
        debugPrint('''
✅ CONNESSIONE STORJ STABILITA CON SUCCESSO!
   • Endpoint: $endpoint
   • Buckets disponibili: ${buckets.length}''');
      }

      // Contrassegna il servizio come inizializzato
      _isInitialized = true;
    } catch (e) {
      // ❌ GESTIONE ERRORI DURANTE L'INIZIALIZZAZIONE
      if (kDebugMode) {
        debugPrint('''
🚨 ERRORE CRITICO DURANTE L'INIZIALIZZAZIONE!
   • Tipo errore: ${e.runtimeType}
   • Dettagli: $e''');
      }
      // Rilancia l'eccezione per permettere alla chiamata esterna di gestirla
      rethrow;
    }
  }

  // ====================================================================================
  // ⬆️ UPLOAD DI FILE SU STORJ
  // ====================================================================================
  Future<String> uploadFile(String filePath) async {
    // Verifica che il servizio sia stato inizializzato
    if (_minio == null) {
      throw Exception(
        'Servizio non inizializzato! Chiamare initialize() prima di usare i metodi',
      );
    }

    try {
      // 🗂️ Creazione riferimento al file locale
      final file = File(filePath);

      // 📝 Estrazione del nome file dal percorso completo
      final fileName = p.basename(file.path);

      // 🔍 VERIFICA ESISTENZA FILE LOCALE
      if (!await file.exists()) {
        throw Exception('File non trovato al percorso specificato: $filePath');
      }

      // 📦 LETTURA CONTENUTO DEL FILE
      final fileBytes = await file.readAsBytes();

      // 🔄 Conversione in stream (formato richiesto da Minio)
      final stream = Stream.value(fileBytes);

      // 🚀 OPERAZIONE DI UPLOAD VERA E PROPRIA
      // CORREZIONE: rimosso il parametro 'length' non supportato
      await _minio!.putObject(
        bucketName, // Bucket di destinazione
        fileName, // Nome dell'oggetto su Storj
        stream, // Stream contenente i dati
      );

      // 📣 NOTIFICA DI SUCCESSO (debug)
      if (kDebugMode) {
        debugPrint('''
📤 UPLOAD COMPLETATO CON SUCCESSO!
   • File: $fileName
   • Dimensione: ${(fileBytes.length / 1024).toStringAsFixed(2)} KB
   • Bucket: $bucketName''');
      }

      // Restituisce il nome del file (che sarà l'object key su Storj)
      return fileName;
    } catch (e) {
      // ❌ GESTIONE ERRORI DURANTE L'UPLOAD
      if (kDebugMode) {
        debugPrint('''
🚨 ERRORE DURANTE L'UPLOAD!
   • Percorso file: $filePath
   • Dettagli errore: $e''');
      }
      rethrow;
    }
  }

  // ====================================================================================
  // ⬇️ DOWNLOAD DI FILE DA STORJ
  // ====================================================================================
  Future<String> downloadFile(String objectKey) async {
    // Verifica inizializzazione servizio
    if (_minio == null) throw Exception('Servizio non inizializzato!');

    // 🔄 CONTROLLO CACHE IN MEMORIA
    // ----------------------------------------------------------------------------------
    // Se l'oggetto è già in cache, restituisci il percorso locale immediatamente
    if (_audioCache.containsKey(objectKey)) {
      if (kDebugMode) {
        debugPrint('♻️ File recuperato dalla cache RAM: $objectKey');
      }
      return _audioCache[objectKey]!;
    }

    try {
      // 📂 OTTIENI LA DIRECTORY DOCUMENTI DELL'APP
      final appDir = await getApplicationDocumentsDirectory();

      // 🗂️ Costruisci il percorso locale per il file
      final localPath = '${appDir.path}/$objectKey';
      final localFile = File(localPath);

      // 🔍 VERIFICA SE IL FILE ESISTE GIÀ LOCALMENTE
      // --------------------------------------------------------------------------------
      // Evita di scaricare nuovamente se già presente
      if (await localFile.exists()) {
        // Aggiorna la cache per accessi futuri
        _audioCache[objectKey] = localPath;
        return localPath;
      }

      // 🌐 OPERAZIONE DI DOWNLOAD DA STORJ
      // --------------------------------------------------------------------------------
      // Ottieni lo stream dei dati dall'oggetto Storj
      final stream = await _minio!.getObject(bucketName, objectKey);

      // 🧩 BYTESBUILDER PER ACCUMULARE I DATI SCARICATI
      final bytesBuilder = BytesBuilder();

      // 🔁 Leggi i chunk di dati dallo stream
      await for (var chunk in stream) {
        bytesBuilder.add(chunk); // Aggiungi ogni chunk al builder
      }

      // 💾 SALVATAGGIO SU DISCO
      // --------------------------------------------------------------------------------
      // Converti i dati accumulati in Uint8List e scrivi sul file
      await localFile.writeAsBytes(bytesBuilder.toBytes());

      // 📥 AGGIORNAMENTO CACHE
      _audioCache[objectKey] = localPath;

      // 📣 NOTIFICA DI SUCCESSO
      if (kDebugMode) {
        debugPrint('''
📥 DOWNLOAD COMPLETATO CON SUCCESSO!
   • Oggetto: $objectKey
   • Percorso locale: $localPath''');
      }

      return localPath;
    } catch (e) {
      // ❌ GESTIONE ERRORI DURANTE IL DOWNLOAD
      if (kDebugMode) {
        debugPrint('''
🚨 ERRORE DURANTE IL DOWNLOAD!
   • Object key: $objectKey
   • Dettagli errore: $e''');
      }
      rethrow;
    }
  }

  // ====================================================================================
  // 🗑️ CANCELLAZIONE DI FILE DA STORJ
  // ====================================================================================
  Future<void> deleteFile(String objectKey) async {
    // Verifica inizializzazione servizio
    if (_minio == null) throw Exception('Servizio non inizializzato!');

    try {
      // 🧹 OPERAZIONE DI CANCELLAZIONE
      await _minio!.removeObject(bucketName, objectKey);

      // 📣 NOTIFICA DI SUCCESSO
      if (kDebugMode) {
        debugPrint('''
🗑️ FILE CANCELLATO DA STORJ!
   • Oggetto: $objectKey
   • Bucket: $bucketName''');
      }
    } catch (e) {
      // ⚠️ GESTIONE SPECIALE ERRORI "NON TROVATO"
      // ----------------------------------------------------------------------------------
      // Se l'oggetto è già stato cancellato o non esiste
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        if (kDebugMode) {
          debugPrint(
            '⚠️ Oggetto non trovato (probabilmente già cancellato): $objectKey',
          );
        }
      } else {
        // ❌ GESTIONE DI ALTRI ERRORI
        if (kDebugMode) {
          debugPrint('''
🚨 ERRORE DURANTE LA CANCELLAZIONE!
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
    // Svuota la mappa di cache
    _audioCache.clear();

    // Notifica operazione (solo in debug)
    if (kDebugMode) {
      debugPrint('🧹 Cache locale svuotata con successo');
    }
  }
}
