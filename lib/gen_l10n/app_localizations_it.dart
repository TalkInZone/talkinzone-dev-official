// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get relNow => 'adesso';

  @override
  String relMinutesAgo(int count) {
    return '$count min fa';
  }

  @override
  String relHoursAgo(int count) {
    return '$count h fa';
  }

  @override
  String get distVeryClose => 'vicinissimo';

  @override
  String get distClose => 'vicino';

  @override
  String get distInArea => 'nelle vicinanze';

  @override
  String get distFar => 'lontano';

  @override
  String get distVeryFar => 'molto lontano';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'Reazioni';

  @override
  String get close => 'Chiudi';

  @override
  String get you => 'Tu';

  @override
  String get anonymous => 'Anonimo';

  @override
  String get tooltipSettings => 'Impostazioni';

  @override
  String get tooltipFilters => 'Filtri';

  @override
  String get tooltipRadius => 'Raggio';

  @override
  String get tooltipProfile => 'Profilo';

  @override
  String get tooltipReactions => 'Aggiungi reazione';

  @override
  String get noMessagesInArea => 'Ancora nessun messaggio in questa zona.';

  @override
  String get newLabel => 'NUOVO';

  @override
  String get composerHint => 'Scrivi un breve messaggio (opzionale)…';

  @override
  String get welcomeTitle => 'Benvenuto!';

  @override
  String get welcomeBody =>
      'Lascia brevi note vocali o testi alle persone vicino a te. I messaggi si autodistruggono dopo pochi minuti.';

  @override
  String get understood => 'Ho capito';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Devi essere autenticato per bloccare utenti.';

  @override
  String get cannotBlockYourself => 'Non puoi bloccare te stesso.';

  @override
  String get invalidUserIdToBlock => 'ID utente non valido.';

  @override
  String get blockIgnoreTitle => 'Blocca utente';

  @override
  String get blockIgnoreTitleShort => 'Blocca utente';

  @override
  String get blockIgnoreSubtitle =>
      'Non vedrai più i messaggi di questo utente.';

  @override
  String blockConfirmText(String name) {
    return 'Bloccare $name? Non vedrai più i suoi messaggi.';
  }

  @override
  String get cancel => 'Annulla';

  @override
  String get block => 'Blocca';

  @override
  String get userBlockedSimple => 'Utente bloccato.';

  @override
  String get blockError => 'Impossibile bloccare l’utente';

  @override
  String get reportUserTitle => 'Segnala utente';

  @override
  String get reportUserTitleShort => 'Segnala utente';

  @override
  String get reportUserSubtitle => 'Invia una segnalazione ai moderatori.';

  @override
  String get reportDescribeOptional => 'Descrivi il problema (opzionale)';

  @override
  String get reportReasonHint => 'Motivo…';

  @override
  String get send => 'Invia';

  @override
  String get reportSentThanks => 'Grazie, la tua segnalazione è stata inviata.';

  @override
  String get reportNotSent => 'Segnalazione non inviata';

  @override
  String get cannotReportYourself => 'Non puoi segnalare te stesso.';

  @override
  String get operationNotAllowed => 'Operazione non consentita.';
}
