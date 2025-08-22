// lib/i18n_t.dart
//
// Wrapper "T" che espone le stringhe di AppLocalizations come METODI.
// Così puoi continuare a chiamare t.xxx() ovunque nel codice.
//
// Uso:
//   import 'gen_l10n/app_localizations.dart';
//   import 'i18n_t.dart';
//   final t = T(AppLocalizations.of(context));
//
// Esempi:
//   t.close()
//   t.relMinutesAgo(5)
//   t.blockConfirmText("Mario")

import 'gen_l10n/app_localizations.dart';

class T {
  final AppLocalizations _t;
  T(this._t);

  // ---- relative time ----
  String relNow() => _t.relNow;
  String relMinutesAgo(int count) => _t.relMinutesAgo(count);
  String relHoursAgo(int count) => _t.relHoursAgo(count);

  // ---- distanza ----
  String distVeryClose() => _t.distVeryClose;
  String distClose() => _t.distClose;
  String distInArea() => _t.distInArea;
  String distFar() => _t.distFar;
  String distVeryFar() => _t.distVeryFar;
  String unitM() => _t.unitM;
  String unitKm() => _t.unitKm;

  // ---- UI base / labels ----
  String reactionsTitle() => _t.reactionsTitle;
  String close() => _t.close;
  String you() => _t.you;
  String anonymous() => _t.anonymous;

  // ---- tooltips ----
  String tooltipSettings() => _t.tooltipSettings;
  String tooltipFilters() => _t.tooltipFilters;
  String tooltipRadius() => _t.tooltipRadius;
  String tooltipProfile() => _t.tooltipProfile;
  String tooltipReactions() => _t.tooltipReactions;

  // ---- liste/empty states ----
  String noMessagesInArea() => _t.noMessagesInArea;
  String newLabel() => _t.newLabel;

  // ---- composer ----
  String composerHint() => _t.composerHint;

  // ---- welcome overlay ----
  String welcomeTitle() => _t.welcomeTitle;
  String welcomeBody() => _t.welcomeBody;
  String understood() => _t.understood;

  // ---- block/report flows ----
  String mustBeAuthenticatedToBlock() => _t.mustBeAuthenticatedToBlock;
  String cannotBlockYourself() => _t.cannotBlockYourself;
  String invalidUserIdToBlock() => _t.invalidUserIdToBlock;
  String blockIgnoreTitle() => _t.blockIgnoreTitle;
  String blockIgnoreTitleShort() => _t.blockIgnoreTitleShort;
  String blockIgnoreSubtitle() => _t.blockIgnoreSubtitle;
  String cancel() => _t.cancel;
  String block() => _t.block;
  String userBlockedSimple() => _t.userBlockedSimple;
  String blockError() => _t.blockError;

  String reportUserTitle() => _t.reportUserTitle;
  String reportUserTitleShort() => _t.reportUserTitleShort;
  String reportUserSubtitle() => _t.reportUserSubtitle;
  String reportDescribeOptional() => _t.reportDescribeOptional;
  String reportReasonHint() => _t.reportReasonHint;
  String send() => _t.send;
  String reportSentThanks() => _t.reportSentThanks;
  String reportNotSent() => _t.reportNotSent;
  String cannotReportYourself() => _t.cannotReportYourself;
  String operationNotAllowed() => _t.operationNotAllowed;

  // con placeholder
  String blockConfirmText(String name) => _t.blockConfirmText(name);
}
