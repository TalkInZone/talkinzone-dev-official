// lib/i18n_compat.dart
//
// "Shim" per rendere invocabili con () i getter String di AppLocalizations.
// Esempio: t.close() -> chiama il getter `t.close` che è una String.
//
// Non servono import: estendiamo direttamente String.
// I metodi con parametri (es. relMinutesAgo(int)) continuano a funzionare
// normalmente perché sono già funzioni generate da gen_l10n.

extension CallableString on String {
  /// Permette di chiamare una String come se fosse una funzione senza argomenti.
  /// Utile per mantenere la compatibilità con codice che usa `t.key()`.
  String call() => this;
}
