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
  String get welcomeBody =>
      'Leave quick voice notes or short texts to people nearby. Messages auto-delete after a few minutes.';

  @override
  String get understood => 'Got it';

  @override
  String get mustBeAuthenticatedToBlock =>
      'You must be signed in to block users.';

  @override
  String get cannotBlockYourself => 'You can’t block yourself.';

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
    return 'Block $name? You won’t see their messages anymore.';
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
  String get cannotReportYourself => 'You can’t report yourself.';

  @override
  String get operationNotAllowed => 'Operation not allowed.';
}
