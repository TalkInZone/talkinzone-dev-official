import 'package:flutter/material.dart';
import '../theme_controller.dart';

/// Selettore pronto da inserire nella pagina Impostazioni
/// (o ovunque ti sia comodo).
class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = ThemeController.instance;
    final mode = ctl.mode;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Tema'),
              subtitle: Text('Scegli come appare l’app'),
              leading: Icon(Icons.brightness_6_outlined),
            ),
            const SizedBox(height: 4),
            RadioListTile<ThemeMode>(
              value: ThemeMode.system,
              groupValue: mode,
              onChanged: (m) => ctl.setMode(m ?? ThemeMode.system),
              title: const Text('Sistema'),
              subtitle: const Text('Segui il tema del dispositivo'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.light,
              groupValue: mode,
              onChanged: (m) => ctl.setMode(m ?? ThemeMode.light),
              title: const Text('Chiaro'),
            ),
            RadioListTile<ThemeMode>(
              value: ThemeMode.dark,
              groupValue: mode,
              onChanged: (m) => ctl.setMode(m ?? ThemeMode.dark),
              title: const Text('Scuro'),
            ),
          ],
        ),
      ),
    );
  }
}
