import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nara/features/foundation/presentation/providers/foundation_providers.dart';
import 'package:nara/features/security/domain/entities/security_entities.dart';
import 'package:nara/features/security/presentation/providers/security_providers.dart';

final appLockedProvider = NotifierProvider<AppLockController, bool>(
  AppLockController.new,
);

class AppLockController extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;

  void unlock() => state = false;
}

class AppLifecycleLock extends ConsumerStatefulWidget {
  const AppLifecycleLock({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppLifecycleLock> createState() => _AppLifecycleLockState();
}

class _AppLifecycleLockState extends ConsumerState<AppLifecycleLock>
    with WidgetsBindingObserver {
  final _pinController = TextEditingController();
  DateTime? _backgroundedAt;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _lockOnColdStart());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final preferences = ref
        .read(foundationControllerProvider)
        .value
        ?.preferences;
    if (!(preferences?.appLockEnabled ?? false)) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _backgroundedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed && _backgroundedAt != null) {
      final elapsed = DateTime.now().difference(_backgroundedAt!).inSeconds;
      _backgroundedAt = null;
      if (elapsed >= (preferences?.lockTimeoutSeconds ?? 30)) {
        ref.read(appLockedProvider.notifier).lock();
      }
    }
  }

  Future<void> _lockOnColdStart() async {
    final foundation = await ref.read(foundationControllerProvider.future);
    if (mounted && foundation.preferences.appLockEnabled) {
      ref.read(appLockedProvider.notifier).lock();
    }
  }

  Future<void> _unlockWithPin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref
        .read(pinSecurityServiceProvider)
        .verify(_pinController.text);
    if (!mounted) return;
    if (result.isSuccess) {
      _pinController.clear();
      ref.read(appLockedProvider.notifier).unlock();
    } else {
      setState(() {
        _busy = false;
        _error = switch (result.status) {
          PinVerificationStatus.locked =>
            'Terlalu banyak percobaan. Coba lagi dalam ${result.remainingSeconds} detik.',
          PinVerificationStatus.notConfigured =>
            'PIN belum tersedia. Pulihkan akses melalui pengaturan aplikasi.',
          _ => 'PIN salah. Silakan coba lagi.',
        };
      });
    }
  }

  Future<void> _unlockWithBiometric() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final success = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate(reason: 'Buka kunci Nara');
    if (!mounted) return;
    if (success) {
      ref.read(appLockedProvider.notifier).unlock();
    } else {
      setState(() {
        _busy = false;
        _error = 'Biometrik tidak berhasil. Gunakan PIN sebagai alternatif.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockedProvider);
    if (!isLocked) return widget.child;

    final preferences = ref
        .watch(foundationControllerProvider)
        .value
        ?.preferences;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                  semanticLabel: 'Aplikasi terkunci',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nara terkunci',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text('Masukkan PIN 6 angka untuk melanjutkan.'),
                const SizedBox(height: 20),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TextField(
                    controller: _pinController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _unlockWithPin(),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _unlockWithPin,
                  icon: _busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.lock_open),
                  label: const Text('Buka dengan PIN'),
                ),
                if (preferences?.biometricEnabled ?? false) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _busy ? null : _unlockWithBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Gunakan biometrik'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
