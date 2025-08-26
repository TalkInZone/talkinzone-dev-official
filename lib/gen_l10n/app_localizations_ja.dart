// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get relNow => '今';

  @override
  String relMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String relHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String get distVeryClose => '非常に近い';

  @override
  String get distClose => '近い';

  @override
  String get distInArea => 'あなたのエリア内';

  @override
  String get distFar => '遠い';

  @override
  String get distVeryFar => '非常に遠い';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'リアクション';

  @override
  String get close => '閉じる';

  @override
  String get you => 'あなた';

  @override
  String get anonymous => '匿名';

  @override
  String get tooltipSettings => '設定';

  @override
  String get tooltipFilters => 'フィルター';

  @override
  String get tooltipRadius => '半径';

  @override
  String get tooltipProfile => 'プロフィール';

  @override
  String get tooltipReactions => 'リアクションを追加';

  @override
  String get noMessagesInArea => 'このエリアにはまだメッセージがありません。';

  @override
  String get newLabel => '新規';

  @override
  String get composerHint => '短いメッセージを書く（オプション）…';

  @override
  String get welcomeTitle => 'ようこそ！';

  @override
  String get welcomeSubtitle => '開始するには、Googleアカウントでサインインしてください';

  @override
  String get welcomeBody =>
      '近くの人にクイックな音声メモや短いテキストを残してください。メッセージは数分後に自動的に削除されます。';

  @override
  String get understood => 'わかりました';

  @override
  String get mustBeAuthenticatedToBlock => 'ユーザーをブロックするにはサインインする必要があります。';

  @override
  String get cannotBlockYourself => '自分自身をブロックすることはできません。';

  @override
  String get invalidUserIdToBlock => '無効なユーザーIDです。';

  @override
  String get blockIgnoreTitle => 'ユーザーをブロック';

  @override
  String get blockIgnoreTitleShort => 'ユーザーをブロック';

  @override
  String get blockIgnoreSubtitle => 'このユーザーのメッセージが表示されなくなります。';

  @override
  String blockConfirmText(String name) {
    return '$nameをブロックしますか？このユーザーのメッセージが表示されなくなります。';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get block => 'ブロック';

  @override
  String get userBlockedSimple => 'ユーザーをブロックしました。';

  @override
  String get blockError => 'ユーザーをブロックできませんでした';

  @override
  String get reportUserTitle => 'ユーザーを通報';

  @override
  String get reportUserTitleShort => 'ユーザーを通報';

  @override
  String get reportUserSubtitle => 'モデレーターに報告を送信します。';

  @override
  String get reportDescribeOptional => '問題を説明する（オプション）';

  @override
  String get reportReasonHint => '理由…';

  @override
  String get send => '送信';

  @override
  String get reportSentThanks => '報告を送信しました。ありがとうございます。';

  @override
  String get reportNotSent => '報告が送信されませんでした';

  @override
  String get cannotReportYourself => '自分自身を通報することはできません。';

  @override
  String get operationNotAllowed => '操作が許可されていません。';

  @override
  String get loginFailed => 'ログインに失敗しました。もう一度お試しください。';

  @override
  String get signInWithGoogle => 'Googleでサインイン';

  @override
  String get customCategoryWarning => '設定でカスタムカテゴリー名を設定してください。';

  @override
  String get invalidOperation => '無効な操作です。';

  @override
  String get userBlocked => 'ユーザーをブロックしました。';

  @override
  String get yourAccount => 'あなたのアカウント';

  @override
  String get userId => 'ユーザーID：';

  @override
  String get noId => 'IDなし';

  @override
  String get name => '名前：';

  @override
  String get noName => '名前なし';

  @override
  String get email => 'メール：';

  @override
  String get noEmail => 'メールなし';

  @override
  String get provider => 'プロバイダー：';

  @override
  String get logout => 'ログアウト';

  @override
  String get ageGateTitle => 'プロフィールを完成させる';

  @override
  String ageGateSubtitle(int years) {
    return 'TalkInZoneを引き続き使用するには、生年月日を入力する必要があります（最低年齢：$years歳）。';
  }

  @override
  String get birthDate => '生年月日';

  @override
  String get selectDate => '日付を選択';

  @override
  String get selectBirthDate => '生年月日を選択してください';

  @override
  String get truthDeclaration => '提供されたデータが真実であることを宣言します。';

  @override
  String get falseWarning => '警告：虚偽の申告はアカウントの停止につながる可能性があります。';

  @override
  String get confirmAndContinue => '確認して続行';

  @override
  String get missingDate => '生年月日を選択してください。';

  @override
  String tooYoung(int years) {
    return 'アプリを使用するには少なくとも$years歳である必要があります。';
  }

  @override
  String get mustAccept => '提供されたデータが真実であることを確認する必要があります。';

  @override
  String get genericError => 'エラーが発生しました。もう一度お試しください。';

  @override
  String maxCharsError(int count) {
    return '最大$count文字';
  }

  @override
  String get blockUser => 'ユーザーをブロック';

  @override
  String get blockUserConfirmation =>
      '本当にこのユーザーをブロックしますか？\n\n• このユーザーのメッセージが表示されなくなります\n• このユーザーはあなたのメッセージを見られなくなります';

  @override
  String get settingsTitle => '設定';

  @override
  String get themeLabel => 'テーマ';

  @override
  String get languageLabel => '言語';

  @override
  String get notificationsLabel => '通知';

  @override
  String get gpsManagement => 'GPS管理';

  @override
  String get customCategory => 'カスタムカテゴリー';

  @override
  String get blockedUsers => 'ブロックしたユーザー';

  @override
  String get appVersion => 'アプリバージョン';

  @override
  String get enableNotifications => '通知を有効にする';

  @override
  String get notificationSound => '通知音';

  @override
  String get backgroundExecution => 'バックグラウンド実行';

  @override
  String get enableLocation => '位置情報アクセスを有効にする';

  @override
  String get customCategoryName => 'カスタムカテゴリー名';

  @override
  String get noBlockedUsers => 'ブロックしたユーザーはいません';

  @override
  String get unblock => 'ブロック解除';

  @override
  String get lightTheme => 'ライト';

  @override
  String get darkTheme => 'ダーク';

  @override
  String get greyTheme => 'グレー';

  @override
  String get greyThemeDescription => 'ニュートラルなライト/ダークパレット';

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
  String get authorizationGranted => '認証が許可されました';

  @override
  String get requestAuthorization => '認証をリクエスト';

  @override
  String get notificationSoundDescription => '新しいメッセージが届いたときに音を再生する';

  @override
  String get batteryOptimizationDisabled => 'バッテリー最適化が無効です';

  @override
  String get batteryOptimizationWarning => 'アプリがバックグラウンドで通知を受信しない可能性があります';

  @override
  String get locationAccessEnabled => '位置情報アクセスが有効です';

  @override
  String get requestGpsAuthorization => 'GPS認証をリクエスト';

  @override
  String get noCategorySet => 'なし — タップして設定';

  @override
  String get activeCategory => 'アクティブ';

  @override
  String get remove => '削除';

  @override
  String get edit => '編集';

  @override
  String get customCategoryDialogTitle => 'カスタムカテゴリー';

  @override
  String get customCategoryDialogDescription =>
      'カスタムカテゴリーの名前を設定してください。まったく同じ名前のメッセージのみがフィルターで表示されます。';

  @override
  String get customCategoryHint => '例: \"ランナー東京北\"';

  @override
  String get nameCannotBeEmpty => '名前を空にすることはできません';

  @override
  String get customCategoryDisabled => 'カスタムカテゴリーが無効です';

  @override
  String get customCategorySet => 'カスタムカテゴリーが設定されました';

  @override
  String get permissionRequired => '認証が必要です';

  @override
  String get notificationPermissionMessage => '通知を受信するには、システム設定で権限を有効にしてください。';

  @override
  String get locationPermissionRequired => '位置情報権限が必要です';

  @override
  String get locationPermissionMessage => 'GPS機能を有効にするには、設定で位置情報アクセスを許可してください。';

  @override
  String get ok => 'OK';

  @override
  String get settings => '設定';

  @override
  String get save => '保存';

  @override
  String get category_free => 'フリー';

  @override
  String get category_warning => '警告';

  @override
  String get category_help => 'ヘルプ';

  @override
  String get category_events => 'イベント';

  @override
  String get category_notice => '通知';

  @override
  String get category_info => '情報';

  @override
  String get category_custom => 'カスタム';
}
