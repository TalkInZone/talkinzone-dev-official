// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get relNow => 'ahora';

  @override
  String relMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String relHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String get distVeryClose => 'muy cerca';

  @override
  String get distClose => 'cerca';

  @override
  String get distInArea => 'en tu área';

  @override
  String get distFar => 'lejos';

  @override
  String get distVeryFar => 'muy lejos';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'Reacciones';

  @override
  String get close => 'Cerrar';

  @override
  String get you => 'Tú';

  @override
  String get anonymous => 'Anónimo';

  @override
  String get tooltipSettings => 'Configuración';

  @override
  String get tooltipFilters => 'Filtros';

  @override
  String get tooltipRadius => 'Radio';

  @override
  String get tooltipProfile => 'Perfil';

  @override
  String get tooltipReactions => 'Añadir reacción';

  @override
  String get noMessagesInArea => 'Aún no hay mensajes en esta zona.';

  @override
  String get newLabel => 'NUEVO';

  @override
  String get composerHint => 'Escribe un mensaje corto (opcional)…';

  @override
  String get welcomeTitle => '¡Bienvenido!';

  @override
  String get welcomeSubtitle =>
      'Para comenzar, inicia sesión con tu cuenta de Google';

  @override
  String get welcomeBody =>
      'Deja notas de voz o textos cortos a personas cercanas. Los mensajes se autodestruyen después de unos minutos.';

  @override
  String get understood => 'Entendido';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Debes estar autenticado para bloquear usuarios.';

  @override
  String get cannotBlockYourself => 'No puedes bloquearte a ti mismo.';

  @override
  String get invalidUserIdToBlock => 'ID de usuario no válido.';

  @override
  String get blockIgnoreTitle => 'Bloquear usuario';

  @override
  String get blockIgnoreTitleShort => 'Bloquear usuario';

  @override
  String get blockIgnoreSubtitle => 'No verás más mensajes de este usuario.';

  @override
  String blockConfirmText(String name) {
    return '¿Bloquear a $name? No verás sus mensajes.';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get block => 'Bloquear';

  @override
  String get userBlockedSimple => 'Usuario bloqueado.';

  @override
  String get blockError => 'No se pudo bloquear al usuario';

  @override
  String get reportUserTitle => 'Reportar usuario';

  @override
  String get reportUserTitleShort => 'Reportar usuario';

  @override
  String get reportUserSubtitle => 'Envía un reporte a los moderadores.';

  @override
  String get reportDescribeOptional => 'Describe el problema (opcional)';

  @override
  String get reportReasonHint => 'Motivo…';

  @override
  String get send => 'Enviar';

  @override
  String get reportSentThanks => 'Gracias, tu reporte fue enviado.';

  @override
  String get reportNotSent => 'Reporte no enviado';

  @override
  String get cannotReportYourself => 'No puedes reportarte a ti mismo.';

  @override
  String get operationNotAllowed => 'Operación no permitida.';

  @override
  String get loginFailed => 'Error de inicio de sesión. Intenta nuevamente.';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';

  @override
  String get customCategoryWarning =>
      'Establece el nombre de la categoría personalizada en Configuración.';

  @override
  String get invalidOperation => 'Operación no válida.';

  @override
  String get userBlocked => 'Usuario bloqueado.';

  @override
  String get yourAccount => 'Tu cuenta';

  @override
  String get userId => 'ID de usuario:';

  @override
  String get noId => 'Sin ID';

  @override
  String get name => 'Nombre:';

  @override
  String get noName => 'Sin nombre';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'Sin email';

  @override
  String get provider => 'Proveedor:';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get ageGateTitle => 'Completa tu perfil';

  @override
  String ageGateSubtitle(int years) {
    return 'Para continuar usando TalkInZone debes indicar tu fecha de nacimiento (edad mínima: $years años).';
  }

  @override
  String get birthDate => 'Fecha de nacimiento';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get selectBirthDate => 'Selecciona tu fecha de nacimiento';

  @override
  String get truthDeclaration =>
      'Declaro que los datos proporcionados son verídicos.';

  @override
  String get falseWarning =>
      'Advertencia: declaraciones falsas pueden resultar en suspensión de cuenta.';

  @override
  String get confirmAndContinue => 'Confirmar y continuar';

  @override
  String get missingDate => 'Selecciona una fecha de nacimiento.';

  @override
  String tooYoung(int years) {
    return 'Debes tener al menos $years años para usar la app.';
  }

  @override
  String get mustAccept =>
      'Debes confirmar que los datos proporcionados son verídicos.';

  @override
  String get genericError => 'Ocurrió un error. Intenta nuevamente.';

  @override
  String maxCharsError(int count) {
    return 'Máx. $count caracteres';
  }

  @override
  String get blockUser => 'Bloquear usuario';

  @override
  String get blockUserConfirmation =>
      '¿Realmente quieres bloquear a este usuario?\n\n• No verás ninguno de sus mensajes\n• Él/Ella no verá ninguno de tus mensajes';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get themeLabel => 'Tema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get notificationsLabel => 'Notificaciones';

  @override
  String get gpsManagement => 'Gestión GPS';

  @override
  String get customCategory => 'Categoría personalizada';

  @override
  String get blockedUsers => 'Usuarios bloqueados';

  @override
  String get appVersion => 'Versión de la App';

  @override
  String get enableNotifications => 'Habilitar notificaciones';

  @override
  String get notificationSound => 'Sonido de notificación';

  @override
  String get backgroundExecution => 'Ejecución en segundo plano';

  @override
  String get enableLocation => 'Habilitar acceso a ubicación';

  @override
  String get customCategoryName => 'Nombre de categoría personalizada';

  @override
  String get noBlockedUsers => 'No hay usuarios bloqueados';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Oscuro';

  @override
  String get greyTheme => 'Gris';

  @override
  String get greyThemeDescription => 'Paleta neutra claro/oscuro';

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
  String get authorizationGranted => 'Autorización concedida';

  @override
  String get requestAuthorization => 'Solicitar autorización';

  @override
  String get notificationSoundDescription =>
      'Reproducir sonido al llegar nuevo mensaje';

  @override
  String get batteryOptimizationDisabled =>
      'Optimización de batería desactivada';

  @override
  String get batteryOptimizationWarning =>
      'La app podría no recibir notificaciones en segundo plano';

  @override
  String get locationAccessEnabled => 'Acceso a ubicación habilitado';

  @override
  String get requestGpsAuthorization => 'Solicitar autorización GPS';

  @override
  String get noCategorySet => 'Ninguna — toca para establecer';

  @override
  String get activeCategory => 'Activa';

  @override
  String get remove => 'Eliminar';

  @override
  String get edit => 'Editar';

  @override
  String get customCategoryDialogTitle => 'Categoría personalizada';

  @override
  String get customCategoryDialogDescription =>
      'Establece el nombre de tu categoría personalizada. Solo los mensajes con exactamente el mismo nombre serán visibles en filtros.';

  @override
  String get customCategoryHint => 'Ej. \"Corredor Madrid Norte\"';

  @override
  String get nameCannotBeEmpty => 'El nombre no puede estar vacío';

  @override
  String get customCategoryDisabled => 'Categoría personalizada desactivada';

  @override
  String get customCategorySet => 'Categoría personalizada establecida';

  @override
  String get permissionRequired => 'Autorización requerida';

  @override
  String get notificationPermissionMessage =>
      'Para recibir notificaciones, activa permisos en configuración del sistema.';

  @override
  String get locationPermissionRequired => 'Permiso de ubicación requerido';

  @override
  String get locationPermissionMessage =>
      'Para habilitar funciones GPS, permite acceso a ubicación en configuración.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'CONFIGURACIÓN';

  @override
  String get save => 'Guardar';

  @override
  String get selectCategory => 'Seleccionar categoría:';

  @override
  String get filterByCategory => 'Filtrar mensajes por categoría:';

  @override
  String get category_free => 'Libre';

  @override
  String get category_warning => 'Advertencia';

  @override
  String get category_help => 'Ayuda';

  @override
  String get category_events => 'Eventos';

  @override
  String get category_notice => 'Aviso';

  @override
  String get category_info => 'Información';

  @override
  String get category_custom => 'Personalizada';

  @override
  String get deleteConfirmTitle => '¿Eliminar mensaje?';

  @override
  String get deleteConfirmBody =>
      'Esto eliminará permanentemente tu mensaje para todos.';

  @override
  String get deleteMessage => 'Eliminar';

  @override
  String get deleted => 'Eliminado';

  @override
  String get deleteError => 'No se pudo eliminar el mensaje';

  @override
  String get tooltipDelete => 'Eliminar';
}
