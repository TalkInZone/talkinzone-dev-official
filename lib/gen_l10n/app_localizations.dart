import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uk.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('ja'),
    Locale('pt'),
    Locale('ru'),
    Locale('uk'),
    Locale('zh')
  ];

  /// No description provided for @relNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get relNow;

  /// No description provided for @relMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String relMinutesAgo(int count);

  /// No description provided for @relHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String relHoursAgo(int count);

  /// No description provided for @distVeryClose.
  ///
  /// In en, this message translates to:
  /// **'very close'**
  String get distVeryClose;

  /// No description provided for @distClose.
  ///
  /// In en, this message translates to:
  /// **'close'**
  String get distClose;

  /// No description provided for @distInArea.
  ///
  /// In en, this message translates to:
  /// **'in your area'**
  String get distInArea;

  /// No description provided for @distFar.
  ///
  /// In en, this message translates to:
  /// **'far'**
  String get distFar;

  /// No description provided for @distVeryFar.
  ///
  /// In en, this message translates to:
  /// **'very far'**
  String get distVeryFar;

  /// No description provided for @unitM.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get unitM;

  /// No description provided for @unitKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get unitKm;

  /// No description provided for @reactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reactions'**
  String get reactionsTitle;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @anonymous.
  ///
  /// In en, this message translates to:
  /// **'Anonymous'**
  String get anonymous;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get tooltipFilters;

  /// No description provided for @tooltipRadius.
  ///
  /// In en, this message translates to:
  /// **'Radius'**
  String get tooltipRadius;

  /// No description provided for @tooltipProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get tooltipProfile;

  /// No description provided for @tooltipReactions.
  ///
  /// In en, this message translates to:
  /// **'Add a reaction'**
  String get tooltipReactions;

  /// No description provided for @noMessagesInArea.
  ///
  /// In en, this message translates to:
  /// **'No messages in this area yet.'**
  String get noMessagesInArea;

  /// No description provided for @newLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get newLabel;

  /// No description provided for @composerHint.
  ///
  /// In en, this message translates to:
  /// **'Write a short message (optional)…'**
  String get composerHint;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To get started, sign in with your Google account'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Leave quick voice notes or short texts to people nearby. Messages auto-delete after a few minutes.'**
  String get welcomeBody;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get understood;

  /// No description provided for @mustBeAuthenticatedToBlock.
  ///
  /// In en, this message translates to:
  /// **'You must be signed in to block users.'**
  String get mustBeAuthenticatedToBlock;

  /// No description provided for @cannotBlockYourself.
  ///
  /// In en, this message translates to:
  /// **'You can\'t block yourself.'**
  String get cannotBlockYourself;

  /// No description provided for @invalidUserIdToBlock.
  ///
  /// In en, this message translates to:
  /// **'Invalid user ID.'**
  String get invalidUserIdToBlock;

  /// No description provided for @blockIgnoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockIgnoreTitle;

  /// No description provided for @blockIgnoreTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockIgnoreTitleShort;

  /// No description provided for @blockIgnoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see messages from this user anymore.'**
  String get blockIgnoreSubtitle;

  /// No description provided for @blockConfirmText.
  ///
  /// In en, this message translates to:
  /// **'Block {name}? You won\'t see their messages anymore.'**
  String blockConfirmText(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @userBlockedSimple.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlockedSimple;

  /// No description provided for @blockError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t block user'**
  String get blockError;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUserTitle;

  /// No description provided for @reportUserTitleShort.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get reportUserTitleShort;

  /// No description provided for @reportUserSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send a report to moderators.'**
  String get reportUserSubtitle;

  /// No description provided for @reportDescribeOptional.
  ///
  /// In en, this message translates to:
  /// **'Describe the problem (optional)'**
  String get reportDescribeOptional;

  /// No description provided for @reportReasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason…'**
  String get reportReasonHint;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @reportSentThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks, your report was sent.'**
  String get reportSentThanks;

  /// No description provided for @reportNotSent.
  ///
  /// In en, this message translates to:
  /// **'Report not sent'**
  String get reportNotSent;

  /// No description provided for @cannotReportYourself.
  ///
  /// In en, this message translates to:
  /// **'You can\'t report yourself.'**
  String get cannotReportYourself;

  /// No description provided for @operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Operation not allowed.'**
  String get operationNotAllowed;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Try again.'**
  String get loginFailed;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @customCategoryWarning.
  ///
  /// In en, this message translates to:
  /// **'Set the name of the custom category in Settings.'**
  String get customCategoryWarning;

  /// No description provided for @invalidOperation.
  ///
  /// In en, this message translates to:
  /// **'Invalid operation.'**
  String get invalidOperation;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.'**
  String get userBlocked;

  /// No description provided for @yourAccount.
  ///
  /// In en, this message translates to:
  /// **'Your account'**
  String get yourAccount;

  /// No description provided for @userId.
  ///
  /// In en, this message translates to:
  /// **'User ID:'**
  String get userId;

  /// No description provided for @noId.
  ///
  /// In en, this message translates to:
  /// **'No ID'**
  String get noId;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name:'**
  String get name;

  /// No description provided for @noName.
  ///
  /// In en, this message translates to:
  /// **'No name'**
  String get noName;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email:'**
  String get email;

  /// No description provided for @noEmail.
  ///
  /// In en, this message translates to:
  /// **'No email'**
  String get noEmail;

  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider:'**
  String get provider;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @ageGateTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get ageGateTitle;

  /// No description provided for @ageGateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'To continue using TalkInZone you must indicate your date of birth (minimum age: {years} years).'**
  String ageGateSubtitle(int years);

  /// No description provided for @birthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDate;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDate;

  /// No description provided for @selectBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Select your date of birth'**
  String get selectBirthDate;

  /// No description provided for @truthDeclaration.
  ///
  /// In en, this message translates to:
  /// **'I declare that the data provided is truthful.'**
  String get truthDeclaration;

  /// No description provided for @falseWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning: false statements may result in account suspension.'**
  String get falseWarning;

  /// No description provided for @confirmAndContinue.
  ///
  /// In en, this message translates to:
  /// **'Confirm and continue'**
  String get confirmAndContinue;

  /// No description provided for @missingDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date of birth.'**
  String get missingDate;

  /// No description provided for @tooYoung.
  ///
  /// In en, this message translates to:
  /// **'You must be at least {years} years old to use the app.'**
  String tooYoung(int years);

  /// No description provided for @mustAccept.
  ///
  /// In en, this message translates to:
  /// **'You must confirm that the data provided is truthful.'**
  String get mustAccept;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get genericError;

  /// No description provided for @maxCharsError.
  ///
  /// In en, this message translates to:
  /// **'Max {count} characters'**
  String maxCharsError(int count);

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUser;

  /// No description provided for @blockUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you really want to block this user?\n\n• You will no longer see any of their messages\n• They will no longer see any of your messages'**
  String get blockUserConfirmation;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeLabel.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get themeLabel;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @gpsManagement.
  ///
  /// In en, this message translates to:
  /// **'GPS Management'**
  String get gpsManagement;

  /// No description provided for @customCategory.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get customCategory;

  /// No description provided for @blockedUsers.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsers;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get appVersion;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @notificationSound.
  ///
  /// In en, this message translates to:
  /// **'Notification sound'**
  String get notificationSound;

  /// No description provided for @backgroundExecution.
  ///
  /// In en, this message translates to:
  /// **'Background execution'**
  String get backgroundExecution;

  /// No description provided for @enableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable location access'**
  String get enableLocation;

  /// No description provided for @customCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Custom category name'**
  String get customCategoryName;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @greyTheme.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get greyTheme;

  /// No description provided for @greyThemeDescription.
  ///
  /// In en, this message translates to:
  /// **'Neutral light/dark palette'**
  String get greyThemeDescription;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italiano'**
  String get italian;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get german;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get spanish;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @ukrainian.
  ///
  /// In en, this message translates to:
  /// **'Українська'**
  String get ukrainian;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Português'**
  String get portuguese;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get chinese;

  /// No description provided for @japanese.
  ///
  /// In en, this message translates to:
  /// **'日本語'**
  String get japanese;

  /// No description provided for @authorizationGranted.
  ///
  /// In en, this message translates to:
  /// **'Authorization granted'**
  String get authorizationGranted;

  /// No description provided for @requestAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Request authorization'**
  String get requestAuthorization;

  /// No description provided for @notificationSoundDescription.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when a new message arrives'**
  String get notificationSoundDescription;

  /// No description provided for @batteryOptimizationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization disabled'**
  String get batteryOptimizationDisabled;

  /// No description provided for @batteryOptimizationWarning.
  ///
  /// In en, this message translates to:
  /// **'The app might not receive notifications in background'**
  String get batteryOptimizationWarning;

  /// No description provided for @locationAccessEnabled.
  ///
  /// In en, this message translates to:
  /// **'Location access enabled'**
  String get locationAccessEnabled;

  /// No description provided for @requestGpsAuthorization.
  ///
  /// In en, this message translates to:
  /// **'Request GPS authorization'**
  String get requestGpsAuthorization;

  /// No description provided for @noCategorySet.
  ///
  /// In en, this message translates to:
  /// **'None — tap to set'**
  String get noCategorySet;

  /// No description provided for @activeCategory.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeCategory;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @customCategoryDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom category'**
  String get customCategoryDialogTitle;

  /// No description provided for @customCategoryDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'Set the name of your custom category. Only messages with exactly the same name will be visible in filters.'**
  String get customCategoryDialogDescription;

  /// No description provided for @customCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Ex. \"Runner Milan North\"'**
  String get customCategoryHint;

  /// No description provided for @nameCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get nameCannotBeEmpty;

  /// No description provided for @customCategoryDisabled.
  ///
  /// In en, this message translates to:
  /// **'Custom category disabled'**
  String get customCategoryDisabled;

  /// No description provided for @customCategorySet.
  ///
  /// In en, this message translates to:
  /// **'Custom category set'**
  String get customCategorySet;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Authorization required'**
  String get permissionRequired;

  /// No description provided for @notificationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'To receive notifications, enable permissions in system settings.'**
  String get notificationPermissionMessage;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionRequired;

  /// No description provided for @locationPermissionMessage.
  ///
  /// In en, this message translates to:
  /// **'To enable GPS features, allow location access in settings.'**
  String get locationPermissionMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settings;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @category_free.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get category_free;

  /// No description provided for @category_warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get category_warning;

  /// No description provided for @category_help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get category_help;

  /// No description provided for @category_events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get category_events;

  /// No description provided for @category_notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get category_notice;

  /// No description provided for @category_info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get category_info;

  /// No description provided for @category_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get category_custom;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'it',
        'ja',
        'pt',
        'ru',
        'uk',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'uk':
      return AppLocalizationsUk();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
