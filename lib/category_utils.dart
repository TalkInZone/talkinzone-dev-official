// =============================================================================
// 📦 FILE: category_utils.dart
// =============================================================================
import 'package:flutter/material.dart';

// =============================================================================
// 🏷️ ENUM: MessageCategory
// =============================================================================
// 🌈 Categorie di messaggi con proprietà grafiche associate
// 🔸 Ogni categoria ha etichetta, colore e icona distintiva
// 🔸 Utilizzato per classificare messaggi nell'interfaccia
// =============================================================================
enum MessageCategory {
  free('Libero', Color(0xFF2196F3), Icons.chat),
  warning('Warning', Colors.orange, Icons.warning),
  help('Aiuto', Colors.red, Icons.help),
  event('Eventi', Colors.purple, Icons.event),
  alert('Avvisi', Colors.amber, Icons.notification_important),
  info('Info', Colors.green, Icons.info);

  const MessageCategory(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

// =============================================================================
// 🧩 WIDGET: CategorySelector
// =============================================================================
// 🎯 Scopo: Selezionare una singola categoria tra quelle disponibili
// 💡 Funzionalità:
//    - Visualizza tutte le categorie come pulsanti orizzontali
//    - Highlight sulla categoria selezionata
//    - Pulsante di chiusura in alto a destra
// =============================================================================
class CategorySelector extends StatelessWidget {
  final MessageCategory selectedCategory;
  final ValueChanged<MessageCategory> onCategorySelected;
  final VoidCallback onClose;

  const CategorySelector({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // 🏗️ 1. STRUTTURA PRINCIPALE
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(12, 32, 12, 16),

        // 🎨 1.1 STILE CONTENITORE
        // 💄 Effetto card con ombra e bordi arrotondati
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        // 🔣 2. CONTENUTO IMPILATO
        child: Stack(
          children: [
            // ⨯ 2.1 PULSANTE CHIUDI
            // 🔘 Interazione: Richiama onClose al tap
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            ),

            // 📋 2.2 CORPO PRINCIPALE
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✏️ 2.2.1 TITOLO
                const Text(
                  'Seleziona categoria:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // 🎚️ 2.2.2 SELEZIONE CATEGORIE
                // 🔄 Scroll orizzontale per molte categorie
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        MessageCategory.values.map((category) {
                          // ✅ 2.2.2.1 CHECK SELEZIONE
                          final isSelected = selectedCategory == category;

                          return GestureDetector(
                            onTap: () => onCategorySelected(category),

                            // 🖌️ 2.2.2.2 STILE DINAMICO
                            // 💡 Cambia colore in base alla selezione
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? category.color : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: category.color,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),

                              // 🧩 2.2.2.3 CONTENUTO PULSANTE
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 🟦 2.2.2.4 ICONA
                                  Icon(
                                    category.icon,
                                    size: 16,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : category.color,
                                  ),
                                  const SizedBox(width: 4),

                                  // 🔤 2.2.2.5 ETICHETTA
                                  Text(
                                    category.label,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : category.color,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 🧩 WIDGET: FilterSelector
// =============================================================================
// 🎯 Scopo: Abilitare/disabilitare filtri multipli per categoria
// 💡 Funzionalità:
//    - Griglia responsive di chip selezionabili
//    - Visualizzazione stato attivo/inattivo
//    - Pulsante di chiusura
// =============================================================================
class FilterSelector extends StatelessWidget {
  final Set<MessageCategory> activeFilters;
  final ValueChanged<MessageCategory> onFilterToggled;
  final VoidCallback onClose;

  const FilterSelector({
    super.key,
    required this.activeFilters,
    required this.onFilterToggled,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(12, 32, 12, 16),

        // 🎨 1. STILE CONTENITORE (uguale a CategorySelector)
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),

        child: Stack(
          children: [
            // ⨯ 1.1 PULSANTE CHIUDI (stesso funzionamento)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16),
                ),
              ),
            ),

            // 📋 2. CORPO PRINCIPALE
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✏️ 2.1 TITOLO
                const Text(
                  'Filtra messaggi per categoria:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // 📐 2.2 LAYOUT ADATTIVO
                // 🌐 Calcola dimensione pulsanti in base allo spazio
                LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    final buttonWidth =
                        (constraints.maxWidth - (spacing * 2)) / 3;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 12,
                      children:
                          MessageCategory.values.map((category) {
                            // ✅ 2.2.1 CHECK FILTRO ATTIVO
                            final isActive = activeFilters.contains(category);

                            return Material(
                              color: Colors.transparent,

                              // 🖱️ 2.2.2 GESTIONE INTERAZIONE
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => onFilterToggled(category),

                                // 🎨 2.2.3 STILE DINAMICO CHIP
                                child: Container(
                                  width: buttonWidth,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isActive
                                            ? category.color.withAlpha(
                                              51,
                                            ) // 😶‍🌫️ Colore con trasparenza
                                            : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color:
                                          isActive
                                              ? category.color
                                              : Colors.grey[300]!,
                                      width: isActive ? 1.5 : 1,
                                    ),
                                  ),

                                  // 🧩 2.2.4 CONTENUTO CHIP
                                  child: Row(
                                    children: [
                                      // 🟦 ICONA CATEGORIA
                                      Icon(
                                        category.icon,
                                        size: 16,
                                        color:
                                            isActive
                                                ? category.color
                                                : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),

                                      // 🔤 ETICHETTA CATEGORIA
                                      Expanded(
                                        child: Text(
                                          category.label,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isActive
                                                    ? category.color
                                                    : Colors.grey[700],
                                          ),
                                          overflow:
                                              TextOverflow
                                                  .ellipsis, // 💬 Testo troncato con ellissi
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
