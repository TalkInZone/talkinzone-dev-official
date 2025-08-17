import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/category_utils.dart';

class TextComposer extends StatelessWidget {
  final MessageCategory category;
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onToggleCategory;

  const TextComposer({
    super.key,
    required this.category,
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onToggleCategory,
  });

  @override
  Widget build(BuildContext context) {
    final canSend = controller.text.trim().isNotEmpty &&
        controller.text.characters.length <= 250 &&
        !isSending;

    return SafeArea(
      top: false,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onToggleCategory();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                // ignore: deprecated_member_use
                color: category.color.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: category.color, width: 2),
              ),
              child: Icon(category.icon, color: category.color, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 250,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Scrivi (max 250)…',
                counterText: '',
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) {
                if (canSend) onSend();
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: FilledButton(
              onPressed: canSend
                  ? () {
                      HapticFeedback.lightImpact();
                      onSend();
                    }
                  : null,
              style: FilledButton.styleFrom(shape: const CircleBorder()),
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.send),
            ),
          ),
        ],
      ),
    );
  }
}
