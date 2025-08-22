//modulo lettura data nascita

// lib/dob_flow.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Repository per leggere/scrivere la DOB nel documento /utenti/{uid}
class DobRepository {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Normalizza una data locale a mezzanotte UTC (evita problemi di timezone).
  static DateTime normalizeToUtcDay(DateTime localDay) =>
      DateTime.utc(localDay.year, localDay.month, localDay.day);

  /// Salva SOLO `data_di_nascita` su /utenti/{uid} come Timestamp (merge).
  /// Rispetta le regole: niente chiavi extra, valore non nel futuro.
  static Future<void> setDob(DateTime localDay) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('Utente non autenticato');

    final dobUtc = normalizeToUtcDay(localDay);

    // Coerente con regola: deve essere <= request.time
    final now = DateTime.now().toUtc();
    if (dobUtc.isAfter(now)) {
      throw ArgumentError('La data di nascita non può essere nel futuro.');
    }

    final docRef = _db.collection('utenti').doc(uid);

    await docRef.set(
      {
        'data_di_nascita': Timestamp.fromDate(dobUtc),
        // ⚠️ NON scrivere altri campi qui: le tue regole potrebbero rifiutare.
      },
      SetOptions(merge: true),
    );
  }

  /// Parser tollerante: Timestamp (preferito), int (epoch ms), stringa ISO.
  static DateTime? _parseDob(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) {
      return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: false);
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return null;
  }

  /// Carica la DOB da /utenti/{uid}
  static Future<DateTime?> getDob() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final snap = await _db.collection('utenti').doc(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return _parseDob(data['data_di_nascita']);
  }

  /// Calcolo età robusto (no off-by-one).
  static int calcAge(DateTime dob, [DateTime? now]) {
    final n = now ?? DateTime.now();
    int age = n.year - dob.year;
    final hadBirthday =
        (n.month > dob.month) || (n.month == dob.month && n.day >= dob.day);
    if (!hadBirthday) age--;
    return age;
  }

  /// True se utente ha almeno `minAge` anni.
  static Future<bool> isOldEnough(int minAge) async {
    final dob = await getDob();
    if (dob == null) return false;
    return calcAge(dob) >= minAge;
  }
}

/// Widget "gate": se manca la DOB o l’utente è sotto età, mostra la schermata di inserimento.
/// Altrimenti mostra `child`.
class DobGate extends StatefulWidget {
  final Widget child;
  final int minAge;
  final Widget? underAgeBuilder; // opzionale: schermata personalizzata

  const DobGate({
    super.key,
    required this.child,
    this.minAge = 14,
    this.underAgeBuilder,
  });

  @override
  State<DobGate> createState() => _DobGateState();
}

class _DobGateState extends State<DobGate> {
  late final Stream<User?> _authStream;

  @override
  void initState() {
    super.initState();
    _authStream = FirebaseAuth.instance.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _CenteredProgress();
        }
        if (user == null) {
          // Non autenticato: lascia che l’app gestisca il login altrove.
          return widget.child;
        }

        return FutureBuilder<DateTime?>(
          future: DobRepository.getDob(),
          builder: (context, dobSnap) {
            if (dobSnap.connectionState == ConnectionState.waiting) {
              return const _CenteredProgress();
            }
            final dob = dobSnap.data;

            if (dob == null) {
              // Chiedi DOB
              return DobScreen(
                minAge: widget.minAge,
                onSaved: () => setState(() {}),
              );
            }

            final age = DobRepository.calcAge(dob);
            if (age < widget.minAge) {
              return widget.underAgeBuilder ??
                  _UnderAgeScreen(
                    minAge: widget.minAge,
                    onSignOut: () => FirebaseAuth.instance.signOut(),
                  );
            }

            // OK
            return widget.child;
          },
        );
      },
    );
  }
}

class _CenteredProgress extends StatelessWidget {
  const _CenteredProgress();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Semplice schermata per inserire la data di nascita.
/// Salva su /utenti/{uid} il campo `data_di_nascita` come Timestamp (giorno UTC).
class DobScreen extends StatefulWidget {
  final int minAge;
  final VoidCallback? onSaved;

  const DobScreen({super.key, this.minAge = 14, this.onSaved});

  @override
  State<DobScreen> createState() => _DobScreenState();
}

class _DobScreenState extends State<DobScreen> {
  DateTime? _selected;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final earliest = DateTime(now.year - 120, now.month, now.day);
    final latest = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - widget.minAge, now.month, now.day),
      firstDate: earliest,
      lastDate: latest,
      helpText: 'Seleziona la tua data di nascita',
      cancelText: 'Annulla',
      confirmText: 'Conferma',
    );
    if (picked != null) {
      setState(() => _selected = picked);
    }
  }

  Future<void> _save() async {
    if (_selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una data.')),
      );
      return;
    }

    try {
      await DobRepository.setDob(_selected!);

      // (facoltativo) controlla lato client
      final age = DobRepository.calcAge(_selected!);
      if (age < widget.minAge && mounted) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Età non sufficiente'),
            content: Text(
              'Per usare l’app devi avere almeno ${widget.minAge} anni.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Ok'),
              ),
            ],
          ),
        );
      }

      if (mounted) widget.onSaved?.call();
    } on FirebaseException catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore salvataggio: ${e.code}')),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dobStr = _selected == null
        ? 'Nessuna'
        : '${_selected!.day.toString().padLeft(2, '0')}/'
            '${_selected!.month.toString().padLeft(2, '0')}/'
            '${_selected!.year}';

    return Scaffold(
      appBar: AppBar(title: const Text('Data di nascita')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.cake),
              title: const Text('Data selezionata'),
              subtitle: Text(dobStr),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Scegli'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _save,
                child: const Text('Conferma'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnderAgeScreen extends StatelessWidget {
  final int minAge;
  final VoidCallback onSignOut;

  const _UnderAgeScreen({
    required this.minAge,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accesso limitato')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Per usare l’app devi avere almeno $minAge anni.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Se hai selezionato la data sbagliata, esci e riprova dopo l’accesso.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
                label: const Text('Esci'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
