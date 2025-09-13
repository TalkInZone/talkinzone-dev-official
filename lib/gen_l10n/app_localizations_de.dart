// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get relNow => 'jetzt';

  @override
  String relMinutesAgo(int count) {
    return 'vor $count min';
  }

  @override
  String relHoursAgo(int count) {
    return 'vor $count h';
  }

  @override
  String get distVeryClose => 'sehr nah';

  @override
  String get distClose => 'nah';

  @override
  String get distInArea => 'in deiner Nähe';

  @override
  String get distFar => 'weit';

  @override
  String get distVeryFar => 'sehr weit';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'Reaktionen';

  @override
  String get close => 'Schließen';

  @override
  String get you => 'Du';

  @override
  String get anonymous => 'Anonym';

  @override
  String get tooltipSettings => 'Einstellungen';

  @override
  String get tooltipFilters => 'Filter';

  @override
  String get tooltipRadius => 'Radius';

  @override
  String get tooltipProfile => 'Profil';

  @override
  String get tooltipReactions => 'Reaktion hinzufügen';

  @override
  String get noMessagesInArea => 'Noch keine Nachrichten in dieser Gegend.';

  @override
  String get newLabel => 'NEU';

  @override
  String get composerHint => 'Kurze Nachricht schreiben (optional)…';

  @override
  String get welcomeTitle => 'Willkommen!';

  @override
  String get welcomeSubtitle =>
      'Um zu beginnen, melde dich mit deinem Google-Konto an';

  @override
  String get welcomeBody =>
      'Hinterlasse kurze Sprachnachrichten oder Texte für Menschen in deiner Nähe. Nachrichten löschen sich nach wenigen Minuten automatisch.';

  @override
  String get understood => 'Verstanden';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Du musst angemeldet sein, um Benutzer zu blockieren.';

  @override
  String get cannotBlockYourself => 'Du kannst dich nicht selbst blockieren.';

  @override
  String get invalidUserIdToBlock => 'Ungültige Benutzer-ID.';

  @override
  String get blockIgnoreTitle => 'Benutzer blockieren';

  @override
  String get blockIgnoreTitleShort => 'Benutzer blockieren';

  @override
  String get blockIgnoreSubtitle =>
      'Du wirst keine Nachrichten mehr von diesem Benutzer sehen.';

  @override
  String blockConfirmText(String name) {
    return '$name blockieren? Du wirst ihre/seine Nachrichten nicht mehr sehen.';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get block => 'Blockieren';

  @override
  String get userBlockedSimple => 'Benutzer blockiert.';

  @override
  String get blockError => 'Benutzer konnte nicht blockiert werden';

  @override
  String get reportUserTitle => 'Benutzer melden';

  @override
  String get reportUserTitleShort => 'Benutzer melden';

  @override
  String get reportUserSubtitle => 'Sende einen Bericht an die Moderatoren.';

  @override
  String get reportDescribeOptional => 'Problem beschreiben (optional)';

  @override
  String get reportReasonHint => 'Grund…';

  @override
  String get send => 'Senden';

  @override
  String get reportSentThanks => 'Danke, dein Bericht wurde gesendet.';

  @override
  String get reportNotSent => 'Bericht nicht gesendet';

  @override
  String get cannotReportYourself => 'Du kannst dich nicht selbst melden.';

  @override
  String get operationNotAllowed => 'Operation nicht erlaubt.';

  @override
  String get loginFailed =>
      'Anmeldung fehlgeschlagen. Bitte versuche es erneut.';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get customCategoryWarning =>
      'Lege den Namen der benutzerdefinierten Kategorie in den Einstellungen fest.';

  @override
  String get invalidOperation => 'Ungültige Operation.';

  @override
  String get userBlocked => 'Benutzer blockiert.';

  @override
  String get yourAccount => 'Dein Konto';

  @override
  String get userId => 'Benutzer-ID:';

  @override
  String get noId => 'Keine ID';

  @override
  String get name => 'Name:';

  @override
  String get noName => 'Kein Name';

  @override
  String get email => 'E-Mail:';

  @override
  String get noEmail => 'Keine E-Mail';

  @override
  String get provider => 'Anbieter:';

  @override
  String get logout => 'Abmelden';

  @override
  String get ageGateTitle => 'Vervollständige dein Profil';

  @override
  String ageGateSubtitle(int years) {
    return 'Um TalkInZone weiter zu nutzen, musst du dein Geburtsdatum angeben (Mindestalter: $years Jahre).';
  }

  @override
  String get birthDate => 'Geburtsdatum';

  @override
  String get selectDate => 'Datum auswählen';

  @override
  String get selectBirthDate => 'Wähle dein Geburtsdatum';

  @override
  String get truthDeclaration =>
      'Ich erkläre, dass die angegebenen Daten wahrheitsgemäß sind.';

  @override
  String get falseWarning =>
      'Warnung: Falsche Angaben können zur Sperrung des Kontos führen.';

  @override
  String get confirmAndContinue => 'Bestätigen und fortfahren';

  @override
  String get missingDate => 'Bitte wähle ein Geburtsdatum aus.';

  @override
  String tooYoung(int years) {
    return 'Du musst mindestens $years Jahre alt sein, um die App zu nutzen.';
  }

  @override
  String get mustAccept =>
      'Du musst bestätigen, dass die angegebenen Daten wahrheitsgemäß sind.';

  @override
  String get genericError =>
      'Ein Fehler ist aufgetreten. Bitte versuche es erneut.';

  @override
  String maxCharsError(int count) {
    return 'Max. $count Zeichen';
  }

  @override
  String get blockUser => 'Benutzer blockieren';

  @override
  String get blockUserConfirmation =>
      'Möchtest du diesen Benutzer wirklich blockieren?\n\n• Du wirst keine seiner/ihrer Nachrichten mehr sehen\n• Er/sie wird keine deiner Nachrichten mehr sehen';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get themeLabel => 'Thema';

  @override
  String get languageLabel => 'Sprache';

  @override
  String get notificationsLabel => 'Benachrichtigungen';

  @override
  String get gpsManagement => 'GPS-Verwaltung';

  @override
  String get customCategory => 'Benutzerdefinierte Kategorie';

  @override
  String get blockedUsers => 'Blockierte Benutzer';

  @override
  String get appVersion => 'App-Version';

  @override
  String get enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get notificationSound => 'Benachrichtigungston';

  @override
  String get backgroundExecution => 'Hintergrundausführung';

  @override
  String get enableLocation => 'Standortzugriff aktivieren';

  @override
  String get customCategoryName => 'Name der benutzerdefinierten Kategorie';

  @override
  String get noBlockedUsers => 'Keine blockierten Benutzer';

  @override
  String get unblock => 'Entblocken';

  @override
  String get lightTheme => 'Hell';

  @override
  String get darkTheme => 'Dunkel';

  @override
  String get greyTheme => 'Grau';

  @override
  String get greyThemeDescription => 'Neutrale Hell/Dunkel-Palette';

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
  String get authorizationGranted => 'Berechtigung erteilt';

  @override
  String get requestAuthorization => 'Berechtigung anfordern';

  @override
  String get notificationSoundDescription =>
      'Einen Ton bei neuen Nachrichten abspielen';

  @override
  String get batteryOptimizationDisabled => 'Batterieoptimierung deaktiviert';

  @override
  String get batteryOptimizationWarning =>
      'Die App erhält möglicherweise keine Benachrichtigungen im Hintergrund';

  @override
  String get locationAccessEnabled => 'Standortzugriff aktiviert';

  @override
  String get requestGpsAuthorization => 'GPS-Berechtigung anfordern';

  @override
  String get noCategorySet => 'Keine — tippen zum Festlegen';

  @override
  String get activeCategory => 'Aktiv';

  @override
  String get remove => 'Entfernen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get customCategoryDialogTitle => 'Benutzerdefinierte Kategorie';

  @override
  String get customCategoryDialogDescription =>
      'Lege den Namen deiner benutzerdefinierten Kategorie fest. Nur Nachrichten mit genau demselben Namen werden in Filtern sichtbar sein.';

  @override
  String get customCategoryHint => 'z.B. \"Läufer München Nord\"';

  @override
  String get nameCannotBeEmpty => 'Name darf nicht leer sein';

  @override
  String get customCategoryDisabled =>
      'Benutzerdefinierte Kategorie deaktiviert';

  @override
  String get customCategorySet => 'Benutzerdefinierte Kategorie festgelegt';

  @override
  String get permissionRequired => 'Berechtigung erforderlich';

  @override
  String get notificationPermissionMessage =>
      'Um Benachrichtigungen zu erhalten, aktiviere die Berechtigungen in den Systemeinstellungen.';

  @override
  String get locationPermissionRequired => 'Standortberechtigung erforderlich';

  @override
  String get locationPermissionMessage =>
      'Um GPS-Funktionen zu aktivieren, erlaube den Standortzugriff in den Einstellungen.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'EINSTELLUNGEN';

  @override
  String get save => 'Speichern';

  @override
  String get selectCategory => 'Kategorie auswählen:';

  @override
  String get filterByCategory => 'Nachrichten nach Kategorie filtern:';

  @override
  String get category_free => 'Frei';

  @override
  String get category_warning => 'Warnung';

  @override
  String get category_help => 'Hilfe';

  @override
  String get category_events => 'Veranstaltungen';

  @override
  String get category_notice => 'Hinweis';

  @override
  String get category_info => 'Info';

  @override
  String get category_custom => 'Benutzerdefiniert';

  @override
  String get deleteConfirmTitle => 'Nachricht löschen?';

  @override
  String get deleteConfirmBody =>
      'Dies wird Ihre Nachricht dauerhaft für alle entfernen.';

  @override
  String get deleteMessage => 'Löschen';

  @override
  String get deleted => 'Gelöscht';

  @override
  String get deleteError => 'Nachricht konnte nicht gelöscht werden';

  @override
  String get tooltipDelete => 'Löschen';

  @override
  String get versionNoticeTitle => 'Versionshinweis';

  @override
  String versionNoticeBody(String version) {
    return 'Dies ist Version $version und sie ist derzeit experimentell. Viel Spaß bei der Nutzung und hinterlasse gern Feedback. Wenn du Probleme oder Bugs findest, kannst du uns unter talkinzone@gmail.com kontaktieren.';
  }

  @override
  String get versionNoticeLinksIntro =>
      'Unsere Richtlinien und Informationen zum Kinderschutz findest du hier:';

  @override
  String get versionNoticeLink1Label => 'talkinzone-normative.vercel.app';

  @override
  String get versionNoticeLink1Url =>
      'https://talkinzone-normative.vercel.app/';

  @override
  String get versionNoticeLink2Label => 'Kinderschutz-Standards';

  @override
  String get versionNoticeLink2Url =>
      'https://talkinzone-normative.vercel.app/standard_sicurezza_minori.html?lang=de';

  @override
  String get updateRequiredTitle => 'Aktualisierung erforderlich';

  @override
  String get updateRequiredOutdated => 'Die aktuelle App-Version ist veraltet.';

  @override
  String get updateRequiredInstruction =>
      'Um die App weiter zu verwenden, lade die neueste Version aus dem Store herunter.';

  @override
  String get updateRequiredCurrentVersion => 'Aktuelle Version:';
}
