import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Utilizziamo lo stesso Web Client ID per entrambi i campi
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    clientId:
        '282305776445-rumrd5h2kb4mt7e8g6pdkfqpjmi2sk3l.apps.googleusercontent.com',
    serverClientId:
        '282305776445-rumrd5h2kb4mt7e8g6pdkfqpjmi2sk3l.apps.googleusercontent.com',
  );

  Future<User?> signInWithGoogle() async {
    try {
      debugPrint("🔄 [1/6] Inizio processo autenticazione Google...");

      // Tentativo di logout preventivo
      debugPrint("🔒 [2/6] Eseguo logout preventivo...");
      try {
        await _googleSignIn.signOut();
        await _auth.signOut();
        debugPrint("✅ Logout completato");
      } catch (e) {
        debugPrint("⚠️ Errore durante il logout: $e");
      }

      debugPrint("👤 [3/6] Richiedo selezione account Google...");
      final GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        debugPrint(
          "❌ PlatformException durante signIn: [${e.code}] ${e.message}",
        );
        if (e.code == 'sign_in_canceled') {
          debugPrint("👤 Utente ha annullato la selezione account");
          return null;
        }
        if (e.code == 'sign_in_failed' &&
            e.message != null &&
            e.message!.contains('10')) {
          debugPrint(
            "🔥 ERRORE CRITICO: Configurazione sviluppatore errata (10)",
          );
          debugPrint("ℹ️ Soluzioni possibili:");
          debugPrint("1. Verifica SHA-1 in Firebase Console");
          debugPrint("2. Controlla package name in google-services.json");
          debugPrint("3. Aggiungi email di test in Google Cloud Console");
        }
        return null;
      } catch (e) {
        debugPrint("❌ Errore imprevisto durante signIn: $e");
        return null;
      }
     debugPrint("✅ Account selezionato: ${googleUser?.email ?? 'Nessuna email'}");

      debugPrint("🔑 [4/6] Richiedo token di autenticazione...");
      final GoogleSignInAuthentication googleAuth;
      try {
      googleAuth = googleUser!.authentication as GoogleSignInAuthentication;
      } on PlatformException catch (e) {
        debugPrint(
          "❌ PlatformException durante auth: [${e.code}] ${e.message}",
        );
        return null;
      } catch (e) {
        debugPrint("❌ Errore imprevisto durante auth: $e");
        return null;
      }

      // Log dettagliato dei token (primi 10 caratteri per sicurezza)
      debugPrint(
        "🪙 ID Token: ${googleAuth.idToken != null ? 'presente' : 'nullo'}",
      );
      debugPrint(
        "🔓 Access Token: ${googleAuth.accessToken != null ? 'presente' : 'nullo'}",
      );

      if (googleAuth.idToken == null) {
        debugPrint("❌ ID Token mancante - impossibile procedere");
        return null;
      }

      debugPrint("🔥 [5/6] Creo credenziale Firebase...");
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("🚀 [6/6] Autenticazione con Firebase...");
      try {
        final UserCredential userCredential = await _auth.signInWithCredential(
          credential,
        );

        if (userCredential.user == null) {
          debugPrint("❌ Nessun utente restituito da Firebase");
          return null;
        }

        debugPrint("🎉 Accesso riuscito! UID: ${userCredential.user!.uid}");
        await _processUserData(userCredential.user!);
        return userCredential.user;
      } on FirebaseAuthException catch (e) {
        debugPrint("🔥 FirebaseAuthException: [${e.code}] ${e.message}");

        if (e.code == 'account-exists-with-different-credential') {
          debugPrint("⚠️ Account già esistente con credenziali diverse");
        }
        if (e.code == 'invalid-credential') {
          debugPrint("🔑 Credenziali non valide o scadute");
        }
        if (e.code == 'operation-not-allowed') {
          debugPrint(
            "⛔ Autenticazione Google non abilitata in Firebase Console",
          );
        }

        return null;
      } catch (e) {
        debugPrint("❌ Errore durante signInWithCredential: $e");
        return null;
      }
    } catch (e, stack) {
      debugPrint("💥 ERRORE GLOBALE: $e");
      if (kDebugMode) {
        debugPrint("Stack trace: $stack");
      }
      return null;
    }
  }

  Future<void> _processUserData(User user) async {
    try {
      debugPrint("💾 Salvataggio dati utente in Firestore...");
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', user.uid);

      final userDoc = _firestore.collection('utenti').doc(user.uid);

      final userData = {
        'id': user.uid,
        'provider': 'google',
        'email': user.email,
        'nome': user.displayName ?? 'Utente senza nome',
        'foto_url': user.photoURL,
        'data_registrazione': FieldValue.serverTimestamp(),
        'ultimo_accesso': FieldValue.serverTimestamp(),
      };

      await userDoc.set(userData, SetOptions(merge: true));
      debugPrint('✅ Dati utente salvati correttamente');
    } catch (e, stack) {
      debugPrint('❌ Errore salvataggio dati utente: $e');
      if (kDebugMode) {
        debugPrint('Stack trace: $stack');
      }
    }
  }

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      debugPrint("🔒 Disconnessione in corso...");
      await _auth.signOut();
      await _googleSignIn.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_id');
      debugPrint("✅ Disconnessione completata");
    } catch (e, stack) {
      debugPrint("❌ Errore durante la disconnessione: $e");
      if (kDebugMode) {
        debugPrint("Stack trace: $stack");
      }
    }
  }

  // Metodo di debug semplificato
  void debugAuthConfiguration() {
    debugPrint("\n🔧 DEBUG CONFIGURAZIONE AUTH 🔧");
    debugPrint("Package name: com.company.talkinzone");
    debugPrint(
      "Web Client ID: 282305776445-rumrd5h2kb4mt7e8g6pdkfqpjmi2sk3l.apps.googleusercontent.com",
    );
    debugPrint("Firebase Project ID: talkinzone");
    debugPrint("ℹ️ Verifica manualmente SHA-1 in Firebase Console");
  }
}
