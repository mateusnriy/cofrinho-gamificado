import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../core/providers/theme_provider.dart';
import '../features/splash/splash_screen.dart';

class CofrinhoApp extends ConsumerWidget {
  const CofrinhoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Oinc — Meu cofrinho virtual',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Garante escala de texto segura para acessibilidade sem quebrar cards estreitos
        final clampedScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.30,
        );
        final content = MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedScaler),
          child: child ?? const SizedBox.shrink(),
        );

        // Em telas amplas (tablets/desktop/web > 540px), centraliza em um shell mobile de 480px
        if (mediaQuery.size.width > 540) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return ColoredBox(
            color: isDark ? const Color(0xFF06110A) : const Color(0xFFDCE5DC),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: ClipRect(child: content),
              ),
            ),
          );
        }
        return content;
      },
      home: const SplashScreen(),
    );
  }
}
