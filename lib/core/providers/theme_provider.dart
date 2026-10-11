import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const _boxName = 'settings';
  static const _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  void _loadTheme() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        final savedTheme = box.get(_themeKey) as String?;

        if (savedTheme == 'light') {
          state = ThemeMode.light;
        } else if (savedTheme == 'dark') {
          state = ThemeMode.dark;
        } else {
          state = ThemeMode.system;
        }
      }
    } catch (_) {
      state = ThemeMode.system;
    }
  }

  void toggleTheme() {
    HapticFeedback.lightImpact();

    try {
      final box = Hive.box(_boxName);

      if (state == ThemeMode.dark) {
        state = ThemeMode.light;
        box.put(_themeKey, 'light');
      } else if (state == ThemeMode.light) {
        state = ThemeMode.dark;
        box.put(_themeKey, 'dark');
      } else {
        // Se estiver no automático (system), força o escuro ou claro baseando-se no atual
        final isPlatformDark =
            WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                Brightness.dark;
        if (isPlatformDark) {
          state = ThemeMode.light;
          box.put(_themeKey, 'light');
        } else {
          state = ThemeMode.dark;
          box.put(_themeKey, 'dark');
        }
      }
    } catch (_) {
      // Fallback em caso de caixa não aberta
      if (state == ThemeMode.dark) {
        state = ThemeMode.light;
      } else {
        state = ThemeMode.dark;
      }
    }
  }

  void setTheme(ThemeMode mode) {
    HapticFeedback.lightImpact();
    state = mode;

    try {
      final box = Hive.box(_boxName);
      if (mode == ThemeMode.light) {
        box.put(_themeKey, 'light');
      } else if (mode == ThemeMode.dark) {
        box.put(_themeKey, 'dark');
      } else {
        box.delete(_themeKey);
      }
    } catch (_) {}
  }

  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});
