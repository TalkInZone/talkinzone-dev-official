// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get relNow => '现在';

  @override
  String relMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String relHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String get distVeryClose => '非常近';

  @override
  String get distClose => '近';

  @override
  String get distInArea => '在您附近';

  @override
  String get distFar => '远';

  @override
  String get distVeryFar => '非常远';

  @override
  String get unitM => '米';

  @override
  String get unitKm => '公里';

  @override
  String get reactionsTitle => '反应';

  @override
  String get close => '关闭';

  @override
  String get you => '您';

  @override
  String get anonymous => '匿名';

  @override
  String get tooltipSettings => '设置';

  @override
  String get tooltipFilters => '筛选器';

  @override
  String get tooltipRadius => '半径';

  @override
  String get tooltipProfile => '个人资料';

  @override
  String get tooltipReactions => '添加反应';

  @override
  String get noMessagesInArea => '此区域尚无消息。';

  @override
  String get newLabel => '新';

  @override
  String get composerHint => '写一条短消息（可选）…';

  @override
  String get welcomeTitle => '欢迎！';

  @override
  String get welcomeSubtitle => '开始使用，请用您的 Google 账号登录';

  @override
  String get welcomeBody => '给附近的人留下快速语音便条或短文本。消息在几分钟后自动删除。';

  @override
  String get understood => '明白了';

  @override
  String get mustBeAuthenticatedToBlock => '您必须登录才能屏蔽用户。';

  @override
  String get cannotBlockYourself => '您不能屏蔽自己。';

  @override
  String get invalidUserIdToBlock => '用户 ID 无效。';

  @override
  String get blockIgnoreTitle => '屏蔽用户';

  @override
  String get blockIgnoreTitleShort => '屏蔽用户';

  @override
  String get blockIgnoreSubtitle => '您将不再看到此用户的消息。';

  @override
  String blockConfirmText(String name) {
    return '屏蔽 $name？您将不再看到他们的消息。';
  }

  @override
  String get cancel => '取消';

  @override
  String get block => '屏蔽';

  @override
  String get userBlockedSimple => '用户已屏蔽。';

  @override
  String get blockError => '无法屏蔽用户';

  @override
  String get reportUserTitle => '举报用户';

  @override
  String get reportUserTitleShort => '举报用户';

  @override
  String get reportUserSubtitle => '向版主发送报告。';

  @override
  String get reportDescribeOptional => '描述问题（可选）';

  @override
  String get reportReasonHint => '原因…';

  @override
  String get send => '发送';

  @override
  String get reportSentThanks => '谢谢，您的报告已发送。';

  @override
  String get reportNotSent => '报告未发送';

  @override
  String get cannotReportYourself => '您不能举报自己。';

  @override
  String get operationNotAllowed => '操作不允许。';

  @override
  String get loginFailed => '登录失败。请重试。';

  @override
  String get signInWithGoogle => '用 Google 登录';

  @override
  String get customCategoryWarning => '在设置中设置自定义类别名称。';

  @override
  String get invalidOperation => '无效操作。';

  @override
  String get userBlocked => '用户已屏蔽。';

  @override
  String get yourAccount => '您的账户';

  @override
  String get userId => '用户 ID：';

  @override
  String get noId => '无 ID';

  @override
  String get name => '姓名：';

  @override
  String get noName => '无姓名';

  @override
  String get email => '邮箱：';

  @override
  String get noEmail => '无邮箱';

  @override
  String get provider => '提供商：';

  @override
  String get logout => '退出';

  @override
  String get ageGateTitle => '完善您的个人资料';

  @override
  String ageGateSubtitle(int years) {
    return '要继续使用 TalkInZone，您必须注明您的出生日期（最低年龄：$years 岁）。';
  }

  @override
  String get birthDate => '出生日期';

  @override
  String get selectDate => '选择日期';

  @override
  String get selectBirthDate => '选择您的出生日期';

  @override
  String get truthDeclaration => '我声明所提供的数据真实无误。';

  @override
  String get falseWarning => '警告：虚假陈述可能导致账户暂停。';

  @override
  String get confirmAndContinue => '确认并继续';

  @override
  String get missingDate => '请选择出生日期。';

  @override
  String tooYoung(int years) {
    return '您必须年满 $years 岁才能使用此应用。';
  }

  @override
  String get mustAccept => '您必须确认所提供的数据真实无误。';

  @override
  String get genericError => '发生错误。请重试。';

  @override
  String maxCharsError(int count) {
    return '最多 $count 个字符';
  }

  @override
  String get blockUser => '屏蔽用户';

  @override
  String get blockUserConfirmation =>
      '您确定要屏蔽此用户吗？\n\n• 您将不再看到他们的任何消息\n• 他们将不再看到您的任何消息';

  @override
  String get settingsTitle => '设置';

  @override
  String get themeLabel => '主题';

  @override
  String get languageLabel => '语言';

  @override
  String get notificationsLabel => '通知';

  @override
  String get gpsManagement => 'GPS 管理';

  @override
  String get customCategory => '自定义类别';

  @override
  String get blockedUsers => '已屏蔽用户';

  @override
  String get appVersion => '应用版本';

  @override
  String get enableNotifications => '启用通知';

  @override
  String get notificationSound => '通知声音';

  @override
  String get backgroundExecution => '后台运行';

  @override
  String get enableLocation => '启用位置访问';

  @override
  String get customCategoryName => '自定义类别名称';

  @override
  String get noBlockedUsers => '无已屏蔽用户';

  @override
  String get unblock => '取消屏蔽';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get greyTheme => '灰色';

  @override
  String get greyThemeDescription => '中性浅色/深色调色板';

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
  String get authorizationGranted => '已授予授权';

  @override
  String get requestAuthorization => '请求授权';

  @override
  String get notificationSoundDescription => '新消息到达时播放声音';

  @override
  String get batteryOptimizationDisabled => '电池优化已禁用';

  @override
  String get batteryOptimizationWarning => '应用可能无法在后台接收通知';

  @override
  String get locationAccessEnabled => '位置访问已启用';

  @override
  String get requestGpsAuthorization => '请求 GPS 授权';

  @override
  String get noCategorySet => '无 — 点击设置';

  @override
  String get activeCategory => '活跃';

  @override
  String get remove => '移除';

  @override
  String get edit => '编辑';

  @override
  String get customCategoryDialogTitle => '自定义类别';

  @override
  String get customCategoryDialogDescription =>
      '设置您的自定义类别名称。只有具有完全相同名称的消息才能在筛选器中可见。';

  @override
  String get customCategoryHint => '例如：\"北京跑者北部\"';

  @override
  String get nameCannotBeEmpty => '名称不能为空';

  @override
  String get customCategoryDisabled => '自定义类别已禁用';

  @override
  String get customCategorySet => '自定义类别已设置';

  @override
  String get permissionRequired => '需要授权';

  @override
  String get notificationPermissionMessage => '要接收通知，请在系统设置中启用权限。';

  @override
  String get locationPermissionRequired => '需要位置权限';

  @override
  String get locationPermissionMessage => '要启用 GPS 功能，请在设置中允许位置访问。';

  @override
  String get ok => '确定';

  @override
  String get settings => '设置';

  @override
  String get save => '保存';

  @override
  String get category_free => '自由';

  @override
  String get category_warning => '警告';

  @override
  String get category_help => '帮助';

  @override
  String get category_events => '活动';

  @override
  String get category_notice => '通知';

  @override
  String get category_info => '信息';

  @override
  String get category_custom => '自定义';
}
