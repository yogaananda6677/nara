import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foundation = ref.watch(foundationControllerProvider).value;
    final profile = foundation?.profile;
    final preferences = foundation?.preferences ?? const AppPreferences();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text('Pengaturan', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 20),
        Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                profile?.name.isNotEmpty == true
                    ? profile!.name.substring(0, 1).toUpperCase()
                    : 'N',
              ),
            ),
            title: Text(profile?.name ?? 'Profil lokal'),
            subtitle: Text('Asisten: ${profile?.assistantName ?? 'Nara'}'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: profile == null
                ? null
                : () => _editProfile(
                    context,
                    ref,
                    profile.name,
                    profile.assistantName,
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Tampilan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tema aplikasi'),
                const SizedBox(height: 12),
                SegmentedButton<ThemePreference>(
                  segments: const [
                    ButtonSegment(
                      value: ThemePreference.system,
                      icon: Icon(Icons.settings_brightness),
                      label: Text('Sistem'),
                    ),
                    ButtonSegment(
                      value: ThemePreference.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Terang'),
                    ),
                    ButtonSegment(
                      value: ThemePreference.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Gelap'),
                    ),
                  ],
                  selected: {preferences.theme},
                  onSelectionChanged: (selection) {
                    ref
                        .read(foundationControllerProvider.notifier)
                        .updatePreferences(
                          preferences.copyWith(theme: selection.single),
                        );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text('Regional', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Bahasa'),
                trailing: Text(
                  preferences.language == 'id'
                      ? 'Indonesia'
                      : preferences.language,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: const Text('Mata uang'),
                trailing: Text(preferences.currency),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: const Text('Zona waktu'),
                trailing: Text(preferences.timezone),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text('Keamanan', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Kunci aplikasi'),
            subtitle: const Text(
              'Lifecycle guard siap. Aktivasi PIN/biometrik dilakukan pada fase security.',
            ),
            value: preferences.appLockEnabled,
            onChanged: null,
          ),
        ),
        const SizedBox(height: 24),
        const Card(
          child: ListTile(
            leading: Icon(Icons.offline_bolt),
            title: Text('Nara V1 Offline'),
            subtitle: Text('Tidak menggunakan backend, cloud, atau API AI.'),
            trailing: Text('1.0.0'),
          ),
        ),
      ],
    );
  }

  Future<void> _editProfile(
    BuildContext context,
    WidgetRef ref,
    String currentName,
    String currentAssistantName,
  ) async {
    final nameController = TextEditingController(text: currentName);
    final assistantController = TextEditingController(
      text: currentAssistantName,
    );
    final formKey = GlobalKey<FormState>();

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profil lokal'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Anda'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: assistantController,
                decoration: const InputDecoration(labelText: 'Nama asisten'),
                validator: _required,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (submitted == true && context.mounted) {
      final result = await ref
          .read(foundationControllerProvider.notifier)
          .saveProfile(
            name: nameController.text,
            assistantName: assistantController.text,
          );
      if (result case Failure(:final failure)) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      }
    }

    nameController.dispose();
    assistantController.dispose();
  }

  static String? _required(String? value) {
    return value == null || value.trim().isEmpty ? 'Wajib diisi.' : null;
  }
}
