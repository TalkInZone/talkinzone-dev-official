// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get relNow => 'now';

  @override
  String relMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String relHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String get distVeryClose => 'very close';

  @override
  String get distClose => 'close';

  @override
  String get distInArea => 'in your area';

  @override
  String get distFar => 'far';

  @override
  String get distVeryFar => 'very far';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'Reactions';

  @override
  String get close => 'Close';

  @override
  String get you => 'You';

  @override
  String get anonymous => 'Anonymous';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipFilters => 'Filters';

  @override
  String get tooltipRadius => 'Radius';

  @override
  String get tooltipProfile => 'Profile';

  @override
  String get tooltipReactions => 'Add a reaction';

  @override
  String get noMessagesInArea => 'No messages in this area yet.';

  @override
  String get newLabel => 'NEW';

  @override
  String get composerHint => 'Write a short message (optional)…';

  @override
  String get welcomeTitle => 'Welcome!';

  @override
  String get welcomeSubtitle =>
      'To get started, sign in with your Google account';

  @override
  String get welcomeBody =>
      'Leave quick voice notes or short texts to people nearby. Messages auto-delete after a few minutes.';

  @override
  String get understood => 'Got it';

  @override
  String get mustBeAuthenticatedToBlock =>
      'You must be signed in to block users.';

  @override
  String get cannotBlockYourself => 'You can\'t block yourself.';

  @override
  String get invalidUserIdToBlock => 'Invalid user ID.';

  @override
  String get blockIgnoreTitle => 'Block user';

  @override
  String get blockIgnoreTitleShort => 'Block user';

  @override
  String get blockIgnoreSubtitle =>
      'You won\'t see messages from this user anymore.';

  @override
  String blockConfirmText(String name) {
    return 'Block $name? You won\'t see their messages anymore.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get block => 'Block';

  @override
  String get userBlockedSimple => 'User blocked.';

  @override
  String get blockError => 'Couldn\'t block user';

  @override
  String get reportUserTitle => 'Report user';

  @override
  String get reportUserTitleShort => 'Report user';

  @override
  String get reportUserSubtitle => 'Send a report to moderators.';

  @override
  String get reportDescribeOptional => 'Describe the problem (optional)';

  @override
  String get reportReasonHint => 'Reason…';

  @override
  String get send => 'Send';

  @override
  String get reportSentThanks => 'Thanks, your report was sent.';

  @override
  String get reportNotSent => 'Report not sent';

  @override
  String get cannotReportYourself => 'You can\'t report yourself.';

  @override
  String get operationNotAllowed => 'Operation not allowed.';

  @override
  String get loginFailed => 'Login failed. Try again.';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get customCategoryWarning =>
      'Set the name of the custom category in Settings.';

  @override
  String get invalidOperation => 'Invalid operation.';

  @override
  String get userBlocked => 'User blocked.';

  @override
  String get yourAccount => 'Your account';

  @override
  String get userId => 'User ID:';

  @override
  String get noId => 'No ID';

  @override
  String get name => 'Name:';

  @override
  String get noName => 'No name';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'No email';

  @override
  String get provider => 'Provider:';

  @override
  String get logout => 'Logout';

  @override
  String get ageGateTitle => 'Complete your profile';

  @override
  String ageGateSubtitle(int years) {
    return 'To continue using TalkInZone you must indicate your date of birth (minimum age: $years years).';
  }

  @override
  String get birthDate => 'Date of birth';

  @override
  String get selectDate => 'Select a date';

  @override
  String get selectBirthDate => 'Select your date of birth';

  @override
  String get truthDeclaration =>
      'I declare that the data provided is truthful.';

  @override
  String get falseWarning =>
      'Warning: false statements may result in account suspension.';

  @override
  String get confirmAndContinue => 'Confirm and continue';

  @override
  String get missingDate => 'Select a date of birth.';

  @override
  String tooYoung(int years) {
    return 'You must be at least $years years old to use the app.';
  }

  @override
  String get mustAccept =>
      'You must confirm that the data provided is truthful.';

  @override
  String get genericError => 'An error occurred. Please try again.';

  @override
  String maxCharsError(int count) {
    return 'Max $count characters';
  }

  @override
  String get blockUser => 'Block user';

  @override
  String get blockUserConfirmation =>
      'Do you really want to block this user?\n\n• You will no longer see any of their messages\n• They will no longer see any of your messages';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLabel => 'Theme';

  @override
  String get languageLabel => 'Language';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get gpsManagement => 'GPS Management';

  @override
  String get customCategory => 'Custom category';

  @override
  String get blockedUsers => 'Blocked users';

  @override
  String get appVersion => 'App Version';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get notificationSound => 'Notification sound';

  @override
  String get backgroundExecution => 'Background execution';

  @override
  String get enableLocation => 'Enable location access';

  @override
  String get customCategoryName => 'Custom category name';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get unblock => 'Unblock';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get greyTheme => 'Grey';

  @override
  String get greyThemeDescription => 'Neutral light/dark palette';

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
  String get authorizationGranted => 'Authorization granted';

  @override
  String get requestAuthorization => 'Request authorization';

  @override
  String get notificationSoundDescription =>
      'Play a sound when a new message arrives';

  @override
  String get batteryOptimizationDisabled => 'Battery optimization disabled';

  @override
  String get batteryOptimizationWarning =>
      'The app might not receive notifications in background';

  @override
  String get locationAccessEnabled => 'Location access enabled';

  @override
  String get requestGpsAuthorization => 'Request GPS authorization';

  @override
  String get noCategorySet => 'None — tap to set';

  @override
  String get activeCategory => 'Active';

  @override
  String get remove => 'Remove';

  @override
  String get edit => 'Edit';

  @override
  String get customCategoryDialogTitle => 'Custom category';

  @override
  String get customCategoryDialogDescription =>
      'Set the name of your custom category. Only messages with exactly the same name will be visible in filters.';

  @override
  String get customCategoryHint => 'Ex. \"Runner Milan North\"';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get customCategoryDisabled => 'Custom category disabled';

  @override
  String get customCategorySet => 'Custom category set';

  @override
  String get permissionRequired => 'Authorization required';

  @override
  String get notificationPermissionMessage =>
      'To receive notifications, enable permissions in system settings.';

  @override
  String get locationPermissionRequired => 'Location permission required';

  @override
  String get locationPermissionMessage =>
      'To enable GPS features, allow location access in settings.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'SETTINGS';

  @override
  String get save => 'Save';

  @override
  String get selectCategory => 'Select category:';

  @override
  String get filterByCategory => 'Filter messages by category:';

  @override
  String get category_free => 'Free';

  @override
  String get category_warning => 'Warning';

  @override
  String get category_help => 'Help';

  @override
  String get category_events => 'Events';

  @override
  String get category_notice => 'Notice';

  @override
  String get category_info => 'Info';

  @override
  String get category_custom => 'Custom';

  @override
  String get deleteConfirmTitle => 'Delete message?';

  @override
  String get deleteConfirmBody =>
      'This will permanently remove your message for everyone.';

  @override
  String get deleteMessage => 'Delete';

  @override
  String get deleted => 'Deleted';

  @override
  String get deleteError => 'Couldn\'t delete message';

  @override
  String get tooltipDelete => 'Delete';

  @override
  String get versionNoticeTitle => 'Version notice';

  @override
  String versionNoticeBody(String version) {
    return 'This is version $version and it is currently experimental. Enjoy using it and, if you like, leave feedback. If you encounter any issues or bugs, you can contact us at talkinzone@gmail.com.';
  }

  @override
  String get versionNoticeLinksIntro =>
      'To review our policies and child safety information, visit:';

  @override
  String get versionNoticeLink1Label => 'talkinzone-normative.vercel.app';

  @override
  String get versionNoticeLink1Url =>
      'https://talkinzone-normative.vercel.app/';

  @override
  String get versionNoticeLink2Label => 'Child safety standards';

  @override
  String get versionNoticeLink2Url =>
      'https://talkinzone-normative.vercel.app/standard_sicurezza_minori.html?lang=en';

  @override
  String get updateRequiredTitle => 'Update required';

  @override
  String get updateRequiredOutdated => 'The current app version is outdated.';

  @override
  String get updateRequiredInstruction =>
      'To continue using the app, download the latest version from the store.';

  @override
  String get updateRequiredCurrentVersion => 'Current version:';
}
