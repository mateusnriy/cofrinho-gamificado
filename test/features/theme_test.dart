import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/core/providers/theme_provider.dart';
import 'package:cofrinho_digital/features/home/home_screen.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';
import 'package:cofrinho_digital/core/theme/app_theme.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('theme_test_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(GoalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DepositModelAdapter());
    }
    await Hive.openBox('settings');
    await Hive.openBox<GoalModel>('goals');
    await Hive.openBox<DepositModel>('deposits');
  });

  tearDown(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThemeNotifier Unit Tests', () {
    test('Deve inicializar com ThemeMode.system quando não há valor salvo', () {
      final container = ProviderContainer();
      final mode = container.read(themeProvider);
      expect(mode, equals(ThemeMode.system));
    });

    test('Deve restaurar ThemeMode.light quando "light" está salvo no Hive', () {
      final box = Hive.box('settings');
      box.put('theme_mode', 'light');

      final notifier = ThemeNotifier();
      expect(notifier.state, equals(ThemeMode.light));
    });

    test('Deve restaurar ThemeMode.dark quando "dark" está salvo no Hive', () {
      final box = Hive.box('settings');
      box.put('theme_mode', 'dark');

      final notifier = ThemeNotifier();
      expect(notifier.state, equals(ThemeMode.dark));
    });

    test('toggleTheme() deve alternar entre light e dark e persistir no Hive', () {
      final box = Hive.box('settings');
      final notifier = ThemeNotifier();

      // Força light
      notifier.setTheme(ThemeMode.light);
      expect(notifier.state, equals(ThemeMode.light));
      expect(box.get('theme_mode'), equals('light'));

      // Alterna para dark
      notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.dark));
      expect(box.get('theme_mode'), equals('dark'));

      // Alterna de volta para light
      notifier.toggleTheme();
      expect(notifier.state, equals(ThemeMode.light));
      expect(box.get('theme_mode'), equals('light'));
    });

    test('setTheme(ThemeMode.system) remove a chave theme_mode do Hive', () {
      final box = Hive.box('settings');
      final notifier = ThemeNotifier();

      notifier.setTheme(ThemeMode.dark);
      expect(box.get('theme_mode'), equals('dark'));

      notifier.setTheme(ThemeMode.system);
      expect(notifier.state, equals(ThemeMode.system));
      expect(box.get('theme_mode'), isNull);
    });
  });

  group('Theme Toggle Widget Tests', () {
    Widget buildHomeScreenWithTheme() {
      return ProviderScope(
        child: Consumer(
          builder: (context, ref, child) {
            final themeMode = ref.watch(themeProvider);
            return MaterialApp(
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: themeMode,
              home: const HomeScreen(),
            );
          },
        ),
      );
    }

    testWidgets('Deve exibir o botão de alternar tema no cabeçalho da HomeScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreenWithTheme());
      await tester.pumpAndSettle();

      // Verifica presença do botão de tema pelo tooltip
      final themeButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            (widget.tooltip == 'Mudar para modo escuro' ||
                widget.tooltip == 'Mudar para modo claro'),
      );
      expect(themeButton, findsOneWidget);
    });

    testWidgets(
        'Ao tocar no alternador de tema na HomeScreen, o tema deve alternar e gravar no Hive',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildHomeScreenWithTheme());
      await tester.pumpAndSettle();

      final box = Hive.box('settings');

      final themeButton = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            (widget.tooltip == 'Mudar para modo escuro' ||
                widget.tooltip == 'Mudar para modo claro'),
      );
      expect(themeButton, findsOneWidget);

      // Clica para alternar tema
      await tester.tap(themeButton);
      await tester.pumpAndSettle();

      // Verifica que o Hive gravou a nova preferência
      final savedTheme = box.get('theme_mode');
      expect(savedTheme, isNotNull);
      expect(savedTheme == 'light' || savedTheme == 'dark', isTrue);
    });
  });
}
