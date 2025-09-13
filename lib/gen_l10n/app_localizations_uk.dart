// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get relNow => 'зараз';

  @override
  String relMinutesAgo(int count) {
    return '$count хв тому';
  }

  @override
  String relHoursAgo(int count) {
    return '$count год тому';
  }

  @override
  String get distVeryClose => 'дуже близько';

  @override
  String get distClose => 'близько';

  @override
  String get distInArea => 'поруч з вами';

  @override
  String get distFar => 'далеко';

  @override
  String get distVeryFar => 'дуже далеко';

  @override
  String get unitM => 'м';

  @override
  String get unitKm => 'км';

  @override
  String get reactionsTitle => 'Реакції';

  @override
  String get close => 'Закрити';

  @override
  String get you => 'Ви';

  @override
  String get anonymous => 'Анонім';

  @override
  String get tooltipSettings => 'Налаштування';

  @override
  String get tooltipFilters => 'Фільтри';

  @override
  String get tooltipRadius => 'Радіус';

  @override
  String get tooltipProfile => 'Профіль';

  @override
  String get tooltipReactions => 'Додати реакцію';

  @override
  String get noMessagesInArea => 'Поки що немає повідомлень у цій зоні.';

  @override
  String get newLabel => 'НОВЕ';

  @override
  String get composerHint => 'Напишіть коротке повідомлення (необов\'язково)…';

  @override
  String get welcomeTitle => 'Ласкаво просимо!';

  @override
  String get welcomeSubtitle =>
      'Щоб почати, увійдіть за допомогою облікового запису Google';

  @override
  String get welcomeBody =>
      'Залишайте короткі голосові повідомлення або тексти людям поруч. Повідомлення автоматично видаляються через кілька хвилин.';

  @override
  String get understood => 'Зрозуміло';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Ви повинні бути авторизовані, щоб блокувати користувачів.';

  @override
  String get cannotBlockYourself => 'Ви не можете заблокувати себе.';

  @override
  String get invalidUserIdToBlock => 'Недійсний ідентифікатор користувача.';

  @override
  String get blockIgnoreTitle => 'Заблокувати користувача';

  @override
  String get blockIgnoreTitleShort => 'Заблокувати користувача';

  @override
  String get blockIgnoreSubtitle =>
      'Ви більше не будете бачити повідомлення цього користувача.';

  @override
  String blockConfirmText(String name) {
    return 'Заблокувати $name? Ви більше не будете бачити його/її повідомлення.';
  }

  @override
  String get cancel => 'Скасувати';

  @override
  String get block => 'Заблокувати';

  @override
  String get userBlockedSimple => 'Користувача заблоковано.';

  @override
  String get blockError => 'Не вдалося заблокувати користувача';

  @override
  String get reportUserTitle => 'Поскаржитися на користувача';

  @override
  String get reportUserTitleShort => 'Поскаржитися на користувача';

  @override
  String get reportUserSubtitle => 'Надішліть скаргу модераторам.';

  @override
  String get reportDescribeOptional => 'Опишіть проблему (необов\'язково)';

  @override
  String get reportReasonHint => 'Причина…';

  @override
  String get send => 'Надіслати';

  @override
  String get reportSentThanks => 'Дякуємо, ваша скарга надіслана.';

  @override
  String get reportNotSent => 'Скаргу не надіслано';

  @override
  String get cannotReportYourself => 'Ви не можете поскаржитися на себе.';

  @override
  String get operationNotAllowed => 'Операція не дозволена.';

  @override
  String get loginFailed => 'Помилка входу. Спробуйте ще раз.';

  @override
  String get signInWithGoogle => 'Увійти з Google';

  @override
  String get customCategoryWarning =>
      'Встановіть назву користувацької категорії в Налаштуваннях.';

  @override
  String get invalidOperation => 'Недійсна операція.';

  @override
  String get userBlocked => 'Користувача заблоковано.';

  @override
  String get yourAccount => 'Ваш обліковий запис';

  @override
  String get userId => 'ID користувача:';

  @override
  String get noId => 'Немає ID';

  @override
  String get name => 'Ім\'я:';

  @override
  String get noName => 'Немає імені';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'Немає email';

  @override
  String get provider => 'Провайдер:';

  @override
  String get logout => 'Вийти';

  @override
  String get ageGateTitle => 'Завершіть ваш профіль';

  @override
  String ageGateSubtitle(int years) {
    return 'Щоб продовжити використання TalkInZone, ви повинні вказати вашу дату народження (мінімальний вік: $years років).';
  }

  @override
  String get birthDate => 'Дата народження';

  @override
  String get selectDate => 'Вибрати дату';

  @override
  String get selectBirthDate => 'Виберіть вашу дату народження';

  @override
  String get truthDeclaration => 'Я заявляю, що надані дані є правдивими.';

  @override
  String get falseWarning =>
      'Увага: неправдиві заяви можуть призвести до блокування облікового запису.';

  @override
  String get confirmAndContinue => 'Підтвердити та продовжити';

  @override
  String get missingDate => 'Виберіть дату народження.';

  @override
  String tooYoung(int years) {
    return 'Вам має бути щонайменше $years років, щоб використовувати додаток.';
  }

  @override
  String get mustAccept =>
      'Ви повинні підтвердити, що надані дані є правдивими.';

  @override
  String get genericError => 'Сталася помилка. Будь ласка, спробуйте ще раз.';

  @override
  String maxCharsError(int count) {
    return 'Макс. $count символів';
  }

  @override
  String get blockUser => 'Заблокувати користувача';

  @override
  String get blockUserConfirmation =>
      'Ви дійсно хочете заблокувати цього користувача?\n\n• Ви більше не будете бачити жодних його повідомлень\n• Він/вона більше не буде бачити жодних ваших повідомлень';

  @override
  String get settingsTitle => 'Налаштування';

  @override
  String get themeLabel => 'Тема';

  @override
  String get languageLabel => 'Мова';

  @override
  String get notificationsLabel => 'Сповіщення';

  @override
  String get gpsManagement => 'Керування GPS';

  @override
  String get customCategory => 'Користувацька категорія';

  @override
  String get blockedUsers => 'Заблоковані користувачі';

  @override
  String get appVersion => 'Версія додатка';

  @override
  String get enableNotifications => 'Увімкнути сповіщення';

  @override
  String get notificationSound => 'Звук сповіщення';

  @override
  String get backgroundExecution => 'Фоновий режим';

  @override
  String get enableLocation => 'Увімкнути доступ до локації';

  @override
  String get customCategoryName => 'Назва користувацької категорії';

  @override
  String get noBlockedUsers => 'Немає заблокованих користувачів';

  @override
  String get unblock => 'Розблокувати';

  @override
  String get lightTheme => 'Світла';

  @override
  String get darkTheme => 'Темна';

  @override
  String get greyTheme => 'Сіра';

  @override
  String get greyThemeDescription => 'Нейтральна світла/темна палітра';

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
  String get authorizationGranted => 'Авторизацію надано';

  @override
  String get requestAuthorization => 'Запит авторизації';

  @override
  String get notificationSoundDescription =>
      'Відтворювати звук при надходженні нового повідомлення';

  @override
  String get batteryOptimizationDisabled => 'Оптимізацію батареї вимкнено';

  @override
  String get batteryOptimizationWarning =>
      'Додаток може не отримувати сповіщення у фоновому режимі';

  @override
  String get locationAccessEnabled => 'Доступ до локації увімкнено';

  @override
  String get requestGpsAuthorization => 'Запит авторизації GPS';

  @override
  String get noCategorySet => 'Немає — торкніться, щоб встановити';

  @override
  String get activeCategory => 'Активна';

  @override
  String get remove => 'Видалити';

  @override
  String get edit => 'Редагувати';

  @override
  String get customCategoryDialogTitle => 'Користувацька категорія';

  @override
  String get customCategoryDialogDescription =>
      'Встановіть назву вашої користувацької категорії. Лише повідомлення з такою ж назвою будуть видимі у фільтрах.';

  @override
  String get customCategoryHint => 'Напр. \"Бігун Київ Північ\"';

  @override
  String get nameCannotBeEmpty => 'Назва не може бути порожньою';

  @override
  String get customCategoryDisabled => 'Користувацьку категорію вимкнено';

  @override
  String get customCategorySet => 'Користувацьку категорію встановлено';

  @override
  String get permissionRequired => 'Потрібна авторизація';

  @override
  String get notificationPermissionMessage =>
      'Для отримання сповіщень увімкніть дозволи в системних налаштуваннях.';

  @override
  String get locationPermissionRequired => 'Потрібен дозвіл на локацію';

  @override
  String get locationPermissionMessage =>
      'Для вмикання GPS-функцій дозвольте доступ до локації в налаштуваннях.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'НАЛАШТУВАННЯ';

  @override
  String get save => 'Зберегти';

  @override
  String get selectCategory => 'Виберіть категорію:';

  @override
  String get filterByCategory => 'Фільтрувати повідомлення за категорією:';

  @override
  String get category_free => 'Вільна';

  @override
  String get category_warning => 'Попередження';

  @override
  String get category_help => 'Допомога';

  @override
  String get category_events => 'Події';

  @override
  String get category_notice => 'Повідомлення';

  @override
  String get category_info => 'Інформація';

  @override
  String get category_custom => 'Користувацька';

  @override
  String get deleteConfirmTitle => 'Видалити повідомлення?';

  @override
  String get deleteConfirmBody =>
      'Це назавжди видалить ваше повідомлення для всіх.';

  @override
  String get deleteMessage => 'Видалити';

  @override
  String get deleted => 'Видалено';

  @override
  String get deleteError => 'Не вдалося видалити повідомлення';

  @override
  String get tooltipDelete => 'Видалити';

  @override
  String get versionNoticeTitle => 'Повідомлення про версію';

  @override
  String versionNoticeBody(String version) {
    return 'Це версія $version, і наразі вона експериментальна. Користуйтеся із задоволенням і, якщо бажаєте, залиште відгук. Якщо виникнуть проблеми або помилки, напишіть на адресу: talkinzone@gmail.com.';
  }

  @override
  String get versionNoticeLinksIntro =>
      'Щоб переглянути політики та інформацію щодо безпеки неповнолітніх, відвідайте:';

  @override
  String get versionNoticeLink1Label => 'talkinzone-normative.vercel.app';

  @override
  String get versionNoticeLink1Url =>
      'https://talkinzone-normative.vercel.app/';

  @override
  String get versionNoticeLink2Label => 'Стандарти безпеки дітей';

  @override
  String get versionNoticeLink2Url =>
      'https://talkinzone-normative.vercel.app/standard_sicurezza_minori.html?lang=uk';

  @override
  String get updateRequiredTitle => 'Потрібне оновлення';

  @override
  String get updateRequiredOutdated => 'Поточна версія застосунку застаріла.';

  @override
  String get updateRequiredInstruction =>
      'Щоб і надалі користуватися застосунком, завантажте останню версію з магазину.';

  @override
  String get updateRequiredCurrentVersion => 'Поточна версія:';
}
