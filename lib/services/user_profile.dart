// lib/services/user_profile.dart
//
// Modulo centrale per la gestione del profilo utente in Firestore.
// - Definisce TUTTE le chiavi supportate dall'app (fonte di verità).
// - Fornisce default per nuove chiavi (auto-migrazione non distruttiva).
// - Esegue upsert al login (crea/aggiorna), aggiunge chiavi mancanti,
//   e opzionalmente rimuove (pruning) chiavi non più presenti nello script.
// - Espone helper per aggiornare solo ultimo_accesso, gestire id_bloccati,
//   e impostare/cancellare data_di_nascita.

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
  // static const affidabilita = 'affidabilita';
  static const idBloccati = 'id_bloccati'; // LISTA di UID

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
    // UserProfileKeys.affidabilita: () => 0,
    UserProfileKeys.idBloccati: () => <String>[],
    UserProfileKeys.dataDiNascita: () => null, // valorizzata dall’utente
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
      // UserProfileKeys.affidabilita: defaults[UserProfileKeys.affidabilita]!(),
      UserProfileKeys.idBloccati: defaults[UserProfileKeys.idBloccati]!(),
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
  /// Esegue una piccola validazione: non può essere nel futuro.
  static Map<String, dynamic> setDataDiNascita(DateTime? dob) {
    if (dob == null) {
      return {UserProfileKeys.dataDiNascita: null};
    }
    final now = DateTime.now();
    if (dob.isAfter(now)) {
      throw ArgumentError('La data di nascita non può essere futura.');
    }
    return {UserProfileKeys.dataDiNascita: Timestamp.fromDate(dob)};
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
  /// - aggiunge SOLO chiavi mancanti con default
  /// - opzionalmente elimina chiavi non presenti nello script (pruning)
  static Future<void> _reconcileSchema(
    DocumentReference<Map<String, dynamic>> ref, {
    required Map<String, dynamic> existing,
    required bool pruneUnknownKeys,
    required bool documentJustCreated,
  }) async {
    final schemaKeys = UserProfileSchema.defaults.keys.toSet();

    // Aggiunte mancanti
    final Map<String, dynamic> toAdd = {};
    for (final key in schemaKeys) {
      final exists = existing.containsKey(key) && existing[key] != null;
      if (!exists) {
        if (!documentJustCreated && key == UserProfileKeys.dataRegistrazione) {
          continue; // non reinizializzare data_registrazione
        }
        toAdd[key] = UserProfileSchema.defaults[key]!();
      }
    }

    // Rimozione extra (chiavi non presenti nello script)
    final Map<String, dynamic> toDelete = {};
    if (pruneUnknownKeys) {
      for (final key in existing.keys) {
        if (!schemaKeys.contains(key)) {
          toDelete[key] = FieldValue.delete();
        }
      }
    }

    if (toAdd.isNotEmpty || toDelete.isNotEmpty) {
      await ref.set({...toAdd, ...toDelete}, SetOptions(merge: true));
    }
  }
}
