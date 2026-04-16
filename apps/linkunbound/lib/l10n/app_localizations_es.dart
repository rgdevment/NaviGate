// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get copyUrl => 'Copiar URL';

  @override
  String get alwaysOpenHere => 'Abrir siempre aquí';

  @override
  String get tabGeneral => 'General';

  @override
  String get tabRules => 'Reglas';

  @override
  String get tabAbout => 'Acerca de';

  @override
  String get sectionDefaultBrowser => 'NAVEGADOR PREDETERMINADO';

  @override
  String get isDefaultBrowser =>
      'LinkUnbound está configurado como navegador predeterminado';

  @override
  String get notDefaultBrowser =>
      'LinkUnbound no está configurado como navegador predeterminado';

  @override
  String get setDefault => 'Establecer';

  @override
  String get sectionStartup => 'INICIO';

  @override
  String get launchAtStartup => 'Iniciar con Windows';

  @override
  String get sectionLanguage => 'IDIOMA';

  @override
  String get languageAuto => 'Automático (sistema)';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get sectionBrowsers => 'NAVEGADORES';

  @override
  String get addBrowserTooltip => 'Añadir navegador personalizado';

  @override
  String get refreshBrowsersTooltip => 'Actualizar navegadores';

  @override
  String get menuEdit => 'Editar';

  @override
  String get menuDuplicate => 'Duplicar';

  @override
  String get menuRemove => 'Eliminar';

  @override
  String foundBrowsersCount(int count) {
    return '$count navegadores encontrados';
  }

  @override
  String get editBrowserTitle => 'Editar navegador';

  @override
  String get addBrowserTitle => 'Añadir navegador personalizado';

  @override
  String get fieldName => 'Nombre';

  @override
  String get fieldExecutablePath => 'Ruta del ejecutable';

  @override
  String get fieldExtraArgs =>
      'Argumentos adicionales (separados por espacios)';

  @override
  String get fieldIconPath => 'Ruta de icono personalizado (opcional)';

  @override
  String get fieldIconHint => 'Dejar vacío para detectar desde el ejecutable';

  @override
  String get cancel => 'Cancelar';

  @override
  String get add => 'Añadir';

  @override
  String get save => 'Guardar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get sectionUrlRules => 'REGLAS DE URL';

  @override
  String get noRulesYet =>
      'Sin reglas aún. Las reglas se crean desde el selector de navegadores al marcar \"Abrir siempre aquí\".';

  @override
  String get columnDomain => 'Dominio';

  @override
  String get columnBrowser => 'Navegador';

  @override
  String get deleteRuleTitle => 'Eliminar regla';

  @override
  String deleteRuleContent(String domain) {
    return '¿Eliminar la regla para \"$domain\"?';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteRuleTooltip => 'Eliminar regla';

  @override
  String get sectionAbout => 'ACERCA DE';

  @override
  String appVersion(String version) {
    return 'Versión $version';
  }

  @override
  String get appDescription =>
      'Selector de navegadores de código abierto para Windows.';

  @override
  String get mitLicense => 'Licencia MIT';

  @override
  String get sectionActions => 'ACCIONES';

  @override
  String get resetConfigLabel => 'Restablecer configuración';

  @override
  String get resetConfigDescription =>
      'Limpiar navegadores y reglas, luego volver a escanear';

  @override
  String get unregisterLabel => 'Desregistrar LinkUnbound';

  @override
  String get unregisterDescription =>
      'Eliminar de la lista de navegadores de Windows';

  @override
  String get resetConfigTitle => 'Restablecer configuración';

  @override
  String get resetConfigContent =>
      'Esto eliminará todos los navegadores, reglas e iconos, luego volverá a escanear los navegadores instalados. ¿Continuar?';

  @override
  String get reset => 'Restablecer';

  @override
  String get unregisterTitle => 'Desregistrar LinkUnbound';

  @override
  String get unregisterContent =>
      'Esto eliminará LinkUnbound de la lista de navegadores de Windows. Es posible que necesites cambiar tu navegador predeterminado en la Configuración de Windows después. ¿Continuar?';

  @override
  String get unregisterAction => 'Desregistrar';
}
