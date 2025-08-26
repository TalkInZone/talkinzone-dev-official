// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get relNow => 'agora';

  @override
  String relMinutesAgo(int count) {
    return 'há $count min';
  }

  @override
  String relHoursAgo(int count) {
    return 'há $count h';
  }

  @override
  String get distVeryClose => 'muito perto';

  @override
  String get distClose => 'perto';

  @override
  String get distInArea => 'na sua área';

  @override
  String get distFar => 'longe';

  @override
  String get distVeryFar => 'muito longe';

  @override
  String get unitM => 'm';

  @override
  String get unitKm => 'km';

  @override
  String get reactionsTitle => 'Reações';

  @override
  String get close => 'Fechar';

  @override
  String get you => 'Você';

  @override
  String get anonymous => 'Anônimo';

  @override
  String get tooltipSettings => 'Configurações';

  @override
  String get tooltipFilters => 'Filtros';

  @override
  String get tooltipRadius => 'Raio';

  @override
  String get tooltipProfile => 'Perfil';

  @override
  String get tooltipReactions => 'Adicionar reação';

  @override
  String get noMessagesInArea => 'Ainda não há mensagens nesta área.';

  @override
  String get newLabel => 'NOVO';

  @override
  String get composerHint => 'Escreva uma mensagem curta (opcional)…';

  @override
  String get welcomeTitle => 'Bem-vindo!';

  @override
  String get welcomeSubtitle =>
      'Para começar, faça login com sua conta do Google';

  @override
  String get welcomeBody =>
      'Deixe notas de voz ou textos curtos para pessoas próximas. As mensagens se autodestroem após alguns minutos.';

  @override
  String get understood => 'Entendi';

  @override
  String get mustBeAuthenticatedToBlock =>
      'Você deve estar autenticado para bloquear usuários.';

  @override
  String get cannotBlockYourself => 'Você não pode bloquear a si mesmo.';

  @override
  String get invalidUserIdToBlock => 'ID de usuário inválido.';

  @override
  String get blockIgnoreTitle => 'Bloquear usuário';

  @override
  String get blockIgnoreTitleShort => 'Bloquear usuário';

  @override
  String get blockIgnoreSubtitle =>
      'Você não verá mais mensagens deste usuário.';

  @override
  String blockConfirmText(String name) {
    return 'Bloquear $name? Você não verá mais as mensagens dele(a).';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get block => 'Bloquear';

  @override
  String get userBlockedSimple => 'Usuário bloqueado.';

  @override
  String get blockError => 'Não foi possível bloquear o usuário';

  @override
  String get reportUserTitle => 'Denunciar usuário';

  @override
  String get reportUserTitleShort => 'Denunciar usuário';

  @override
  String get reportUserSubtitle => 'Envie um relatório aos moderadores.';

  @override
  String get reportDescribeOptional => 'Descreva o problema (opcional)';

  @override
  String get reportReasonHint => 'Motivo…';

  @override
  String get send => 'Enviar';

  @override
  String get reportSentThanks => 'Obrigado, sua denúncia foi enviada.';

  @override
  String get reportNotSent => 'Denúncia não enviada';

  @override
  String get cannotReportYourself => 'Você não pode se denunciar.';

  @override
  String get operationNotAllowed => 'Operação não permitida.';

  @override
  String get loginFailed => 'Falha no login. Tente novamente.';

  @override
  String get signInWithGoogle => 'Entrar com Google';

  @override
  String get customCategoryWarning =>
      'Defina o nome da categoria personalizada em Configurações.';

  @override
  String get invalidOperation => 'Operação inválida.';

  @override
  String get userBlocked => 'Usuário bloqueado.';

  @override
  String get yourAccount => 'Sua conta';

  @override
  String get userId => 'ID do usuário:';

  @override
  String get noId => 'Sem ID';

  @override
  String get name => 'Nome:';

  @override
  String get noName => 'Sem nome';

  @override
  String get email => 'Email:';

  @override
  String get noEmail => 'Sem email';

  @override
  String get provider => 'Provedor:';

  @override
  String get logout => 'Sair';

  @override
  String get ageGateTitle => 'Complete seu perfil';

  @override
  String ageGateSubtitle(int years) {
    return 'Para continuar usando o TalkInZone, você deve indicar sua data de nascimento (idade mínima: $years anos).';
  }

  @override
  String get birthDate => 'Data de nascimento';

  @override
  String get selectDate => 'Selecionar data';

  @override
  String get selectBirthDate => 'Selecione sua data de nascimento';

  @override
  String get truthDeclaration =>
      'Declaro que os dados fornecidos são verídicos.';

  @override
  String get falseWarning =>
      'Atenção: declarações falsas podem resultar na suspensão da conta.';

  @override
  String get confirmAndContinue => 'Confirmar e continuar';

  @override
  String get missingDate => 'Selecione uma data de nascimento.';

  @override
  String tooYoung(int years) {
    return 'Você deve ter pelo menos $years anos para usar o aplicativo.';
  }

  @override
  String get mustAccept =>
      'Você deve confirmar que os dados fornecidos são verídicos.';

  @override
  String get genericError => 'Ocorreu um erro. Por favor, tente novamente.';

  @override
  String maxCharsError(int count) {
    return 'Máx. $count caracteres';
  }

  @override
  String get blockUser => 'Bloquear usuário';

  @override
  String get blockUserConfirmation =>
      'Você realmente quer bloquear este usuário?\n\n• Você não verá mais nenhuma mensagem dele(a)\n• Ele(a) não verá mais nenhuma mensagem sua';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get themeLabel => 'Tema';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get notificationsLabel => 'Notificações';

  @override
  String get gpsManagement => 'Gerenciamento GPS';

  @override
  String get customCategory => 'Categoria personalizada';

  @override
  String get blockedUsers => 'Usuários bloqueados';

  @override
  String get appVersion => 'Versão do App';

  @override
  String get enableNotifications => 'Ativar notificações';

  @override
  String get notificationSound => 'Som de notificação';

  @override
  String get backgroundExecution => 'Execução em segundo plano';

  @override
  String get enableLocation => 'Ativar acesso à localização';

  @override
  String get customCategoryName => 'Nome da categoria personalizada';

  @override
  String get noBlockedUsers => 'Nenhum usuário bloqueado';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get lightTheme => 'Claro';

  @override
  String get darkTheme => 'Escuro';

  @override
  String get greyTheme => 'Cinza';

  @override
  String get greyThemeDescription => 'Paleta neutra claro/escuro';

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
  String get authorizationGranted => 'Autorização concedida';

  @override
  String get requestAuthorization => 'Solicitar autorização';

  @override
  String get notificationSoundDescription =>
      'Reproduzir som ao chegar nova mensagem';

  @override
  String get batteryOptimizationDisabled => 'Otimização de bateria desativada';

  @override
  String get batteryOptimizationWarning =>
      'O app pode não receber notificações em segundo plano';

  @override
  String get locationAccessEnabled => 'Acesso à localização ativado';

  @override
  String get requestGpsAuthorization => 'Solicitar autorização GPS';

  @override
  String get noCategorySet => 'Nenhuma — toque para definir';

  @override
  String get activeCategory => 'Ativa';

  @override
  String get remove => 'Remover';

  @override
  String get edit => 'Editar';

  @override
  String get customCategoryDialogTitle => 'Categoria personalizada';

  @override
  String get customCategoryDialogDescription =>
      'Defina o nome da sua categoria personalizada. Apenas mensagens com exatamente o mesmo nome serão visíveis nos filtros.';

  @override
  String get customCategoryHint => 'Ex. \"Corredor São Paulo Norte\"';

  @override
  String get nameCannotBeEmpty => 'O nome não pode estar vazio';

  @override
  String get customCategoryDisabled => 'Categoria personalizada desativada';

  @override
  String get customCategorySet => 'Categoria personalizada definida';

  @override
  String get permissionRequired => 'Autorização necessária';

  @override
  String get notificationPermissionMessage =>
      'Para receber notificações, ative as permissões nas configurações do sistema.';

  @override
  String get locationPermissionRequired =>
      'Permissão de localização necessária';

  @override
  String get locationPermissionMessage =>
      'Para ativar as funções GPS, permita o acesso à localização nas configurações.';

  @override
  String get ok => 'OK';

  @override
  String get settings => 'CONFIGURAÇÕES';

  @override
  String get save => 'Salvar';

  @override
  String get category_free => 'Livre';

  @override
  String get category_warning => 'Aviso';

  @override
  String get category_help => 'Ajuda';

  @override
  String get category_events => 'Eventos';

  @override
  String get category_notice => 'Aviso';

  @override
  String get category_info => 'Informação';

  @override
  String get category_custom => 'Personalizada';
}
