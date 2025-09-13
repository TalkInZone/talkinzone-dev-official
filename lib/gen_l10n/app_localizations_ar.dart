// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get relNow => 'الآن';

  @override
  String relMinutesAgo(int count) {
    return 'منذ $count دقيقة';
  }

  @override
  String relHoursAgo(int count) {
    return 'منذ $count ساعة';
  }

  @override
  String get distVeryClose => 'قريب جداً';

  @override
  String get distClose => 'قريب';

  @override
  String get distInArea => 'في منطقتك';

  @override
  String get distFar => 'بعيد';

  @override
  String get distVeryFar => 'بعيد جداً';

  @override
  String get unitM => 'م';

  @override
  String get unitKm => 'كم';

  @override
  String get reactionsTitle => 'ردود الفعل';

  @override
  String get close => 'إغلاق';

  @override
  String get you => 'أنت';

  @override
  String get anonymous => 'مجهول';

  @override
  String get tooltipSettings => 'الإعدادات';

  @override
  String get tooltipFilters => 'الفلاتر';

  @override
  String get tooltipRadius => 'نصف القطر';

  @override
  String get tooltipProfile => 'الملف الشخصي';

  @override
  String get tooltipReactions => 'إضافة رد فعل';

  @override
  String get noMessagesInArea => 'لا توجد رسائل في هذه المنطقة بعد.';

  @override
  String get newLabel => 'جديد';

  @override
  String get composerHint => 'اكتب رسالة قصيرة (اختياري)…';

  @override
  String get welcomeTitle => 'مرحباً!';

  @override
  String get welcomeSubtitle =>
      'للبدء، سجل الدخول باستخدام حساب Google الخاص بك';

  @override
  String get welcomeBody =>
      'اترك ملاحظات صوتية أو نصوص قصيرة للأشخاص القريبين. الرسائل تختفي تلقائياً بعد بضع دقائق.';

  @override
  String get understood => 'فهمت';

  @override
  String get mustBeAuthenticatedToBlock =>
      'يجب أن تكون مسجلاً الدخول لحظر المستخدمين.';

  @override
  String get cannotBlockYourself => 'لا يمكنك حظر نفسك.';

  @override
  String get invalidUserIdToBlock => 'معرف مستخدم غير صالح.';

  @override
  String get blockIgnoreTitle => 'حظر المستخدم';

  @override
  String get blockIgnoreTitleShort => 'حظر المستخدم';

  @override
  String get blockIgnoreSubtitle => 'لن ترى رسائل هذا المستخدم بعد الآن.';

  @override
  String blockConfirmText(String name) {
    return 'حظر $name؟ لن ترى رسائله بعد الآن.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get block => 'حظر';

  @override
  String get userBlockedSimple => 'تم حظر المستخدم.';

  @override
  String get blockError => 'تعذر حظر المستخدم';

  @override
  String get reportUserTitle => 'الإبلاغ عن مستخدم';

  @override
  String get reportUserTitleShort => 'الإبلاغ عن مستخدم';

  @override
  String get reportUserSubtitle => 'إرسال تقرير إلى المشرفين.';

  @override
  String get reportDescribeOptional => 'صف المشكلة (اختياري)';

  @override
  String get reportReasonHint => 'السبب…';

  @override
  String get send => 'إرسال';

  @override
  String get reportSentThanks => 'شكراً، تم إرسال تقريرك.';

  @override
  String get reportNotSent => 'لم يتم إرسال التقرير';

  @override
  String get cannotReportYourself => 'لا يمكنك الإبلاغ عن نفسك.';

  @override
  String get operationNotAllowed => 'العملية غير مسموحة.';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. حاول مرة أخرى.';

  @override
  String get signInWithGoogle => 'تسجيل الدخول باستخدام Google';

  @override
  String get customCategoryWarning =>
      'قم بتعيين اسم الفئة المخصصة في الإعدادات.';

  @override
  String get invalidOperation => 'عملية غير صالحة.';

  @override
  String get userBlocked => 'تم حظر المستخدم.';

  @override
  String get yourAccount => 'حسابك';

  @override
  String get userId => 'معرف المستخدم:';

  @override
  String get noId => 'لا يوجد معرف';

  @override
  String get name => 'الاسم:';

  @override
  String get noName => 'لا يوجد اسم';

  @override
  String get email => 'البريد الإلكتروني:';

  @override
  String get noEmail => 'لا يوجد بريد إلكتروني';

  @override
  String get provider => 'مزود الخدمة:';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get ageGateTitle => 'أكمل ملفك الشخصي';

  @override
  String ageGateSubtitle(int years) {
    return 'لمواصلة استخدام TalkInZone، يجب عليك الإشارة إلى تاريخ ميلادك (الحد الأدنى للعمر: $years سنة).';
  }

  @override
  String get birthDate => 'تاريخ الميلاد';

  @override
  String get selectDate => 'اختر تاريخاً';

  @override
  String get selectBirthDate => 'اختر تاريخ ميلادك';

  @override
  String get truthDeclaration => 'أعلن أن البيانات المقدمة صحيحة.';

  @override
  String get falseWarning =>
      'تحذير: التصريحات الكاذبة قد تؤدي إلى تعليق الحساب.';

  @override
  String get confirmAndContinue => 'تأكيد ومتابعة';

  @override
  String get missingDate => 'اختر تاريخ ميلاد.';

  @override
  String tooYoung(int years) {
    return 'يجب أن يكون عمرك $years سنة على الأقل لاستخدام التطبيق.';
  }

  @override
  String get mustAccept => 'يجب أن تؤكد أن البيانات المقدمة صحيحة.';

  @override
  String get genericError => 'حدث خطأ. يرجى المحاولة مرة أخرى.';

  @override
  String maxCharsError(int count) {
    return 'الحد الأقصى $count حرف';
  }

  @override
  String get blockUser => 'حظر المستخدم';

  @override
  String get blockUserConfirmation =>
      'هل تريد حقاً حظر هذا المستخدم؟\n\n• لن ترى أي من رسائله بعد الآن\n• لن يرى أي من رسائلك بعد الآن';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get themeLabel => 'المظهر';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get notificationsLabel => 'الإشعارات';

  @override
  String get gpsManagement => 'إدارة GPS';

  @override
  String get customCategory => 'فئة مخصصة';

  @override
  String get blockedUsers => 'المستخدمون المحظورون';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get enableNotifications => 'تمكين الإشعارات';

  @override
  String get notificationSound => 'صوت الإشعار';

  @override
  String get backgroundExecution => 'التنفيذ في الخلفية';

  @override
  String get enableLocation => 'تمكين الوصول إلى الموقع';

  @override
  String get customCategoryName => 'اسم الفئة المخصصة';

  @override
  String get noBlockedUsers => 'لا يوجد مستخدمون محظورون';

  @override
  String get unblock => 'إلغاء الحظر';

  @override
  String get lightTheme => 'فاتح';

  @override
  String get darkTheme => 'غامق';

  @override
  String get greyTheme => 'رمادي';

  @override
  String get greyThemeDescription => 'لوحة ألوان محايدة فاتحة/غامقة';

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
  String get authorizationGranted => 'تم منح التخويل';

  @override
  String get requestAuthorization => 'طلب التخويل';

  @override
  String get notificationSoundDescription => 'تشغيل صوت عند وصول رسالة جديدة';

  @override
  String get batteryOptimizationDisabled => 'تعطيل تحسين البطارية';

  @override
  String get batteryOptimizationWarning =>
      'قد لا يتلقى التطبيق إشعارات في الخلفية';

  @override
  String get locationAccessEnabled => 'تم تمكين الوصول إلى الموقع';

  @override
  String get requestGpsAuthorization => 'طلب تخويل GPS';

  @override
  String get noCategorySet => 'لا شيء — انقر لتعيين';

  @override
  String get activeCategory => 'نشط';

  @override
  String get remove => 'إزالة';

  @override
  String get edit => 'تعديل';

  @override
  String get customCategoryDialogTitle => 'فئة مخصصة';

  @override
  String get customCategoryDialogDescription =>
      'قم بتعيين اسم فئتك المخصصة. فقط الرسائل التي تحمل نفس الاسم بالضبط ستكون مرئية في الفلاتر.';

  @override
  String get customCategoryHint => 'مثال: \"عداء شمال الرياض\"';

  @override
  String get nameCannotBeEmpty => 'لا يمكن أن يكون الاسم فارغاً';

  @override
  String get customCategoryDisabled => 'تم تعطيل الفئة المخصصة';

  @override
  String get customCategorySet => 'تم تعيين الفئة المخصصة';

  @override
  String get permissionRequired => 'مطلوب تخويل';

  @override
  String get notificationPermissionMessage =>
      'لتلقي الإشعارات، قم بتمكين الأذونات في إعدادات النظام.';

  @override
  String get locationPermissionRequired => 'مطلوب إذن الموقع';

  @override
  String get locationPermissionMessage =>
      'لتمكين ميزات GPS، اسمح بالوصول إلى الموقع في الإعدادات.';

  @override
  String get ok => 'موافق';

  @override
  String get settings => 'الإعدادات';

  @override
  String get save => 'حفظ';

  @override
  String get selectCategory => 'اختر الفئة:';

  @override
  String get filterByCategory => 'تصفية الرسائل حسب الفئة:';

  @override
  String get category_free => 'حر';

  @override
  String get category_warning => 'تحذير';

  @override
  String get category_help => 'مساعدة';

  @override
  String get category_events => 'أحداث';

  @override
  String get category_notice => 'إشعار';

  @override
  String get category_info => 'معلومات';

  @override
  String get category_custom => 'مخصص';

  @override
  String get deleteConfirmTitle => 'حذف الرسالة؟';

  @override
  String get deleteConfirmBody => 'سيؤدي هذا إلى إزالة رسالتك نهائياً للجميع.';

  @override
  String get deleteMessage => 'حذف';

  @override
  String get deleted => 'تم الحذف';

  @override
  String get deleteError => 'تعذر حذف الرسالة';

  @override
  String get tooltipDelete => 'حذف';

  @override
  String get versionNoticeTitle => 'إشعار الإصدار';

  @override
  String versionNoticeBody(String version) {
    return 'هذا هو الإصدار $version وهو حاليًا تجريبي. استمتع باستخدامه، وإذا رغبت، اترك ملاحظاتك. إذا واجهت أي مشاكل أو أخطاء، يمكنك التواصل معنا عبر البريد الإلكتروني: talkinzone@gmail.com.';
  }

  @override
  String get versionNoticeLinksIntro =>
      'للاطلاع على السياسات ومعلومات سلامة الأطفال، تفضل بزيارة:';

  @override
  String get versionNoticeLink1Label => 'talkinzone-normative.vercel.app';

  @override
  String get versionNoticeLink1Url =>
      'https://talkinzone-normative.vercel.app/';

  @override
  String get versionNoticeLink2Label => 'معايير سلامة الأطفال';

  @override
  String get versionNoticeLink2Url =>
      'https://talkinzone-normative.vercel.app/standard_sicurezza_minori.html?lang=ar';

  @override
  String get updateRequiredTitle => 'مطلوب تحديث';

  @override
  String get updateRequiredOutdated => 'إصدار التطبيق الحالي قديم.';

  @override
  String get updateRequiredInstruction =>
      'لمتابعة استخدام التطبيق، حمّل أحدث نسخة من المتجر.';

  @override
  String get updateRequiredCurrentVersion => 'الإصدار الحالي:';
}
