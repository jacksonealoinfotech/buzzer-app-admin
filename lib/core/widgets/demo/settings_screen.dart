import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:buzzer_app_admin/core/localization/locale_cubit.dart';
import 'package:buzzer_app_admin/core/responsive/app_spacing.dart';
import 'package:buzzer_app_admin/core/theme/theme_cubit.dart';
import 'package:buzzer_app_admin/core/widgets/display/common_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final localeCubit = context.watch<LocaleCubit>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          const SectionHeader(title: 'Preferences'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme Mode'),
                  subtitle: Text(themeCubit.state.name.toUpperCase()),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => themeCubit.toggleTheme(),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language'),
                  subtitle: Text(localeCubit.state.languageCode.toUpperCase()),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                  ),
                  onTap: () => localeCubit.toggleLocale(),
                ),
              ],
            ),
          ),
          Gap.v16,
          const SectionHeader(title: 'Security & Diagnostics'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: const Text('Security Self-Check'),
              subtitle: const Text('Inspect OWASP MASVS enforcement'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/security-check'),
            ),
          ),
        ],
      ),
    );
  }
}
