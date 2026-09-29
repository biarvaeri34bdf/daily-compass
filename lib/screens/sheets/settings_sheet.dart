import 'package:flutter/material.dart';

import '../../assets.dart';
import '../../game/storage.dart';
import '../../theme.dart';

enum SettingsAction { resetToday, resetAll }

/// Preferences plus the two destructive resets.
class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final void Function(AppSettings) onChanged;

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late AppSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettings(
      eveningReminder: widget.settings.eveningReminder,
      haptics: widget.settings.haptics,
      weeklyHints: widget.settings.weeklyHints,
    );
  }

  void _apply(void Function() mutate) {
    setState(mutate);
    widget.onChanged(_settings);
  }

  Future<void> _confirm(SettingsAction action) async {
    final isAll = action == SettingsAction.resetAll;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Text(
          isAll ? 'Reset all data' : 'Reset today',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          isAll
              ? 'Routines and history go back to defaults. This cannot be undone.'
              : 'Clears every check-in logged for today.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isAll ? 'RESET ALL' : 'RESET',
              style: const TextStyle(
                color: AppColors.accentDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      Navigator.of(context).pop(action);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.5,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: <Widget>[
            const SizedBox(height: 12),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                AppAssets.icon,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.4,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: <Widget>[
                  SwitchListTile(
                    value: _settings.eveningReminder,
                    title: const Text('Evening reminder card'),
                    onChanged: (v) =>
                        _apply(() => _settings.eveningReminder = v),
                  ),
                  SwitchListTile(
                    value: _settings.haptics,
                    title: const Text('Haptics'),
                    onChanged: (v) => _apply(() => _settings.haptics = v),
                  ),
                  SwitchListTile(
                    value: _settings.weeklyHints,
                    title: const Text('Show weekly hints'),
                    onChanged: (v) => _apply(() => _settings.weeklyHints = v),
                  ),
                  const Divider(color: AppColors.hairline),
                  ListTile(
                    leading: const Icon(
                      Icons.refresh,
                      color: AppColors.textSecondary,
                    ),
                    title: const Text('Reset today'),
                    onTap: () => _confirm(SettingsAction.resetToday),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline,
                      color: AppColors.accentDeep,
                    ),
                    title: const Text('Reset all data'),
                    onTap: () => _confirm(SettingsAction.resetAll),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 18, top: 6),
              child: Text(
                'VERSION 1.0.0 · OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.4,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
