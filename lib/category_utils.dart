// =============================================================================
// 📦 FILE: category_utils.dart
// =============================================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
//// 🔧 Helper: nome categoria personalizzata da SharedPreferences
// =============================================================================
Future<String?> loadCustomCategoryName() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = (prefs.getString('custom_category_name') ?? '').trim();
  if (raw.isEmpty) return null;
  return raw;
}

/// Etichetta da mostrare a UI:
/// - se categoria = custom -> usa `messageCustomName` (se presente), altrimenti `prefsCustomName`.
/// - altrimenti ritorna la label standard.
String displayCategoryLabel(
  MessageCategory c, {
  String? messageCustomName,
  String? prefsCustomName,
}) {
  if (c == MessageCategory.custom) {
    final s = (messageCustomName ?? prefsCustomName ?? '').trim();
    return s.isNotEmpty ? s : 'Personalizzata';
  }
  return c.label;
}

// =============================================================================
// 🏷️ ENUM: MessageCategory
// =============================================================================
enum MessageCategory {
  free('Libero', Color(0xFF2196F3), Icons.chat),
  warning('Warning', Colors.orange, Icons.warning),
  help('Aiuto', Colors.red, Icons.help),
  event('Eventi', Colors.purple, Icons.event),
  alert('Avvisi', Colors.amber, Icons.notification_important),
  info('Info', Colors.green, Icons.info),

  // 🆕 Custom (l’etichetta effettiva la fornisce displayCategoryLabel)
  custom('Personalizzata', Color(0xFF455A64), Icons.tag);

  const MessageCategory(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

// =============================================================================
// 🧩 CategorySelector — scelta categoria invio
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
    // MOD: palette dinamica dal tema
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<String?>(
      future: loadCustomCategoryName(),
      builder: (context, snap) {
        final customName = snap.data;
        final categories = MessageCategory.values
            .where((c) =>
                c != MessageCategory.custom ||
                (customName != null && customName.isNotEmpty))
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(12, 32, 12, 16),
            decoration: BoxDecoration(
              // MOD: niente bianco fisso → surface del tema
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                // ombra leggera; in dark i temi Material3 gestiscono overlay
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.35 : 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              // MOD: bordo tenue coerente col tema
              border: Border.all(color: cs.outlineVariant, width: 1),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        // MOD: niente grigio fisso → surfaceVariant
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant, width: 1),
                      ),
                      child: Icon(Icons.close,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleziona categoria:',
                      style: TextStyle(
                        // MOD: testo sul tema
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          final isSelected = selectedCategory == category;
                          final label = displayCategoryLabel(
                            category,
                            prefsCustomName: customName,
                          );

                          // MOD: colori adattivi per il chip
                          final Color chipBg = isSelected
                              ? category.color
                              : cs.surfaceContainerHighest;
                          final Color chipBorder =
                              isSelected ? category.color : cs.outlineVariant;
                          final Color iconColor =
                              isSelected ? Colors.white : cs.onSurfaceVariant;
                          final Color textColor =
                              isSelected ? Colors.white : cs.onSurface;

                          return GestureDetector(
                            onTap: () => onCategorySelected(category),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(20),
                                border:
                                    Border.all(color: chipBorder, width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(category.icon,
                                      size: 16, color: iconColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
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
      },
    );
  }
}

// =============================================================================
// 🧩 FilterSelector — filtri multipli
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
    // MOD: palette dinamica dal tema
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return FutureBuilder<String?>(
      future: loadCustomCategoryName(),
      builder: (context, snap) {
        final customName = snap.data;
        final categories = MessageCategory.values
            .where((c) =>
                c != MessageCategory.custom ||
                (customName != null && customName.isNotEmpty))
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(12, 32, 12, 16),
            decoration: BoxDecoration(
              // MOD: niente bianco fisso → surface del tema
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(
                      theme.brightness == Brightness.dark ? 0.35 : 0.10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(color: cs.outlineVariant, width: 1),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onClose,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        // MOD: niente grigio fisso → surfaceVariant
                        color: cs.surfaceContainerHighest,
                        shape: BoxShape.circle,
                        border: Border.all(color: cs.outlineVariant, width: 1),
                      ),
                      child: Icon(Icons.close,
                          size: 18, color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filtra messaggi per categoria:',
                      style: TextStyle(
                        // MOD: testo sul tema
                        color: cs.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const spacing = 8.0;
                        final buttonWidth =
                            (constraints.maxWidth - (spacing * 2)) / 3;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: 12,
                          children: categories.map((category) {
                            final isActive = activeFilters.contains(category);
                            final label = displayCategoryLabel(
                              category,
                              prefsCustomName: customName,
                            );

                            // MOD: stile adattivo per i “bottoni” filtro
                            final bg = isActive
                                ? _blendOn(
                                    cs.surface,
                                    category.color,
                                    theme.brightness == Brightness.dark
                                        ? 0.28
                                        : 0.16)
                                : cs.surfaceContainerHighest;
                            final borderColor =
                                isActive ? category.color : cs.outlineVariant;
                            final iconColor =
                                isActive ? category.color : cs.onSurfaceVariant;
                            final textColor =
                                isActive ? category.color : cs.onSurface;

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => onFilterToggled(category),
                                child: Container(
                                  width: buttonWidth,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: bg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                        color: borderColor, width: 1.2),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(category.icon,
                                          size: 16, color: iconColor),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
      },
    );
  }

  // MOD: piccolo helper per fondere un colore “accento” con una base (surface)
  Color _blendOn(Color base, Color overlay, double opacity) {
    // ignore: deprecated_member_use
    return Color.alphaBlend(overlay.withOpacity(opacity), base);
  }
}
