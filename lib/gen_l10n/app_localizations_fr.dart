// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get relNow => 'maintenant';

  @override
  String relMinutesAgo(int count) {
    return 'il y a $count min';
  }

  @override
  String relHoursAgo(int count) {
    return 'il y a $count h';
  }

  @override
  String get distVeryClose => 'très proche';

  @override
  String get distClose => 'proche';

  @override
  String get distInArea => 'dans votre zone';

  @override
  String get distFar => 'loin';

  @override
  String get distVeryFar => 'très loin';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'Réactions';

  @override
  String get close => 'Fermer';

  @override
  String get you => 'Vous';

  @override
  String get anonymous => 'Anonyme';

  @override
  String get tooltipSettings => 'Paramètres';

  @override
  String get tooltipFilters => 'Filtres';

  @override
  String get tooltipRadius => 'Rayon';

  @override
  String get tooltipProfile => 'Profil';

  @override
  String get tooltipReactions => 'Ajouter une réaction';

  @override
  String get noMessagesInArea =>
      'Aucun message dans cette zone pour le moment.';

  @override
  String get newLabel => 'NOUVEAU';

  @override
  String get composerHint => 'Écrivez un message court (optionnel)…';

  @override
  String get welcomeTitle => 'Bienvenue !';

  @override
  String get welcomeSubtitle =>
      'Pour commencer, connectez-vous avec votre compte Google';

  @override
  String get welcomeBody =>
      'Laissez des notes vocales ou des textes courts aux personnes à proximité. Les messages s\'autodétruisent après quelques minutes.';

  @override
  String get understood => 'Compris';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Vous devez être connecté pour bloquer des utilisateurs.';

  @override
  String get cannotBlockYourself =>
      'Vous ne pouvez pas vous bloquer vous-même.';

  @override
  String get invalidUserIdToBlock => 'ID utilisateur invalide.';

  @override
  String get blockIgnoreTitle => 'Bloquer l\'utilisateur';

  @override
  String get blockIgnoreTitleShort => 'Bloquer l\'utilisateur';

  @override
  String get blockIgnoreSubtitle =>
      'Vous ne verrez plus les messages de cet utilisateur.';

  @override
  String blockConfirmText(String name) {
    return 'Bloquer $name ? Vous ne verrez plus ses messages.';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get block => 'Bloquer';

  @override
  String get userBlockedSimple => 'Utilisateur bloqué.';

  @override
  String get blockError => 'Impossible de bloquer l\'utilisateur';

  @override
  String get reportUserTitle => 'Signaler l\'utilisateur';

  @override
  String get reportUserTitleShort => 'Signaler l\'utilisateur';

  @override
  String get reportUserSubtitle => 'Envoyer un rapport aux modérateurs.';

  @override
  String get reportDescribeOptional => 'Décrivez le problème (optionnel)';

  @override
  String get reportReasonHint => 'Raison…';

  @override
  String get send => 'Envoyer';

  @override
  String get reportSentThanks => 'Merci, votre rapport a été envoyé.';

  @override
  String get reportNotSent => 'Rapport non envoyé';

  @override
  String get cannotReportYourself =>
      'Vous ne pouvez pas vous signaler vous-même.';

  @override
  String get operationNotAllowed => 'Opération non autorisée.';

  @override
  String get loginFailed => 'Échec de la connexion. Réessayez.';

  @override
  String get signInWithGoogle => 'Se connecter avec Google';

  @override
  String get customCategoryWarning =>
      'Définissez le nom de la catégorie personnalisée dans Paramètres.';

  @override
  String get invalidOperation => 'Opération invalide.';

  @override
  String get userBlocked => 'Utilisateur bloqué.';

  @override
  String get yourAccount => 'Votre compte';

  @override
  String get userId => 'ID utilisateur :';

  @override
  String get noId => 'Aucun ID';

  @override
  String get name => 'Nom :';

  @override
  String get noName => 'Aucun nom';

  @override
  String get email => 'Email :';

  @override
  String get noEmail => 'Aucun email';

  @override
  String get provider => 'Fournisseur :';

  @override
  String get logout => 'Déconnexion';

  @override
  String get ageGateTitle => 'Complétez votre profil';

  @override
  String ageGateSubtitle(int years) {
    return 'Pour continuer à utiliser TalkInZone, vous devez indiquer votre date de naissance (âge minimum : $years ans).';
  }

  @override
  String get birthDate => 'Date de naissance';

  @override
  String get selectDate => 'Sélectionner une date';

  @override
  String get selectBirthDate => 'Sélectionnez votre date de naissance';

  @override
  String get truthDeclaration =>
      'Je déclare que les données fournies sont véridiques.';

  @override
  String get falseWarning =>
      'Attention : les déclarations fausses peuvent entraîner la suspension du compte.';

  @override
  String get confirmAndContinue => 'Confirmer et continuer';

  @override
  String get missingDate => 'Sélectionnez une date de naissance.';

  @override
  String tooYoung(int years) {
    return 'Vous devez avoir au moins $years ans pour utiliser l\'application.';
  }

  @override
  String get mustAccept =>
      'Vous devez confirmer que les données fournies sont véridiques.';

  @override
  String get genericError => 'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String maxCharsError(int count) {
    return 'Max $count caractères';
  }

  @override
  String get blockUser => 'Bloquer l\'utilisateur';

  @override
  String get blockUserConfirmation =>
      'Voulez-vous vraiment bloquer cet utilisateur ?\n\n• Vous ne verrez plus aucun de ses messages\n• Il/Elle ne verra plus aucun de vos messages';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get themeLabel => 'Thème';

  @override
  String get languageLabel => 'Langue';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get gpsManagement => 'Gestion GPS';

  @override
  String get customCategory => 'Catégorie personnalisée';

  @override
  String get blockedUsers => 'Utilisateurs bloqués';

  @override
  String get appVersion => 'Version de l\'application';

  @override
  String get enableNotifications => 'Activer les notifications';

  @override
  String get notificationSound => 'Son de notification';

  @override
  String get backgroundExecution => 'Exécution en arrière-plan';

  @override
  String get enableLocation => 'Activer l\'accès à la localisation';

  @override
  String get customCategoryName => 'Nom de la catégorie personnalisée';

  @override
  String get noBlockedUsers => 'Aucun utilisateur bloqué';

  @override
  String get unblock => 'Débloquer';

  @override
  String get lightTheme => 'Clair';

  @override
  String get darkTheme => 'Sombre';

  @override
  String get greyTheme => 'Gris';

  @override
  String get greyThemeDescription => 'Palette neutre clair/sombre';

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
  String get authorizationGranted => 'Autorisation accordée';

  @override
  String get requestAuthorization => 'Demander une autorisation';

  @override
  String get notificationSoundDescription =>
      'Jouer un son à l\'arrivée d\'un nouveau message';

  @override
  String get batteryOptimizationDisabled => 'Optimisation batterie désactivée';

  @override
  String get batteryOptimizationWarning =>
      'L\'application pourrait ne pas recevoir de notifications en arrière-plan';

  @override
  String get locationAccessEnabled => 'Accès à la localisation activé';

  @override
  String get requestGpsAuthorization => 'Demander l\'autorisation GPS';

  @override
  String get noCategorySet => 'Aucune — touchez pour définir';

  @override
  String get activeCategory => 'Active';

  @override
  String get remove => 'Supprimer';

  @override
  String get edit => 'Modifier';

  @override
  String get customCategoryDialogTitle => 'Catégorie personnalisée';

  @override
  String get customCategoryDialogDescription =>
      'Définissez le nom de votre catégorie personnalisée. Seuls les messages avec exactement le même nom seront visibles dans les filtres.';

  @override
  String get customCategoryHint => 'Ex. \"Coureur Paris Nord\"';

  @override
  String get nameCannotBeEmpty => 'Le nom ne peut pas être vide';

  @override
  String get customCategoryDisabled => 'Catégorie personnalisée désactivée';

  @override
  String get customCategorySet => 'Catégorie personnalisée définie';

  @override
  String get permissionRequired => 'Autorisation requise';

  @override
  String get notificationPermissionMessage =>
      'Pour recevoir des notifications, activez les permissions dans les paramètres système.';

  @override
  String get locationPermissionRequired => 'Permission de localisation requise';

  @override
  String get locationPermissionMessage =>
      'Pour activer les fonctionnalités GPS, autorisez l\'accès à la localisation dans les paramètres.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'PARAMÈTRES';

  @override
  String get save => 'Sauvegarder';

  @override
  String get selectCategory => 'Sélectionner la catégorie:';

  @override
  String get filterByCategory => 'Filtrer les messages par catégorie:';

  @override
  String get category_free => 'Libre';

  @override
  String get category_warning => 'Avertissement';

  @override
  String get category_help => 'Aide';

  @override
  String get category_events => 'Événements';

  @override
  String get category_notice => 'Avis';

  @override
  String get category_info => 'Info';

  @override
  String get category_custom => 'Personnalisée';

  @override
  String get deleteConfirmTitle => 'Supprimer le message ?';

  @override
  String get deleteConfirmBody =>
      'Cela supprimera définitivement votre message pour tout le monde.';

  @override
  String get deleteMessage => 'Supprimer';

  @override
  String get deleted => 'Supprimé';

  @override
  String get deleteError => 'Impossible de supprimer le message';

  @override
  String get tooltipDelete => 'Supprimer';

  @override
  String get versionNoticeTitle => 'Avis de version';

  @override
  String versionNoticeBody(String version) {
    return 'Ceci est la version $version et elle est actuellement expérimentale. Profitez-en et, si vous le souhaitez, laissez un commentaire. Si vous rencontrez des problèmes ou des bogues, vous pouvez nous contacter à l’adresse talkinzone@gmail.com.';
  }

  @override
  String get versionNoticeLinksIntro =>
      'Pour consulter les politiques et la sécurité des mineurs, visitez :';

  @override
  String get versionNoticeLink1Label => 'talkinzone-normative.vercel.app';

  @override
  String get versionNoticeLink1Url =>
      'https://talkinzone-normative.vercel.app/';

  @override
  String get versionNoticeLink2Label => 'Normes de sécurité des mineurs';

  @override
  String get versionNoticeLink2Url =>
      'https://talkinzone-normative.vercel.app/standard_sicurezza_minori.html?lang=fr';

  @override
  String get updateRequiredTitle => 'Mise à jour requise';

  @override
  String get updateRequiredOutdated =>
      'La version actuelle de l’application est obsolète.';

  @override
  String get updateRequiredInstruction =>
      'Pour continuer à utiliser l’app, téléchargez la dernière version depuis le store.';

  @override
  String get updateRequiredCurrentVersion => 'Version actuelle :';
}
