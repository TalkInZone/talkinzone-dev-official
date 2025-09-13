// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get relNow => 'сейчас';

  @override
  String relMinutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String relHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String get distVeryClose => 'очень близко';

  @override
  String get distClose => 'близко';

  @override
  String get distInArea => 'в вашем районе';

  @override
  String get distFar => 'далеко';

  @override
  String get distVeryFar => 'очень далеко';

  @override
  String get unitM => 'м';

  @override
  String get unitKm => 'км';

  @override
  String get reactionsTitle => 'Реакции';

  @override
  String get close => 'Закрыть';

  @override
  String get you => 'Вы';

  @override
  String get anonymous => 'Аноним';

  @override
  String get tooltipSettings => 'Настройки';

  @override
  String get tooltipFilters => 'Фильтры';

  @override
  String get tooltipRadius => 'Радиус';

  @override
  String get tooltipProfile => 'Профиль';

  @override
  String get tooltipReactions => 'Добавить реакцию';

  @override
  String get noMessagesInArea => 'В этой области пока нет сообщений.';

  @override
  String get newLabel => 'НОВОЕ';

  @override
  String get composerHint => 'Напишите короткое сообщение (необязательно)…';

  @override
  String get welcomeTitle => 'Добро пожаловать!';

  @override
  String get welcomeSubtitle =>
      'Чтобы начать, войдите с помощью своей учетной записи Google';

  @override
  String get welcomeBody =>
      'Оставляйте короткие голосовые сообщения или тексты людям поблизости. Сообщения автоматически удаляются через несколько минут.';

  @override
  String get understood => 'Понятно';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Вы должны быть авторизованы, чтобы блокировать пользователей.';

  @override
  String get cannotBlockYourself => 'Вы не можете заблокировать себя.';

  @override
  String get invalidUserIdToBlock => 'Неверный идентификатор пользователя.';

  @override
  String get blockIgnoreTitle => 'Заблокировать пользователя';

  @override
  String get blockIgnoreTitleShort => 'Заблокировать пользователя';

  @override
  String get blockIgnoreSubtitle =>
      'Вы больше не будете видеть сообщения этого пользователя.';

  @override
  String blockConfirmText(String name) {
    return 'Заблокировать $name? Вы больше не будете видеть его/ее сообщения.';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get block => 'Заблокировать';

  @override
  String get userBlockedSimple => 'Пользователь заблокирован.';

  @override
  String get blockError => 'Не удалось заблокировать пользователя';

  @override
  String get reportUserTitle => 'Пожаловаться на пользователя';

  @override
  String get reportUserTitleShort => 'Пожаловаться на пользователя';

  @override
  String get reportUserSubtitle => 'Отправить жалобу модераторам.';

  @override
  String get reportDescribeOptional => 'Опишите проблему (необязательно)';

  @override
  String get reportReasonHint => 'Причина…';

  @override
  String get send => 'Отправить';

  @override
  String get reportSentThanks => 'Спасибо, ваша жалоба отправлена.';

  @override
  String get reportNotSent => 'Жалоба не отправлена';

  @override
  String get cannotReportYourself => 'Вы не можете пожаловаться на себя.';

  @override
  String get operationNotAllowed => 'Операция не разрешена.';

  @override
  String get loginFailed => 'Ошибка входа. Попробуйте снова.';

  @override
  String get signInWithGoogle => 'Войти с Google';

  @override
  String get customCategoryWarning =>
      'Установите название пользовательской категории в Настройках.';

  @override
  String get invalidOperation => 'Неверная операция.';

  @override
  String get userBlocked => 'Пользователь заблокирован.';

  @override
  String get yourAccount => 'Ваша учетная запись';

  @override
  String get userId => 'ID пользователя:';

  @override
  String get noId => 'Нет ID';

  @override
  String get name => 'Имя:';

  @override
  String get noName => 'Нет имени';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'Нет email';

  @override
  String get provider => 'Провайдер:';

  @override
  String get logout => 'Выйти';

  @override
  String get ageGateTitle => 'Завершите ваш профиль';

  @override
  String ageGateSubtitle(int years) {
    return 'Чтобы продолжить использование TalkInZone, вы должны указать вашу дату рождения (минимальный возраст: $years лет).';
  }

  @override
  String get birthDate => 'Дата рождения';

  @override
  String get selectDate => 'Выбрать дату';

  @override
  String get selectBirthDate => 'Выберите вашу дату рождения';

  @override
  String get truthDeclaration =>
      'Я заявляю, что предоставленные данные являются правдивыми.';

  @override
  String get falseWarning =>
      'Внимание: ложные заявления могут привести к блокировке учетной записи.';

  @override
  String get confirmAndContinue => 'Подтвердить и продолжить';

  @override
  String get missingDate => 'Выберите дату рождения.';

  @override
  String tooYoung(int years) {
    return 'Вам должно быть не менее $years лет, чтобы использовать приложение.';
  }

  @override
  String get mustAccept =>
      'Вы должны подтвердить, что предоставленные данные являются правдивыми.';

  @override
  String get genericError => 'Произошла ошибка. Пожалуйста, попробуйте снова.';

  @override
  String maxCharsError(int count) {
    return 'Макс. $count символов';
  }

  @override
  String get blockUser => 'Заблокировать пользователя';

  @override
  String get blockUserConfirmation =>
      'Вы действительно хотите заблокировать этого пользователя?\n\n• Вы больше не будете видеть его сообщений\n• Он/она больше не будет видеть ваших сообщений';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get themeLabel => 'Тема';

  @override
  String get languageLabel => 'Язык';

  @override
  String get notificationsLabel => 'Уведомления';

  @override
  String get gpsManagement => 'Управление GPS';

  @override
  String get customCategory => 'Пользовательская категория';

  @override
  String get blockedUsers => 'Заблокированные пользователи';

  @override
  String get appVersion => 'Версия приложения';

  @override
  String get enableNotifications => 'Включить уведомления';

  @override
  String get notificationSound => 'Звук уведомления';

  @override
  String get backgroundExecution => 'Фоновое выполнение';

  @override
  String get enableLocation => 'Включить доступ к местоположению';

  @override
  String get customCategoryName => 'Название пользовательской категории';

  @override
  String get noBlockedUsers => 'Нет заблокированных пользователей';

  @override
  String get unblock => 'Разблокировать';

  @override
  String get lightTheme => 'Светлая';

  @override
  String get darkTheme => 'Темная';

  @override
  String get greyTheme => 'Серая';

  @override
  String get greyThemeDescription => 'Нейтральная светлая/темная палитра';

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
  String get authorizationGranted => 'Авторизация предоставлена';

  @override
  String get requestAuthorization => 'Запрос авторизации';

  @override
  String get notificationSoundDescription =>
      'Воспроизводить звук при получении нового сообщения';

  @override
  String get batteryOptimizationDisabled => 'Оптимизация батареи отключена';

  @override
  String get batteryOptimizationWarning =>
      'Приложение может не получать уведомления в фоновом режиме';

  @override
  String get locationAccessEnabled => 'Доступ к местоположению включен';

  @override
  String get requestGpsAuthorization => 'Запрос авторизации GPS';

  @override
  String get noCategorySet => 'Нет — нажмите, чтобы установить';

  @override
  String get activeCategory => 'Активная';

  @override
  String get remove => 'Удалить';

  @override
  String get edit => 'Редактировать';

  @override
  String get customCategoryDialogTitle => 'Пользовательская категория';

  @override
  String get customCategoryDialogDescription =>
      'Установите название вашей пользовательской категории. Только сообщения с точно таким же названием будут видны в фильтрах.';

  @override
  String get customCategoryHint => 'Напр. \"Бегун Москва Север\"';

  @override
  String get nameCannotBeEmpty => 'Название не может быть пустым';

  @override
  String get customCategoryDisabled => 'Пользовательская категория отключена';

  @override
  String get customCategorySet => 'Пользовательская категория установлена';

  @override
  String get permissionRequired => 'Требуется авторизация';

  @override
  String get notificationPermissionMessage =>
      'Для получения уведомлений включите разрешения в системных настройках.';

  @override
  String get locationPermissionRequired =>
      'Требуется разрешение на местоположение';

  @override
  String get locationPermissionMessage =>
      'Для включения GPS-функций разрешите доступ к местоположению в настройках.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'НАСТРОЙКИ';

  @override
  String get save => 'Сохранить';

  @override
  String get selectCategory => 'Выберите категорию:';

  @override
  String get filterByCategory => 'Фильтровать сообщения по категории:';

  @override
  String get category_free => 'Свободная';

  @override
  String get category_warning => 'Предупреждение';

  @override
  String get category_help => 'Помощь';

  @override
  String get category_events => 'События';

  @override
  String get category_notice => 'Уведомление';

  @override
  String get category_info => 'Информация';

  @override
  String get category_custom => 'Пользовательская';

  @override
  String get deleteConfirmTitle => 'Удалить сообщение?';

  @override
  String get deleteConfirmBody =>
      'Это навсегда удалит ваше сообщение для всех.';

  @override
  String get deleteMessage => 'Удалить';

  @override
  String get deleted => 'Удалено';

  @override
  String get deleteError => 'Не удалось удалить сообщение';

  @override
  String get tooltipDelete => 'Удалить';

  @override
  String get versionNoticeTitle => 'Уведомление о версии';

  @override
  String versionNoticeBody(String version) {
    return 'Это версия $version, она сейчас является экспериментальной. Приятного использования и, если хотите, оставьте отзыв. Если обнаружите проблемы или ошибки, пишите на адрес: talkinzone@gmail.com.';
  }

  @override
  String get versionNoticeLinksIntro =>
      'Чтобы ознакомиться с правилами и информацией о безопасности детей, посетите:';

  @override
  String get versionNoticeLink1Label => 'talkinzone-normative.vercel.app';

  @override
  String get versionNoticeLink1Url =>
      'https://talkinzone-normative.vercel.app/';

  @override
  String get versionNoticeLink2Label => 'Стандарты безопасности детей';

  @override
  String get versionNoticeLink2Url =>
      'https://talkinzone-normative.vercel.app/standard_sicurezza_minori.html?lang=ru';

  @override
  String get updateRequiredTitle => 'Требуется обновление';

  @override
  String get updateRequiredOutdated => 'Текущая версия приложения устарела.';

  @override
  String get updateRequiredInstruction =>
      'Чтобы продолжить использование приложения, скачайте последнюю версию из магазина.';

  @override
  String get updateRequiredCurrentVersion => 'Текущая версия:';
}
