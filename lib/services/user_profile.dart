// lib/services/user_profile.dart
//
// Modulo centrale per la gestione del profilo utente in Firestore.
// - Definisce TUTTE le chiavi supportate dall'app (fonte di verità).
// - Fornisce default per nuove chiavi (auto-migrazione non distruttiva).
// - Esegue upsert al login (crea/aggiorna), aggiunge chiavi mancanti,
//   e opzionalmente rimuove (pruning) chiavi non più presenti nello script.
// - Espone helper per aggiornare solo ultimo_accesso, gestire id_bloccati,
//   e impostare/cancellare data_di_nascita.
//
// 🔧 FIX anti-“rimbalzo” age-gate:
// Il reconcile/pruning NON deve mai impostare `data_di_nascita` a null
// né riscriverla. Il pruning ora usa merge:true + FieldValue.delete().

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Chiavi del profilo utente (TENERE AGGIORNATE QUI).
class UserProfileKeys {
  // === 6 chiavi principali (estratte da servizi esterni / auth) ===
  static const dataRegistrazione =
      'data_registrazione'; // solo alla prima creazione
  static const email = 'email';
  static const fotoUrl = 'foto_url';
  static const nome = 'nome';
  static const provider = 'provider';
  static const ultimoAccesso =
      'ultimo_accesso'; // aggiornato ad OGNI ingresso in app

  // === chiavi aggiuntive (app) ===
  static const status = 'status';
  static const likeTotali = 'like_totali';
  static const idBloccati = 'id_bloccati'; // LISTA di UID
  static const blockedNames =
      'blocked_names'; // MAPPA { uid -> nomeMostrabile }

  /// Nuova chiave richiesta
  static const dataDiNascita = 'data_di_nascita'; // Timestamp o null
}

/// Schema + default per ogni chiave.
/// NOTA: i default sono funzioni per poter usare FieldValue.* quando serve.
class UserProfileSchema {
  /// Se aggiungi una nuova chiave in futuro:
  /// 1) Definisci la costante in UserProfileKeys
  /// 2) Aggiungi qui il suo default.
  static final Map<String, dynamic Function()> defaults = {
    // 6 principali
    UserProfileKeys.provider: () => 'google',
    UserProfileKeys.email: () => null, // viene impostata dal provider
    UserProfileKeys.nome: () => 'Utente senza nome',
    UserProfileKeys.fotoUrl: () => null,
    UserProfileKeys.dataRegistrazione: () =>
        FieldValue.serverTimestamp(), // SOLO alla creazione
    UserProfileKeys.ultimoAccesso: () =>
        FieldValue.serverTimestamp(), // toccato a ogni ingresso

    // aggiuntive
    UserProfileKeys.status: () => 'active',
    UserProfileKeys.likeTotali: () => 0,
    UserProfileKeys.idBloccati: () => <String>[],
    UserProfileKeys.blockedNames: () => <String, String>{},

    // Età: viene valorizzata dall’utente nel gate, default = null
    UserProfileKeys.dataDiNascita: () => null,
  };

  /// Mappa iniziale alla PRIMA creazione del documento.
  static Map<String, dynamic> initialFromFirebaseUser(
    User user, {
    String provider = 'google',
  }) {
    return {
      // 6 principali
      UserProfileKeys.provider: provider,
      UserProfileKeys.email: user.email,
      UserProfileKeys.nome:
          user.displayName ?? defaults[UserProfileKeys.nome]!(),
      UserProfileKeys.fotoUrl: user.photoURL,
      UserProfileKeys.dataRegistrazione: FieldValue.serverTimestamp(),
      UserProfileKeys.ultimoAccesso: FieldValue.serverTimestamp(),

      // aggiuntive
      UserProfileKeys.status: defaults[UserProfileKeys.status]!(),
      UserProfileKeys.likeTotali: defaults[UserProfileKeys.likeTotali]!(),
      UserProfileKeys.idBloccati: defaults[UserProfileKeys.idBloccati]!(),
      UserProfileKeys.blockedNames: defaults[UserProfileKeys.blockedNames]!(),

      // Età (null alla creazione, l’utente la imposta nel gate)
      UserProfileKeys.dataDiNascita: defaults[UserProfileKeys.dataDiNascita]!(),
    };
  }
}

class UserProfile {
  /// Upsert al login:
  /// - Se il doc NON esiste -> crea con tutte le chiavi.
  /// - Se esiste -> aggiorna campi del provider + ultimo_accesso, NON tocca data_registrazione,
  ///   aggiunge chiavi mancanti e (opzionale) rimuove quelle non più presenti nello script.
  static Future<void> upsertOnAuth(
    User user, {
    String provider = 'google',
    bool pruneUnknownKeys = true, // pruning attivo di default
  }) async {
    final ref = FirebaseFirestore.instance.collection('utenti').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set(
        UserProfileSchema.initialFromFirebaseUser(user, provider: provider),
      );
      return;
    }

