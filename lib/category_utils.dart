// =============================================================================
// 📦 FILE: category_utils.dart
// =============================================================================
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// =============================================================================
// 🔧 Helper: nome categoria personalizzata da SharedPreferences
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seleziona categoria:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                          return GestureDetector(
                            onTap: () => onCategorySelected(category),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    isSelected ? category.color : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: category.color,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.icon,
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : category.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filtra messaggi per categoria:',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => onFilterToggled(category),
                                child: Container(
                                  width: buttonWidth,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? category.color.withAlpha(51)
                                        : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isActive
                                          ? category.color
                                          : Colors.grey[300]!,
                                      width: isActive ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        category.icon,
                                        size: 16,
                                        color: isActive
                                            ? category.color
                                            : Colors.grey[600],
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          label,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w500,
                                            color: isActive
                                                ? category.color
                                                : Colors.grey[700],
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
}
