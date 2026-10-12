import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cofrinho_digital/features/onboarding/onboarding_screen.dart';
import 'package:cofrinho_digital/data/models/goal_model.dart';
import 'package:cofrinho_digital/data/models/deposit_model.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('onboarding_test_');
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
    await Hive.openBox('gamification');
    await Hive.openBox('wallet');
    await Hive.openBox('mascot_box');
  });

  tearDown(() async {
    try {
      await Hive.close().timeout(const Duration(milliseconds: 200), onTimeout: () => null);
    } catch (_) {}
    try {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  testWidgets('Deve exibir elementos visuais do Onboarding e mascote Porko',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Valida título e subtítulo com o branding Oinc
    expect(find.textContaining('Bem-vindo ao Oinc!'), findsOneWidget);
    expect(find.text('Oinc — Meu cofrinho virtual'), findsOneWidget);

    // Valida os 3 benefícios centrais
    expect(find.text('Metas com Propósito'), findsOneWidget);
    expect(find.text('Projeções Inteligentes'), findsOneWidget);
    expect(find.text('Gamificação & Recompensas'), findsOneWidget);

    // Valida botões de ação
    expect(find.text('Criar Primeira Meta'), findsOneWidget);
    expect(find.text('Explorar o aplicativo primeiro'), findsOneWidget);

    // Valida ícone do mascote
    expect(find.byIcon(Icons.savings_rounded), findsOneWidget);
  });

  testWidgets(
      'Ao tocar em "Criar Primeira Meta", deve gravar has_seen_onboarding = true',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final settingsBox = Hive.box('settings');
    expect(settingsBox.get('has_seen_onboarding', defaultValue: false), isFalse);

    // Clica no botão primário
    final ctaButton = find.text('Criar Primeira Meta');
    expect(ctaButton, findsOneWidget);
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();

    // Verifica que a flag foi persistida
    expect(settingsBox.get('has_seen_onboarding'), isTrue);
  });

  testWidgets(
      'Ao tocar em "Explorar o aplicativo primeiro", deve gravar has_seen_onboarding = true',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    final settingsBox = Hive.box('settings');
    expect(settingsBox.get('has_seen_onboarding', defaultValue: false), isFalse);

    // Clica no botão secundário
    final exploreButton = find.text('Explorar o aplicativo primeiro');
    expect(exploreButton, findsOneWidget);
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    // Verifica que a flag foi persistida
    expect(settingsBox.get('has_seen_onboarding'), isTrue);
  });
}