    await ref.set({
      UserProfileKeys.provider: provider,
      UserProfileKeys.email: user.email,
      UserProfileKeys.nome: user.displayName ??
          UserProfileSchema.defaults[UserProfileKeys.nome]!(),
      UserProfileKeys.fotoUrl: user.photoURL,
      UserProfileKeys.ultimoAccesso: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await _reconcileSchema(
      ref,
      existing: (snap.data() ?? const <String, dynamic>{}),
      pruneUnknownKeys: pruneUnknownKeys,
      documentJustCreated: false,
    );
  }

  /// Aggiorna SOLO l'ultimo_accesso (usare all'avvio app e quando torna in foreground).
  static Map<String, dynamic> touchLastAccess() {
    return {UserProfileKeys.ultimoAccesso: FieldValue.serverTimestamp()};
  }

  /// Aggiunge/rimuove UID nella lista dei bloccati.
  static Map<String, dynamic> resetBlockedList() {
    return {UserProfileKeys.idBloccati: <String>[]};
  }

  static Map<String, dynamic> blockUsers(List<String> uids) {
    return {UserProfileKeys.idBloccati: FieldValue.arrayUnion(uids)};
  }

  static Map<String, dynamic> unblockUsers(List<String> uids) {
    return {UserProfileKeys.idBloccati: FieldValue.arrayRemove(uids)};
  }

  /// Imposta la data di nascita (Timestamp) o la cancella se null.
  /// - Non può essere nel futuro
  /// - Normalizzata a mezzanotte UTC (evita problemi di fuso/orario legale)
  static Map<String, dynamic> setDataDiNascita(DateTime? dobLocal) {
    if (dobLocal == null) {
      return {UserProfileKeys.dataDiNascita: null};
    }
    final now = DateTime.now();
    if (dobLocal.isAfter(now)) {
      throw ArgumentError('La data di nascita non può essere futura.');
    }
    final dobUtc = DateTime.utc(dobLocal.year, dobLocal.month, dobLocal.day);
    return {UserProfileKeys.dataDiNascita: Timestamp.fromDate(dobUtc)};
  }

  /// (Opzionale) Sincronizza schema on-demand per un UID specifico.
  static Future<void> syncSchemaWithDatabase(String uid,
      {bool pruneUnknownKeys = true}) async {
    final ref = FirebaseFirestore.instance.collection('utenti').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) return;
    await _reconcileSchema(
      ref,
      existing: (snap.data() ?? const <String, dynamic>{}),
      pruneUnknownKeys: pruneUnknownKeys,
      documentJustCreated: false,
    );
  }

  /// Confronta con lo schema:
  /// - aggiunge SOLO chiavi mancanti con default (MAI `data_di_nascita`)
  /// - opzionalmente elimina chiavi non presenti nello script (pruning)
  ///   usando merge:true + FieldValue.delete() per evitare overwrite.
  static Future<void> _reconcileSchema(
    DocumentReference<Map<String, dynamic>> ref, {
    required Map<String, dynamic> existing,
    required bool pruneUnknownKeys,
    required bool documentJustCreated,
  }) async {
    final schemaKeys = UserProfileSchema.defaults.keys.toSet();

    // 1) Pruning: prepara solo DELETE delle chiavi non previste
    final Map<String, dynamic> deletes = {};
    if (pruneUnknownKeys) {
      for (final key in existing.keys) {
        if (!schemaKeys.contains(key)) {
          deletes[key] = FieldValue.delete();
        }
      }
    }

    // 2) Aggiunte mancanti con default (ma NON per data_di_nascita)
    final Map<String, dynamic> toAdd = {};
    for (final key in schemaKeys) {
      if (key == UserProfileKeys.dataDiNascita) {
        // mai auto-scrivere data_di_nascita: la gestisce l'utente dal gate
        continue;
      }
      final hasNonNull = existing.containsKey(key) && existing[key] != null;

      if (!hasNonNull) {
        // Non reinizializzare data_registrazione su documenti già esistenti
        if (!documentJustCreated && key == UserProfileKeys.dataRegistrazione) {
          continue;
        }
        toAdd[key] = UserProfileSchema.defaults[key]!();
      }
    }

    // 3) Unica write con merge:true:
    //    - elimina solo le chiavi extra
    //    - aggiunge le mancanti
    //    - NON tocca i campi esistenti (inclusa data_di_nascita)
    if (toAdd.isNotEmpty || deletes.isNotEmpty) {
      await ref.set({...deletes, ...toAdd}, SetOptions(merge: true));
    }
  }
}
