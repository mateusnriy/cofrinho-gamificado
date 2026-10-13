import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/providers/global_providers.dart';
import '../../core/providers/theme_provider.dart';
import '../../data/models/deposit_model.dart';
import '../../data/models/goal_model.dart';
import '../mascot/mascot_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// Central completa de Perfil e Configurações do Usuário (7 seções — Story 6.6 / AUD-08).
class ProfileSettingsModal extends ConsumerStatefulWidget {
  const ProfileSettingsModal({super.key});

  @override
  ConsumerState<ProfileSettingsModal> createState() =>
      _ProfileSettingsModalState();
}

class _ProfileSettingsModalState extends ConsumerState<ProfileSettingsModal> {
  static const List<String> _avatars = [
    '🐷',
    '🦊',
    '🐼',
    '🦁',
    '🐸',
    '🦄',
    '🐱',
    '🐶',
  ];

  Box get _settingsBox => Hive.box('settings');

  String get _userName =>
      (_settingsBox.get('user_name') as String?)?.trim().isNotEmpty == true
          ? (_settingsBox.get('user_name') as String)
          : 'Poupador Oinc';

  String get _userAvatar =>
      (_settingsBox.get('user_avatar') as String?) ?? '🐷';

  bool _getBool(String key, {bool defaultValue = false}) {
    return (_settingsBox.get(key) as bool?) ?? defaultValue;
  }

  String _getString(String key, {String defaultValue = ''}) {
    return (_settingsBox.get(key) as String?) ?? defaultValue;
  }

  Future<void> _setSetting(String key, dynamic value) async {
    HapticFeedback.selectionClick();
    await _settingsBox.put(key, value);
    if (mounted) setState(() {});
  }

