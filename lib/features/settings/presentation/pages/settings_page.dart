import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/core/result/result.dart';
import 'package:nara/database/database_provider.dart';
import 'package:nara/features/backup/application/backup_codec.dart';
import 'package:nara/features/backup/presentation/providers/backup_providers.dart';
import 'package:nara/features/foundation/domain/entities/app_preferences.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';
import 'package:nara/features/security/domain/entities/security_entities.dart';
import 'package:nara/features/security/presentation/providers/security_providers.dart';

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
        _SecuritySettingsCard(preferences: preferences),
        const SizedBox(height: 24),
        Text('Backup lokal', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const _BackupSettingsCard(),
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

class _SecuritySettingsCard extends ConsumerWidget {
  const _SecuritySettingsCard({required this.preferences});

  final AppPreferences preferences;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            secondary: const Icon(Icons.lock_outline),
            title: const Text('Kunci aplikasi'),
            subtitle: const Text('PIN disimpan sebagai hash, bukan teks asli.'),
            value: preferences.appLockEnabled,
            onChanged: (enabled) => enabled
                ? _enableLock(context, ref)
                : _disableLock(context, ref),
          ),
          if (preferences.appLockEnabled) ...[
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Buka dengan biometrik'),
              subtitle: const Text('PIN tetap tersedia sebagai alternatif.'),
              value: preferences.biometricEnabled,
              onChanged: (enabled) => _setBiometric(context, ref, enabled),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Kunci setelah'),
              trailing: DropdownButton<int>(
                value: preferences.lockTimeoutSeconds,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Langsung')),
                  DropdownMenuItem(value: 30, child: Text('30 detik')),
                  DropdownMenuItem(value: 60, child: Text('1 menit')),
                  DropdownMenuItem(value: 300, child: Text('5 menit')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(foundationControllerProvider.notifier)
                        .updatePreferences(
                          preferences.copyWith(lockTimeoutSeconds: value),
                        );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _enableLock(BuildContext context, WidgetRef ref) async {
    final pins = await _pinDialog(context, confirm: true);
    if (pins == null || !context.mounted) return;
    if (pins.$1 != pins.$2) {
      _message(context, 'Konfirmasi PIN tidak sama.');
      return;
    }
    try {
      await ref.read(pinSecurityServiceProvider).setPin(pins.$1);
      await ref
          .read(foundationControllerProvider.notifier)
          .updatePreferences(preferences.copyWith(appLockEnabled: true));
      if (context.mounted) _message(context, 'Kunci aplikasi aktif.');
    } on FormatException catch (error) {
      if (context.mounted) _message(context, error.message);
    }
  }

  Future<void> _disableLock(BuildContext context, WidgetRef ref) async {
    final pins = await _pinDialog(context);
    if (pins == null || !context.mounted) return;
    final result = await ref.read(pinSecurityServiceProvider).verify(pins.$1);
    if (!context.mounted) return;
    if (!result.isSuccess) {
      _message(
        context,
        result.status == PinVerificationStatus.locked
            ? 'Akses sementara dikunci. Tunggu ${result.remainingSeconds} detik.'
            : 'PIN salah. Kunci aplikasi tetap aktif.',
      );
      return;
    }
    await ref.read(pinSecurityServiceProvider).removePin();
    await ref
        .read(foundationControllerProvider.notifier)
        .updatePreferences(
          preferences.copyWith(appLockEnabled: false, biometricEnabled: false),
        );
    if (context.mounted) _message(context, 'Kunci aplikasi dinonaktifkan.');
  }

  Future<void> _setBiometric(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      final authenticator = ref.read(biometricAuthenticatorProvider);
      if (!await authenticator.isAvailable()) {
        if (context.mounted) {
          _message(context, 'Biometrik belum tersedia di perangkat ini.');
        }
        return;
      }
      if (!await authenticator.authenticate(
        reason: 'Konfirmasi aktivasi biometrik Nara',
      )) {
        if (context.mounted) {
          _message(context, 'Konfirmasi biometrik dibatalkan.');
        }
        return;
      }
    }
    await ref
        .read(foundationControllerProvider.notifier)
        .updatePreferences(preferences.copyWith(biometricEnabled: enabled));
  }

  Future<(String, String)?> _pinDialog(
    BuildContext context, {
    bool confirm = false,
  }) async {
    final pin = TextEditingController();
    final confirmation = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(confirm ? 'Buat PIN Nara' : 'Konfirmasi PIN'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinField(pin, 'PIN 6 angka'),
              if (confirm) ...[
                const SizedBox(height: 12),
                _pinField(confirmation, 'Ulangi PIN'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(dialogContext, (
                  pin.text,
                  confirm ? confirmation.text : '',
                ));
              }
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    pin.dispose();
    confirmation.dispose();
    return result;
  }

  Widget _pinField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 6,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (value) => value?.length == 6 ? null : 'Harus tepat 6 angka.',
    );
  }
}

class _BackupSettingsCard extends ConsumerStatefulWidget {
  const _BackupSettingsCard();

  @override
  ConsumerState<_BackupSettingsCard> createState() =>
      _BackupSettingsCardState();
}

class _BackupSettingsCardState extends ConsumerState<_BackupSettingsCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Backup dienkripsi di perangkat. Simpan password sendiri; Nara tidak dapat memulihkannya.',
            ),
          ),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: const Text('Buat backup terenkripsi'),
            subtitle: const Text('Data keamanan PIN tidak ikut diekspor.'),
            enabled: !_busy,
            onTap: () => _runBackup(restore: false),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Pulihkan dari backup'),
            subtitle: const Text(
              'Data lokal saat ini akan diganti setelah validasi.',
            ),
            enabled: !_busy,
            onTap: () => _runBackup(restore: true),
          ),
          if (_busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }

  Future<void> _runBackup({required bool restore}) async {
    final password = await _passwordDialog(restore: restore);
    if (password == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final service = ref.read(backupFileServiceProvider);
      final completed = restore
          ? await service.restore(password)
          : await service.export(password);
      if (!mounted) return;
      if (completed && restore) {
        ref.invalidate(appDatabaseProvider);
      }
      _message(
        context,
        completed
            ? restore
                  ? 'Restore selesai. Kunci aplikasi dinonaktifkan untuk keamanan.'
                  : 'Backup terenkripsi berhasil disimpan.'
            : 'Proses dibatalkan.',
      );
    } on BackupException catch (error) {
      if (mounted) _message(context, error.message);
    } catch (_) {
      if (mounted) _message(context, 'Proses gagal. Data lokal tidak diubah.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _passwordDialog({required bool restore}) async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(restore ? 'Password backup' : 'Lindungi backup'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Password minimal 8 karakter',
            ),
            validator: (value) =>
                (value?.length ?? 0) < 8 ? 'Minimal 8 karakter.' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: Text(restore ? 'Pilih file' : 'Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();
    return password;
  }
}

void _message(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
