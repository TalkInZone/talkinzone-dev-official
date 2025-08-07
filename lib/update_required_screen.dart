// ███████████████████████████████████████
// ███ UPDATE_REQUIRED_SCREEN WIDGET ███
// ███████████████████████████████████████
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      home: Scaffold(
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
                // 🧩 ICONA VISIVA
                // ↪️ Funzione: Comunicare il concetto di aggiornamento
                // ⚡ Input: Icona system_update, dimensione 80, colore blu
                // 📤 Output: Elemento grafico immediatamente riconoscibile
                // 🔄 Logica: Utilizza un'icona standard per chiarezza
                const Icon(Icons.system_update, size: 80, color: Colors.blue),
                const SizedBox(height: 30),

                // ════════════════════════════════════════
                // 🎯 TITLE SECTION
                // ════════════════════════════════════════
                // 🧩 TITOLO PRINCIPALE
                // ↪️ Funzione: Comunicare l'urgenza dell'azione
                // ⚡ Input: Testo in grassetto 24px
                // 📤 Output: Messaggio prominente
                // 🔄 Logica: Enfatizza la natura obbligatoria dell'aggiornamento
                const Text(
                  'Aggiornamento richiesto',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),

                // ════════════════════════════════════════
                // 🎯 DESCRIPTION SECTION
                // ════════════════════════════════════════
                // 🧩 PRIMA RIGA DESCRIZIONE
                // ↪️ Funzione: Spiegare la situazione corrente
                // ⚡ Input: Testo centrato 16px
                // 📤 Output: Informazione chiara sullo stato dell'app
                // 🔄 Logica: Comunica il problema senza tecnicismi
                const Text(
                  'La versione attuale dell\'applicazione è obsoleta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 10),

                // 🧩 SECONDA RIGA DESCRIZIONE
                // ↪️ Funzione: Istruire l'utente sull'azione necessaria
                // ⚡ Input: Testo centrato con colore attenuato
                // 📤 Output: Guida all'operazione da compiere
                // 🔄 Logica: Indica chiaramente la soluzione (scaricare dallo store)
                const Text(
                  'Per continuare a utilizzare l\'app, scarica l\'ultima versione disponibile dallo store.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 40),

                // ════════════════════════════════════════
                // 🎯 VERSION INFO SECTION
                // ════════════════════════════════════════
                // 🧩 INDICAZIONE VERSIONE
                // ↪️ Funzione: Mostrare la versione corrente
                // ⚡ Input: Testo in stile corsivo
                // 📤 Output: Riferimento chiaro per l'utente
                // 🔄 Logica: Aiuta l'utente a confrontare le versioni
                const Text(
                  'Versione attuale: 0.4',
                  style: TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 30),

                // ════════════════════════════════════════
                // 🎯 EXIT BUTTON SECTION
                // ════════════════════════════════════════
                // 🧩 BOTTONE CHIUSURA
                // ↪️ Funzione: Uscita forzata dall'applicazione
                // ⚡ Input: Stile personalizzato con padding
                // 📤 Output: Interazione primaria per l'utente
                // 🔄 Logica: Termina l'app con SystemNavigator.pop()
                // 💥 Side Effect: Chiusura immediata dell'app
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
      ),
    );
  }
}
