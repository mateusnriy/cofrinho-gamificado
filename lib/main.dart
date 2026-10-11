import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'data/models/goal_model.dart';
import 'data/models/deposit_model.dart';
import 'core/utils/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Hive.initFlutter();
  Hive.registerAdapter(GoalModelAdapter());
  Hive.registerAdapter(DepositModelAdapter());

  // CORREÇÃO: Abre todos os bancos de dados antes de desenhar a interface
  await Hive.openBox('settings');
  await Hive.openBox<GoalModel>('goals');
  await Hive.openBox<DepositModel>('deposits');
  await Hive.openBox('gamification');
  await Hive.openBox('wallet');

  await NotificationService().initialize();

  runApp(
    const ProviderScope(
      child: CofrinhoApp(),
    ),
  );
}
