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
  String get welcomeSubtitle =>
      'Per iniziare, accedi con il tuo account Google';

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
  String get blockError => 'Impossibile bloccare l\'utente';

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

  @override
  String get loginFailed => 'Accesso fallito. Riprova.';

  @override
  String get signInWithGoogle => 'Accedi dengan Google';

  @override
  String get customCategoryWarning =>
      'Imposta il nome della categoria personalizzata nelle Impostazioni.';

  @override
  String get invalidOperation => 'Operazione non valida.';

  @override
  String get userBlocked => 'Utente bloccato.';

  @override
  String get yourAccount => 'Il tuo account';

  @override
  String get userId => 'ID utente:';

  @override
  String get noId => 'Nessun ID';

  @override
  String get name => 'Nome:';

  @override
  String get noName => 'Nessun nome';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'Nessuna email';

  @override
  String get provider => 'Provider:';

  @override
  String get logout => 'Esci';

  @override
  String get ageGateTitle => 'Completa il profilo';

  @override
  String ageGateSubtitle(int years) {
    return 'Per continuare ad usare TalkInZone devi indicare la tua data di nascita (età minima: $years anni).';
  }

  @override
  String get birthDate => 'Data di nascita';

  @override
  String get selectDate => 'Seleziona una data';

  @override
  String get selectBirthDate => 'Seleziona la tua data di nascita';

  @override
  String get truthDeclaration => 'Dichiaro che i dati forniti sono veritieri.';

  @override
  String get falseWarning =>
      'Attenzione: dichiarazioni false possono comportare la sospensione dell\'account.';

  @override
  String get confirmAndContinue => 'Conferma e continua';

  @override
  String get missingDate => 'Seleziona una data di nascita.';

  @override
  String tooYoung(int years) {
    return 'Per usare l\'app devi avere almeno $years anni.';
  }

  @override
  String get mustAccept => 'Devi confermare che i dati forniti sono veritieri.';

  @override
  String get genericError => 'Si è verificato un errore. Riprova.';

  @override
  String maxCharsError(int count) {
    return 'Max $count caratteri';
  }

  @override
  String get blockUser => 'Blocca utente';

  @override
  String get blockUserConfirmation =>
      'Vuoi davvero bloccare questo utente?\n\n• Non vedrai più nessun suo messaggio\n• Lui non vedrà più nessun tuo messaggio';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get themeLabel => 'Tema';

  @override
  String get languageLabel => 'Lingua';

  @override
  String get notificationsLabel => 'Notifiche';

  @override
  String get gpsManagement => 'Gestione GPS';

  @override
  String get customCategory => 'Categoria personalizzata';

  @override
  String get blockedUsers => 'Utenti bloccati';

  @override
  String get appVersion => 'Versione App';

  @override
  String get enableNotifications => 'Abilita notifiche';

  @override
  String get notificationSound => 'Suono di notifica';

  @override
  String get backgroundExecution => 'Esecuzione in background';

  @override
  String get enableLocation => 'Abilita accesso alla posizione';

  @override
  String get customCategoryName => 'Nome categoria personalizzata';

  @override
  String get noBlockedUsers => 'Nessun utente bloccato';

  @override
  String get unblock => 'Sblocca';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get greyTheme => 'Grey';

  @override
  String get greyThemeDescription => 'Palette neutra in chiaro/scuro';

  @override
  String get english => 'English';

  @override
  String get italian => 'Italiano';

  @override
  String get german => 'Deutsch';

  @override
  String get spanish => 'Español';

  @override
  String get french => 'Français';

  @override
  String get ukrainian => 'Українська';

  @override
  String get russian => 'Русский';

  @override
  String get portuguese => 'Português';

  @override
  String get arabic => 'العربية';

  @override
  String get chinese => '中文';

  @override
  String get japanese => '日本語';

  @override
  String get authorizationGranted => 'Autorizzazione concessa';

  @override
  String get requestAuthorization => 'Richiedi autorizzazione';

  @override
  String get notificationSoundDescription =>
      'Riproduci un suono quando arriva un nuovo messaggio';

  @override
  String get batteryOptimizationDisabled =>
      'Ottimizzazione batteria disattivata';

  @override
  String get batteryOptimizationWarning =>
      'L\'app potrebbe non ricevere notifiche in background';

  @override
  String get locationAccessEnabled => 'Accesso alla posizione abilitado';

  @override
  String get requestGpsAuthorization => 'Richiedi autorizzazione GPS';

  @override
  String get noCategorySet => 'Nessuna — tocca per impostare';

  @override
  String get activeCategory => 'Attiva';

  @override
  String get remove => 'Rimuovi';

  @override
  String get edit => 'Modifica';

  @override
  String get customCategoryDialogTitle => 'Categoria personalizzata';

  @override
  String get customCategoryDialogDescription =>
      'Imposta il nome della tua categoria personalizzata. Solo i messaggi con esattamente lo stesso nome saranno visibili nei filtri.';

  @override
  String get customCategoryHint => 'Es. \"Runner Milano Nord\"';

  @override
  String get nameCannotBeEmpty => 'Il nome non può essere vuoto';

  @override
  String get customCategoryDisabled => 'Categoria personalizzata disattivata';

  @override
  String get customCategorySet => 'Categoria personalizzata impostata';

  @override
  String get permissionRequired => 'Autorizzazione richiesta';

  @override
  String get notificationPermissionMessage =>
      'Per ricevere notifiche, abilita i permessi nelle impostazioni di sistema.';

  @override
  String get locationPermissionRequired => 'Permesso posizione richiesto';

  @override
  String get locationPermissionMessage =>
      'Per abilitare le funzionalità GPS, consenti l\'accesso alla posizione nelle impostazioni.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'IMPOSTAZIONI';

  @override
  String get save => 'Salva';

  @override
  String get category_free => 'Libero';

  @override
  String get category_warning => 'Warning';

  @override
  String get category_help => 'Aiuto';

  @override
  String get category_events => 'Eventi';

  @override
  String get category_notice => 'Avviso';

  @override
  String get category_info => 'Info';

  @override
  String get category_custom => 'Personalizzata';
}
