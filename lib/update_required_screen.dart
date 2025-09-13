// ███████████████████████████████████████
// ███ UPDATE_REQUIRED_SCREEN WIDGET ███
// ███████████████████████████████████████
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'gen_l10n/app_localizations.dart';

/// Schermata di aggiornamento obbligatorio
///
/// Mostrata quando l'app rileva una versione obsoleta.
/// Informa l'utente che deve aggiornare l'applicazione
/// per continuare a utilizzarla, fornendo:
/// - Icona visivamente riconoscibile
/// - Messaggio esplicativo
/// - Versione corrente
/// - Bottone per uscire dall'app
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ════════════════════════════════════════
    // 🎯 ROOT WIDGET STRUCTURE
    // ════════════════════════════════════════
    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (ctx) {
          final l10n = AppLocalizations.of(ctx);

          return Scaffold(
            body: Container(
              // 🧩 CONTENITORE PRINCIPALE
              // ↪️ Funzione: Definisce lo sfondo e il padding
              // ⚡ Input: Colore bianco e padding 40px
              // 📤 Output: Area visuale con spaziatura uniforme
              // 🔄 Logica: Crea un contenitore responsive con sfondo neutro
              color: Colors.white,
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ════════════════════════════════════════
                    // 🎯 UPDATE ICON SECTION
                    // ════════════════════════════════════════
                    const Icon(Icons.system_update,
                        size: 80, color: Colors.blue),
                    const SizedBox(height: 30),

                    // ════════════════════════════════════════
                    // 🎯 TITLE SECTION
                    // ════════════════════════════════════════
                    Text(
                      l10n.updateRequiredTitle,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ════════════════════════════════════════
                    // 🎯 DESCRIPTION SECTION
                    // ════════════════════════════════════════
                    Text(
                      l10n.updateRequiredOutdated,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      l10n.updateRequiredInstruction,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    const SizedBox(height: 40),

                    // ════════════════════════════════════════
                    // 🎯 VERSION INFO SECTION
                    // ════════════════════════════════════════
                    Text(
                      '${l10n.updateRequiredCurrentVersion} 0.5',
                      style: const TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ════════════════════════════════════════
                    // 🎯 EXIT BUTTON SECTION
                    // ════════════════════════════════════════
                    ElevatedButton(
                      onPressed: () => SystemNavigator.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text(
                        'ESCI',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