  void _openEditProfileDialog(BuildContext context, bool isDark) {
    final controller = TextEditingController(text: _userName);
    String selectedAvatar = _userAvatar;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1B2E22) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Editar Perfil',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escolha seu avatar:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _avatars.map((emoji) {
                    final isSel = emoji == selectedAvatar;
                    return InkWell(
                      onTap: () => setModalState(() => selectedAvatar = emoji),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSel
                              ? const Color(0xFF2E7D32).withValues(alpha: 0.2)
                              : (isDark
                                  ? const Color(0xFF243B2A)
                                  : const Color(0xFFEEF3EE)),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel
                                ? const Color(0xFF2E7D32)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Seu nome ou apelido:',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Ex: Mateus, Poupador...',
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF243B2A)
                        : const Color(0xFFEEF3EE),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = controller.text.trim();
                await _settingsBox.put(
                  'user_name',
                  newName.isEmpty ? 'Poupador Oinc' : newName,
                );
                await _settingsBox.put('user_avatar', selectedAvatar);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Salvar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackupJson(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final goals = ref.read(goalRepositoryProvider).getAll();
    final depositsBox = Hive.box<DepositModel>('deposits');
    final allDeposits = depositsBox.values.toList();
    final walletBalance = ref.read(walletBalanceProvider);
    final mascot = ref.read(mascotRepositoryProvider).getMascot();

    final payload = {
      'app': 'Oinc — Meu cofrinho virtual',
      'version': '3.2.0',
      'exportedAt': DateTime.now().toIso8601String(),
      'user': {
        'name': _userName,
        'avatar': _userAvatar,
      },
      'walletBalance': walletBalance,
      'mascot': mascot.toMap(),
      'goals': goals
          .map(
            (g) => {
              'id': g.id,
              'name': g.name,
              'targetAmount': g.targetAmount,
              'savedAmount': g.savedAmount,
              'deadline': g.deadline?.toIso8601String(),
              'iconCodePoint': g.iconCodePoint,
              'colorValue': g.colorValue,
              'note': g.note,
              'createdAt': g.createdAt.toIso8601String(),
              'isArchived': g.isArchived,
              'reminderTime': g.reminderTime,
              'rhythm': g.rhythm,
            },
          )
          .toList(),
      'deposits': allDeposits
          .map(
            (d) => {
              'id': d.id,
              'goalId': d.goalId,
              'amount': d.amount,
              'date': d.date.toIso8601String(),
              'note': d.note,
            },
          )
          .toList(),
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '📤 Backup JSON copiado para a área de transferência!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2E7D32),
      ),
    );
  }

  void _openImportBackupDialog(BuildContext context, bool isDark) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2E22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '📥 Restaurar Backup JSON',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cole abaixo o conteúdo JSON exportado anteriormente:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '{ "app": "Oinc...", "goals": [...] }',
                filled: true,
                fillColor:
                    isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final raw = controller.text.trim();
              if (raw.isEmpty) return;
              try {
                final decoded = jsonDecode(raw) as Map<String, dynamic>;
                final goalsList = (decoded['goals'] as List?) ?? [];
                final goalRepo = ref.read(goalRepositoryProvider);
                for (final item in goalsList) {
                  if (item is Map) {
                    final g = GoalModel(
                      id: item['id']?.toString() ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: item['name']?.toString() ?? 'Meta Importada',
                      targetAmount:
                          (item['targetAmount'] as num?)?.toDouble() ?? 100.0,
                      savedAmount:
                          (item['savedAmount'] as num?)?.toDouble() ?? 0.0,
                      deadline: item['deadline'] != null
                          ? DateTime.tryParse(item['deadline'].toString())
                          : null,
                      iconCodePoint:
                          (item['iconCodePoint'] as int?) ?? 0xe57f,
                      colorValue:
                          (item['colorValue'] as int?) ?? 0xFF2E7D32,
                      note: item['note']?.toString(),
                      createdAt: item['createdAt'] != null
                          ? (DateTime.tryParse(item['createdAt'].toString()) ??
                              DateTime.now())
                          : DateTime.now(),
                      isArchived: (item['isArchived'] as bool?) ?? false,
                      reminderTime: item['reminderTime']?.toString(),
                      rhythm: item['rhythm']?.toString() ?? 'weekly',
                    );
                    await goalRepo.save(g);
                  }
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✅ Backup restaurado com sucesso!'),
                      backgroundColor: Color(0xFF2E7D32),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        '❌ Formato JSON inválido. Verifique os dados colados.',
                      ),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
            ),
            child: const Text(
              'Restaurar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmResetAllData(BuildContext context, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1B2E22) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          '⚠️ Apagar todos os dados?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Esta ação removerá todas as suas metas, histórico de depósitos, conquistas e itens comprados neste aparelho. Deseja realmente zerar o aplicativo?',
          style: TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'Sim, zerar tudo',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      HapticFeedback.heavyImpact();
      await Hive.box<GoalModel>('goals').clear();
      await Hive.box<DepositModel>('deposits').clear();
      if (Hive.isBoxOpen('wallet')) await Hive.box('wallet').clear();
      if (Hive.isBoxOpen('gamification')) await Hive.box('gamification').clear();
      if (Hive.isBoxOpen('badges')) await Hive.box('badges').clear();
      if (Hive.isBoxOpen('mascot_box')) await Hive.box('mascot_box').clear();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧹 Todos os dados locais foram reiniciados.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final mascot = ref.watch(equippedMascotProvider);
    final walletBalance = ref.watch(walletBalanceProvider);
    final streakData = ref.watch(streakProvider);
    final currentStreak = (streakData['currentStreak'] as int?) ?? 0;

    final highContrast = _getBool('high_contrast', defaultValue: false);
    final reduceMotion = _getBool('reduce_motion', defaultValue: false);
    final dailyReminder = _getBool('daily_reminder_enabled', defaultValue: true);
    final reminderTime = _getString('daily_reminder_time', defaultValue: '20:00');
    final streakAlert = _getBool('streak_alert_enabled', defaultValue: true);
    final hapticsEnabled = _getBool('haptics_enabled', defaultValue: true);
    final soundEnabled = _getBool('sound_effects_enabled', defaultValue: true);
    final hideBalanceDefault =
        _getBool('hide_balance_by_default', defaultValue: true);
    final defaultRhythm = _getString('default_rhythm', defaultValue: 'weekly');

    final maxModalHeight = MediaQuery.of(context).size.height * 0.88;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⚙️ Perfil e Configurações',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 22),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            const Divider(height: 12),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Perfil do Poupador ─────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1B2E22)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF2F4A37)
                              : const Color(0xFFE2E8E2),
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () =>
                                _openEditProfileDialog(context, isDark),
                            child: CircleAvatar(
                              radius: 28,
                              backgroundColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.15),
                              child: Text(
                                _userAvatar,
                                style: const TextStyle(fontSize: 28),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '🪙 $walletBalance moedas • 🔥 $currentStreak dias seguidos',
                                  style: TextStyle(
                                    fontFamily: 'Nunito',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFFA5D6A7)
                                        : const Color(0xFF566259),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                _openEditProfileDialog(context, isDark),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text(
                              'Editar',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── 2. Tema Visual e Acessibilidade ──────────────────────
                    _buildSectionTitle('🎨 Tema Visual e Acessibilidade'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildThemeChoice(
                            label: 'Auto',
                            icon: Icons.brightness_auto_rounded,
                            isSelected: themeMode == ThemeMode.system,
                            onTap: () => ref
                                .read(themeProvider.notifier)
                                .setTheme(ThemeMode.system),
                            context: context,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeChoice(
                            label: 'Claro',
                            icon: Icons.light_mode_rounded,
                            isSelected: themeMode == ThemeMode.light,
                            onTap: () => ref
                                .read(themeProvider.notifier)
                                .setTheme(ThemeMode.light),
                            context: context,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildThemeChoice(
                            label: 'Escuro',
                            icon: Icons.dark_mode_rounded,
                            isSelected: themeMode == ThemeMode.dark,
                            onTap: () => ref
                                .read(themeProvider.notifier)
                                .setTheme(ThemeMode.dark),
                            context: context,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark: isDark,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: highContrast,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            'Alto Contraste Visual (WCAG AA)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Reforça bordas e legibilidade de textos',
                            style: TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) => _setSetting('high_contrast', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: reduceMotion,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            'Reduzir Animações e Movimento',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Suaviza confetes e transições de tela',
                            style: TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) => _setSetting('reduce_motion', val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── 3. Notificações e Lembretes ──────────────────────────
                    _buildSectionTitle('🔔 Notificações e Lembretes'),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark: isDark,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: dailyReminder,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            'Lembrete Diário de Economia',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: Text(
                            dailyReminder
                                ? 'Ativo todos os dias às $reminderTime'
                                : 'Desativado',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) =>
                              _setSetting('daily_reminder_enabled', val),
                        ),
                        if (dailyReminder) ...[
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                            ),
                            leading: const Icon(
                              Icons.schedule_rounded,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                            title: const Text(
                              'Horário do Lembrete',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32)
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                reminderTime,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            onTap: () async {
                              final parts = reminderTime.split(':');
                              final initial = TimeOfDay(
                                hour: int.tryParse(parts.first) ?? 20,
                                minute: parts.length > 1
                                    ? (int.tryParse(parts[1]) ?? 0)
                                    : 0,
                              );
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: initial,
                              );
                              if (picked != null) {
                                final formatted =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                await _setSetting(
                                  'daily_reminder_time',
                                  formatted,
                                );
                              }
                            },
                          ),
                        ],
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: streakAlert,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            'Alerta de Proteção de Ofensiva 🔥',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Avisa se você esquecer de guardar no dia',
                            style: TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) =>
                              _setSetting('streak_alert_enabled', val),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── 4. Som, Vibração e Mascote ───────────────────────────
                    _buildSectionTitle('🐷 Som, Vibração e Mascote'),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark: isDark,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: hapticsEnabled,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            'Vibração Tátil (Haptics)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Resposta tátil ao depositar e cuidar do Porko',
                            style: TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) =>
                              _setSetting('haptics_enabled', val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: soundEnabled,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            'Efeitos Sonoros de Moedas',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Sons alegres ao bater metas e conquistas',
                            style: TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) =>
                              _setSetting('sound_effects_enabled', val),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.pets_rounded,
                              color: Color(0xFF10B981),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Configurar Mascote (${mascot.name})',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Mude o nome, cuide do humor e veja os status',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MascotScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── 5. Preferências de Metas e Privacidade ───────────────
                    _buildSectionTitle('🔒 Metas e Privacidade'),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark: isDark,
                      children: [
                        SwitchListTile.adaptive(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 2,
                          ),
                          value: hideBalanceDefault,
                          activeThumbColor: const Color(0xFF2E7D32),
                          title: const Text(
                            r'Ocultar Saldo por Padrão (R$ ••••)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Revela por 3 segundos ao tocar no card de saldo',
                            style: TextStyle(fontSize: 11),
                          ),
                          onChanged: (val) =>
                              _setSetting('hide_balance_by_default', val),
                        ),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ritmo Padrão para Novas Metas',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildRhythmChip(
                                    'daily',
                                    '☀️ Diário',
                                    defaultRhythm,
                                    isDark,
                                  ),
                                  _buildRhythmChip(
                                    'weekly',
                                    '📅 Semanal',
                                    defaultRhythm,
                                    isDark,
                                  ),
                                  _buildRhythmChip(
                                    'monthly',
                                    '🗓️ Mensal',
                                    defaultRhythm,
                                    isDark,
                                  ),
                                  _buildRhythmChip(
                                    'free',
                                    '🌱 Livre',
                                    defaultRhythm,
                                    isDark,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── 6. Dados e Armazenamento 100% Offline ────────────────
                    _buildSectionTitle('💾 Backup e Dados Offline'),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark: isDark,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          leading: const Icon(
                            Icons.upload_file_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                          title: const Text(
                            'Exportar Backup (JSON)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Copia suas metas e histórico em formato JSON',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.copy_rounded, size: 18),
                          onTap: () => _exportBackupJson(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          leading: const Icon(
                            Icons.download_for_offline_rounded,
                            color: Color(0xFF0288D1),
                          ),
                          title: const Text(
                            'Restaurar Backup (JSON)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Importa dados de um backup salvo anteriormente',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () =>
                              _openImportBackupDialog(context, isDark),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          leading: const Icon(
                            Icons.delete_forever_rounded,
                            color: Color(0xFFEF4444),
                          ),
                          title: const Text(
                            'Resetar Todos os Dados',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                          subtitle: const Text(
                            'Apaga metas, depósitos e conquistas deste aparelho',
                            style: TextStyle(fontSize: 11),
                          ),
                          onTap: () => _confirmResetAllData(context, isDark),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── 7. Ajuda e Sobre o Oinc! ─────────────────────────────
                    _buildSectionTitle('ℹ️ Ajuda e Sobre'),
                    const SizedBox(height: 10),
                    _buildSettingsCard(
                      isDark: isDark,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                          ),
                          leading: const Icon(
                            Icons.waving_hand_rounded,
                            color: Color(0xFFF59E0B),
                          ),
                          title: const Text(
                            'Rever Boas-Vindas (Onboarding)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          subtitle: const Text(
                            'Reveja a apresentação inicial do Porko',
                            style: TextStyle(fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const OnboardingScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Oinc — Meu cofrinho virtual • v3.2.0',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '100% Offline, Seguro e Privado no seu Aparelho',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );
  }

  Widget _buildSettingsCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2E22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2F4A37) : const Color(0xFFE2E8E2),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildRhythmChip(
    String value,
    String label,
    String current,
    bool isDark,
  ) {
    final isSelected = value == current;
    return InkWell(
      onTap: () => _setSetting('default_rhythm', value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2E7D32)
              : (isDark ? const Color(0xFF243B2A) : const Color(0xFFEEF3EE)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF1A1A1A)),
          ),
        ),
      ),
    );
  }

  // Card tátil de escolha de tema
  Widget _buildThemeChoice({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.15)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? primary : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primary : theme.textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
